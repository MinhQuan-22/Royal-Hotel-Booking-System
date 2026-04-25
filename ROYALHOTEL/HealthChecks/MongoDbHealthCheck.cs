using Microsoft.Extensions.Diagnostics.HealthChecks;
using MongoDB.Driver;

namespace ROYALHOTEL.HealthChecks;

/// <summary>
/// Custom MongoDB health check sử dụng MongoClientSettings
/// để tránh vấn đề URL encoding với password chứa ký tự đặc biệt
/// </summary>
public class MongoDbHealthCheck : IHealthCheck
{
    private readonly IMongoDatabase _database;

    public MongoDbHealthCheck(IConfiguration configuration)
    {
        var databaseName = configuration["MongoDb:DatabaseName"] ?? "RoyalHotelCatalogDb";

        var settings = MongoClientSettings.FromConnectionString("mongodb://localhost:27017");
        settings.Credential = MongoCredential.CreateCredential(
            databaseName: "admin",
            username: "admin",
            password: "MongoAdmin@123"
        );
        settings.ServerSelectionTimeout = TimeSpan.FromSeconds(5);

        var client = new MongoClient(settings);
        _database = client.GetDatabase(databaseName);
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Ping database để kiểm tra kết nối
            await _database.RunCommandAsync<MongoDB.Bson.BsonDocument>(
                new MongoDB.Bson.BsonDocument("ping", 1),
                cancellationToken: cancellationToken
            );

            return HealthCheckResult.Healthy("MongoDB connection is healthy");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy(
                "MongoDB connection failed",
                exception: ex
            );
        }
    }
}
