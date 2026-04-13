namespace ROYALHOTEL.ViewModels
{
    public class AdminDashboardViewModel
    {
        public int TotalRooms { get; set; }
        public int ActiveRooms { get; set; }
        public int TotalBookings { get; set; }
        public int PendingBookings { get; set; }
        public decimal TotalRevenue { get; set; }
        public string OccupancyRate { get; set; } = "0%";
        public int TotalAccounts { get; set; }
        public int ActivePricingRules { get; set; }
    }
}