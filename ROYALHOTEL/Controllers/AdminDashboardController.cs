using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Services.Analytics;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminDashboardController : Controller
    {
        private readonly IDashboardRepository _dashRepo;

        public AdminDashboardController(IDashboardRepository dashRepo)
        {
            _dashRepo = dashRepo;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        // ── Trang Dashboard chính ──────────────────────────────────────────────
        // Nhận filter: hotelId (int, 0=all), year, month (0=full year)
        // Gọi 5 Stored Procedures qua DashboardRepository (Dapper)
        // Không còn mock data — toàn bộ từ RoyalHotelDb
        // ─────────────────────────────────────────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> Index(int? hotelId, int? year, int? month)
        {
            if (!IsAdmin())
                return RedirectToAction("Login", "Account");

            // Mặc định truy cập lần đầu: Los Angeles (1), tháng/năm hiện tại
            if (!Request.Query.Any())
            {
                hotelId = 1;
                year = DateTime.UtcNow.Year;
                month = DateTime.UtcNow.Month;
            }

            int actualYear  = year ?? DateTime.UtcNow.Year;
            int actualMonth = month ?? 0;
            int? hid        = (hotelId ?? 0) > 0 ? hotelId : null;
            int passHotelId = hotelId ?? 0;

            // ── Gọi song song các SPs để tối ưu thời gian response ──────────
            var kpiTask       = _dashRepo.GetKpiAsync(hid, actualYear, actualMonth);
            var annualTask    = _dashRepo.GetMonthlyRevenueAsync(hid, actualYear, 0); // Always 12 months for big chart
            var monthlyTask   = actualMonth != 0 ? _dashRepo.GetMonthlyRevenueAsync(hid, actualYear, actualMonth) : Task.FromResult(new List<MonthlyRevenuePoint>());
            var topRoomsTask  = _dashRepo.GetTopRoomsAsync(hid, actualYear, actualMonth);
            var occupancyTask = _dashRepo.GetRoomOccupancyAsync(hid, actualYear, actualMonth);
            var cancelTask    = _dashRepo.GetCancellationTrendAsync(hid, actualYear, actualMonth);
            var hotelsTask    = _dashRepo.GetHotelsAsync();

            await Task.WhenAll(kpiTask, annualTask, monthlyTask, topRoomsTask, occupancyTask, cancelTask, hotelsTask);

            var kpi       = kpiTask.Result;
            var annualRev = annualTask.Result;
            var topRooms  = topRoomsTask.Result;
            var occupancy = occupancyTask.Result;
            var cancel    = cancelTask.Result;
            var hotels    = hotelsTask.Result.ToList();

            List<MonthlyRevenuePoint> monthlyRev;
            if (actualMonth == 0)
            {
                // Gộp 12 tháng thành 4 Quý (Tránh trùng lặp với Biểu đồ lớn)
                monthlyRev = new List<MonthlyRevenuePoint>
                {
                    new MonthlyRevenuePoint { Label = "Quý 1", NetRevenue = annualRev.Where(x => x.Label == "T1" || x.Label == "T2" || x.Label == "T3").Sum(x => x.NetRevenue) },
                    new MonthlyRevenuePoint { Label = "Quý 2", NetRevenue = annualRev.Where(x => x.Label == "T4" || x.Label == "T5" || x.Label == "T6").Sum(x => x.NetRevenue) },
                    new MonthlyRevenuePoint { Label = "Quý 3", NetRevenue = annualRev.Where(x => x.Label == "T7" || x.Label == "T8" || x.Label == "T9").Sum(x => x.NetRevenue) },
                    new MonthlyRevenuePoint { Label = "Quý 4", NetRevenue = annualRev.Where(x => x.Label == "T10" || x.Label == "T11" || x.Label == "T12").Sum(x => x.NetRevenue) }
                };
            }
            else
            {
                monthlyRev = monthlyTask.Result;
            }

            decimal maxW = monthlyRev.Any() ? monthlyRev.Max(x => x.NetRevenue) : 1;
            if (maxW == 0) maxW = 1;
            foreach (var pt in monthlyRev) pt.MaxValue = maxW;

            // ── Tạo label chi nhánh ──────────────────────────────────────────
            string branchLabel = hid.HasValue
                ? hotels.FirstOrDefault(h => h.Id == hid)?.Name ?? "Chi nhánh"
                : "Tất cả chi nhánh";

            // ── Insights tự động từ KPI thực ────────────────────────────────
            var insights = BuildInsights(kpi, hotels, hid);

            var vm = new AdminDashboardViewModel
            {
                SelectedBranch  = hid.HasValue ? $"hotel_{hid}" : "all",
                SelectedYear    = actualYear,
                SelectedMonth   = actualMonth,

                GrossRevenue     = kpi.GrossRevenue,
                RefundAmount     = kpi.RefundAmount,
                NetRevenue       = kpi.NetRevenue,
                TotalBookings    = kpi.TotalBookings,
                OccupancyRate    = $"{kpi.OccupancyRate:F1}%",
                CancellationRate = $"{kpi.CancellationRate:F1}%",

                MonthlyRevenue      = monthlyRev,
                AnnualMonthlyRevenue = annualRev,
                TopRooms            = topRooms,
                RoomOccupancies     = occupancy,
                CancellationTrend   = cancel,
                Insights            = insights,

                Hotels       = hotels.Select(h => (h.Id, h.Name, h.City)).ToList(),
                HotelId      = passHotelId,
                BranchLabel  = branchLabel
            };

            return View(vm);
        }

        // ── API: GET /AdminDashboard/GetKpi?hotelId=0&year=2026&month=0 ──────
        [HttpGet]
        public async Task<IActionResult> GetKpi(int hotelId = 0, int year = 0, int month = 0)
        {
            if (!IsAdmin()) return Unauthorized(new { error = "Admin only" });
            if (year == 0) year = DateTime.UtcNow.Year;
            try
            {
                var kpi = await _dashRepo.GetKpiAsync(hotelId > 0 ? hotelId : null, year, month);
                return Json(kpi);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // ── API: GET /AdminDashboard/GetHotels ────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> GetHotels()
        {
            if (!IsAdmin()) return Unauthorized(new { error = "Admin only" });
            var hotels = await _dashRepo.GetHotelsAsync();
            return Json(hotels);
        }

        // ── Insights tự động dựa trên KPI thực ──────────────────────────────
        private static List<InsightItem> BuildInsights(
            ROYALHOTEL.DTOs.DashboardKpiDto kpi,
            List<HotelSummaryDto> hotels,
            int? hotelId)
        {
            var list = new List<InsightItem>();

            // Insight 1: Occupancy cao → đề xuất tăng giá
            if (kpi.OccupancyRate > 80)
                list.Add(new InsightItem
                {
                    Icon  = "bi-graph-up-arrow", Level = "success",
                    Title = $"Tỷ lệ lấp phòng cao ({kpi.OccupancyRate:F1}%)",
                    Body  = "Occupancy vượt 80%. Đề xuất tăng giá 8–12% vào cuối tuần và kỳ lễ để tối ưu doanh thu thực tế.",
                    MetricText = $"Occupancy: {kpi.OccupancyRate:F1}%"
                });
            else if (kpi.OccupancyRate > 0 && kpi.OccupancyRate < 50)
                list.Add(new InsightItem
                {
                    Icon  = "bi-tag", Level = "warning",
                    Title = $"Tỷ lệ lấp phòng thấp ({kpi.OccupancyRate:F1}%)",
                    Body  = "Occupancy dưới 50%. Cân nhắc khuyến mãi, gói corporate rate hoặc combo dài hạn để tăng công suất.",
                    MetricText = $"Occupancy: {kpi.OccupancyRate:F1}%"
                });

            // Insight 2: Cancellation cao
            if (kpi.CancellationRate > 10)
                list.Add(new InsightItem
                {
                    Icon  = "bi-exclamation-triangle", Level = "warning",
                    Title = $"Tỷ lệ hủy cao ({kpi.CancellationRate:F1}%)",
                    Body  = "Tỷ lệ hủy vượt 10%. Xem xét yêu cầu đặt cọc cao hơn hoặc điều chỉnh chính sách hủy miễn phí.",
                    MetricText = $"Hủy phòng: {kpi.CancellationRate:F1}%"
                });

            // Insight 3: Refund chiếm tỷ lệ lớn
            if (kpi.GrossRevenue > 0)
            {
                decimal refundPct = kpi.RefundAmount / kpi.GrossRevenue * 100;
                if (refundPct > 8)
                    list.Add(new InsightItem
                    {
                        Icon  = "bi-arrow-counterclockwise", Level = "danger",
                        Title = $"Hoàn tiền chiếm {refundPct:F1}% doanh thu gộp",
                        Body  = $"Tổng hoàn {kpi.RefundAmount:N0} ₫ / Gross {kpi.GrossRevenue:N0} ₫. Kiểm tra chính sách hủy và lý do hoàn tiền phổ biến.",
                        MetricText = $"Hoàn tiền: {refundPct:F1}%"
                    });
            }

            // Insight 4: Không có data
            if (kpi.TotalBookings == 0)
                list.Add(new InsightItem
                {
                    Icon  = "bi-info-circle", Level = "info",
                    Title = "Chưa có dữ liệu trong kỳ này",
                    Body  = "Không tìm thấy booking trong kỳ được chọn. Hãy kiểm tra lại bộ lọc Chi nhánh, Năm, Tháng.",
                    MetricText = "Booking: 0"
                });

            // Insight 5: Mọi thứ ổn
            if (list.Count == 0 && kpi.TotalBookings > 0)
                list.Add(new InsightItem
                {
                    Icon  = "bi-check-circle-fill", Level = "success",
                    Title = "Chỉ số hoạt động ổn định",
                    Body  = "Các chỉ số doanh thu, tỷ lệ lấp phòng và hủy phòng đang ở mức an toàn. Tiếp tục duy trì chiến lược hiện tại.",
                    MetricText = "Trạng thái: Ổn định"
                });

            return list.Take(3).ToList();
        }
    }
}
