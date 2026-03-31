using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Accounts;

public interface IUserSessionService
{
    void SignIn(Account account);
    void SignOut();
}
