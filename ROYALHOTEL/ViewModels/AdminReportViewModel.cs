namespace ROYALHOTEL.ViewModels
{
    public class AdminReportViewModel
    {
        // Room Status Summary Data
        public int TotalRoomsCount { get; set; }
        public int AvailableRoomsCount { get; set; }
        public int OccupiedRoomsCount { get; set; }
        public int MaintenanceRoomsCount { get; set; }

        // Booking Stats Summary
        public int TotalBookingsMonth { get; set; }
        public int CompletedBookingsMonth { get; set; }
        public int CancelledBookingsMonth { get; set; }

        // Mock Chart Data for Pricing Trend passing to view
        public List<int> StandardPricingData { get; set; } = new List<int>();
        public List<int> DeluxePricingData { get; set; } = new List<int>();
        public List<string> PricingLabels { get; set; } = new List<string>();
        
        // Quick Stats Mock
        public decimal TotalRevenueMonth { get; set; }

        // Monthly Revenue Trend Data
        public List<decimal> MonthlyRevenueData { get; set; } = new List<decimal>();
        public List<string> MonthlyRevenueLabels { get; set; } = new List<string>();

        // Top 3 Revenue Rooms
        public List<TopRevenueRoom> TopRevenueRooms { get; set; } = new List<TopRevenueRoom>();
    }

    public class TopRevenueRoom
    {
        public string? RoomCode { get; set; }
        public string? RoomName { get; set; }
        public string? RoomType { get; set; }
        public int TotalBookings { get; set; }
        public decimal RevenueGenerated { get; set; }
        public decimal OccupancyRate { get; set; }
    }
}