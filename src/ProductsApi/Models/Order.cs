namespace ProductsApi.Models;

public class Order
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public string Status { get; set; } = "Pending"; // Pending -> StockReserved -> Shipped, or -> Failed
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class CreateOrderDto
{
    public int ProductId { get; set; }
    public int Quantity { get; set; }
}

public class EventLogEntry
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string Payload { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
