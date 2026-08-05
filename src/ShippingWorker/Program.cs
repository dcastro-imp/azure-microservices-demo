using Azure.Identity;
using Azure.Messaging.ServiceBus;
using ShippingWorker;

var builder = Host.CreateApplicationBuilder(args);

var serviceBusNamespace = builder.Configuration["ServiceBusNamespace"]
    ?? throw new InvalidOperationException("ServiceBusNamespace configuration is required.");

builder.Services.AddSingleton(new ServiceBusClient(serviceBusNamespace, new DefaultAzureCredential(),
    new ServiceBusClientOptions { TransportType = ServiceBusTransportType.AmqpWebSockets }));
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();
