using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.Security;
using ROYALHOTEL.ViewModels.Account;

namespace ROYALHOTEL.Services.Accounts;

public class AuthService : IAuthService
{
    private readonly RoyalHotelDbContext _db;

    public AuthService(RoyalHotelDbContext db)
    {
        _db = db;
    }

    public async Task<OperationResult<Account>> LoginAsync(LoginInputModel input)
    {
        var email = NormalizeEmail(input.Email);
        var password = input.Password ?? "";

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            return OperationResult<Account>.Fail("Vui lòng điền đầy đủ thông tin");

        var account = await _db.Accounts
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Email == email);

        if (account == null || !CryptoHelper.VerifyPassword(password, account.PasswordHash, account.PasswordSalt))
            return OperationResult<Account>.Fail("Email hoặc mật khẩu không đúng");

        if (string.Equals(account.Status ?? "active", "locked", StringComparison.OrdinalIgnoreCase))
            return OperationResult<Account>.Fail("Tài khoản của bạn đã bị khóa");

        return OperationResult<Account>.Ok(account);
    }

    public async Task<OperationResult<Account>> RegisterAsync(RegisterInputModel input)
    {
        var fullName = (input.FullName ?? "").Trim();
        var email = NormalizeEmail(input.Email);
        var phone = (input.Phone ?? "").Trim();
        var password = input.Password ?? "";
        var confirmPassword = input.ConfirmPassword ?? "";

        if (string.IsNullOrWhiteSpace(fullName) ||
            string.IsNullOrWhiteSpace(email) ||
            string.IsNullOrWhiteSpace(phone) ||
            string.IsNullOrWhiteSpace(password) ||
            string.IsNullOrWhiteSpace(confirmPassword))
        {
            return OperationResult<Account>.Fail("Vui lòng điền đầy đủ thông tin");
        }

        if (password.Length < 6)
            return OperationResult<Account>.Fail("Mật khẩu tối thiểu 6 ký tự");

        if (!string.Equals(password, confirmPassword, StringComparison.Ordinal))
            return OperationResult<Account>.Fail("Mật khẩu xác nhận không khớp");

        var exists = await _db.Accounts.AnyAsync(x => x.Email == email);
        if (exists)
            return OperationResult<Account>.Fail("Email đã được đăng ký");

        var (hash, salt) = CryptoHelper.HashPassword(password);

        var account = new Account
        {
            FullName = fullName,
            Email = email,
            Phone = phone,
            PasswordHash = hash,
            PasswordSalt = salt,
            Role = "user",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Accounts.Add(account);
        await _db.SaveChangesAsync();

        return OperationResult<Account>.Ok(account);
    }

    private static string NormalizeEmail(string? email)
    {
        return (email ?? "").Trim().ToLowerInvariant();
    }
}
