namespace ROYALHOTEL.Models;

public class HomePageVM
{
    public string UserName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public List<Room> FeaturedRooms { get; set; } = new List<Room>();
}
