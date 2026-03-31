namespace ROYALHOTEL.Commands.Common
{
    // interface for dispatching admin commands
    public interface IAdminCommandDispatcher
    {
        Task<AdminCommandResult> DispatchAsync<TCommand>(TCommand command)
            where TCommand : IAdminCommand;
    }
}