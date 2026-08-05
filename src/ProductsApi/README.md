# Products API — A .NET REST API Example

A minimal but complete **REST API** built with **ASP.NET Core (.NET 10)** to help you understand how REST APIs work. It manages a list of `Product` resources with full **CRUD** (Create, Read, Update, Delete).

Data is now stored in a real **SQLite database** using **Entity Framework Core**, so records persist across restarts.

---

## What is a REST API? (quick primer)

A REST API exposes **resources** (here: *products*) that you interact with using **HTTP methods (verbs)**:

| HTTP Verb | Meaning | Example | Success Status |
|-----------|---------|---------|----------------|
| `GET` | Read data | `GET /api/products` | `200 OK` |
| `GET` | Read one | `GET /api/products/1` | `200 OK` / `404` |
| `POST` | Create new | `POST /api/products` | `201 Created` |
| `PUT` | Replace existing | `PUT /api/products/1` | `204 No Content` |
| `DELETE` | Remove | `DELETE /api/products/1` | `204 No Content` |

Key ideas: **resources have URLs**, **verbs describe the action**, and the server returns **status codes** to say what happened.

---

## Project Structure

```
ProductsApi/
├── Program.cs                 # App startup: DI, DbContext, middleware, routing
├── Controllers/
│   └── ProductsController.cs  # REST endpoints (the HTTP layer, async)
├── Services/
│   ├── IProductService.cs        # Abstraction (what operations exist)
│   ├── EfProductService.cs       # SQLite/EF Core store (used by the app)
│   └── InMemoryProductService.cs # Reference in-memory implementation
├── Data/
│   └── AppDbContext.cs        # EF Core DbContext (maps classes -> tables)
├── Migrations/                # Auto-generated EF schema migrations
├── Models/
│   ├── Product.cs             # The resource/entity
│   └── ProductDtos.cs         # Input shapes + validation rules
├── ProductsApi.http           # Ready-to-run example HTTP requests
├── products.db                # SQLite database file (created on first run)
└── ProductsApi.csproj         # Project + dependencies
```

**Why these layers?** Separating *Controller → Service → Model* keeps code clean:
the controller only handles HTTP, the service handles logic/data, so you could later
swap the in-memory store for a real database without touching the controller.

---

## How to Run

From this folder (`ProductsApi/`):

```bash
dotnet run
```

Then open your browser at:

- **Swagger UI (interactive docs + tester):** http://localhost:5080/
- **API endpoint:** http://localhost:5080/api/products

> On first run, EF Core creates `products.db` and seeds 3 sample products. Because it's a real database, any changes you make now **persist across restarts**.

---

## Try It Out

### Using the browser
Open http://localhost:5080/ and use the **Swagger UI** to click through each endpoint.

### Using curl
```bash
# Get all products
curl http://localhost:5080/api/products

# Get one product
curl http://localhost:5080/api/products/1

# Create a product
curl -X POST http://localhost:5080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Wireless Mouse","category":"Electronics","price":25.99,"stock":100}'

# Update a product
curl -X PUT http://localhost:5080/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Gaming Laptop","category":"Electronics","price":1500,"stock":10}'

# Delete a product
curl -X DELETE http://localhost:5080/api/products/2
```

### Using the .http file
Open `ProductsApi.http` in VS Code (with the REST Client extension) or a JetBrains IDE and click **Send Request** above any request.

---

## Concepts Demonstrated

- **Controller-based routing** with attribute routes (`[HttpGet]`, `[HttpPost]`, etc.).
- **Dependency Injection** — the controller receives `IProductService` automatically.
- **DTOs + validation** — clients send `CreateProductDto`; invalid input auto-returns `400 Bad Request`.
- **Proper status codes** — `200`, `201` (with `Location` header), `204`, `404`.
- **Swagger/OpenAPI** — auto-generated interactive documentation.
- **Separation of concerns** — HTTP layer vs. business/data layer.
- **Entity Framework Core + SQLite** — real database persistence via `AppDbContext`.
- **Async data access** — all service/controller methods are `async`.
- **Migrations & seeding** — schema and sample data are versioned and applied automatically on startup.

---

## Working with the Database (EF Core)

The database schema is managed with **migrations** (versioned schema changes).

```bash
# Add a new migration after you change the model/DbContext
dotnet dotnet-ef migrations add <MigrationName>

# Apply migrations manually (the app also does this automatically on startup)
dotnet dotnet-ef database update

# Remove the last migration (if not yet applied)
dotnet dotnet-ef migrations remove
```

To reset the database completely, stop the app and delete `products.db`, then run again.

---

## Next Steps to Learn More

1. Add a `PATCH` endpoint for partial updates.
2. Add **pagination** and **filtering** to `GET /api/products`.
3. Add **authentication** (e.g. JWT bearer tokens).
4. Swap SQLite for **Azure SQL Database** (a managed PaaS database).
5. Deploy it to **Azure App Service** (ties directly into your AZ-900 studies — App Service is PaaS!).
