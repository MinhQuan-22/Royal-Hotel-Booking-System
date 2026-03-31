using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

public class PricingRuleAdminService : IPricingRuleAdminService
{
    private readonly RoyalHotelDbContext _db;

    public PricingRuleAdminService(RoyalHotelDbContext db)
    {
        _db = db;
    }

    public Task<List<PricingRule>> GetAllAsync()
        => _db.PricingRules.AsNoTracking().OrderBy(r => r.Priority).ThenBy(r => r.Name).ToListAsync();

    public Task<PricingRule?> GetByIdAsync(int id)
        => _db.PricingRules.AsNoTracking().FirstOrDefaultAsync(r => r.Id == id);

    public async Task CreateAsync(PricingRule rule, string? changedBy)
    {
        var now = DateTime.UtcNow;
        rule.CreatedAt = now;
        rule.UpdatedAt = now;
        rule.CreatedBy = changedBy;
        rule.UpdatedBy = changedBy;

        _db.PricingRules.Add(rule);

        var history = BuildHistory(rule, "create", changedBy, now);
        _db.PricingRuleHistories.Add(history);

        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(PricingRule rule, string? changedBy)
    {
        var now = DateTime.UtcNow;
        rule.UpdatedAt = now;
        rule.UpdatedBy = changedBy;

        _db.PricingRules.Update(rule);

        var history = BuildHistory(rule, "update", changedBy, now);
        _db.PricingRuleHistories.Add(history);

        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(int id, string? changedBy)
    {
        var rule = await _db.PricingRules.FindAsync(id);
        if (rule == null)
            return;

        var history = BuildHistory(rule, "delete", changedBy, DateTime.UtcNow);
        _db.PricingRuleHistories.Add(history);

        _db.PricingRules.Remove(rule);
        await _db.SaveChangesAsync();
    }

    public Task<List<PricingRuleHistory>> GetHistoriesAsync(int ruleId)
        => _db.PricingRuleHistories
              .AsNoTracking()
              .Where(h => h.PricingRuleId == ruleId)
              .OrderByDescending(h => h.ChangedAt)
              .ToListAsync();

    private static PricingRuleHistory BuildHistory(PricingRule rule, string action, string? changedBy, DateTime changedAt)
        => new()
        {
            PricingRuleId = rule.Id == 0 ? null : rule.Id,
            ActionType = action,
            RuleName = rule.Name,
            RuleType = rule.RuleType,
            RoomType = rule.RoomType,
            StartDate = rule.StartDate,
            EndDate = rule.EndDate,
            DayOfWeekMask = rule.DayOfWeekMask,
            Multiplier = rule.Multiplier,
            Priority = rule.Priority,
            IsActive = rule.IsActive,
            Notes = rule.Notes,
            ChangedAt = changedAt,
            ChangedBy = changedBy
        };
}
