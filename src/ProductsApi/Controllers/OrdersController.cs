using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProductsApi.Data;
using ProductsApi.Models;
using ProductsApi.Services;

namespace ProductsApi.Controllers;

[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IEventPublisher _eventPublisher;

    public OrdersController(AppDbContext db, IEventPublisher eventPublisher)
    {
        _db = db;
        _eventPublisher = eventPublisher;
    }

    // GET /api/orders -> list all orders (newest first), so the frontend can
    // show live status as inventory-worker/shipping-worker process them async.
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Order>>> GetAll()
    {
        return Ok(await _db.Orders.AsNoTracking().OrderByDescending(o => o.Id).ToListAsync());
    }

    // GET /api/orders/5/events -> the event timeline for one order, written by
    // audit-worker as each step of the pipeline completes.
    [HttpGet("{id:int}/events")]
    public async Task<ActionResult<IEnumerable<EventLogEntry>>> GetEvents(int id)
    {
        var events = await _db.EventLogs.AsNoTracking()
            .Where(e => e.OrderId == id)
            .OrderBy(e => e.CreatedAt)
            .ToListAsync();
        return Ok(events);
    }

    // POST /api/orders -> place an order. This does NOT reserve stock itself —
    // it just records the intent and publishes "OrderCreated". inventory-worker
    // decides asynchronously whether there's enough stock.
    [HttpPost]
    public async Task<ActionResult<Order>> Create([FromBody] CreateOrderDto dto)
    {
        var product = await _db.Products.FindAsync(dto.ProductId);
        if (product is null)
            return NotFound(new { message = $"Product {dto.ProductId} not found." });

        var order = new Order
        {
            ProductId = dto.ProductId,
            ProductName = product.Name,
            Quantity = dto.Quantity,
            Status = "Pending"
        };

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        await _eventPublisher.PublishAsync("orders", "OrderCreated", new
        {
            OrderId = order.Id,
            ProductId = order.ProductId,
            ProductName = order.ProductName,
            Quantity = order.Quantity
        });

        return CreatedAtAction(nameof(GetAll), order);
    }
}
