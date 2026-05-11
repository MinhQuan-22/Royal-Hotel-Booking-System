using ROYALHOTEL.Models;

namespace RoyalHotel.Tests;

/// <summary>
/// Tests for booking status transition rules and code generation format.
/// Tests business logic that is portable and doesn't require a real DB.
/// </summary>
public class BookingServiceTests
{
    // ---------------------------------------------------------------
    // Helpers: Simulating business rules from CoreBookingService
    // ---------------------------------------------------------------

    private static bool CanCancelBooking(string status)
        => status is not ("CheckedIn" or "CheckedOut" or "Cancelled" or "Completed");

    private static string GenerateBookingCode(DateTime date, int sequenceNum)
    {
        var prefix = $"RH-{date:yyyyMMdd}-";
        return $"{prefix}{sequenceNum:D3}";
    }

    private static Booking MakePendingBooking(int id = 1) => new Booking
    {
        Id = id,
        BookingCode = GenerateBookingCode(DateTime.Today, id),
        RoomId = 1,
        AccountId = 10,
        CheckIn = DateTime.Today.AddDays(7),
        CheckOut = DateTime.Today.AddDays(9),
        Guests = 2,
        GuestName = "Nguyen Van A",
        GuestEmail = "guest@example.com",
        GuestPhone = "0912345678",
        PricePerNight = 1_200_000m,
        TotalAmount = 2_400_000m,
        Status = "Pending",
        CreatedAt = DateTime.UtcNow
    };

    private static Booking MakeConfirmedBooking(DateTime checkIn) => new Booking
    {
        Id = 2,
        BookingCode = GenerateBookingCode(DateTime.Today, 2),
        RoomId = 1,
        AccountId = 10,
        CheckIn = checkIn,
        CheckOut = checkIn.AddDays(2),
        Guests = 2,
        PricePerNight = 1_000_000m,
        TotalAmount = 2_000_000m,
        Status = "Confirmed",
        CreatedAt = DateTime.UtcNow,
        PaymentTransactions = new List<PaymentTransaction>
        {
            new PaymentTransaction
            {
                Id = 1,
                BookingId = 2,
                TransactionType = "Payment",
                PaymentMethod = "bank_transfer",
                Amount = 2_000_000m,
                Status = "Paid",
                ProcessedAt = DateTime.UtcNow.AddMinutes(-30),
                CreatedAt = DateTime.UtcNow.AddMinutes(-30)
            }
        }
    };

    // ---------------------------------------------------------------
    // Booking Code Format Tests
    // ---------------------------------------------------------------

    [Fact]
    public void BookingCode_ShouldFollowFormat_RH_YYYYMMDD_NNN()
    {
        var date = new DateTime(2026, 5, 11);
        var code = GenerateBookingCode(date, 3);

        Assert.Equal("RH-20260511-003", code);
    }

    [Fact]
    public void BookingCode_FirstBookingOfDay_ShouldEndWith001()
    {
        var code = GenerateBookingCode(DateTime.Today, 1);

        Assert.EndsWith("-001", code);
    }

    // ---------------------------------------------------------------
    // Booking Status Transition Tests
    // ---------------------------------------------------------------

    [Fact]
    public void PendingBooking_CanBeCancelled()
    {
        var booking = MakePendingBooking();

        Assert.True(CanCancelBooking(booking.Status));
    }

    [Fact]
    public void CheckedInBooking_CannotBeCancelled()
    {
        var booking = MakePendingBooking();
        booking.Status = "CheckedIn";

        Assert.False(CanCancelBooking(booking.Status));
    }

    [Fact]
    public void CheckedOutBooking_CannotBeCancelled()
    {
        var booking = MakePendingBooking();
        booking.Status = "CheckedOut";

        Assert.False(CanCancelBooking(booking.Status));
    }

    [Fact]
    public void CompletedBooking_CannotBeCancelled()
    {
        var booking = MakePendingBooking();
        booking.Status = "Completed";

        Assert.False(CanCancelBooking(booking.Status));
    }

    [Fact]
    public void AlreadyCancelledBooking_CannotBeCancelledAgain()
    {
        var booking = MakePendingBooking();
        booking.Status = "Cancelled";

        Assert.False(CanCancelBooking(booking.Status));
    }

    [Fact]
    public void ConfirmedBooking_CanBeCancelled()
    {
        // Confirmed bookings CAN be cancelled (with refund policy)
        var booking = MakeConfirmedBooking(DateTime.Today.AddDays(10));

        Assert.True(CanCancelBooking(booking.Status));
    }

    // ---------------------------------------------------------------
    // Booking Data Integrity Tests
    // ---------------------------------------------------------------

    [Fact]
    public void NewBooking_ShouldDefaultToStatusPending()
    {
        var booking = new Booking();

        Assert.Equal("Pending", booking.Status);
    }

    [Fact]
    public void NewBooking_ShouldHaveEmptyPaymentTransactions()
    {
        var booking = new Booking();

        Assert.NotNull(booking.PaymentTransactions);
        Assert.Empty(booking.PaymentTransactions);
    }

    [Fact]
    public void Booking_TotalAmount_ShouldMatchPricePerNightTimesNights()
    {
        var booking = MakePendingBooking();
        var nights = (booking.CheckOut - booking.CheckIn).Days;
        var expected = booking.PricePerNight * nights;

        Assert.Equal(expected, booking.TotalAmount);
    }
}
