-- Run once in the portal Query Editor (public network access must be
-- temporarily enabled — see scripts/04-create-sql.sh).

CREATE TABLE [Products] (
    [Id] int NOT NULL IDENTITY,
    [Name] nvarchar(100) NOT NULL,
    [Category] nvarchar(100) NOT NULL,
    [Price] decimal(18,2) NOT NULL,
    [Stock] int NOT NULL,
    CONSTRAINT [PK_Products] PRIMARY KEY ([Id])
);

CREATE TABLE [Orders] (
    [Id] int NOT NULL IDENTITY,
    [ProductId] int NOT NULL,
    [ProductName] nvarchar(100) NOT NULL,
    [Quantity] int NOT NULL,
    [Status] nvarchar(30) NOT NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_Orders] PRIMARY KEY ([Id])
);

-- NOTE: table is "EventLog" (singular) — the ProductsApi EF Core model maps
-- to this explicitly via .ToTable("EventLog"), since the DbSet property name
-- ("EventLogs") would otherwise make EF look for a pluralized table name.
CREATE TABLE [EventLog] (
    [Id] int NOT NULL IDENTITY,
    [OrderId] int NOT NULL,
    [EventType] nvarchar(50) NOT NULL,
    [Payload] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_EventLog] PRIMARY KEY ([Id])
);

INSERT INTO [Products] (Name, Category, Price, Stock) VALUES
    ('Laptop', 'Electronics', 1200.00, 15),
    ('Coffee Mug', 'Kitchen', 9.99, 200),
    ('Desk Chair', 'Furniture', 149.50, 30);
