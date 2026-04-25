using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using System.Text;
using ROYALHOTEL.Data;
using ROYALHOTEL.DTOs;

namespace ROYALHOTEL.Services.Analytics;

/// <summary>
/// Service implementation for analytics and audit reporting
/// </summary>
public class AnalyticsService : IAnalyticsService
{
    private readonly RoyalHotelDbContext _context;
    private readonly ILogger<AnalyticsService> _logger;

    public AnalyticsService(
        RoyalHotelDbContext context,
        ILogger<AnalyticsService> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Retrieves quarterly revenue analytics by executing the Quarterly_Revenue_Analytics stored procedure
    /// </summary>
    public async Task<IEnumerable<QuarterlyRevenueDto>> GetQuarterlyRevenueAnalyticsAsync(
        int? hotelId = null,
        int? year = null,
        int? quarter = null)
    {
        try
        {
            // Create SQL parameters with proper NULL handling
            var hotelIdParam = new SqlParameter("@HotelId", (object?)hotelId ?? DBNull.Value);
            var yearParam = new SqlParameter("@Year", (object?)year ?? DBNull.Value);
            var quarterParam = new SqlParameter("@Quarter", (object?)quarter ?? DBNull.Value);

            // Execute stored procedure using SqlQueryRaw
            var results = await _context.Database
                .SqlQueryRaw<QuarterlyRevenueDto>(
                    "EXEC Quarterly_Revenue_Analytics @HotelId, @Year, @Quarter",
                    hotelIdParam, yearParam, quarterParam)
                .ToListAsync();

            _logger.LogInformation(
                "Retrieved {Count} quarterly revenue records for HotelId={HotelId}, Year={Year}, Quarter={Quarter}",
                results.Count, hotelId, year, quarter);

            return results;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error executing Quarterly_Revenue_Analytics with HotelId={HotelId}, Year={Year}, Quarter={Quarter}",
                hotelId, year, quarter);
            
            // Return empty collection on error (fail-safe behavior)
            return Enumerable.Empty<QuarterlyRevenueDto>();
        }
    }

    /// <summary>
    /// Parses room rate change logs with optional date range filtering
    /// </summary>
    public async Task<IEnumerable<RateChangeDto>> ParseRateChangeLogAsync(
        int roomId,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        try
        {
            var query = _context.RoomRateChangeLogs
                .Where(log => log.RoomId == roomId);

            // Apply date range filters if provided
            if (startDate.HasValue)
                query = query.Where(log => log.ChangedAt >= startDate.Value);

            if (endDate.HasValue)
                query = query.Where(log => log.ChangedAt <= endDate.Value);

            // Execute query with Room navigation property
            var logs = await query
                .Include(log => log.Room)
                .OrderByDescending(log => log.ChangedAt)
                .ToListAsync();

            // Map to DTO
            var results = logs.Select(log => new RateChangeDto
            {
                Id = log.Id,
                RoomId = log.RoomId,
                RoomCode = log.Room.Code,
                RoomName = log.Room.Name,
                OldRate = log.OldRate,
                NewRate = log.NewRate,
                ChangePercent = log.ChangePercent,
                ChangedAt = log.ChangedAt,
                ChangedBy = log.ChangedBy
            }).ToList();

            _logger.LogInformation(
                "Retrieved {Count} rate change logs for RoomId={RoomId}, StartDate={StartDate}, EndDate={EndDate}",
                results.Count, roomId, startDate, endDate);

            return results;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error parsing rate change logs for RoomId={RoomId}, StartDate={StartDate}, EndDate={EndDate}",
                roomId, startDate, endDate);
            
            // Return empty collection on error
            return Enumerable.Empty<RateChangeDto>();
        }
    }

    /// <summary>
    /// Formats rate change data into an HTML table with proper encoding to prevent XSS
    /// </summary>
    public string FormatRateChangeReport(IEnumerable<RateChangeDto> changes)
    {
        if (!changes.Any())
            return "<p>No rate changes found.</p>";

        var sb = new StringBuilder();
        sb.AppendLine("<table class='table table-striped'>");
        sb.AppendLine("<thead><tr>");
        sb.AppendLine("<th>Room</th><th>Old Rate</th><th>New Rate</th>");
        sb.AppendLine("<th>Change %</th><th>Changed At</th><th>Changed By</th>");
        sb.AppendLine("</tr></thead><tbody>");

        foreach (var change in changes)
        {
            // HTML encode all user-provided data to prevent XSS
            var roomDisplay = System.Net.WebUtility.HtmlEncode($"{change.RoomCode} - {change.RoomName}");
            var changedBy = System.Net.WebUtility.HtmlEncode(change.ChangedBy ?? "System");
            
            // Apply CSS class based on positive/negative change
            var changeClass = change.ChangePercent > 0 ? "text-success" : "text-danger";

            sb.AppendLine("<tr>");
            sb.AppendLine($"<td>{roomDisplay}</td>");
            sb.AppendLine($"<td>${change.OldRate:N2}</td>");
            sb.AppendLine($"<td>${change.NewRate:N2}</td>");
            sb.AppendLine($"<td class='{changeClass}'>{change.ChangePercent:+0.00;-0.00}%</td>");
            sb.AppendLine($"<td>{change.ChangedAt:yyyy-MM-dd HH:mm:ss}</td>");
            sb.AppendLine($"<td>{changedBy}</td>");
            sb.AppendLine("</tr>");
        }

        sb.AppendLine("</tbody></table>");
        return sb.ToString();
    }
}
