using Microsoft.EntityFrameworkCore;
using ProductsApi.Models;

namespace ProductsApi.Data;

// The DbContext is EF Core's bridge between your C# classes and the database.
// Each DbSet<T> becomes a table. EF translates LINQ queries into SQL for you.
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    // Maps to a "Products" table in the SQLite database.
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<EventLogEntry> EventLogs => Set<EventLogEntry>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure column constraints (optional but good practice).
        modelBuilder.Entity<Product>(entity =>
        {
            entity.Property(p => p.Name).IsRequired().HasMaxLength(100);
            entity.Property(p => p.Category).IsRequired().HasMaxLength(100);
            entity.Property(p => p.Price).HasColumnType("decimal(18,2)");
        });

        modelBuilder.Entity<Order>(entity =>
        {
            entity.Property(o => o.ProductName).IsRequired().HasMaxLength(100);
            entity.Property(o => o.Status).IsRequired().HasMaxLength(30);
        });

        modelBuilder.Entity<EventLogEntry>(entity =>
        {
            entity.ToTable("EventLog"); // actual table name in SQL is singular, not the pluralized DbSet name
            entity.Property(e => e.EventType).IsRequired().HasMaxLength(50);
        });

        // Seed data: EF writes these rows during the migration.
        modelBuilder.Entity<Product>().HasData(
            new Product { Id = 1, Name = "Laptop", Category = "Electronics", Price = 1200.00m, Stock = 15 },
            new Product { Id = 2, Name = "Coffee Mug", Category = "Kitchen", Price = 9.99m, Stock = 200 },
            new Product { Id = 3, Name = "Desk Chair", Category = "Furniture", Price = 149.50m, Stock = 30 }
        );
    }
}
