using System.Collections.Generic;

namespace ROYALHOTEL.ViewModels
{
    /// <summary>
    /// ViewModel chính cho trang Admin Dashboard - hỗ trợ lọc theo chi nhánh và kỳ thời gian
    /// </summary>
    public class AdminDashboardViewModel
    {
        // ── Bộ lọc hiện tại ──────────────────────────────────────────
        public string SelectedBranch { get; set; } = "all";
        public int SelectedYear { get; set; } = 2026;
        public int SelectedMonth { get; set; } = 0; // 0 = Tất cả tháng

        // Bộ lọc hotel thực (HotelId từ DB, 0=all)
        public int HotelId { get; set; } = 0;
        public string BranchLabel { get; set; } = "Tất cả chi nhánh";
        /// <summary>Danh sách hotels từ DB để render dropdown</summary>
        public List<(int Id, string Name, string City)> Hotels { get; set; } = new();

        // ── KPI chính ────────────────────────────────────────────────
        public decimal NetRevenue { get; set; }
        public decimal GrossRevenue { get; set; }
        public decimal RefundAmount { get; set; }
        public int TotalBookings { get; set; }
        public string OccupancyRate { get; set; } = "0%";
        public string CancellationRate { get; set; } = "0%";

        // ── Biểu đồ Net Revenue theo tháng (phụ thuộc filter) ────────
        public List<MonthlyRevenuePoint> MonthlyRevenue { get; set; } = new();

        // ── Biểu đồ so sánh 12 tháng (luôn đủ 12 tháng, full-width) ─
        public List<MonthlyRevenuePoint> AnnualMonthlyRevenue { get; set; } = new();

        // ── Top 3 phòng theo Net Revenue ─────────────────────────────
        public List<TopRoomDashItem> TopRooms { get; set; } = new();

        // ── Occupancy theo phòng ──────────────────────────────────────
        public List<RoomOccupancyItem> RoomOccupancies { get; set; } = new();

        // ── Cancellation & Refund theo tháng ─────────────────────────
        public List<CancellationTrendPoint> CancellationTrend { get; set; } = new();

        // ── Insight / gợi ý quyết định ───────────────────────────────
        public List<InsightItem> Insights { get; set; } = new();
    }

    public class MonthlyRevenuePoint
    {
        public string Label { get; set; } = "";      // "T1", "T2" ...
        public decimal NetRevenue { get; set; }
        public decimal MaxValue { get; set; }         // dùng tính %bar width
    }

    public class TopRoomDashItem
    {
        public string Branch { get; set; } = "";
        public string RoomCode { get; set; } = "";
        public string RoomName { get; set; } = "";
        public string RoomType { get; set; } = "";
        public decimal NetRevenue { get; set; }
        public int TotalBookings { get; set; }
        public int Rank { get; set; }
    }

    public class RoomOccupancyItem
    {
        public string RoomCode { get; set; } = "";
        public string RoomName { get; set; } = "";
        public string Branch { get; set; } = "";
        public decimal OccupancyPct { get; set; }    // 0–100
    }

    public class CancellationTrendPoint
    {
        public string Label { get; set; } = "";
        public int Cancelled { get; set; }
        public decimal RefundAmount { get; set; }
        public int TotalBookings { get; set; }
    }

    public class InsightItem
    {
        public string Icon { get; set; } = "bi-lightbulb";
        public string Level { get; set; } = "info";  // "success", "warning", "danger", "info"
        public string Title { get; set; } = "";
        public string Body { get; set; } = "";
        public string MetricText { get; set; } = "";
    }
}