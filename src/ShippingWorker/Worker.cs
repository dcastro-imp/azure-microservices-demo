using System.Text.Json;
using Azure.Messaging.ServiceBus;
using Microsoft.Data.SqlClient;

namespace ShippingWorker;

public class Worker(ILogger<Worker> logger, ServiceBusClient client, IConfiguration config) : BackgroundService
{
    private ServiceBusProcessor? _processor;
    private ServiceBusSender? _sender;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _sender = client.CreateSender("orders");
        _processor = client.CreateProcessor("orders", "stock-reserved-sub");
        _processor.ProcessMessageAsync += HandleMessageAsync;
        _processor.ProcessErrorAsync += HandleErrorAsync;
        await _processor.StartProcessingAsync(stoppingToken);

        logger.LogInformation("ShippingWorker listening on 'orders/stock-reserved-sub'");
        await Task.Delay(Timeout.Infinite, stoppingToken).ContinueWith(_ => { });
    }

    private async Task HandleMessageAsync(ProcessMessageEventArgs args)
    {
        var payload = JsonSerializer.Deserialize<StockReservedEvent>(args.Message.Body.ToString())!;
        logger.LogInformation("[Shipping] StockReserved: OrderId={OrderId}", payload.OrderId);

        // Simulate the real work of preparing a shipment (label, packing, carrier pickup).
        await Task.Delay(TimeSpan.FromSeconds(3));

        var connectionString = config.GetConnectionString("Default");
        await using var conn = new SqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new SqlCommand("UPDATE Orders SET Status = 'Shipped' WHERE Id = @OrderId;", conn);
        cmd.Parameters.AddWithValue("@OrderId", payload.OrderId);
        await cmd.ExecuteNonQueryAsync();

        logger.LogInformation("[Shipping] Order {OrderId} marked as Shipped", payload.OrderId);

        var message = new ServiceBusMessage(JsonSerializer.Serialize(new { payload.OrderId }))
        {
            Subject = "ShippingScheduled"
        };
        await _sender!.SendMessageAsync(message);

        await args.CompleteMessageAsync(args.Message);
    }

    private Task HandleErrorAsync(ProcessErrorEventArgs args)
    {
        logger.LogError(args.Exception, "[Shipping] Error processing message");
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_processor is not null) await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
    }
}

public record StockReservedEvent(int OrderId, int ProductId, int Quantity);
