using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Commands.Bookings
{
    public class CheckInBookingCommandHandler : IAdminCommandHandler<CheckInBookingCommand>
    {
        private readonly RoyalHotelDbContext _context;

        public CheckInBookingCommandHandler(RoyalHotelDbContext context)
        {
            _context = context;
        }

        public async Task<AdminCommandResult> HandleAsync(CheckInBookingCommand command)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(x => x.Id == command.BookingId);

            if (booking == null)
                return AdminCommandResult.Fail("Booking not found.");

            if (booking.Status != "Confirmed")
                return AdminCommandResult.Fail("Only confirmed booking can be checked in.");

            booking.Status = "CheckedIn";
            await _context.SaveChangesAsync();

            return AdminCommandResult.Ok("Guest checked in successfully.");
        }
    }
}