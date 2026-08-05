using Microsoft.EntityFrameworkCore;
using ProductsApi.Data;
using ProductsApi.Models;

namespace ProductsApi.Services;

// The real implementation: talks to the SQLite database via EF Core.
// It receives the AppDbContext through dependency injection.
public class EfProductService : IProductService
{
    private readonly AppDbContext _db;

    public EfProductService(AppDbContext db)
    {
        _db = db;
    }

    // AsNoTracking() is a small optimization for read-only queries.
    public async Task<IEnumerable<Product>> GetAllAsync() =>
        await _db.Products.AsNoTracking().OrderBy(p => p.Id).ToListAsync();

    public async Task<Product?> GetByIdAsync(int id) =>
        await _db.Products.FindAsync(id);

    public async Task<Product> CreateAsync(CreateProductDto dto)
    {
        var product = new Product
        {
            Name = dto.Name,
            Category = dto.Category,
            Price = dto.Price,
            Stock = dto.Stock
        };

        _db.Products.Add(product);
        await _db.SaveChangesAsync(); // EF assigns the Id here.
        return product;
    }

    public async Task<bool> UpdateAsync(int id, UpdateProductDto dto)
    {
        var product = await _db.Products.FindAsync(id);
        if (product is null)
            return false;

        product.Name = dto.Name;
        product.Category = dto.Category;
        product.Price = dto.Price;
        product.Stock = dto.Stock;

        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var product = await _db.Products.FindAsync(id);
        if (product is null)
            return false;

        _db.Products.Remove(product);
        await _db.SaveChangesAsync();
        return true;
    }
}
