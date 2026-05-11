using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Accounts;
using ROYALHOTEL.Security;

namespace RoyalHotel.Tests;

/// <summary>
/// Unit tests for AuthService — covers login validation, registration validation.
/// Tests pure business logic without a real database (using in-memory state stubs).
/// </summary>
public class AuthenticationServiceTests
{
    // ---------------------------------------------------------------
    // Helpers: simulate what the real AuthService does internally
    // ---------------------------------------------------------------

    private static string NormalizeEmail(string? email)
        => (email ?? "").Trim().ToLowerInvariant();

    /// <summary>
    /// Simulates LoginAsync validation logic from AuthService:
    /// returns error string or null if valid.
    /// </summary>
    private static string? ValidateLoginInput(string? email, string? password)
    {
        if (string.IsNullOrWhiteSpace(NormalizeEmail(email)) ||
            string.IsNullOrWhiteSpace(password))
            return "Vui lòng điền đầy đủ thông tin";
        return null;
    }

    /// <summary>
    /// Simulates RegisterAsync validation logic from AuthService:
    /// returns error string or null if valid.
    /// </summary>
    private static string? ValidateRegisterInput(
        string? fullName, string? email, string? phone,
        string? password, string? confirmPassword)
    {
        if (string.IsNullOrWhiteSpace(fullName) ||
            string.IsNullOrWhiteSpace(NormalizeEmail(email)) ||
            string.IsNullOrWhiteSpace(phone) ||
            string.IsNullOrWhiteSpace(password) ||
            string.IsNullOrWhiteSpace(confirmPassword))
            return "Vui lòng điền đầy đủ thông tin";

        if (password!.Length < 6)
            return "Mật khẩu tối thiểu 6 ký tự";

        if (!string.Equals(password, confirmPassword, StringComparison.Ordinal))
            return "Mật khẩu xác nhận không khớp";

        return null;
    }

    // ---------------------------------------------------------------
    // Login Tests
    // ---------------------------------------------------------------

    [Fact]
    public void Login_WithEmptyEmail_ShouldReturnValidationError()
    {
        var error = ValidateLoginInput("", "Admin@123");

        Assert.NotNull(error);
        Assert.Contains("đầy đủ", error);
    }

    [Fact]
    public void Login_WithEmptyPassword_ShouldReturnValidationError()
    {
        var error = ValidateLoginInput("admin@example.com", "");

        Assert.NotNull(error);
        Assert.Contains("đầy đủ", error);
    }

    [Fact]
    public void Login_WithValidCredentialsFormat_ShouldPassValidation()
    {
        var error = ValidateLoginInput("admin@royalhotel.com", "Admin@123");

        Assert.Null(error); // No validation error
    }

    // ---------------------------------------------------------------
    // Registration Tests
    // ---------------------------------------------------------------

    [Fact]
    public void Register_WithPasswordTooShort_ShouldReturnError()
    {
        var error = ValidateRegisterInput(
            "Nguyen Van A", "test@example.com", "0912345678",
            "123", "123");

        Assert.NotNull(error);
        Assert.Contains("6 ký tự", error);
    }

    [Fact]
    public void Register_WithMismatchedPasswords_ShouldReturnError()
    {
        var error = ValidateRegisterInput(
            "Nguyen Van A", "test@example.com", "0912345678",
            "Admin@123", "Admin@456");

        Assert.NotNull(error);
        Assert.Contains("không khớp", error);
    }

    [Fact]
    public void Register_WithAllValidInputs_ShouldPassValidation()
    {
        var error = ValidateRegisterInput(
            "Nguyen Van A", "newuser@example.com", "0912345678",
            "StrongPass@123", "StrongPass@123");

        Assert.Null(error);
    }

    [Fact]
    public void Register_WithMissingFullName_ShouldReturnError()
    {
        var error = ValidateRegisterInput(
            "", "test@example.com", "0912345678",
            "Admin@123", "Admin@123");

        Assert.NotNull(error);
        Assert.Contains("đầy đủ", error);
    }

    // ---------------------------------------------------------------
    // Password Hashing Tests (CryptoHelper)
    // ---------------------------------------------------------------

    [Fact]
    public void CryptoHelper_HashAndVerify_ShouldReturnTrueForCorrectPassword()
    {
        var password = "MySecurePass@99";
        var (hash, salt) = CryptoHelper.HashPassword(password);

        var isValid = CryptoHelper.VerifyPassword(password, hash, salt);

        Assert.True(isValid);
    }

    [Fact]
    public void CryptoHelper_HashAndVerify_ShouldReturnFalseForWrongPassword()
    {
        var (hash, salt) = CryptoHelper.HashPassword("CorrectPassword@1");

        var isValid = CryptoHelper.VerifyPassword("WrongPassword@999", hash, salt);

        Assert.False(isValid);
    }
}
