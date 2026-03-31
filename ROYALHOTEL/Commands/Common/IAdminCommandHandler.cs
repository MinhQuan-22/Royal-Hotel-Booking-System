namespace ROYALHOTEL.Commands.Common
{
    // interface for handling admin commands
    public interface IAdminCommandHandler<in TCommand>
        where TCommand : IAdminCommand
    {
        Task<AdminCommandResult> HandleAsync(TCommand command);
    }
}