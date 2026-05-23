namespace ROYALHOTEL.Services.Email
{
    public class SmtpSettings
    {
        public string Host { get; set; } = "";
        public int Port { get; set; } = 587;
        public string Username { get; set; } = "";
        public string Password { get; set; } = "";
        public string FromEmail { get; set; } = "";
        public string FromName { get; set; } = "Royal Hotel";
        public bool EnableSsl { get; set; } = true;

        /// <summary>
        /// P1-3: Email address to receive admin notifications (e.g. new escalation alerts).
        /// Falls back to FromEmail if not set.
        /// </summary>
        public string AdminNotificationEmail { get; set; } = "";
    }
}
