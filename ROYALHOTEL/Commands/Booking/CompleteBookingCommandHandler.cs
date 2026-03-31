using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Commands.Bookings
{
    public class CompleteBookingCommandHandler : IAdminCommandHandler<CompleteBookingCommand>
    {
        private readonly RoyalHotelDbContext _context;

        public CompleteBookingCommandHandler(RoyalHotelDbContext context)
        {
            _context = context;
        }

        public async Task<AdminCommandResult> HandleAsync(CompleteBookingCommand command)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(x => x.Id == command.BookingId);

            if (booking == null)
                return AdminCommandResult.Fail("Booking not found.");

            if (booking.Status != "CheckedOut")
                return AdminCommandResult.Fail("Only checked-out booking can be completed.");

            booking.Status = "Completed";
            await _context.SaveChangesAsync();

            return AdminCommandResult.Ok("Booking completed successfully.");
        }
    }
}