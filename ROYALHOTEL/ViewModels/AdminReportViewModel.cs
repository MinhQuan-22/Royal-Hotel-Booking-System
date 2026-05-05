using System.Collections.Generic;

namespace ROYALHOTEL.ViewModels
{
    public class AdminReportViewModel
    {
        // ── Bộ lọc ──────────────────────────────────────────────────
        public string SelectedBranch { get; set; } = "all";
        public int SelectedYear { get; set; } = 2026;
        public int SelectedMonth { get; set; } = 0; // 0 = Tất cả tháng

        // ── Summary Cards ────────────────────────────────────────────
        public decimal GrossRevenue { get; set; }
        public decimal RefundAmount { get; set; }
        public decimal NetRevenue => GrossRevenue - RefundAmount;
        public decimal RevPAR { get; set; }
        public string AvgOccupancyRate { get; set; } = "0%";

        // ── Room Performance Table ────────────────────────────────────
        public List<RoomPerformanceRow> RoomPerformance { get; set; } = new();

        // ── Top 3 Ranking (Window Function: RANK() OVER PARTITION BY) ─
        public List<TopRoomReportItem> TopRooms { get; set; } = new();

        // ── Time Analysis ────────────────────────────────────────────
        public string HighestRevenueMonth { get; set; } = "";
        public decimal HighestRevenueValue { get; set; }
        public string LowestRevenueMonth { get; set; } = "";
        public decimal LowestRevenueValue { get; set; }
        public string MostBookingMonth { get; set; } = "";
        public int MostBookingCount { get; set; }
        public string PeakPeriod { get; set; } = "";
        public string LowPeriod { get; set; } = "";

        // ── Pricing Recommendations ──────────────────────────────────
        public List<PricingRecommendation> PricingRecs { get; set; } = new();
    }

    public class RoomPerformanceRow
    {
        public string Branch { get; set; } = "";
        public string RoomCode { get; set; } = "";
        public string RoomName { get; set; } = "";
        public string RoomType { get; set; } = "";
        public decimal GrossRevenue { get; set; }
        public decimal RefundAmount { get; set; }
        public decimal NetRevenue => GrossRevenue - RefundAmount;
        public int TotalBookings { get; set; }
        public decimal OccupancyPct { get; set; }
        public decimal CancellationPct { get; set; }
        public string SuggestedAction { get; set; } = "";
        public string ActionLevel { get; set; } = "info";
    }

    public class TopRoomReportItem
    {
        public int Rank { get; set; }
        public string Branch { get; set; } = "";
        public string RoomCode { get; set; } = "";
        public string RoomName { get; set; } = "";
        public string RoomType { get; set; } = "";
        public decimal NetRevenue { get; set; }
        public decimal OccupancyPct { get; set; }
        public int TotalBookings { get; set; }
        public decimal ContributionPct { get; set; } // % đóng góp tổng DT
    }

    public class PricingRecommendation
    {
        public string RoomCode { get; set; } = "";
        public string RoomName { get; set; } = "";
        public string Branch { get; set; } = "";
        public decimal OccupancyPct { get; set; }
        public decimal CancellationPct { get; set; }
        public string Recommendation { get; set; } = "";
        public string Level { get; set; } = "info";
        public string Icon { get; set; } = "bi-arrow-right";
    }
}