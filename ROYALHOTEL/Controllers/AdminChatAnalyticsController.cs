using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers;


/// <summary>
/// P3-1: Admin analytics dashboard for AI Chat system.
/// Shows message volumes, escalation rates, AI response metrics, and conversation trends.
/// </summary>
public class AdminChatAnalyticsController : Controller
{
    private readonly RoyalHotelDbContext _context;
    private readonly ILogger<AdminChatAnalyticsController> _logger;

    public AdminChatAnalyticsController(
        RoyalHotelDbContext context,
        ILogger<AdminChatAnalyticsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    private bool IsAdmin()
    {
        var role = HttpContext.Session.GetString("USER_ROLE");
        return role != null && role.ToLower() == "admin";
    }

    // GET /AdminChatAnalytics
    [HttpGet]
    public async Task<IActionResult> Index(int days = 30)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        days = Math.Clamp(days, 1, 365);
        var since = DateTime.UtcNow.AddDays(-days);

        // ── Overview KPIs ──
        var totalConversations = await _context.ChatConversations
            .Where(c => c.CreatedAt >= since)
            .CountAsync();

        var escalatedCount = await _context.ChatConversations
            .Where(c => c.CreatedAt >= since &&
                        (c.Status == "EscalatedToAdmin" || c.Status == "AnsweredByAdmin" || c.Status == "Closed"))
            .CountAsync();

        var closedCount = await _context.ChatConversations
            .Where(c => c.CreatedAt >= since && c.Status == "Closed")
            .CountAsync();

        var totalMessages = await _context.ChatMessages
            .Where(m => m.CreatedAt >= since)
            .CountAsync();

        var aiMessages = await _context.ChatMessages
            .Where(m => m.CreatedAt >= since && m.SenderType == "AI")
            .CountAsync();

        var adminMessages = await _context.ChatMessages
            .Where(m => m.CreatedAt >= since && m.SenderType == "Admin")
            .CountAsync();

        var userMessages = await _context.ChatMessages
            .Where(m => m.CreatedAt >= since && m.SenderType == "User")
            .CountAsync();

        // Escalation rate
        double escalationRate = totalConversations > 0
            ? Math.Round((double)escalatedCount / totalConversations * 100, 1)
            : 0;

        // ── Daily conversation trend (last N days) ──
        var dailyData = await _context.ChatConversations
            .Where(c => c.CreatedAt >= since)
            .GroupBy(c => c.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .OrderBy(x => x.Date)
            .ToListAsync();

        // ── Daily escalation trend ──
        var dailyEscalations = await _context.ChatConversations
            .Where(c => c.EscalatedAt.HasValue && c.EscalatedAt >= since)
            .GroupBy(c => c.EscalatedAt!.Value.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .OrderBy(x => x.Date)
            .ToListAsync();


        // ── Top escalation reasons ──
        var topReasons = await _context.ChatConversations
            .Where(c => c.CreatedAt >= since && !string.IsNullOrEmpty(c.EscalationReason))
            .GroupBy(c => c.EscalationReason!)
            .Select(g => new TopReasonDto { Reason = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .Take(5)
            .ToListAsync();

        // ── Avg messages per conversation ──
        var avgMsgsPerConv = totalConversations > 0
            ? Math.Round((double)totalMessages / totalConversations, 1)
            : 0;

        // ── Recent escalations (last 10) ──
        var recentEscalations = await _context.ChatConversations
            .Include(c => c.Account)
            .Where(c => c.EscalatedAt.HasValue && c.EscalatedAt >= since)
            .OrderByDescending(c => c.EscalatedAt)
            .Take(10)
            .Select(c => new RecentEscalationDto
            {
                Id = c.Id,
                ConversationCode = c.ConversationCode,
                GuestName = c.GuestName ?? (c.Account != null ? c.Account.FullName : "Khách ẩn danh"),
                EscalationReason = c.EscalationReason,
                EscalatedAt = c.EscalatedAt,
                Status = c.Status
            })
            .ToListAsync();

        // ── Build chart data ──
        // Fill in missing dates with 0
        var dateRange = Enumerable.Range(0, days)
            .Select(i => DateTime.UtcNow.AddDays(-days + 1 + i).Date)
            .ToList();

        var convsByDate = dailyData.ToDictionary(x => x.Date, x => x.Count);
        var escalByDate = dailyEscalations.ToDictionary(x => x.Date, x => x.Count);

        var chartLabels = dateRange.Select(d => d.ToString("dd/MM")).ToList();
        var chartConvData = dateRange.Select(d => convsByDate.GetValueOrDefault(d, 0)).ToList();
        var chartEscalData = dateRange.Select(d => escalByDate.GetValueOrDefault(d, 0)).ToList();

        ViewBag.Days = days;
        ViewBag.TotalConversations = totalConversations;
        ViewBag.EscalatedCount = escalatedCount;
        ViewBag.ClosedCount = closedCount;
        ViewBag.EscalationRate = escalationRate;
        ViewBag.TotalMessages = totalMessages;
        ViewBag.AIMessages = aiMessages;
        ViewBag.AdminMessages = adminMessages;
        ViewBag.UserMessages = userMessages;
        ViewBag.AvgMsgsPerConv = avgMsgsPerConv;
        ViewBag.TopReasons = topReasons;
        ViewBag.RecentEscalations = recentEscalations;
        ViewBag.ChartLabels = System.Text.Json.JsonSerializer.Serialize(chartLabels);
        ViewBag.ChartConvData = System.Text.Json.JsonSerializer.Serialize(chartConvData);
        ViewBag.ChartEscalData = System.Text.Json.JsonSerializer.Serialize(chartEscalData);

        return View();
    }

    // GET /AdminChatAnalytics/ApiSummary — JSON endpoint for real-time refresh
    [HttpGet]
    public async Task<IActionResult> ApiSummary(int days = 7)
    {
        if (!IsAdmin()) return Unauthorized();

        days = Math.Clamp(days, 1, 90);
        var since = DateTime.UtcNow.AddDays(-days);

        var total = await _context.ChatConversations.Where(c => c.CreatedAt >= since).CountAsync();
        var escalated = await _context.ChatConversations
            .Where(c => c.EscalatedAt.HasValue && c.EscalatedAt >= since).CountAsync();
        var aiMsgs = await _context.ChatMessages
            .Where(m => m.CreatedAt >= since && m.SenderType == "AI").CountAsync();

        return Ok(new
        {
            totalConversations = total,
            escalatedCount = escalated,
            escalationRate = total > 0 ? Math.Round((double)escalated / total * 100, 1) : 0,
            aiMessages = aiMsgs,
            period = $"Last {days} days"
        });
    }
}
