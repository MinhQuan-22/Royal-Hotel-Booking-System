using ROYALHOTEL.Commands.Common;

namespace ROYALHOTEL.Commands.Bookings
{
    //command to confirm a booking, only for admin users
    public class CompleteBookingCommand : IAdminCommand
    {
        public int BookingId { get; set; }
    }
}