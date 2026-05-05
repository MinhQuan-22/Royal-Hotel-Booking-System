using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using ROYALHOTEL.DTOs;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Services.Analytics
{
    /// <summary>
    /// Dapper repository gọi các Stored Procedure Dashboard Analytics.
    /// Hoàn toàn tách biệt khỏi EF/DbContext — không conflict booking/payment logic.
    /// </summary>
    public class DashboardRepository : IDashboardRepository
    {
        private readonly string _connStr;

        public DashboardRepository(IConfiguration config)
        {
            _connStr = config.GetConnectionString("DefaultConnection")
                       ?? throw new InvalidOperationException("DefaultConnection missing");
        }

        // ── Helper ──────────────────────────────────────────────────────────
        private SqlConnection Conn() => new SqlConnection(_connStr);

        // ── KPI Summary ──────────────────────────────────────────────────────
        public async Task<DashboardKpiDto> GetKpiAsync(int? hotelId, int year, int month)
        {
            using var conn = Conn();
            var p = new DynamicParameters();
            p.Add("@HotelId", hotelId, DbType.Int32);
            p.Add("@Year",    year,    DbType.Int32);
            p.Add("@Month",   month,   DbType.Int32);

            var result = await conn.QuerySingleOrDefaultAsync<DashboardKpiDto>(
                "sp_GetDashboardKpi", p, commandType: CommandType.StoredProcedure);

            result ??= new DashboardKpiDto();
            result.HotelId = hotelId;
            result.Year    = year;
            result.Month   = month;

            if (hotelId.HasValue)
            {
                var hotels = await GetHotelsAsync();
                result.HotelName = hotels.FirstOrDefault(h => h.Id == hotelId)?.Name ?? "Chi nhánh";
            }
            return result;
        }

        // ── Monthly Revenue (12 tháng, luôn đủ) ─────────────────────────────
        public async Task<List<MonthlyRevenuePoint>> GetMonthlyRevenueAsync(int? hotelId, int year, int month = 0)
        {
            using var conn = Conn();
            var p = new DynamicParameters();
            p.Add("@HotelId", hotelId, DbType.Int32);
            p.Add("@Year",    year,    DbType.Int32);
            p.Add("@Month",   month,   DbType.Int32);

            var rows = await conn.QueryAsync<MonthlyRevenueRaw>(
                "sp_GetDashboardMonthlyRevenue", p, commandType: CommandType.StoredProcedure);

            var list = rows.Select(r => new MonthlyRevenuePoint
            {
                Label      = r.Label,
                NetRevenue = r.NetRevenue
            }).ToList();

            // Tính MaxValue để View dùng tính % bar width
            decimal max = list.Any() ? list.Max(x => x.NetRevenue) : 1;
            if (max == 0) max = 1;
            foreach (var item in list) item.MaxValue = max;

            return list;
        }

        // ── Top N Rooms ──────────────────────────────────────────────────────
        public async Task<List<TopRoomDashItem>> GetTopRoomsAsync(int? hotelId, int year, int month, int topN = 3)
        {
            using var conn = Conn();
            var p = new DynamicParameters();
            p.Add("@HotelId", hotelId, DbType.Int32);
            p.Add("@Year",    year,    DbType.Int32);
            p.Add("@Month",   month,   DbType.Int32);
            p.Add("@TopN",    topN,    DbType.Int32);

            var rows = await conn.QueryAsync<TopRoomRaw>(
                "sp_GetDashboardTopRooms", p, commandType: CommandType.StoredProcedure);

            return rows.Select((r, i) => new TopRoomDashItem
            {
                Rank          = r.Rank,
                Branch        = r.Branch,
                RoomCode      = r.RoomCode,
                RoomName      = r.RoomName,
                RoomType      = r.RoomType,
                NetRevenue    = r.NetRevenue,
                TotalBookings = r.TotalBookings
            }).ToList();
        }

        // ── Room Occupancy ───────────────────────────────────────────────────
        public async Task<List<RoomOccupancyItem>> GetRoomOccupancyAsync(int? hotelId, int year, int month, int topN = 5)
        {
            using var conn = Conn();
            var p = new DynamicParameters();
            p.Add("@HotelId", hotelId, DbType.Int32);
            p.Add("@Year",    year,    DbType.Int32);
            p.Add("@Month",   month,   DbType.Int32);
            p.Add("@TopN",    topN,    DbType.Int32);

            var rows = await conn.QueryAsync<RoomOccupancyItem>(
                "sp_GetDashboardRoomOccupancy", p, commandType: CommandType.StoredProcedure);

            return rows.ToList();
        }

        // ── Cancellation Trend ───────────────────────────────────────────────
        public async Task<List<CancellationTrendPoint>> GetCancellationTrendAsync(int? hotelId, int year, int month)
        {
            using var conn = Conn();
            var p = new DynamicParameters();
            p.Add("@HotelId", hotelId, DbType.Int32);
            p.Add("@Year",    year,    DbType.Int32);
            p.Add("@Month",   month,   DbType.Int32);

            var rows = await conn.QueryAsync<CancellationTrendPoint>(
                "sp_GetDashboardCancellationTrend", p, commandType: CommandType.StoredProcedure);

            return rows.ToList();
        }

        // ── Hotels dropdown ──────────────────────────────────────────────────
        public async Task<IEnumerable<HotelSummaryDto>> GetHotelsAsync()
        {
            using var conn = Conn();
            return await conn.QueryAsync<HotelSummaryDto>(
                "SELECT Id, Name, City FROM Hotels ORDER BY Id",
                commandType: CommandType.Text);
        }

        // ── Raw DTOs (chỉ dùng nội bộ để map SP result) ─────────────────────
        private class MonthlyRevenueRaw
        {
            public int MonthNum { get; set; }
            public string Label { get; set; } = "";
            public decimal NetRevenue { get; set; }
            public int BookingCount { get; set; }
        }

        private class TopRoomRaw
        {
            public int Rank { get; set; }
            public string Branch { get; set; } = "";
            public string RoomCode { get; set; } = "";
            public string RoomName { get; set; } = "";
            public string RoomType { get; set; } = "";
            public decimal NetRevenue { get; set; }
            public int TotalBookings { get; set; }
            public long HotelRank { get; set; }
            public decimal ContribPct { get; set; }
        }
    }
}
