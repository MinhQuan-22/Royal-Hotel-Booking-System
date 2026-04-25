using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using MongoDB.Driver;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using System.Security.Cryptography;
using System.Text;

namespace ROYALHOTEL.Services.Catalog;

/// <summary>
/// Implement IHotelCatalogService trên MongoDB với caching layer.
/// Toàn bộ query đi qua MongoDbContext.HotelCatalog collection.
/// </summary>
public class MongoHotelCatalogService : IHotelCatalogService
{
    private readonly MongoDbContext _mongo;
    private readonly IMemoryCache _cache;
    private readonly ILogger<MongoHotelCatalogService> _logger;
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(10);

    public MongoHotelCatalogService(
        MongoDbContext mongo,
        IMemoryCache cache,
        ILogger<MongoHotelCatalogService> logger)
    {
        _mongo = mongo;
        _cache = cache;
        _logger = logger;
    }

    private static string GenerateCacheKey(RoomCatalogQuery query)
    {
        var keyBuilder = new StringBuilder();
        
        if (query.AmenityKeys != null && query.AmenityKeys.Any())
        {
            keyBuilder.Append("amenities:");
            keyBuilder.Append(string.Join(",", query.AmenityKeys.OrderBy(k => k)));
        }
        
        if (!string.IsNullOrWhiteSpace(query.City))
        {
            keyBuilder.Append("|city:");
            keyBuilder.Append(query.City.ToLowerInvariant());
        }
        
        if (!string.IsNullOrWhiteSpace(query.TextSearch))
        {
            keyBuilder.Append("|text:");
            keyBuilder.Append(query.TextSearch.ToLowerInvariant());
        }

        // Hash để tránh key quá dài
        using var sha256 = SHA256.Create();
        var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(keyBuilder.ToString()));
        return $"catalog:search:{Convert.ToBase64String(hashBytes)}";
    }

    /// <inheritdoc/>
    public async Task<List<HotelCatalogDocument>> SearchByAmenitiesAsync(
        IEnumerable<string> amenityKeys, string? city = null)
    {
        var keys = amenityKeys
            .Where(k => !string.IsNullOrWhiteSpace(k))
            .Select(k => k.Trim().ToLowerInvariant())
            .Distinct()
            .ToList();

        if (keys.Count == 0)
            return new List<HotelCatalogDocument>();

        var builder = Builders<HotelCatalogDocument>.Filter;

        // Filter: rooms.amenities phải chứa TẤT CẢ amenity keys được yêu cầu
        var filters = keys.Select(k =>
            builder.AnyEq("rooms.amenities", k) |
            builder.AnyEq("amenities", k)
        ).ToList();

        var combinedFilter = builder.And(filters);

        // Optional: thêm filter city nếu có
        if (!string.IsNullOrWhiteSpace(city))
        {
            combinedFilter = builder.And(combinedFilter,
                builder.Regex(x => x.City,
                    new MongoDB.Bson.BsonRegularExpression(city.Trim(), "i")));
        }

        return await _mongo.HotelCatalog
            .Find(combinedFilter)
            .ToListAsync();
    }

    /// <inheritdoc/>
    public async Task<HotelCatalogDocument?> GetByHotelIdAsync(int hotelId)
    {
        return await _mongo.HotelCatalog
            .Find(x => x.HotelId == hotelId)
            .FirstOrDefaultAsync();
    }

    /// <inheritdoc/>
    public async Task UpsertAsync(HotelCatalogDocument doc)
    {
        doc.UpdatedAt = DateTime.UtcNow;

        var filter = Builders<HotelCatalogDocument>.Filter
            .Eq(x => x.HotelId, doc.HotelId);

        var options = new ReplaceOptions { IsUpsert = true };

        await _mongo.HotelCatalog.ReplaceOneAsync(filter, doc, options);
    }

    /// <inheritdoc/>
    public async Task<List<int>?> SearchRoomCandidatesAsync(RoomCatalogQuery query)
    {
        // Không có filter MongoDB → bypass, trả null để query SQL trực tiếp
        var hasAmenityFilter = query.AmenityKeys?.Any(k => !string.IsNullOrWhiteSpace(k)) == true;
        var hasCityFilter = !string.IsNullOrWhiteSpace(query.City);
        var hasTextFilter = !string.IsNullOrWhiteSpace(query.TextSearch);

        if (!hasAmenityFilter && !hasCityFilter && !hasTextFilter)
            return null;

        // Check cache first
        var cacheKey = GenerateCacheKey(query);
        if (_cache.TryGetValue<List<int>>(cacheKey, out var cachedResult))
        {
            _logger.LogDebug("MongoDB search cache HIT for key {CacheKey}", cacheKey);
            return cachedResult;
        }

        _logger.LogDebug("MongoDB search cache MISS for key {CacheKey}", cacheKey);

        var builder = Builders<HotelCatalogDocument>.Filter;
        var filters = new List<FilterDefinition<HotelCatalogDocument>>();

        // Amenity filter: room-level amenities (mỗi key phải thoả ít nhất ở room hoặc hotel level)
        if (hasAmenityFilter)
        {
            var keys = query.AmenityKeys!
                .Where(k => !string.IsNullOrWhiteSpace(k))
                .Select(k => k.Trim().ToLowerInvariant())
                .Distinct()
                .ToList();

            foreach (var key in keys)
            {
                filters.Add(
                    builder.AnyEq("rooms.amenities", key) |
                    builder.AnyEq("amenities", key)
                );
            }
        }

        // City filter
        if (hasCityFilter)
        {
            filters.Add(builder.Regex(x => x.City,
                new MongoDB.Bson.BsonRegularExpression(query.City!.Trim(), "i")));
        }

        // Text search filter
        if (hasTextFilter)
        {
            filters.Add(builder.Text(query.TextSearch!));
        }

        var finalFilter = filters.Count == 1
            ? filters[0]
            : builder.And(filters);

        var docs = await _mongo.HotelCatalog
            .Find(finalFilter)
            .ToListAsync();

        // Flatten tất cả room_id candidates từ các hotel matching
        var roomIds = docs
            .SelectMany(d => d.Rooms)
            .Select(r => r.RoomId)
            .Distinct()
            .ToList();

        // Cache result
        _cache.Set(cacheKey, roomIds, CacheDuration);
        _logger.LogDebug("MongoDB search result cached for {Duration} minutes", CacheDuration.TotalMinutes);

        // Nếu có filter nhưng không tìm thấy kết quả → trả empty list (không bypass SQL)
        return roomIds;
    }
}
