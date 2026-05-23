using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.Models;

/// <summary>
/// Stores configurable hotel policies that can be managed by admin
/// and used by the AI chat system for policy-related questions.
/// </summary>
public class HotelPolicy
{
    public int Id { get; set; }

    /// <summary>Policy key/slug e.g. "checkin", "checkout", "cancellation", "children", "payment"</summary>
    [Required, MaxLength(100)]
    public string PolicyKey { get; set; } = "";

    /// <summary>Display name shown to admin: e.g. "Chính sách Check-in"</summary>
    [Required, MaxLength(200)]
    public string PolicyName { get; set; } = "";

    /// <summary>Policy content in Vietnamese, supports multi-line markdown</summary>
    [Required]
    public string Content { get; set; } = "";

    /// <summary>Category for grouping: e.g. "Policies", "FAQ"</summary>
    [MaxLength(50)]
    public string Category { get; set; } = "Policies";

    /// <summary>Sort order for display</summary>
    public int SortOrder { get; set; } = 0;

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
