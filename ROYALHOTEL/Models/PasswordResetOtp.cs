using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.Models
{
    public class PasswordResetOtp
    {
        public Guid Id { get; set; } // DB default NEWID()

        public int AccountId { get; set; }

        public Account? Account { get; set; }

        [Required, MaxLength(200)]
        public string OtpHash { get; set; } = "";

        [Required, MaxLength(200)]
        public string OtpSalt { get; set; } = "";

        public DateTime ExpiresAt { get; set; }

        public DateTime? UsedAt { get; set; }

        public int AttemptCount { get; set; } = 0; // DB default 0

        public DateTime CreatedAt { get; set; } // DB default SYSDATETIME()
    }
}
