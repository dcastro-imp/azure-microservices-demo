using System.Text.Json;
using Azure.Messaging.ServiceBus;

namespace ProductsApi.Services;

public class ServiceBusEventPublisher : IEventPublisher
{
    private readonly ServiceBusClient _client;
    private readonly ILogger<ServiceBusEventPublisher> _logger;

    public ServiceBusEventPublisher(ServiceBusClient client, ILogger<ServiceBusEventPublisher> logger)
    {
        _client = client;
        _logger = logger;
    }

    public async Task PublishAsync<T>(string topicName, string eventType, T payload)
    {
        // A new sender per call is fine here: ServiceBusClient pools the
        // underlying connection, so senders are cheap to create.
        var sender = _client.CreateSender(topicName);

        var message = new ServiceBusMessage(JsonSerializer.Serialize(payload))
        {
            ContentType = "application/json",
            Subject = eventType // lets subscribers filter by event type if needed
        };

        await sender.SendMessageAsync(message);
        _logger.LogInformation("Published event '{EventType}' to topic '{Topic}'", eventType, topicName);
    }
}
