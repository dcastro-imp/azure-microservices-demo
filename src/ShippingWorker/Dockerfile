FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ShippingWorker.csproj .
RUN dotnet restore ShippingWorker.csproj

COPY . .
RUN dotnet publish ShippingWorker.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/runtime:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "ShippingWorker.dll"]
