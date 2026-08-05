using ProductsApi.Models;

namespace ProductsApi.Services;

// The interface describes WHAT operations exist, not HOW they work.
// Controllers depend on this abstraction (dependency injection), so the
// EF-backed implementation can be swapped without changing the controller.
// Database calls are asynchronous, so every method returns a Task.
public interface IProductService
{
    Task<IEnumerable<Product>> GetAllAsync();
    Task<Product?> GetByIdAsync(int id);
    Task<Product> CreateAsync(CreateProductDto dto);
    Task<bool> UpdateAsync(int id, UpdateProductDto dto);
    Task<bool> DeleteAsync(int id);
}
