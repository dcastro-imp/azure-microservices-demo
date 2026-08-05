using System.Text.Json;
using Azure.Messaging.ServiceBus;

namespace NotificationWorker;

public class Worker(ILogger<Worker> logger, ServiceBusClient client) : BackgroundService
{
    private ServiceBusProcessor? _productsProcessor;
    private ServiceBusProcessor? _orderStatusProcessor;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _productsProcessor = client.CreateProcessor("products", "notification-sub");
        _productsProcessor.ProcessMessageAsync += HandleProductMessageAsync;
        _productsProcessor.ProcessErrorAsync += HandleErrorAsync;
        await _productsProcessor.StartProcessingAsync(stoppingToken);

        // order-status-sub has a filter for Subject IN ('StockReservationFailed','ShippingScheduled')
        // — this worker notifies the "customer" of either outcome, without needing DB access at all.
        _orderStatusProcessor = client.CreateProcessor("orders", "order-status-sub");
        _orderStatusProcessor.ProcessMessageAsync += HandleOrderStatusAsync;
        _orderStatusProcessor.ProcessErrorAsync += HandleErrorAsync;
        await _orderStatusProcessor.StartProcessingAsync(stoppingToken);

        logger.LogInformation("NotificationWorker listening on 'products/notification-sub' and 'orders/order-status-sub'");
        await Task.Delay(Timeout.Infinite, stoppingToken).ContinueWith(_ => { });
    }

    private async Task HandleProductMessageAsync(ProcessMessageEventArgs args)
    {
        var body = args.Message.Body.ToString();
        logger.LogInformation("[Notification] Received '{EventType}': {Body}", args.Message.Subject, body);

        // Simulated business logic: send an email/push notification, post to
        // a Slack channel, etc. Independent of InventoryWorker's processing.
        logger.LogInformation("[Notification] Sent 'new product available' notification.");

        await args.CompleteMessageAsync(args.Message);
    }

    private async Task HandleOrderStatusAsync(ProcessMessageEventArgs args)
    {
        var eventType = args.Message.Subject;
        var body = args.Message.Body.ToString();

        if (eventType == "ShippingScheduled")
        {
            logger.LogInformation("[Notification] Order shipped! Notifying customer: {Body}", body);
        }
        else
        {
            logger.LogWarning("[Notification] Order failed! Notifying customer: {Body}", body);
        }

        await args.CompleteMessageAsync(args.Message);
    }

    private Task HandleErrorAsync(ProcessErrorEventArgs args)
    {
        logger.LogError(args.Exception, "[Notification] Error processing message");
        return Task.CompletedTask;
    }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        if (_productsProcessor is not null) await _productsProcessor.StopProcessingAsync(cancellationToken);
        if (_orderStatusProcessor is not null) await _orderStatusProcessor.StopProcessingAsync(cancellationToken);
        await base.StopAsync(cancellationToken);
    }
}
