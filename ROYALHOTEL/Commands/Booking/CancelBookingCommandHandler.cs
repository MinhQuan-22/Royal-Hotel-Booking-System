using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Services.Booking;

namespace ROYALHOTEL.Commands.Bookings
{
    public class CancelBookingCommandHandler : IAdminCommandHandler<CancelBookingCommand>
    {
        private readonly IBookingService _bookingService;

        public CancelBookingCommandHandler(IBookingService bookingService)
        {
            _bookingService = bookingService;
        }

        public async Task<AdminCommandResult> HandleAsync(CancelBookingCommand command)
        {
            var (success, message) = await _bookingService.CancelBookingAsync(command.BookingId, 0, isAdmin: true);
            
            if(!success) return AdminCommandResult.Fail(message);
            return AdminCommandResult.Ok("Booking đã được hủy bằng Policy system.");
        }
    }
}