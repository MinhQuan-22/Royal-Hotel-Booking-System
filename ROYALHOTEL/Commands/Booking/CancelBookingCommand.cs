using ROYALHOTEL.Commands.Common;

namespace ROYALHOTEL.Commands.Bookings
{
    //command to cancel a booking, only for admin users
    public class CancelBookingCommand : IAdminCommand
    {
        public int BookingId { get; set; }
    }
}