using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.EntityFrameworkCore;
using ProductsApi.Data;
using ProductsApi.Services;

// The WebApplicationBuilder sets up configuration, logging, and DI.
var builder = WebApplication.CreateBuilder(args);

var keyVaultName = builder.Configuration["KeyVaultName"];
if (!string.IsNullOrWhiteSpace(keyVaultName))
{
    builder.Configuration.AddAzureKeyVault(new Uri($"https://{keyVaultName}.vault.azure.net/"), new Azure.Identity.DefaultAzureCredential());
}

// ---- Register services in the Dependency Injection container ----

// Enables controller-based endpoints (our ProductsController).
builder.Services.AddControllers();

// Register the EF Core DbContext. Locally (dotnet run) we default to SQLite
// for a zero-setup dev experience. In Azure, setting UseSqlServer=true (an
// App Service application setting) switches to Azure SQL Database, using
// the connection string's "Active Directory Managed Identity" auth mode —
// no password anywhere.
var useSqlServer = builder.Configuration.GetValue<bool>("UseSqlServer");
builder.Services.AddDbContext<AppDbContext>(options =>
{
    if (useSqlServer)
    {
        options.UseSqlServer(builder.Configuration.GetConnectionString("Default"));
    }
    else
    {
        options.UseSqlite(builder.Configuration.GetConnectionString("Default")
                          ?? "Data Source=products.db");
    }
});

// Register the EF-backed data service. It's SCOPED because the DbContext
// it depends on is scoped (one instance per HTTP request).
builder.Services.AddScoped<IProductService, EfProductService>();

// Event publishing: if a Service Bus namespace is configured, publish real
// events using Managed Identity (no connection string/key anywhere). Falls
// back to a no-op publisher for local dev without cloud resources.
var serviceBusNamespace = builder.Configuration["ServiceBusNamespace"];
if (!string.IsNullOrWhiteSpace(serviceBusNamespace))
{
    // AmqpWebSockets (443) instead of native AMQP (5671) — see InventoryWorker/Program.cs for details.
    builder.Services.AddSingleton(new ServiceBusClient(serviceBusNamespace, new Azure.Identity.DefaultAzureCredential(),
        new ServiceBusClientOptions { TransportType = ServiceBusTransportType.AmqpWebSockets }));
    builder.Services.AddSingleton<IEventPublisher, ServiceBusEventPublisher>();

    // Administration client for the /api/status dashboard endpoint. This needs
    // broader "Data Owner" permissions than the sender above — a deliberate,
    // documented trade-off for observability (see AZURE-LEARNING-GUIDE.md).
    builder.Services.AddSingleton(new Azure.Messaging.ServiceBus.Administration.ServiceBusAdministrationClient(
        serviceBusNamespace, new Azure.Identity.DefaultAzureCredential()));
}
else
{
    builder.Services.AddSingleton<IEventPublisher, NoOpEventPublisher>();
}

// CORS: allows the React frontend (served from a different origin) to call this API.
builder.Services.AddCors(options =>
{
    options.AddPolicy("frontend", policy => policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

// Swagger/OpenAPI: auto-generates interactive API docs + a test UI.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Ensure the database schema exists on startup. SQLite uses EF Core
// migrations (versioned, tracked in Migrations/). SQL Server uses
// EnsureCreated() instead, since we don't maintain a separate migrations
// set for that provider — fine for this project's simple, stable schema.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    if (useSqlServer)
    {
        db.Database.EnsureCreated();
    }
    else
    {
        db.Database.Migrate();
    }
}

// ---- Configure the HTTP request pipeline (middleware) ----

// Show Swagger UI at the root (/) so it's easy to explore in the browser.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "Products API v1");
        options.RoutePrefix = string.Empty; // serve UI at "/"
    });
}

if (app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors("frontend");
app.UseAuthorization();

// Map controller routes (e.g. /api/products).
app.MapControllers();

app.Run();
