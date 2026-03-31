using ROYALHOTEL.ViewModels.Account;

namespace ROYALHOTEL.Services.Accounts;

public interface IPasswordResetService
{
    Task<ForgotPasswordResult> SendResetOtpAsync(ForgotPasswordInputModel input);
    Task<OperationResult> ResetPasswordAsync(ResetPasswordInputModel input);
    Task<string> GetExpiresAtIsoAsync(string requestId);
}
