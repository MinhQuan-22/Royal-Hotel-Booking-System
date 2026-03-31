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

        var subject = $"Xác nhận đặt phòng - Royal Luxury Hotel | {booking.BookingCode}";
        var htmlBody = BuildConfirmationEmailHtml(booking);

        await _emailSender.SendAsync(booking.GuestEmail, subject, htmlBody);
    }

    private string BuildConfirmationEmailHtml(Models.Booking booking)
    {
        var culture = new CultureInfo("vi-VN");
        var nights = (booking.CheckOut - booking.CheckIn).Days;

        var guestName = string.IsNullOrWhiteSpace(booking.GuestName) ? "Quý khách" : booking.GuestName.Trim();
        var roomName = booking.Room?.Name ?? "N/A";
        var roomCode = booking.Room?.Code ?? "N/A";
        var paymentMethod = FormatPaymentMethod(booking.PaymentMethod);
        var bookingStatus = FormatBookingStatus(booking.Status);

        var checkInStr = booking.CheckIn.ToString("dd/MM/yyyy");
        var checkOutStr = booking.CheckOut.ToString("dd/MM/yyyy");
        var createdAtStr = booking.CreatedAt.ToString("dd/MM/yyyy HH:mm");

        var pricePerNightStr = booking.PricePerNight?.ToString("N0", culture) ?? "0";
        var totalAmountStr = booking.TotalAmount?.ToString("N0", culture) ?? "0";

        return $@"
<!DOCTYPE html>
<html lang='vi'>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Xác nhận đặt phòng</title>
</head>
<body style='margin:0; padding:0; background-color:#f5f3ef; font-family:Arial, Helvetica, sans-serif; color:#2f2a24;'>
    <table role='presentation' cellpadding='0' cellspacing='0' border='0' width='100%' style='background-color:#f5f3ef; margin:0; padding:24px 0;'>
        <tr>
            <td align='center'>
                <table role='presentation' cellpadding='0' cellspacing='0' border='0' width='680' style='max-width:680px; width:100%; background-color:#ffffff; border:1px solid #e7dfd3;'>
                    
                    <tr>
                        <td style='padding:36px 40px 20px 40px; text-align:center; border-bottom:1px solid #ece6dc;'>
                            <div style='font-size:13px; letter-spacing:3px; color:#8b7355; text-transform:uppercase; margin-bottom:8px;'>
                                Royal Luxury Hotel
                            </div>
                            <div style='font-size:28px; font-weight:700; color:#1f1a17; line-height:1.3;'>
                                Xác nhận đặt phòng
                            </div>
                            <div style='margin-top:10px; font-size:14px; color:#6e6255; line-height:1.6;'>
                                Cảm ơn quý khách đã lựa chọn dịch vụ lưu trú tại Royal Luxury Hotel.
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style='padding:32px 40px 8px 40px;'>
                            <p style='margin:0 0 16px 0; font-size:15px; line-height:1.8; color:#2f2a24;'>
                                Kính gửi <strong>{guestName}</strong>,
                            </p>

                            <p style='margin:0 0 16px 0; font-size:15px; line-height:1.8; color:#2f2a24;'>
                                Royal Luxury Hotel xin trân trọng xác nhận đặt phòng của quý khách đã được ghi nhận thành công.
                                Thông tin chi tiết được trình bày dưới đây để quý khách tiện theo dõi và sử dụng khi làm thủ tục nhận phòng.
                            </p>
                        </td>
                    </tr>

                    <tr>
                        <td style='padding:8px 40px 0 40px;'>
                            <table role='presentation' cellpadding='0' cellspacing='0' border='0' width='100%' style='border:1px solid #ddd2c2; background-color:#fbfaf8;'>
                                <tr>
                                    <td style='padding:18px 22px; border-bottom:1px solid #e7dfd3;'>
                                        <div style='font-size:12px; text-transform:uppercase; letter-spacing:1.8px; color:#8b7355; margin-bottom:6px;'>
                                            Mã đặt phòng
                                        </div>
                                        <div style='font-size:22px; font-weight:700; color:#1f1a17;'>
                                            {booking.BookingCode}
                                        </div>
                                    </td>
                                </tr>
                                <tr>
                                    <td style='padding:0 22px 6px 22px;'>
                                        <table role='presentation' cellpadding='0' cellspacing='0' border='0' width='100%' style='border-collapse:collapse;'>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; width:42%; font-size:14px; color:#7b6d5f;'>
                                                    Hạng phòng
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {roomName} ({roomCode})
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Ngày nhận phòng
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {checkInStr} - 14:00
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Ngày trả phòng
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {checkOutStr} - 12:00
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Thời gian lưu trú
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {nights} đêm
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Số lượng khách
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {booking.Guests} khách
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Giá mỗi đêm
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {pricePerNightStr} VNĐ
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Tổng thanh toán
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:18px; color:#8b6b3f; font-weight:700;'>
                                                    {totalAmountStr} VNĐ
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Phương thức thanh toán
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {paymentMethod}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#7b6d5f;'>
                                                    Trạng thái booking
                                                </td>
                                                <td style='padding:16px 0; border-bottom:1px solid #ece6dc; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {bookingStatus}
                                                </td>
                                            </tr>
                                            <tr>
                                                <td style='padding:16px 0; font-size:14px; color:#7b6d5f;'>
                                                    Thời điểm đặt
                                                </td>
                                                <td style='padding:16px 0; font-size:14px; color:#1f1a17; font-weight:600;'>
                                                    {createdAtStr}
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                    <tr>
                        <td style='padding:28px 40px 0 40px;'>
                            <div style='padding:18px 20px; background-color:#f8f5f0; border-left:3px solid #b08a57; font-size:14px; line-height:1.8; color:#4e4338;'>
                                Quý khách vui lòng chuẩn bị mã đặt phòng <strong>{booking.BookingCode}</strong> khi đến nhận phòng để quá trình check-in được diễn ra nhanh chóng và thuận tiện hơn.
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style='padding:28px 40px 8px 40px;'>
                            <p style='margin:0 0 14px 0; font-size:15px; line-height:1.8; color:#2f2a24;'>
                                Nếu cần hỗ trợ thêm về thông tin đặt phòng, thay đổi lịch lưu trú hoặc các yêu cầu đặc biệt, quý khách vui lòng liên hệ bộ phận chăm sóc khách hàng của khách sạn.
                            </p>

                            <p style='margin:0; font-size:15px; line-height:1.8; color:#2f2a24;'>
                                Trân trọng,<br>
                                <strong>Royal Luxury Hotel</strong>
                            </p>
                        </td>
                    </tr>

                    <tr>
                        <td style='padding:28px 40px 34px 40px; border-top:1px solid #ece6dc;'>
                            <table role='presentation' cellpadding='0' cellspacing='0' border='0' width='100%'>
                                <tr>
                                    <td style='font-size:13px; line-height:1.8; color:#6e6255; text-align:center;'>
                                        Royal Luxury Hotel<br>
                                        123 Đường ABC, Quận XYZ, TP. Hồ Chí Minh<br>
                                        Email: chudinhminhquan1002@gmail.com &nbsp;|&nbsp; Hotline: 1900-xxxx
                                    </td>
                                </tr>
                                <tr>
                                    <td style='padding-top:14px; font-size:12px; line-height:1.7; color:#9a8f84; text-align:center;'>
                                        Đây là email được gửi tự động từ hệ thống xác nhận đặt phòng. Vui lòng không phản hồi trực tiếp vào email này.
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>

                </table>
            </td>
        </tr>
    </table>
</body>
</html>";
    }

    private static string FormatPaymentMethod(string? paymentMethod)
    {
        return paymentMethod?.Trim().ToLowerInvariant() switch
        {
            "bank_transfer" => "Chuyển khoản ngân hàng",
            "card" => "Thẻ tín dụng / Ghi nợ",
            "visa" => "Thẻ Visa",
            _ => string.IsNullOrWhiteSpace(paymentMethod) ? "N/A" : paymentMethod
        };
    }

    private static string FormatBookingStatus(string? status)
    {
        return status?.Trim() switch
        {
            "Pending" => "Chờ thanh toán",
            "Confirmed" => "Đã xác nhận",
            "CheckedIn" => "Đã nhận phòng",
            "CheckedOut" => "Đã trả phòng",
            "Completed" => "Hoàn tất",
            "Cancelled" => "Đã hủy",
            _ => string.IsNullOrWhiteSpace(status) ? "N/A" : status
        };
    }
}