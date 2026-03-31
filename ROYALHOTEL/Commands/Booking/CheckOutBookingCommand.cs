using ROYALHOTEL.Commands.Common;

namespace ROYALHOTEL.Commands.Bookings
{
    // command to check out a booking
    public class CheckOutBookingCommand : IAdminCommand
    {
        public int BookingId { get; set; }
    }
}