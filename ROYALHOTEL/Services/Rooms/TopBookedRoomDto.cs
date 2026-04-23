namespace ROYALHOTEL.Services.Rooms;

/// <summary>
/// DTO for stored procedure sp_GetTopBookedRooms result
/// </summary>
public class TopBookedRoomDto
{
    public int RoomId { get; set; }
    public string RoomCode { get; set; } = "";
    public string RoomName { get; set; } = "";
    public string RoomType { get; set; } = "";
    public int BookingCount { get; set; }
}
