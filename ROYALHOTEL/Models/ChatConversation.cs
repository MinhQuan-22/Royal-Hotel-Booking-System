using System.ComponentModel.DataAnnotations;

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

        [Required, MaxLength(30)]
        public string Status { get; set; } = "Open"; // Open, EscalatedToAdmin, AnsweredByAdmin, Closed

        [MaxLength(500)]
        public string? EscalationReason { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
    }
}
