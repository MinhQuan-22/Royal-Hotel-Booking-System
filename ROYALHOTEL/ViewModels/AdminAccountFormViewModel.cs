namespace ROYALHOTEL.ViewModels
{
    public class AdminAccountFormViewModel
    {
        public int Id { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string Role { get; set; } = "user";

        public string Status { get; set; } = "active";
    }
}