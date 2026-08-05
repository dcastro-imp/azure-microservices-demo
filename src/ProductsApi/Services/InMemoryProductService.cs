using System.Collections.Concurrent;
using ProductsApi.Models;

namespace ProductsApi.Services;

// A simple thread-safe in-memory implementation kept as a REFERENCE.
// The app now uses EfProductService (real SQLite persistence), but this
// shows how the same interface can have a different implementation.
// Data resets when the app stops. Methods are async only to satisfy the
// interface; the work itself is synchronous, so we wrap results in Task.
public class InMemoryProductService : IProductService
{
    private readonly ConcurrentDictionary<int, Product> _products = new();
    private int _nextId = 0;

    public InMemoryProductService()
    {
        // Seed some sample data so the API returns something on first run.
        Seed(new CreateProductDto { Name = "Laptop", Category = "Electronics", Price = 1200.00m, Stock = 15 });
        Seed(new CreateProductDto { Name = "Coffee Mug", Category = "Kitchen", Price = 9.99m, Stock = 200 });
        Seed(new CreateProductDto { Name = "Desk Chair", Category = "Furniture", Price = 149.50m, Stock = 30 });
    }

    private Product Seed(CreateProductDto dto)
    {
        var id = Interlocked.Increment(ref _nextId);
        var product = new Product
        {
            Id = id,
            Name = dto.Name,
            Category = dto.Category,
            Price = dto.Price,
            Stock = dto.Stock
        };
        _products[id] = product;
        return product;
    }

    public Task<IEnumerable<Product>> GetAllAsync() =>
        Task.FromResult(_products.Values.OrderBy(p => p.Id).AsEnumerable());

    public Task<Product?> GetByIdAsync(int id) =>
        Task.FromResult(_products.TryGetValue(id, out var product) ? product : null);

    public Task<Product> CreateAsync(CreateProductDto dto) => Task.FromResult(Seed(dto));

    public Task<bool> UpdateAsync(int id, UpdateProductDto dto)
    {
        if (!_products.TryGetValue(id, out var product))
            return Task.FromResult(false);

        product.Name = dto.Name;
        product.Category = dto.Category;
        product.Price = dto.Price;
        product.Stock = dto.Stock;
        return Task.FromResult(true);
    }

    public Task<bool> DeleteAsync(int id) => Task.FromResult(_products.TryRemove(id, out _));
}
