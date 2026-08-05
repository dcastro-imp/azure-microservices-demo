using Microsoft.AspNetCore.Mvc;
using ProductsApi.Models;
using ProductsApi.Services;

namespace ProductsApi.Controllers;

// [ApiController] enables automatic model validation and helpful defaults.
// [Route("api/[controller]")] maps this to /api/products
// ("[controller]" is replaced by the class name minus "Controller").
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _service;
    private readonly IEventPublisher _eventPublisher;

    // The service is INJECTED by the framework (dependency injection).
    public ProductsController(IProductService service, IEventPublisher eventPublisher)
    {
        _service = service;
        _eventPublisher = eventPublisher;
    }

    // GET /api/products  -> return all products (200 OK)
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetAll()
    {
        return Ok(await _service.GetAllAsync());
    }

    // GET /api/products/5  -> return one product, or 404 if not found
    [HttpGet("{id:int}")]
    public async Task<ActionResult<Product>> GetById(int id)
    {
        var product = await _service.GetByIdAsync(id);
        if (product is null)
            return NotFound(new { message = $"Product {id} not found." });

        return Ok(product);
    }

    // POST /api/products  -> create a product (201 Created + Location header)
    [HttpPost]
    public async Task<ActionResult<Product>> Create([FromBody] CreateProductDto dto)
    {
        var created = await _service.CreateAsync(dto);

        // Publish asynchronously: the HTTP response doesn't wait on downstream
        // consumers (InventoryWorker, NotificationWorker) — they process the
        // event independently, whenever they pick it up.
        await _eventPublisher.PublishAsync("products", "ProductCreated", created);

        // CreatedAtAction returns 201 and adds a Location header pointing
        // to the new resource (REST best practice).
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    // PUT /api/products/5  -> replace an existing product (204 No Content)
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateProductDto dto)
    {
        var updated = await _service.UpdateAsync(id, dto);
        if (!updated)
            return NotFound(new { message = $"Product {id} not found." });

        return NoContent();
    }

    // DELETE /api/products/5  -> delete a product (204 No Content)
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _service.DeleteAsync(id);
        if (!deleted)
            return NotFound(new { message = $"Product {id} not found." });

        return NoContent();
    }
}
