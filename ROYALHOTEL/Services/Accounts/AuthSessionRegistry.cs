namespace ROYALHOTEL.Services.Accounts;

public sealed class AuthSessionRegistry
{
    private static readonly Lazy<AuthSessionRegistry> _instance =
        new(() => new AuthSessionRegistry());

    public static AuthSessionRegistry Instance => _instance.Value;

    private AuthSessionRegistry()
    {
    }

    public string UserNameKey => "USER_NAME";
    public string UserEmailKey => "USER_EMAIL";
    public string UserRoleKey => "USER_ROLE";
    public string UserIdKey => "USER_ID";
}
