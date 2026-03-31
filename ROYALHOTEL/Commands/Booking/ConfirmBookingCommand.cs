using ROYALHOTEL.Commands.Common;

namespace ROYALHOTEL.Commands.Bookings
{
    //command to confirm a booking 
    public class ConfirmBookingCommand : IAdminCommand
    {
        public int BookingId { get; set; }
    }
}