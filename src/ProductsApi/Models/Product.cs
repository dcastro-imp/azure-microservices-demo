namespace ProductsApi.Models;

// The data model (entity) representing a single product.
// This is what our REST API exposes as a "resource".
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Stock { get; set; }
}
