namespace ProductsApi.Services;

// Used when no Service Bus namespace is configured (e.g. local dev without
// cloud resources). Lets the API run end-to-end without failing on startup.
public class NoOpEventPublisher : IEventPublisher
{
    private readonly ILogger<NoOpEventPublisher> _logger;

    public NoOpEventPublisher(ILogger<NoOpEventPublisher> logger)
    {
        _logger = logger;
    }

    public Task PublishAsync<T>(string topicName, string eventType, T payload)
    {
        _logger.LogInformation("(No-op) Would publish '{EventType}' to topic '{Topic}' — no ServiceBusNamespace configured", eventType, topicName);
        return Task.CompletedTask;
    }
}
