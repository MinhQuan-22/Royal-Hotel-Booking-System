namespace ROYALHOTEL.Services.Accounts;

public class ForgotPasswordResult : OperationResult
{
    public string Email { get; init; } = "";
    public string RequestId { get; init; } = "";
    public string ExpiresAtIso { get; init; } = "";

    public static ForgotPasswordResult Ok(string email, Guid requestId, DateTime expiresAt, string message) => new()
    {
        Success = true,
        Message = message,
        Email = email,
        RequestId = requestId.ToString(),
        ExpiresAtIso = expiresAt.ToString("o")
    };

    public new static ForgotPasswordResult Fail(string message) => new()
    {
        Success = false,
        Message = message
    };
}
