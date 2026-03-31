using Microsoft.Extensions.DependencyInjection;

namespace ROYALHOTEL.Commands.Common
{
    // class to dispatch admin commands to their respective handlers
    public class AdminCommandDispatcher : IAdminCommandDispatcher
    {
        private readonly IServiceProvider _serviceProvider;

        public AdminCommandDispatcher(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public async Task<AdminCommandResult> DispatchAsync<TCommand>(TCommand command)
            where TCommand : IAdminCommand
        {
            var handler = _serviceProvider.GetRequiredService<IAdminCommandHandler<TCommand>>();
            return await handler.HandleAsync(command);
        }
    }
}

