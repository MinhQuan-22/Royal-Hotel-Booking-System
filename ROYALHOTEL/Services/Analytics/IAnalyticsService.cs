using ROYALHOTEL.DTOs;

namespace ROYALHOTEL.Services.Analytics;

/// <summary>
/// Service interface for analytics and audit reporting
/// </summary>
public interface IAnalyticsService
{
    /// <summary>
    /// Retrieves quarterly revenue analytics for top 3 revenue-generating rooms per hotel per quarter
    /// </summary>
    /// <param name="hotelId">Optional hotel ID filter</param>
    /// <param name="year">Optional year filter</param>
    /// <param name="quarter">Optional quarter filter (1-4)</param>
    /// <returns>Collection of quarterly revenue data</returns>
    Task<IEnumerable<QuarterlyRevenueDto>> GetQuarterlyRevenueAnalyticsAsync(
        int? hotelId = null,
        int? year = null,
        int? quarter = null);

    /// <summary>
    /// Parses room rate change logs for a specific room within a date range
    /// </summary>
    /// <param name="roomId">Room ID to query</param>
    /// <param name="startDate">Optional start date filter</param>
    /// <param name="endDate">Optional end date filter</param>
    /// <returns>Collection of rate change data</returns>
    Task<IEnumerable<RateChangeDto>> ParseRateChangeLogAsync(
        int roomId,
        DateTime? startDate = null,
        DateTime? endDate = null);

    /// <summary>
    /// Formats rate change data into an HTML report
    /// </summary>
    /// <param name="changes">Collection of rate changes to format</param>
    /// <returns>HTML-formatted report string</returns>
    string FormatRateChangeReport(IEnumerable<RateChangeDto> changes);
}
