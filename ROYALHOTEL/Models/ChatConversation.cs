using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace ROYALHOTEL.Models
{
    public class ChatConversation
    {
        public int Id { get; set; }

        [Required, MaxLength(50)]
        public string ConversationCode { get; set; } = "";

        public int? AccountId { get; set; }
        public Account? Account { get; set; }

        [MaxLength(200)]
        public string? GuestName { get; set; }

        [MaxLength(200)]
        public string? GuestEmail { get; set; }

        [MaxLength(20)]
        public string? GuestPhone { get; set; }

        [Required, MaxLength(30)]
        public string Status { get; set; } = "Open"; // Open, EscalatedToAdmin, AnsweredByAdmin, Closed

        [MaxLength(500)]
        public string? EscalationReason { get; set; }

        /// <summary>
        /// Timestamp when conversation was escalated to admin
        /// Used to filter messages: only show messages created AFTER this timestamp to admin
        /// </summary>
        public DateTime? EscalatedAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        [JsonIgnore]
        public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
    }
}
