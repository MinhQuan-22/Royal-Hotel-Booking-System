using Microsoft.AspNetCore.Http;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Accounts;

public class UserSessionService : IUserSessionService
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly AuthSessionRegistry _registry = AuthSessionRegistry.Instance;

    public UserSessionService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public void SignIn(Account account)
    {
        var session = GetSession();
        session.SetString(_registry.UserNameKey, account.FullName);
        session.SetString(_registry.UserEmailKey, account.Email);
        session.SetString(_registry.UserRoleKey, account.Role ?? "user");
        session.SetInt32(_registry.UserIdKey, account.Id);
    }

    public void SignOut()
    {
        var session = GetSession();
        session.Remove(_registry.UserNameKey);
        session.Remove(_registry.UserEmailKey);
        session.Remove(_registry.UserRoleKey);
        session.Remove(_registry.UserIdKey);
    }

    private ISession GetSession()
    {
        return _httpContextAccessor.HttpContext?.Session
            ?? throw new InvalidOperationException("Http session is not available.");
    }
}
