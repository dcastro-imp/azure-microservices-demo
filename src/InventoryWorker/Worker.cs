using System.Text.Json;
using Azure.Messaging.ServiceBus;
using Microsoft.Data.SqlClient;

namespace InventoryWorker;

public class Worker(ILogger<Worker> logger, ServiceBusClient client, IConfiguration config) : BackgroundService
{
    private ServiceBusProcessor? _productsProcessor;
    private ServiceBusProcessor? _ordersProcessor;
    private ServiceBusSender? _ordersSender;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Original demo pipeline: "products" topic, logs only.
        _productsProcessor = client.CreateProcessor("products", "inventory-sub");
        _productsProcessor.ProcessMessageAsync += HandleProductMessageAsync;
        _productsProcessor.ProcessErrorAsync += HandleErrorAsync;
        await _productsProcessor.StartProcessingAsync(stoppingToken);

        // Real pipeline: "orders" topic, "order-created-sub" — checks actual
        // stock in SQL and decides whether the order can proceed.
        _ordersSender = client.CreateSender("orders");
        _ordersProcessor = client.CreateProcessor("orders", "order-created-sub");
        _ordersProcessor.ProcessMessageAsync += HandleOrderCreatedAsync;
        _ordersProcessor.ProcessErrorAsync += HandleErrorAsync;
        await _ordersProcessor.StartProcessingAsync(stoppingToken);

        logger.LogInformation("InventoryWorker listening on 'products/inventory-sub' and 'orders/order-created-sub'");

        await Task.Delay(Timeout.Infinite, stoppingToken).ContinueWith(_ => { });
    }

    private async Task HandleProductMessageAsync(ProcessMessageEventArgs args)
    {
        var body = args.Message.Body.ToString();
        logger.LogInformation("[Inventory] Received '{EventType}': {Body}", args.Message.Subject, body);

        // Simulated business logic: this is where you'd check/reserve stock,
        // reorder from a supplier, update a warehouse system, etc.
        // The delay stands in for a real, slower downstream call — without it,
        // processing is too fast for a backlog to ever build up, so KEDA never
        // sees a reason to scale out.
        await Task.Delay(TimeSpan.FromSeconds(4));
        logger.LogInformation("[Inventory] Reserved stock for new product.");

        // Marks the message as successfully processed and removes it from the
        // subscription. If we never call this (or the process crashes first),
        // Service Bus redelivers it automatically after a lock timeout.
        await args.CompleteMessageAsync(args.Message);
    }

    private async Task HandleOrderCreatedAsync(ProcessMessageEventArgs args)
    {
        var payload = JsonSerializer.Deserialize<OrderCreatedEvent>(args.Message.Body.ToString())!;
        logger.LogInformation("[Inventory] OrderCreated: OrderId={OrderId} ProductId={ProductId} Qty={Qty}",
            payload.OrderId, payload.ProductId, payload.Quantity);

        var connectionString = config.GetConnectionString("Default");
        await using var conn = new SqlConnection(connectionString);
        await conn.OpenAsync();

        // Check current stock.
        int currentStock;
        await using (var checkCmd = new SqlCommand("SELECT Stock FROM Products WHERE Id = @ProductId", conn))
        {
            checkCmd.Parameters.AddWithValue("@ProductId", payload.ProductId);
            var result = await checkCmd.ExecuteScalarAsync();
            currentStock = result is null ? 0 : (int)result;
        }

        if (currentStock >= payload.Quantity)
        {
            // Enough stock: decrement it and mark the order as reserved.
            await using (var updateCmd = new SqlCommand(
                "UPDATE Products SET Stock = Stock - @Qty WHERE Id = @ProductId; " +
                "UPDATE Orders SET Status = 'StockReserved' WHERE Id = @OrderId;", conn))
            {
                updateCmd.Parameters.AddWithValue("@Qty", payload.Quantity);
                updateCmd.Parameters.AddWithValue("@ProductId", payload.ProductId);
                updateCmd.Parameters.AddWithValue("@OrderId", payload.OrderId);
                await updateCmd.ExecuteNonQueryAsync();
            }

            logger.LogInformation("[Inventory] Stock reserved for OrderId={OrderId}", payload.OrderId);
            await PublishAsync("StockReserved", new { payload.OrderId, payload.ProductId, payload.Quantity });
        }
        else
        {
            await using var updateCmd = new SqlCommand("UPDATE Orders SET Status = 'Failed' WHERE Id = @OrderId;", conn);
            updateCmd.Parameters.AddWithValue("@OrderId", payload.OrderId);
            await updateCmd.ExecuteNonQueryAsync();

            logger.LogWarning("[Inventory] Insufficient stock for OrderId={OrderId} (has {Stock}, needs {Qty})",
                payload.OrderId, currentStock, payload.Quantity);
            await PublishAsync("StockReservationFailed", new
            {
                payload.OrderId,
                Reason = $"Insufficient stock (has {currentStock}, needs {payload.Quantity})"
            });
        }

        await args.CompleteMessageAsync(args.Message);
    }

    private async Task PublishAsync<T>(string eventType, T payload)
    {
        var message = new ServiceBusMessage(JsonSerializer.Serialize(payload)) { Subject = eventType };
        await _ordersSender!.SendMessageAsync(message);
        logger.LogInformation("[Inventory] Published '{EventType}'", eventType);
    }

    private Task HandleErrorAsync(ProcessErrorEventArgs args)
    {
        logger.LogError(args.Exception, "[Inventory] Error processing message");
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_productsProcessor is not null) await _productsProcessor.StopProcessingAsync(cancellationToken);
        if (_ordersProcessor is not null) await _ordersProcessor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
    }
}

public record OrderCreatedEvent(int OrderId, int ProductId, string ProductName, int Quantity);
