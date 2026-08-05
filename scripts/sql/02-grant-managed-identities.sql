-- Run once per Container App AFTER it has been deployed at least once
-- (Azure AD can only resolve a Managed Identity that already exists).
-- The name in brackets must match the Container App name exactly.

CREATE USER [productsapi] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [productsapi];
ALTER ROLE db_datawriter ADD MEMBER [productsapi];

CREATE USER [inventory-worker] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [inventory-worker];
ALTER ROLE db_datawriter ADD MEMBER [inventory-worker];

CREATE USER [shipping-worker] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [shipping-worker];
ALTER ROLE db_datawriter ADD MEMBER [shipping-worker];

CREATE USER [audit-worker] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [audit-worker];
ALTER ROLE db_datawriter ADD MEMBER [audit-worker];

-- notification-worker deliberately has NO database user: it never touches
-- SQL directly, so it gets no DB permissions at all (least privilege).
