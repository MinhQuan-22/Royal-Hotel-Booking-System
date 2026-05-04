namespace ROYALHOTEL.DTOs;

/// <summary>
/// DTO for quarterly revenue analytics data
/// </summary>
public class QuarterlyRevenueDto
{
    public int HotelId { get; set; }
    public string HotelName { get; set; } = "";
    public string Quarter { get; set; } = ""; // "Q1", "Q2", "Q3", "Q4"
    public int Year { get; set; }
    public string RoomCode { get; set; } = "";
    public string RoomName { get; set; } = "";
    public decimal TotalRevenue { get; set; }
    public int TotalBookings { get; set; }
}
