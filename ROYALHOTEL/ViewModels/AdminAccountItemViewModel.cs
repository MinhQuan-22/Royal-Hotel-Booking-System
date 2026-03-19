using System;

namespace ROYALHOTEL.ViewModels
{
    public class AdminAccountItemViewModel
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string Role { get; set; } = "user";
        public string Status { get; set; } = "active";
        public DateTime CreatedAt { get; set; }
    }
}