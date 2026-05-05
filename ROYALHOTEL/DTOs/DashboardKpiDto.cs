namespace ROYALHOTEL.DTOs
{
    /// <summary>
    /// KPI Summary cho Admin Dashboard.
    /// Được populate từ Stored Procedure sp_GetDashboardKpi.
    /// Net Revenue = Gross Revenue - Refund Amount (tính ở SQL).
    /// </summary>
    public class DashboardKpiDto
    {
        /// <summary>Tổng doanh thu gộp — SUM(TotalAmount) của booking hợp lệ + phần giữ lại từ Cancelled</summary>
        public decimal GrossRevenue { get; set; }

        /// <summary>Tổng tiền hoàn — SUM(ISNULL(RefundAmount, 0))</summary>
        public decimal RefundAmount { get; set; }

        /// <summary>Doanh thu thực tế = GrossRevenue - RefundAmount (tính ở SQL)</summary>
        public decimal NetRevenue { get; set; }

        /// <summary>Tổng booking trong kỳ (mọi status)</summary>
        public int TotalBookings { get; set; }

        /// <summary>Tỷ lệ lấp phòng % — Occupied room-days / Available room-days</summary>
        public decimal OccupancyRate { get; set; }

        /// <summary>Tỷ lệ hủy phòng % — CancelledBookings / TotalBookings * 100</summary>
        public decimal CancellationRate { get; set; }

        // ── Metadata cho frontend ────────────────────────────
        public int? HotelId { get; set; }
        public int Year { get; set; }
        public int Month { get; set; }
        public string HotelName { get; set; } = "Toàn hệ thống";
    }
}
