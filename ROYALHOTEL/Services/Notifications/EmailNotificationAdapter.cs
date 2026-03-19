using System.Globalization;
using ROYALHOTEL.Services.Email;

namespace ROYALHOTEL.Services.Notifications;

/// <summary>
/// Adapter Pattern: Chuyển đổi từ IBookingNotificationService (target) 
/// sang IEmailSender (adaptee)
/// </summary>
public class EmailNotificationAdapter : IBookingNotificationService
{
    private readonly IEmailSender _emailSender;

    public EmailNotificationAdapter(IEmailSender emailSender)
    {
        _emailSender = emailSender;
    }

    public async Task SendBookingConfirmationAsync(Models.Booking booking)
    {
        // Không gửi nếu không có email
        if (string.IsNullOrWhiteSpace(booking.GuestEmail))
            return;

        // Build subject
        var subject = $"Xác nhận đặt phòng thành công - Royal Hotel [{booking.BookingCode}]";

        // Build HTML body
        var htmlBody = BuildConfirmationEmailHtml(booking);

        // Adapt: Chuyển từ ngôn ngữ nghiệp vụ booking sang technical email call
        await _emailSender.SendAsync(booking.GuestEmail, subject, htmlBody);
    }

    private string BuildConfirmationEmailHtml(Models.Booking booking)
    {
        var culture = new CultureInfo("vi-VN");
        var nights = (booking.CheckOut - booking.CheckIn).Days;
        
        var roomName = booking.Room?.Name ?? "N/A";
        var roomCode = booking.Room?.Code ?? "N/A";
        var paymentMethod = booking.PaymentMethod ?? "N/A";
        
        var checkInStr = booking.CheckIn.ToString("dd/MM/yyyy");
        var checkOutStr = booking.CheckOut.ToString("dd/MM/yyyy");
        var createdAtStr = booking.CreatedAt.ToString("dd/MM/yyyy HH:mm");
        
        var pricePerNightStr = booking.PricePerNight?.ToString("N0", culture) ?? "0";
        var totalAmountStr = booking.TotalAmount?.ToString("N0", culture) ?? "0";

        return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
        .info-row {{ margin: 15px 0; padding: 10px; background: white; border-radius: 5px; }}
        .label {{ font-weight: bold; color: #667eea; }}
        .value {{ color: #333; }}
        .footer {{ text-align: center; margin-top: 30px; padding: 20px; color: #666; font-size: 14px; }}
        .highlight {{ background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🏨 ROYAL LUXURY HOTEL</h1>
            <p>Xác nhận đặt phòng thành công</p>
        </div>
        
        <div class='content'>
            <p>Kính chào <strong>{booking.GuestName}</strong>,</p>
            
            <p>Cảm ơn quý khách đã tin tưởng và đặt phòng tại Royal Hotel. Chúng tôi xin xác nhận thông tin đặt phòng của quý khách như sau:</p>
            
            <div class='highlight'>
                <div class='info-row'>
                    <span class='label'>Mã đặt phòng:</span>
                    <span class='value'>{booking.BookingCode}</span>
                </div>
            </div>
            
            <div class='info-row'>
                <span class='label'>Phòng:</span>
                <span class='value'>{roomName} ({roomCode})</span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Ngày nhận phòng:</span>
                <span class='value'>{checkInStr} - 14:00</span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Ngày trả phòng:</span>
                <span class='value'>{checkOutStr} - 12:00</span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Số đêm:</span>
                <span class='value'>{nights} đêm</span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Số khách:</span>
                <span class='value'>{booking.Guests} người</span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Giá mỗi đêm:</span>
                <span class='value'>{pricePerNightStr} VNĐ</span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Tổng tiền:</span>
                <span class='value' style='font-size: 18px; color: #667eea;'><strong>{totalAmountStr} VNĐ</strong></span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Phương thức thanh toán:</span>
                <span class='value'>{paymentMethod}</span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Trạng thái:</span>
                <span class='value' style='color: #28a745;'><strong>{booking.Status}</strong></span>
            </div>
            
            <div class='info-row'>
                <span class='label'>Thời gian đặt:</span>
                <span class='value'>{createdAtStr}</span>
            </div>
            
            <p style='margin-top: 30px;'>Quý khách vui lòng mang theo mã đặt phòng <strong>{booking.BookingCode}</strong> khi đến nhận phòng.</p>
            
            <p>Nếu có bất kỳ thắc mắc nào, xin vui lòng liên hệ với chúng tôi qua email này hoặc hotline: <strong>1900-xxxx</strong></p>
            
            <p>Chúng tôi rất mong được phục vụ quý khách!</p>
        </div>
        
        <div class='footer'>
            <p><strong>ROYAL LUXURY HOTEL</strong></p>
            <p>Địa chỉ: 123 Đường ABC, Quận XYZ, TP.HCM</p>
            <p>Email: chudinhminhquan1002@gmail.com | Hotline: 1900-xxxx</p>
            <p style='font-size: 12px; color: #999; margin-top: 20px;'>
                Email này được gửi tự động, vui lòng không trả lời trực tiếp.
            </p>
        </div>
    </div>
</body>
</html>";
    }
}
