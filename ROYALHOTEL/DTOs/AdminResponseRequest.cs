using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.DTOs
{
    /// <summary>
    /// DTO for admin response to escalated conversation
    /// Validates: Requirements 10.1
    /// </summary>
    public class AdminResponseRequest
    {
        [Required]
        public int ConversationId { get; set; }

        [Required]
        [MaxLength(2000)]
        public string ResponseText { get; set; } = "";
    }
}
