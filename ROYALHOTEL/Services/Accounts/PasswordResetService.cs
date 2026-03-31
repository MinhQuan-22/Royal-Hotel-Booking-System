using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.Security;
using ROYALHOTEL.Services.Email;
using ROYALHOTEL.ViewModels.Account;

namespace ROYALHOTEL.Services.Accounts;

public class PasswordResetService : IPasswordResetService
{
    private readonly RoyalHotelDbContext _db;
    private readonly IEmailSender _emailSender;

    public PasswordResetService(RoyalHotelDbContext db, IEmailSender emailSender)
    {
        _db = db;
        _emailSender = emailSender;
    }

    public async Task<ForgotPasswordResult> SendResetOtpAsync(ForgotPasswordInputModel input)
    {
        var email = NormalizeEmail(input.Email);
        if (string.IsNullOrWhiteSpace(email))
            return ForgotPasswordResult.Fail("Vui lòng nhập email");

        var account = await _db.Accounts.FirstOrDefaultAsync(x => x.Email == email);
        if (account == null)
            return ForgotPasswordResult.Fail("Email chưa được đăng ký");

        var otp = CryptoHelper.GenerateOtp6();
        var (otpHash, otpSalt) = CryptoHelper.HashOtp(otp);
        var expiresAt = DateTime.UtcNow.AddMinutes(3);

        var activeRequests = await _db.PasswordResetOtps
            .Where(x => x.AccountId == account.Id && x.UsedAt == null && x.ExpiresAt > DateTime.UtcNow)
            .ToListAsync();

        foreach (var request in activeRequests)
            request.UsedAt = DateTime.UtcNow;

        var resetRequest = new PasswordResetOtp
        {
            AccountId = account.Id,
            OtpHash = otpHash,
            OtpSalt = otpSalt,
            ExpiresAt = expiresAt,
            UsedAt = null,
            AttemptCount = 0,
            CreatedAt = DateTime.UtcNow
        };

        _db.PasswordResetOtps.Add(resetRequest);
        await _db.SaveChangesAsync();

        try
        {
            var subject = "Royal Hotel - Mã OTP đặt lại mật khẩu";
            var body = $@"
                <div style='font-family:Arial'>
                  <h2>Royal Luxury Hotel</h2>
                  <p>Mã OTP của anh là: <b style='font-size:20px'>{otp}</b></p>
                  <p>Mã có hiệu lực <b>3 phút</b>.</p>
                </div>";

            await _emailSender.SendAsync(email, subject, body);
        }
        catch (Exception ex)
        {
            return ForgotPasswordResult.Fail($"Không gửi được OTP. Anh kiểm tra cấu hình SMTP. ({ex.Message})");
        }

        return ForgotPasswordResult.Ok(
            email,
            resetRequest.Id,
            expiresAt,
            "OTP đã được gửi đến email. Vui lòng nhập trong 3 phút.");
    }

    public async Task<OperationResult> ResetPasswordAsync(ResetPasswordInputModel input)
    {
        var email = NormalizeEmail(input.Email);
        var otp = (input.Otp ?? "").Trim();
        var newPassword = input.NewPassword ?? "";
        var confirmPassword = input.ConfirmPassword ?? "";

        if (!Guid.TryParse(input.RequestId, out var requestId))
            return OperationResult.Fail("Yêu cầu OTP không hợp lệ");

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(otp))
            return OperationResult.Fail("Vui lòng nhập OTP");

        if (newPassword.Length < 6)
            return OperationResult.Fail("Mật khẩu mới tối thiểu 6 ký tự");

        if (!string.Equals(newPassword, confirmPassword, StringComparison.Ordinal))
            return OperationResult.Fail("Mật khẩu xác nhận không khớp");

        var request = await _db.PasswordResetOtps
            .Include(x => x.Account)
            .FirstOrDefaultAsync(x => x.Id == requestId);

        if (request == null || request.Account == null || !string.Equals(request.Account.Email, email, StringComparison.OrdinalIgnoreCase))
            return OperationResult.Fail("OTP không hợp lệ");

        if (request.UsedAt != null || request.ExpiresAt <= DateTime.UtcNow)
            return OperationResult.Fail("OTP đã hết hạn. Vui lòng gửi lại OTP.");

        if (request.AttemptCount >= 5)
        {
            request.UsedAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return OperationResult.Fail("OTP sai quá nhiều lần. Vui lòng gửi lại OTP.");
        }

        if (!CryptoHelper.VerifyOtp(otp, request.OtpHash, request.OtpSalt))
        {
            request.AttemptCount += 1;
            await _db.SaveChangesAsync();
            return OperationResult.Fail("OTP không đúng");
        }

        var (hash, salt) = CryptoHelper.HashPassword(newPassword);
        request.Account.PasswordHash = hash;
        request.Account.PasswordSalt = salt;
        request.Account.UpdatedAt = DateTime.UtcNow;
        request.UsedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return OperationResult.Ok("Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.");
    }

    public async Task<string> GetExpiresAtIsoAsync(string requestId)
    {
        if (!Guid.TryParse(requestId, out var parsedId))
            return string.Empty;

        var request = await _db.PasswordResetOtps
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == parsedId);

        return request?.ExpiresAt.ToString("o") ?? string.Empty;
    }

    private static string NormalizeEmail(string? email)
    {
        return (email ?? "").Trim().ToLowerInvariant();
    }
}
