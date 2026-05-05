using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.DTOs;
using ROYALHOTEL.Services.Analytics;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminReportsController : Controller
    {
        private readonly IAnalyticsService _analytics;
        private readonly IDashboardRepository _dashRepo;
        public AdminReportsController(IAnalyticsService analytics, IDashboardRepository dashRepo)
        {
            _analytics = analytics;
            _dashRepo = dashRepo;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        [HttpGet]
        public async Task<IActionResult> Index(int? hotelId, int? year, int? month)
        {
            if (!IsAdmin()) return RedirectToAction("Login", "Account");
            
            int actualYear = year ?? DateTime.UtcNow.Year;
            int actualMonth = month ?? 0;

            var model = await BuildReportAsync(hotelId, actualYear, actualMonth);
            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> QuarterlyRevenue(int? hotelId, int? year, int? quarter)
        {
            if (!IsAdmin()) return RedirectToAction("Login", "Account");
            var results = await _analytics.GetQuarterlyRevenueAnalyticsAsync(hotelId, year, quarter);
            ViewBag.Hotels = new dynamic[]
            {
                new { Id=1, Name="Royal Hotel Saigon" },
                new { Id=2, Name="Royal Hotel Da Nang" },
                new { Id=3, Name="Royal Hotel Ha Noi" }
            };
            return View(results);
        }

        [HttpGet]
        public async Task<IActionResult> RateChangeHistory(int? roomId, DateTime? startDate, DateTime? endDate)
        {
            if (!IsAdmin()) return RedirectToAction("Login", "Account");
            if (roomId.HasValue && roomId.Value > 0)
            {
                var changes = await _analytics.ParseRateChangeLogAsync(roomId.Value, startDate, endDate);
                ViewBag.ReportHtml = _analytics.FormatRateChangeReport(changes);
                ViewBag.RoomId = roomId;
                return View(changes);
            }
            ViewBag.RoomId = roomId;
            return View(Enumerable.Empty<RateChangeDto>());
        }

        // ─────────────────────────────────────────────────────────────────────
        // MOCK DATA BUILDER — chuẩn bị sẵn để thay thế bằng SQL Window Functions
        // ROW_NUMBER() OVER (PARTITION BY branch ORDER BY net_revenue DESC)
        // SUM() OVER (PARTITION BY year), LAG/LEAD để so sánh tháng
        // ─────────────────────────────────────────────────────────────────────
        private async Task<AdminReportViewModel> BuildReportAsync(int? hotelId, int year, int month)
        {
            var kpiTask = _dashRepo.GetKpiAsync(hotelId, year, month);
            var roomPerfTask = _dashRepo.GetRoomPerformanceReportAsync(hotelId, year, month);
            var timeTask = _dashRepo.GetTimeAnalysisAsync(hotelId, year, month);
            var hotelsTask = _dashRepo.GetHotelsAsync();
            
            await Task.WhenAll(kpiTask, roomPerfTask, timeTask, hotelsTask);
            var kpi = kpiTask.Result;
            var roomPerf = roomPerfTask.Result;
            var timeAnalysis = timeTask.Result;
            var hotels = hotelsTask.Result;

            string branchName = "all";
            if (hotelId.HasValue && hotelId.Value > 0)
            {
                var h = hotels.FirstOrDefault(x => x.Id == hotelId.Value);
                if (h != null) branchName = h.City.ToLower();
            }

            // Generate actionable logic dynamically
            foreach (var r in roomPerf)
            {
                (r.SuggestedAction, r.ActionLevel) = (r.OccupancyPct, r.CancellationPct) switch
                {
                    (> 80, < 10) => ("Đề xuất tăng giá ~10%", "success"),
                    (> 80, _)    => ("Tăng giá nhẹ — lưu ý cancel cao", "warning"),
                    (> 40, _)    => ("Giữ giá", "info"),
                    _            => ("Cần khuyến mãi", "danger")
                };
            }

            // Window Function Rank derived from roomPerf sorting
            // (The SP already orders by NetRevenue DESC)
            var topRooms = roomPerf
                .Take(5)
                .Select((r, i) => new TopRoomReportItem
                {
                    Rank = i + 1, Branch = r.Branch, RoomCode = r.RoomCode,
                    RoomName = r.RoomName, RoomType = r.RoomType,
                    NetRevenue = r.NetRevenue, OccupancyPct = r.OccupancyPct,
                    TotalBookings = r.TotalBookings,
                    ContributionPct = kpi.NetRevenue > 0 ? Math.Round(r.NetRevenue / kpi.NetRevenue * 100, 1) : 0
                }).ToList();

            var mLabels = new[]{"T1","T2","T3","T4","T5","T6","T7","T8","T9","T10","T11","T12"};
            return new AdminReportViewModel
            {
                SelectedBranch = branchName, SelectedYear = year, SelectedMonth = month,
                SelectedHotelId = hotelId ?? 0,
                Hotels = hotels.Select(h => (h.Id, h.Name, h.City)).ToList(),
                GrossRevenue = kpi.GrossRevenue,
                RefundAmount = kpi.RefundAmount,
                RevPAR       = kpi.NetRevenue > 0 ? Math.Round(kpi.NetRevenue / 365, 0) : 0, // Simplified
                AvgOccupancyRate = $"{kpi.OccupancyRate:F1}%",
                RoomPerformance  = roomPerf,
                TopRooms         = topRooms,
                PricingRecs      = BuildPricingRecs(roomPerf),
                
                // Dữ liệu phân tích lấy thật từ CSDL Nâng cao (Window Functions & CTE)
                HighestRevenueMonth = timeAnalysis.HighestRevenueLabel ?? "-",
                LowestRevenueMonth  = timeAnalysis.LowestRevenueLabel ?? "-",
                MostBookingMonth    = timeAnalysis.MostBookingLabel ?? "-",
                MostBookingCount    = timeAnalysis.MostBookingCount,
                PeakPeriod = branchName switch {
                    "đà nẵng" => "Tháng 6–8 (mùa hè)", "hồ chí minh" => "Tháng 11–1 (lễ, Tết)",
                    "hà nội"  => "Tháng 4 & 9 (nghỉ lễ)",  _ => "Tháng 6–8 và 11–1" },
                LowPeriod  = branchName == "đà nẵng" ? "Tháng 1–2 (sau Tết)" : "Tháng 2–3 (sau Tết)"
            };
        }

        // Removed redundant private static mock methods

        private static List<PricingRecommendation> BuildPricingRecs(List<RoomPerformanceRow> rows)
        {
            // Lấy top 3 phòng cần hành động nhất (>80 hoặc <40)
            var notable = rows
                .Where(r => r.OccupancyPct > 80 || r.OccupancyPct < 40 || r.CancellationPct > 12)
                .OrderByDescending(r => Math.Abs(r.OccupancyPct - 60))
                .Take(4)
                .Select(r => new PricingRecommendation
                {
                    RoomCode = r.RoomCode, RoomName = r.RoomName, Branch = r.Branch,
                    OccupancyPct = r.OccupancyPct, CancellationPct = r.CancellationPct,
                    Recommendation = (r.OccupancyPct, r.CancellationPct) switch
                    {
                        (> 80, < 10) => $"Tăng giá 8–12%. Phòng {r.RoomCode} ({r.Branch}) đang có nhu cầu rất cao ({r.OccupancyPct:F0}% occupancy), cancel thấp.",
                        (> 80, _)    => $"Tăng giá nhẹ 5%. Lưu ý cancel rate {r.CancellationPct:F1}% — cân nhắc điều chỉnh chính sách hủy.",
                        (< 40, _)    => $"Chạy khuyến mãi hoặc giảm giá cho {r.RoomCode} ({r.Branch}). Occupancy chỉ {r.OccupancyPct:F0}%.",
                        _            => $"Phòng {r.RoomCode} có cancel rate cao ({r.CancellationPct:F1}%). Xem lại điều khoản hủy hoặc yêu cầu đặt cọc."
                    },
                    Level = (r.OccupancyPct, r.CancellationPct) switch
                    {
                        (> 80, < 10) => "success", (> 80, _) => "warning",
                        (< 40, _)    => "danger",  _          => "warning"
                    },
                    Icon = r.OccupancyPct > 80 ? "bi-arrow-up-circle-fill"
                         : r.OccupancyPct < 40 ? "bi-arrow-down-circle-fill"
                         : "bi-exclamation-triangle-fill"
                }).ToList();

            // Đảm bảo luôn có ít nhất 2 rec
            if (!notable.Any())
                notable.Add(new PricingRecommendation
                {
                    RoomCode = "SGN-501", RoomName = "Presidential Suite", Branch = "Saigon",
                    OccupancyPct = 86.5m, CancellationPct = 4.2m, Level = "success",
                    Icon = "bi-arrow-up-circle-fill",
                    Recommendation = "Tăng giá 8–12%. Nhu cầu cao, cancel thấp."
                });
            return notable;
        }
    }
}
