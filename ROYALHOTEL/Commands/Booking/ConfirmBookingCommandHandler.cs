using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Commands.Bookings
{
    // command handler to confirm a booking
    public class ConfirmBookingCommandHandler : IAdminCommandHandler<ConfirmBookingCommand>
    {
        private readonly RoyalHotelDbContext _context;

        public ConfirmBookingCommandHandler(RoyalHotelDbContext context)
        {
            _context = context;
        }

        public async Task<AdminCommandResult> HandleAsync(ConfirmBookingCommand command)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(x => x.Id == command.BookingId);

            if (booking == null)
                return AdminCommandResult.Fail("Booking not found.");

            if (booking.Status == "Cancelled")
                return AdminCommandResult.Fail("Cancelled booking cannot be confirmed.");

            if (booking.Status == "Completed")
                return AdminCommandResult.Fail("Completed booking cannot be confirmed again.");

            booking.Status = "Confirmed";
            await _context.SaveChangesAsync();

            return AdminCommandResult.Ok("Booking confirmed successfully.");
        }
    }
}

