namespace ProductsApi.Services;

// Abstraction over "publish this event somewhere". Keeps the controller/service
// layer decoupled from the specific messaging technology (Service Bus today,
// could be swapped for another broker later without touching calling code).
public interface IEventPublisher
{
    Task PublishAsync<T>(string topicName, string eventType, T payload);
}
