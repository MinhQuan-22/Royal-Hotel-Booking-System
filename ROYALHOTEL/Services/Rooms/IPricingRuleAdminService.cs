using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

public interface IPricingRuleAdminService
{
    Task<List<PricingRule>> GetAllAsync();
    Task<PricingRule?> GetByIdAsync(int id);
    Task CreateAsync(PricingRule rule, string? changedBy);
    Task UpdateAsync(PricingRule rule, string? changedBy);
    Task DeleteAsync(int id, string? changedBy);
    Task<List<PricingRuleHistory>> GetHistoriesAsync(int ruleId);
}
