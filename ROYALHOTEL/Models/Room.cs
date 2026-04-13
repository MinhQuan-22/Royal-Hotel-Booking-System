namespace ROYALHOTEL.Models;

public class Room
{
    public int Id { get; set; }
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public string RoomType { get; set; } = ""; // "Standard" / "Deluxe" / "Suite"
    public decimal BasePricePerNight { get; set; }
    public int MaxGuests { get; set; }
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }
    public string? CoverImageUrl { get; set; }

    public int HotelId { get; set; }
    public Hotel Hotel { get; set; } = null!;
    public decimal Rate { get; set; } = 1.0m;
    public string Status { get; set; } = "Available";

    public List<RoomImage> Images { get; set; } = new();
    public List<RoomAmenity> RoomAmenities { get; set; } = new();
}
public class RoomImage
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public string ImageUrl { get; set; } = "";
    public int SortOrder { get; set; }
    public string? AltText { get; set; }
}
public class Amenity
{
    public int Id { get; set; }
    public string AmenityKey { get; set; } = "";
    public string Name { get; set; } = "";
    public string? IconClass { get; set; }
    public string? Category { get; set; }

    public List<RoomAmenity> RoomAmenities { get; set; } = new();
}
public class RoomAmenity
{
    public int RoomId { get; set; }
    public Room Room { get; set; } = null!;
    public int AmenityId { get; set; }
    public Amenity Amenity { get; set; } = null!;
}
