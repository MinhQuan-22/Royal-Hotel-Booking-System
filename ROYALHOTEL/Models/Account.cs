using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.Models
{
    public class Account
    {
        public int Id { get; set; }

        [Required, MaxLength(200)]
        public string FullName { get; set; } = "";

        [Required, MaxLength(200)]
        public string Email { get; set; } = "";

        [Required, MaxLength(200)]
        public string Role { get; set; } = "user"; // admin/user

        [MaxLength(50)]
        public string? Phone { get; set; }

        [Required, MaxLength(500)]
        public string PasswordHash { get; set; } = "";

        [Required, MaxLength(200)]
        public string PasswordSalt { get; set; } = "";

        public DateTime CreatedAt { get; set; } // DB default SYSDATETIME()
        public DateTime UpdatedAt { get; set; } // DB default SYSDATETIME()
        public string Status { get; set; } = "active";

        // Navigation
        public ICollection<Booking> Bookings { get; set; } = new List<Booking>();
    }
}
