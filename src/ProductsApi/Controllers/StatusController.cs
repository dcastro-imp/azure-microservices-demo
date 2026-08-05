using Azure.Messaging.ServiceBus.Administration;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProductsApi.Data;

namespace ProductsApi.Controllers;

// Exposes a snapshot of the underlying architecture's live state — useful for
// a dashboard, but note it needs broader Service Bus permissions than the
// rest of the app (see AZURE-LEARNING-GUIDE.md for the RBAC trade-off).
[ApiController]
[Route("api/status")]
public class StatusController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ServiceBusAdministrationClient? _sbAdmin;

    public StatusController(AppDbContext db, ServiceBusAdministrationClient? sbAdmin = null)
    {
        _db = db;
        _sbAdmin = sbAdmin;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var databaseStatus = new
        {
            connected = true,
            productCount = await _db.Products.CountAsync()
        };

        object? serviceBusStatus = null;
        if (_sbAdmin is not null)
        {
            var inventorySub = await _sbAdmin.GetSubscriptionRuntimePropertiesAsync("products", "inventory-sub");
            var notificationSub = await _sbAdmin.GetSubscriptionRuntimePropertiesAsync("products", "notification-sub");

            serviceBusStatus = new
            {
                inventorySubscription = new
                {
                    activeMessages = inventorySub.Value.ActiveMessageCount,
                    deadLetterMessages = inventorySub.Value.DeadLetterMessageCount
                },
                notificationSubscription = new
                {
                    activeMessages = notificationSub.Value.ActiveMessageCount,
                    deadLetterMessages = notificationSub.Value.DeadLetterMessageCount
                }
            };
        }

        return Ok(new { database = databaseStatus, serviceBus = serviceBusStatus });
    }
}
