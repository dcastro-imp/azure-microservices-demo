using Azure.Identity;
using Azure.Messaging.ServiceBus;
using InventoryWorker;

var builder = Host.CreateApplicationBuilder(args);

var serviceBusNamespace = builder.Configuration["ServiceBusNamespace"]
    ?? throw new InvalidOperationException("ServiceBusNamespace configuration is required.");

// AmqpWebSockets (port 443) instead of the native AMQP port (5671): in some
// VNet-integrated environments, outbound traffic on 5671 is restricted while
// 443 remains open. WebSockets tunnels AMQP over the same port HTTPS uses.
builder.Services.AddSingleton(new ServiceBusClient(serviceBusNamespace, new DefaultAzureCredential(),
    new ServiceBusClientOptions { TransportType = ServiceBusTransportType.AmqpWebSockets }));
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();
