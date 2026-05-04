using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Catalog;

/// <summary>
/// Query object cho MongoDB HotelCatalog — tìm kiếm room candidates.
/// </summary>
public class RoomCatalogQuery
{
    /// <summary>Amenity keys cần filter (ví dụ: "wifi", "pool", "gym")</summary>
    public IReadOnlyList<string>? AmenityKeys { get; set; }

    /// <summary>Lọc theo hotel_id (SQL Hotels.Id) — giới hạn MongoDB có exact chi nhánh</summary>
    public int? HotelId { get; set; }

    /// <summary>Tên thành phố (Da Nang, Nha Trang, Phu Quoc…) — optional, ưu tiên HotelId</summary>
    public string? City { get; set; }

    /// <summary>Từ khoá tìm kiếm description / hotel name</summary>
    public string? TextSearch { get; set; }
}

/// <summary>
/// Contract cho MongoDB HotelCatalog service.
/// Tách biệt hoàn toàn với SQL Server — chỉ trả về candidates (room_id list).
/// </summary>
public interface IHotelCatalogService
{
    /// <summary>
    /// Tìm kiếm theo amenities (và tuỳ chọn city).
    /// Trả về toàn bộ HotelCatalogDocument matching.
    /// </summary>
    Task<List<HotelCatalogDocument>> SearchByAmenitiesAsync(
        IEnumerable<string> amenityKeys, string? city = null);

    /// <summary>
    /// Lấy catalog document theo HotelId (SQL Id).
    /// </summary>
    Task<HotelCatalogDocument?> GetByHotelIdAsync(int hotelId);

    /// <summary>
    /// Upsert một document — dùng trong admin sync.
    /// </summary>
    Task UpsertAsync(HotelCatalogDocument doc);

    /// <summary>
    /// Tìm danh sách room_id candidates từ MongoDB theo query.
    /// Đây là bước 1 trong 2-step search flow.
    /// Trả về null nếu không có filter MongoDB (bypass MongoDB, query SQL trực tiếp).
    /// </summary>
    Task<List<int>?> SearchRoomCandidatesAsync(RoomCatalogQuery query);
}
