FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY InventoryWorker.csproj .
RUN dotnet restore InventoryWorker.csproj

COPY . .
RUN dotnet publish InventoryWorker.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/runtime:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "InventoryWorker.dll"]
