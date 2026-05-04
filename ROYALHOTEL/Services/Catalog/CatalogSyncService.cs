using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using System.Diagnostics;

namespace ROYALHOTEL.Services.Catalog;

/// <summary>
/// Đồng bộ dữ liệu từ SQL Server sang MongoDB HotelCatalog.
/// Được gọi sau khi Admin Create/Edit Room hoặc Amenity.
/// </summary>
public class CatalogSyncService
{
    private readonly RoyalHotelDbContext _sqlDb;
    private readonly IHotelCatalogService _catalogService;
    private readonly ILogger<CatalogSyncService> _logger;

    public CatalogSyncService(
        RoyalHotelDbContext sqlDb,
        IHotelCatalogService catalogService,
        ILogger<CatalogSyncService> logger)
    {
        _sqlDb = sqlDb;
        _catalogService = catalogService;
        _logger = logger;
    }

    /// <summary>
    /// Đọc Room (kèm Hotel, Amenities, Images) từ SQL và upsert vào MongoDB HotelCatalog.
    /// Nếu hotel document đã tồn tại → update thông tin phòng tương ứng.
    /// </summary>
    public async Task SyncRoomToMongoAsync(int roomId)
    {
        var stopwatch = Stopwatch.StartNew();
        _logger.LogInformation("MongoDB sync started for room {RoomId}", roomId);

        try
        {
            // Tải room + hotel + amenities + images từ SQL
            var room = await _sqlDb.Rooms
                .AsNoTracking()
                .Include(r => r.Hotel)
                .Include(r => r.RoomAmenities)
                    .ThenInclude(ra => ra.Amenity)
                .Include(r => r.Images)
                .FirstOrDefaultAsync(r => r.Id == roomId);

            if (room == null)
            {
                _logger.LogWarning("Room {RoomId} not found, skipping MongoDB sync", roomId);
                return;
            }

            var hotelId = room.HotelId;

            // Tải tất cả phòng cùng hotel để build toàn bộ hotel document
            var allRoomsInHotel = await _sqlDb.Rooms
                .AsNoTracking()
                .Include(r => r.RoomAmenities)
                    .ThenInclude(ra => ra.Amenity)
                .Include(r => r.Images)
                .Where(r => r.HotelId == hotelId && r.IsActive)
                .ToListAsync();

            // Tập hợp amenities cấp hotel (union của tất cả phòng)
            var hotelAmenities = allRoomsInHotel
                .SelectMany(r => r.RoomAmenities.Select(ra => ra.Amenity.AmenityKey.ToLowerInvariant()))
                .Distinct()
                .OrderBy(k => k)
                .ToList();

            // Build room entries
            var roomEntries = allRoomsInHotel.Select(r => new RoomCatalogEntry
            {
                RoomId = r.Id,
                RoomCode = r.Code,
                RoomName = r.Name,
                RoomType = r.RoomType,
                Description = r.Description,
                Amenities = r.RoomAmenities
                    .Select(ra => ra.Amenity.AmenityKey.ToLowerInvariant())
                    .Distinct()
                    .OrderBy(k => k)
                    .ToList(),
                Images = r.Images
                    .OrderBy(i => i.SortOrder)
                    .Select(i => i.ImageUrl)
                    .ToList()
            }).ToList();

            // Build hotel images — lấy cover image của tất cả phòng
            var hotelImages = allRoomsInHotel
                .Where(r => !string.IsNullOrWhiteSpace(r.CoverImageUrl))
                .Select(r => r.CoverImageUrl!)
                .Distinct()
                .ToList();

            var hotelDoc = new HotelCatalogDocument
            {
                HotelId = hotelId,
                HotelName = room.Hotel?.Name ?? $"Hotel {hotelId}",
                City = room.Hotel?.City ?? "",
                Country = room.Hotel?.Country ?? "Vietnam",
                Description = room.Hotel != null
                    ? $"Khách sạn sang trọng tại {room.Hotel.City}, {room.Hotel.Country}. {room.Hotel.Address}"
                    : "",
                Amenities = hotelAmenities,
                Images = hotelImages,
                Rooms = roomEntries,
                UpdatedAt = DateTime.UtcNow
            };

            await _catalogService.UpsertAsync(hotelDoc);

            stopwatch.Stop();
            _logger.LogInformation(
                "MongoDB sync completed for room {RoomId} (Hotel {HotelId}) in {ElapsedMs}ms. Synced {RoomCount} rooms, {AmenityCount} amenities",
                roomId, hotelId, stopwatch.ElapsedMilliseconds, roomEntries.Count, hotelAmenities.Count);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, 
                "MongoDB sync failed for room {RoomId} after {ElapsedMs}ms", 
                roomId, stopwatch.ElapsedMilliseconds);
            throw;
        }
    }

    /// <summary>
    /// Đồng bộ toàn bộ dữ liệu SQL → MongoDB (batch sync).
    /// Dùng để khởi tạo lần đầu hoặc re-sync định kỳ.
    /// </summary>
    public async Task SyncAllHotelsAsync()
    {
        var stopwatch = Stopwatch.StartNew();
        _logger.LogInformation("MongoDB batch sync started for all hotels");

        try
        {
            var hotelIds = await _sqlDb.Rooms
                .AsNoTracking()
                .Where(r => r.IsActive)
                .Select(r => r.HotelId)
                .Distinct()
                .ToListAsync();

            _logger.LogInformation("Found {HotelCount} hotels to sync", hotelIds.Count);

            var successCount = 0;
            var failCount = 0;

            foreach (var hotelId in hotelIds)
            {
                try
                {
                    // Lấy một room bất kỳ của hotel để trigger sync
                    var anyRoomId = await _sqlDb.Rooms
                        .AsNoTracking()
                        .Where(r => r.HotelId == hotelId && r.IsActive)
                        .Select(r => r.Id)
                        .FirstOrDefaultAsync();

                    if (anyRoomId > 0)
                    {
                        await SyncRoomToMongoAsync(anyRoomId);
                        successCount++;
                    }
                }
                catch (Exception ex)
                {
                    failCount++;
                    _logger.LogError(ex, "Failed to sync hotel {HotelId}", hotelId);
                }
            }

            stopwatch.Stop();
            _logger.LogInformation(
                "MongoDB batch sync completed in {ElapsedMs}ms. Success: {SuccessCount}, Failed: {FailCount}",
                stopwatch.ElapsedMilliseconds, successCount, failCount);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, 
                "MongoDB batch sync failed after {ElapsedMs}ms", 
                stopwatch.ElapsedMilliseconds);
            throw;
        }
    }
}
