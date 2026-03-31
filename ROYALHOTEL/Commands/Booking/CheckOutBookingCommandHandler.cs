using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Commands.Bookings
{
    public class CheckOutBookingCommandHandler : IAdminCommandHandler<CheckOutBookingCommand>
    {
        private readonly RoyalHotelDbContext _context;

        public CheckOutBookingCommandHandler(RoyalHotelDbContext context)
        {
            _context = context;
        }

        public async Task<AdminCommandResult> HandleAsync(CheckOutBookingCommand command)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(x => x.Id == command.BookingId);

            if (booking == null)
                return AdminCommandResult.Fail("Booking not found.");

            if (booking.Status != "CheckedIn")
                return AdminCommandResult.Fail("Only checked-in booking can be checked out.");

            booking.Status = "CheckedOut";
            await _context.SaveChangesAsync();

            return AdminCommandResult.Ok("Guest checked out successfully.");
        }
    }
}