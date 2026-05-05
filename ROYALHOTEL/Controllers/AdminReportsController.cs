using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.DTOs;
using ROYALHOTEL.Services.Analytics;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminReportsController : Controller
    {
        private readonly IAnalyticsService _analytics;
        public AdminReportsController(IAnalyticsService analytics) => _analytics = analytics;

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        [HttpGet]
        public IActionResult Index(string branch = "all", int year = 2026, int month = 0)
        {
            if (!IsAdmin()) return RedirectToAction("Login", "Account");
            return View(BuildReport(branch, year, month));
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
        private static AdminReportViewModel BuildReport(string branch, int year, int month)
        {
            decimal yMult = year switch { 2024 => 0.78m, 2025 => 0.92m, _ => 1.0m };
            decimal mMult = month == 0 ? 1.0m : GetMonthMultiplier(month, branch);

            var gross  = GetAnnualGross(branch) * yMult * mMult;
            var refund = GetAnnualRefund(branch) * yMult * mMult;
            var occPct = GetOccPct(branch, month);

            var roomPerf = BuildRoomPerf(branch, yMult * mMult);
            var topRooms = roomPerf
                .OrderByDescending(r => r.NetRevenue).Take(3)
                .Select((r, i) => new TopRoomReportItem
                {
                    Rank = i + 1, Branch = r.Branch, RoomCode = r.RoomCode,
                    RoomName = r.RoomName, RoomType = r.RoomType,
                    NetRevenue = r.NetRevenue, OccupancyPct = r.OccupancyPct,
                    TotalBookings = r.TotalBookings,
                    ContributionPct = gross > 0 ? Math.Round(r.NetRevenue / (gross - refund) * 100, 1) : 0
                }).ToList();

            // Time analysis — monthly distribution
            var mDist = GetMonthlyDist(branch);
            int peakIdx = mDist.Select((v,i)=>(v,i)).OrderByDescending(x=>x.v).First().i;
            int lowIdx  = mDist.Select((v,i)=>(v,i)).OrderBy(x=>x.v).First().i;
            var mLabels = new[]{"T1","T2","T3","T4","T5","T6","T7","T8","T9","T10","T11","T12"};
            int bkPeakIdx = new[]{280,260,300,340,370,460,480,470,415,370,350,415}
                .Select((v,i)=>(v,i)).OrderByDescending(x=>x.v).First().i;

            return new AdminReportViewModel
            {
                SelectedBranch = branch, SelectedYear = year, SelectedMonth = month,
                GrossRevenue = Math.Round(gross, 0),
                RefundAmount = Math.Round(refund, 0),
                RevPAR       = Math.Round(gross / 365 * (occPct/100), 0),
                AvgOccupancyRate = $"{occPct:F1}%",
                RoomPerformance  = roomPerf,
                TopRooms         = topRooms,
                PricingRecs      = BuildPricingRecs(roomPerf),
                HighestRevenueMonth = mLabels[peakIdx],
                HighestRevenueValue = Math.Round(gross * mDist[peakIdx], 0),
                LowestRevenueMonth  = mLabels[lowIdx],
                LowestRevenueValue  = Math.Round(gross * mDist[lowIdx], 0),
                MostBookingMonth    = mLabels[bkPeakIdx],
                MostBookingCount    = (int)(500 * mDist[bkPeakIdx] * (branch=="all"?3:1)),
                PeakPeriod = branch switch {
                    "danang" => "Tháng 6–8 (mùa hè biển)", "saigon" => "Tháng 11–1 (lễ, Tết)",
                    "hanoi"  => "Tháng 4 & 9 (nghỉ lễ)",  _ => "T6–T8 và T11–T1" },
                LowPeriod  = branch == "danang" ? "Tháng 1–2 (sau Tết)" : "Tháng 2–3 (sau Tết)"
            };
        }

        private static decimal GetAnnualGross(string b) => b switch {
            "saigon" => 890_000_000m, "danang" => 720_000_000m,
            "hanoi"  => 490_000_000m, _ => 2_100_000_000m };
        private static decimal GetAnnualRefund(string b) => b switch {
            "saigon" => 33_000_000m, "danang" => 36_000_000m,
            "hanoi"  => 26_000_000m, _ => 95_000_000m };
        private static decimal GetOccPct(string b, int m)
        {
            decimal base_ = b switch { "saigon"=>81.5m, "danang"=>67.8m, "hanoi"=>63.2m, _=>73.2m };
            if (b == "danang" && m is >= 6 and <= 8) return base_ + 10m;
            return base_ + (m is 1 or 2 ? -5m : 0m);
        }

        private static decimal[] GetMonthlyDist(string b) =>
            b == "danang"
                ? new[]{.050m,.045m,.060m,.065m,.075m,.140m,.155m,.148m,.080m,.060m,.055m,.067m}
                : b == "saigon"
                    ? new[]{.065m,.058m,.068m,.082m,.088m,.098m,.100m,.098m,.090m,.082m,.092m,.105m}
                    : new[]{.065m,.060m,.070m,.078m,.085m,.105m,.110m,.108m,.095m,.085m,.080m,.095m};

        private static decimal GetMonthMultiplier(int m, string b)
        {
            var dist = GetMonthlyDist(b);
            return dist[m - 1] * 12;
        }

        private static List<RoomPerformanceRow> BuildRoomPerf(string branch, decimal mult)
        {
            var all = new List<RoomPerformanceRow>
            {
                new(){ Branch="Saigon",  RoomCode="SGN-501", RoomName="Presidential Suite", RoomType="Suite",
                    GrossRevenue=30_000_000, RefundAmount=1_200_000, TotalBookings=12, OccupancyPct=86.5m, CancellationPct=4.2m },
                new(){ Branch="Saigon",  RoomCode="SGN-401", RoomName="Executive Suite",    RoomType="Suite",
                    GrossRevenue=22_500_000, RefundAmount=1_500_000, TotalBookings=15, OccupancyPct=79.2m, CancellationPct=6.8m },
                new(){ Branch="Saigon",  RoomCode="SGN-301", RoomName="Saigon Deluxe",      RoomType="Deluxe",
                    GrossRevenue=15_200_000, RefundAmount=700_000,   TotalBookings=22, OccupancyPct=74.8m, CancellationPct=5.5m },
                new(){ Branch="Saigon",  RoomCode="SGN-201", RoomName="City View Room",     RoomType="Superior",
                    GrossRevenue=9_800_000,  RefundAmount=500_000,   TotalBookings=28, OccupancyPct=68.5m, CancellationPct=7.1m },
                new(){ Branch="Saigon",  RoomCode="SGN-101", RoomName="Standard Room",      RoomType="Standard",
                    GrossRevenue=5_500_000,  RefundAmount=400_000,   TotalBookings=35, OccupancyPct=42.2m, CancellationPct=9.8m },
                new(){ Branch="Da Nang", RoomCode="DAN-301", RoomName="Ocean Deluxe",       RoomType="Deluxe",
                    GrossRevenue=23_200_000, RefundAmount=1_200_000, TotalBookings=18, OccupancyPct=72.1m, CancellationPct=8.5m },
                new(){ Branch="Da Nang", RoomCode="DAN-201", RoomName="Seaview Suite",      RoomType="Suite",
                    GrossRevenue=18_500_000, RefundAmount=1_000_000, TotalBookings=10, OccupancyPct=68.4m, CancellationPct=12.0m },
                new(){ Branch="Da Nang", RoomCode="DAN-102", RoomName="Beach Room",         RoomType="Superior",
                    GrossRevenue=8_200_000,  RefundAmount=600_000,   TotalBookings=24, OccupancyPct=60.5m, CancellationPct=11.5m },
                new(){ Branch="Da Nang", RoomCode="DAN-101", RoomName="Beach Standard",     RoomType="Standard",
                    GrossRevenue=4_800_000,  RefundAmount=300_000,   TotalBookings=28, OccupancyPct=35.5m, CancellationPct=14.2m },
                new(){ Branch="Ha Noi",  RoomCode="HAN-301", RoomName="Hanoi Suite",        RoomType="Suite",
                    GrossRevenue=14_800_000, RefundAmount=800_000,   TotalBookings=9,  OccupancyPct=60.8m, CancellationPct=9.2m },
                new(){ Branch="Ha Noi",  RoomCode="HAN-201", RoomName="Premier Room",       RoomType="Superior",
                    GrossRevenue=19_500_000, RefundAmount=1_000_000, TotalBookings=14, OccupancyPct=66.3m, CancellationPct=7.8m },
                new(){ Branch="Ha Noi",  RoomCode="HAN-101", RoomName="Classic Room",       RoomType="Standard",
                    GrossRevenue=5_800_000,  RefundAmount=400_000,   TotalBookings=20, OccupancyPct=38.2m, CancellationPct=11.0m },
            };

            var branchMap = new Dictionary<string,string>
            { ["saigon"]="Saigon", ["danang"]="Da Nang", ["hanoi"]="Ha Noi" };
            var filtered = branch == "all" ? all
                : all.Where(r => r.Branch == (branchMap.ContainsKey(branch) ? branchMap[branch] : "")).ToList();

            foreach (var r in filtered)
            {
                r.GrossRevenue = Math.Round(r.GrossRevenue * mult, 0);
                r.RefundAmount = Math.Round(r.RefundAmount * mult, 0);
                (r.SuggestedAction, r.ActionLevel) = (r.OccupancyPct, r.CancellationPct) switch
                {
                    (> 80, < 10) => ("Đề xuất tăng giá ~10%", "success"),
                    (> 80, _)    => ("Tăng giá nhẹ — lưu ý cancel cao", "warning"),
                    (> 40, _)    => ("Giữ giá", "info"),
                    _            => ("Cần khuyến mãi", "danger")
                };
            }
            return filtered;
        }

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
