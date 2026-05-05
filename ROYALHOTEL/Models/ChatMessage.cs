using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace ROYALHOTEL.Models
{
    public class ChatMessage
    {
        public int Id { get; set; }

        [Required]
        public int ConversationId { get; set; }

        [JsonIgnore]
        public ChatConversation? Conversation { get; set; }

        [Required, MaxLength(20)]
        public string SenderType { get; set; } = ""; // User, AI, Admin

        [Required]
        public string MessageText { get; set; } = "";

        public bool IsEscalationMessage { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
