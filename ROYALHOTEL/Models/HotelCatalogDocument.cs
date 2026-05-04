using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace ROYALHOTEL.Models;

/// <summary>
/// Đại diện cho một document trong collection HotelCatalog (MongoDB).
/// Lưu dữ liệu read-heavy: description, amenities, images.
/// Rate / Status / Availability vẫn nằm ở SQL Server.
/// </summary>
public class HotelCatalogDocument
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    /// <summary>Link sang Hotels.Id ở SQL Server</summary>
    [BsonElement("hotel_id")]
    public int HotelId { get; set; }

    [BsonElement("hotel_name")]
    public string HotelName { get; set; } = "";

    [BsonElement("city")]
    public string City { get; set; } = "";

    [BsonElement("country")]
    public string Country { get; set; } = "Vietnam";

    /// <summary>Mô tả khách sạn — phục vụ full-text search</summary>
    [BsonElement("description")]
    public string Description { get; set; } = "";

    /// <summary>Tiện ích cấp khách sạn (wifi, pool, gym, spa, parking…)</summary>
    [BsonElement("amenities")]
    public List<string> Amenities { get; set; } = new();

    /// <summary>Danh sách URL ảnh khách sạn</summary>
    [BsonElement("images")]
    public List<string> Images { get; set; } = new();

    /// <summary>Danh sách phòng thuộc khách sạn — phục vụ room-level search</summary>
    [BsonElement("rooms")]
    public List<RoomCatalogEntry> Rooms { get; set; } = new();

    [BsonElement("updated_at")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// Thông tin một phòng nhúng trong HotelCatalogDocument.
/// Cho phép tìm kiếm theo amenities của từng phòng.
/// </summary>
public class RoomCatalogEntry
{
    /// <summary>Link sang Rooms.Id ở SQL Server</summary>
    [BsonElement("room_id")]
    public int RoomId { get; set; }

    [BsonElement("room_code")]
    public string RoomCode { get; set; } = "";

    [BsonElement("room_name")]
    public string RoomName { get; set; } = "";

    [BsonElement("room_type")]
    public string RoomType { get; set; } = "";

    /// <summary>Tiện ích cấp phòng — dùng để filter room candidates</summary>
    [BsonElement("amenities")]
    public List<string> Amenities { get; set; } = new();

    [BsonElement("description")]
    public string? Description { get; set; }

    /// <summary>Ảnh riêng của phòng</summary>
    [BsonElement("images")]
    public List<string> Images { get; set; } = new();
}
