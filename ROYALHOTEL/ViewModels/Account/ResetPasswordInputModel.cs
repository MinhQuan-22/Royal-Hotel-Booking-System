namespace ROYALHOTEL.ViewModels.Account;

public class ResetPasswordInputModel
{
    public string RequestId { get; set; } = "";
    public string Email { get; set; } = "";
    public string Otp { get; set; } = "";
    public string NewPassword { get; set; } = "";
    public string ConfirmPassword { get; set; } = "";
}
