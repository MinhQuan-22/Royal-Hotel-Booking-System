using ROYALHOTEL.Commands.Common;

namespace ROYALHOTEL.Commands.Bookings
{
    // command to check in a booking
    public class CheckInBookingCommand : IAdminCommand
    {
        public int BookingId { get; set; }
    }
}