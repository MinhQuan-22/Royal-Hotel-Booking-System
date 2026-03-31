using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.ViewModels.Booking;

namespace ROYALHOTEL.Services.Booking;

/// <summary>
/// Concrete Decorator:
/// bổ sung bước validate trước khi gọi vào core booking service.
/// </summary>
public class BookingValidationDecorator : BookingServiceDecorator
{
    private readonly RoyalHotelDbContext _context;

    public BookingValidationDecorator(IBookingService inner, RoyalHotelDbContext context)
        : base(inner)
    {
        _context = context;
    }

    public override async Task<Models.Booking> CreateBookingAsync(CreateBookingRequest request, int? accountId = null)
    {
        // Validation 1: Room exists and is active
        var room = await _context.Rooms
            .FirstOrDefaultAsync(r => r.Id == request.RoomId && r.IsActive);

        if (room == null)
            throw new InvalidOperationException("Phòng không tồn tại hoặc đang không hoạt động.");

        // Validation 2: CheckOutDate > CheckInDate
        if (request.CheckOutDate <= request.CheckInDate)
            throw new InvalidOperationException("Ngày trả phòng phải sau ngày nhận phòng.");

        // Validation 3: Guests validation (> 0 and <= MaxGuests)
        if (request.Guests <= 0 || request.Guests > room.MaxGuests)
            throw new InvalidOperationException($"Số khách không hợp lệ. Phòng này tối đa {room.MaxGuests} khách.");

        // Validation 4: Overlap check with Confirmed/CheckedIn bookings
        var hasConfirmedOverlap = await _context.Bookings.AnyAsync(b =>
            b.RoomId == request.RoomId &&
            (b.Status == "Confirmed" || b.Status == "CheckedIn") &&
            request.CheckInDate < b.CheckOut &&
            request.CheckOutDate > b.CheckIn);

        if (hasConfirmedOverlap)
            throw new InvalidOperationException("Phòng này đã được đặt trong khoảng thời gian anh chọn.");

        // All validations passed, delegate to wrapped service
        return await base.CreateBookingAsync(request, accountId);
    }
}