# --- Build stage: has the full SDK (compiler, NuGet, etc.) ---
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ProductsApi.csproj .
RUN dotnet restore ProductsApi.csproj

COPY . .
RUN dotnet publish ProductsApi.csproj -c Release -o /app/publish --no-restore

# --- Runtime stage: only the ASP.NET runtime, much smaller than the SDK ---
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Container Apps expects the app to listen on 8080 by convention (configurable, but this is the default)
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "ProductsApi.dll"]
