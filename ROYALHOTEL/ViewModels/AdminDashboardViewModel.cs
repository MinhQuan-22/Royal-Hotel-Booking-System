using System.Collections.Generic;

namespace ROYALHOTEL.ViewModels
{
    public class AdminDashboardViewModel
    {
        public int TotalRooms { get; set; }
        public int ActiveRooms { get; set; }
        public int TotalBookings { get; set; }
        public int PendingBookings { get; set; }
        public decimal TotalRevenue { get; set; }
        public decimal MonthlyRevenue { get; set; }
        public string OccupancyRate { get; set; } = "0%";
        public string CancellationRate { get; set; } = "0%";
        public int TotalAccounts { get; set; }
        public int ActivePricingRules { get; set; }

        public List<TopRevenueRoomViewModel> TopRevenueRooms { get; set; } = new List<TopRevenueRoomViewModel>();
        public List<MostBookedRoomViewModel> MostBookedRooms { get; set; } = new List<MostBookedRoomViewModel>();
        
        // Multi-branch / Accounting analytics
        public int? SelectedHotelId { get; set; }
        public decimal GrossRevenue { get; set; }
        public decimal RefundAmount { get; set; }
        public decimal NetRevenue { get; set; }
    }

    public class TopRevenueRoomViewModel
    {
        public string RoomCode { get; set; } = "";
        public string RoomName { get; set; } = "";
        public string RoomType { get; set; } = "";
        public decimal PricePerNight { get; set; }
        public int TotalBookings { get; set; }
        public string OccupancyRate { get; set; } = "0%";
        public decimal RevenueGenerated { get; set; }
    }

    public class MostBookedRoomViewModel
    {
        public string RoomCode { get; set; } = "";
        public string RoomName { get; set; } = "";
        public string RoomType { get; set; } = "";
        public int TotalNights { get; set; }
        public int TotalBookings { get; set; }
        public decimal TotalRevenue { get; set; }
    }
}