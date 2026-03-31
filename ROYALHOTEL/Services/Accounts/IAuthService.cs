using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels.Account;

namespace ROYALHOTEL.Services.Accounts;

public interface IAuthService
{
    Task<OperationResult<Account>> LoginAsync(LoginInputModel input);
    Task<OperationResult<Account>> RegisterAsync(RegisterInputModel input);
}
