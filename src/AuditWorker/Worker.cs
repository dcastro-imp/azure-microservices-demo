using System.Text.Json;
using Azure.Messaging.ServiceBus;
using Microsoft.Data.SqlClient;

namespace AuditWorker;

// This subscription has NO SQL filter — it receives a copy of every event
// published to the "orders" topic, regardless of type. That's what makes it
// possible to build a complete, ordered timeline per order.
public class Worker(ILogger<Worker> logger, ServiceBusClient client, IConfiguration config) : BackgroundService
{
    private ServiceBusProcessor? _processor;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _processor = client.CreateProcessor("orders", "audit-sub");
        _processor.ProcessMessageAsync += HandleMessageAsync;
        _processor.ProcessErrorAsync += HandleErrorAsync;
        await _processor.StartProcessingAsync(stoppingToken);

        logger.LogInformation("AuditWorker listening on 'orders/audit-sub' (no filter — catches everything)");
        await Task.Delay(Timeout.Infinite, stoppingToken).ContinueWith(_ => { });
    }

    private async Task HandleMessageAsync(ProcessMessageEventArgs args)
    {
        var eventType = args.Message.Subject;
        var body = args.Message.Body.ToString();
        logger.LogInformation("[Audit] Recording event '{EventType}': {Body}", eventType, body);

        using var doc = JsonDocument.Parse(body);
        var orderId = doc.RootElement.GetProperty("OrderId").GetInt32();

        var connectionString = config.GetConnectionString("Default");
        await using var conn = new SqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new SqlCommand(
            "INSERT INTO EventLog (OrderId, EventType, Payload) VALUES (@OrderId, @EventType, @Payload);", conn);
        cmd.Parameters.AddWithValue("@OrderId", orderId);
        cmd.Parameters.AddWithValue("@EventType", eventType);
        cmd.Parameters.AddWithValue("@Payload", body);
        await cmd.ExecuteNonQueryAsync();

        await args.CompleteMessageAsync(args.Message);
    }

    private Task HandleErrorAsync(ProcessErrorEventArgs args)
    {
        logger.LogError(args.Exception, "[Audit] Error processing message");
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_processor is not null) await _processor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
    }
}
