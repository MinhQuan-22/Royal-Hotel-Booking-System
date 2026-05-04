using MongoDB.Driver;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Data;

/// <summary>
/// Singleton context wrapping IMongoDatabase.
/// Expose typed collection HotelCatalog và đảm bảo indexes tồn tại.
/// </summary>
public class MongoDbContext
{
    private readonly IMongoDatabase _database;

    public MongoDbContext(IConfiguration configuration)
    {
        var databaseName = configuration["MongoDb:DatabaseName"]
            ?? "RoyalHotelCatalogDb";

        // Sử dụng MongoClientSettings để tránh vấn đề URL encoding với password chứa ký tự đặc biệt
        var settings = MongoClientSettings.FromConnectionString("mongodb://localhost:27017");
        settings.Credential = MongoCredential.CreateCredential(
            databaseName: "admin",
            username: "admin",
            password: "MongoAdmin@123"
        );

        var client = new MongoClient(settings);
        _database = client.GetDatabase(databaseName);
    }

    public IMongoCollection<HotelCatalogDocument> HotelCatalog
        => _database.GetCollection<HotelCatalogDocument>("HotelCatalog");

    /// <summary>
    /// Tạo indexes cần thiết khi app khởi động.
    /// Idempotent — an toàn khi gọi nhiều lần.
    /// </summary>
    public async Task EnsureIndexesAsync()
    {
        var collection = HotelCatalog;
        var indexModels = new List<CreateIndexModel<HotelCatalogDocument>>();

        // Index 1: hotel_id — unique, tra cứu trực tiếp 1 hotel
        indexModels.Add(new CreateIndexModel<HotelCatalogDocument>(
            Builders<HotelCatalogDocument>.IndexKeys.Ascending(x => x.HotelId),
            new CreateIndexOptions { Name = "idx_hotel_id", Unique = true }
        ));

        // Index 2: amenities — multikey index, filter theo tiện ích
        indexModels.Add(new CreateIndexModel<HotelCatalogDocument>(
            Builders<HotelCatalogDocument>.IndexKeys.Ascending(x => x.Amenities),
            new CreateIndexOptions { Name = "idx_amenities" }
        ));

        // Index 3: city + amenities — compound, filter khu vực + tiện ích
        indexModels.Add(new CreateIndexModel<HotelCatalogDocument>(
            Builders<HotelCatalogDocument>.IndexKeys
                .Ascending(x => x.City)
                .Ascending(x => x.Amenities),
            new CreateIndexOptions { Name = "idx_city_amenities" }
        ));

        // Index 4: text index trên description và hotel_name cho full-text search
        indexModels.Add(new CreateIndexModel<HotelCatalogDocument>(
            Builders<HotelCatalogDocument>.IndexKeys
                .Text(x => x.Description)
                .Text(x => x.HotelName),
            new CreateIndexOptions { Name = "idx_text_search" }
        ));

        // Index 5: rooms.amenities — multikey cho room-level amenity filter
        indexModels.Add(new CreateIndexModel<HotelCatalogDocument>(
            Builders<HotelCatalogDocument>.IndexKeys.Ascending("rooms.amenities"),
            new CreateIndexOptions { Name = "idx_rooms_amenities" }
        ));

        await collection.Indexes.CreateManyAsync(indexModels);
    }
}
