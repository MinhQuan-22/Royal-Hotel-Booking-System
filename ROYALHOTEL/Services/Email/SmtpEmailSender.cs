using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;

namespace ROYALHOTEL.Services.Email
{
    public class SmtpEmailSender : IEmailSender
    {
        private readonly SmtpSettings _s;

        public SmtpEmailSender(IOptions<SmtpSettings> opt)
        {
            _s = opt.Value;
        }

        public async Task SendAsync(string toEmail, string subject, string htmlBody)
        {
            if (string.IsNullOrWhiteSpace(_s.Host) || string.IsNullOrWhiteSpace(_s.FromEmail))
                throw new InvalidOperationException("SMTP chưa được cấu hình trong appsettings.");

            using var msg = new MailMessage();
            msg.From = new MailAddress(_s.FromEmail, _s.FromName);
            msg.To.Add(toEmail);
            msg.Subject = subject;
            msg.Body = htmlBody;
            msg.IsBodyHtml = true;

            using var client = new SmtpClient(_s.Host, _s.Port);
            client.EnableSsl = _s.EnableSsl;

            if (!string.IsNullOrWhiteSpace(_s.Username))
                client.Credentials = new NetworkCredential(_s.Username, _s.Password);

            await client.SendMailAsync(msg);
        }
    }
}
