using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Commands.Bookings
{
    public class CancelBookingCommandHandler : IAdminCommandHandler<CancelBookingCommand>
    {
        private readonly RoyalHotelDbContext _context;

        public CancelBookingCommandHandler(RoyalHotelDbContext context)
        {
            _context = context;
        }

        public async Task<AdminCommandResult> HandleAsync(CancelBookingCommand command)
        {
            var booking = await _context.Bookings.FirstOrDefaultAsync(x => x.Id == command.BookingId);

            if (booking == null)
                return AdminCommandResult.Fail("Booking not found.");

            if (booking.Status == "Completed")
                return AdminCommandResult.Fail("Completed booking cannot be cancelled.");

            booking.Status = "Cancelled";
            await _context.SaveChangesAsync();

            return AdminCommandResult.Ok("Booking cancelled successfully.");
        }
    }
}