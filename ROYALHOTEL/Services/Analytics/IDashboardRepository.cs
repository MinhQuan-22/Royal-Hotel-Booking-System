using ROYALHOTEL.DTOs;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Services.Analytics
{
    public interface IDashboardRepository
    {
        /// <summary>sp_GetDashboardKpi — KPI tổng hợp</summary>
        Task<DashboardKpiDto> GetKpiAsync(int? hotelId, int year, int month);

        /// <summary>sp_GetDashboardMonthlyRevenue — Net Revenue 12 tháng (hoặc 4 tuần nếu có month)</summary>
        Task<List<MonthlyRevenuePoint>> GetMonthlyRevenueAsync(int? hotelId, int year, int month = 0);

        /// <summary>sp_GetDashboardTopRooms — Top N phòng theo Net Revenue (RANK OVER PARTITION)</summary>
        Task<List<TopRoomDashItem>> GetTopRoomsAsync(int? hotelId, int year, int month, int topN = 3);

        /// <summary>sp_GetDashboardRoomOccupancy — Tỷ lệ lấp phòng từng phòng</summary>
        Task<List<RoomOccupancyItem>> GetRoomOccupancyAsync(int? hotelId, int year, int month, int topN = 5);

        /// <summary>sp_GetDashboardCancellationTrend — Xu hướng hủy phòng theo tháng/tuần</summary>
        Task<List<CancellationTrendPoint>> GetCancellationTrendAsync(int? hotelId, int year, int month);

        /// <summary>Danh sách Hotels để build dropdown filter</summary>
        Task<IEnumerable<HotelSummaryDto>> GetHotelsAsync();
    }

    public class HotelSummaryDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string City { get; set; } = "";
    }
}
