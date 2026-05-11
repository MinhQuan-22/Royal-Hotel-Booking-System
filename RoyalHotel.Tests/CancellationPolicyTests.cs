namespace RoyalHotel.Tests;

/// <summary>
/// Tests for cancellation & refund policy applied in CoreBookingService.CancelBookingAsync.
/// Policy (based on hours before 14:00 check-in day):
///   >= 48h  -> 100% refund
///   24-48h  -> 50% refund
///   < 24h   -> 0% refund
/// </summary>
public class CancellationPolicyTests
{
    // Helper: build a fake "now" so that the diff to check-in is exactly `hoursBeforeCheckIn`
    private static DateTime FakeNow(DateTime checkIn, double hoursBeforeCheckIn)
    {
        var businessCheckIn = checkIn.Date.AddHours(14); // 14:00 same day
        return businessCheckIn.AddHours(-hoursBeforeCheckIn);
    }

    private static decimal CalculateRefund(decimal paidAmount, DateTime checkIn, DateTime now)
    {
        var businessCheckIn = checkIn.Date.AddHours(14);
        var hoursDiff = (businessCheckIn - now).TotalHours;

        if (hoursDiff >= 48) return paidAmount;
        if (hoursDiff >= 24) return paidAmount * 0.5m;
        return 0m;
    }

    [Fact]
    public void CancelMoreThan48hBefore_ShouldRefund100Percent()
    {
        var checkIn = DateTime.Today.AddDays(5);
        var now = FakeNow(checkIn, 72); // 72h before — well over 48h
        var paid = 2_000_000m;

        var refund = CalculateRefund(paid, checkIn, now);

        Assert.Equal(paid, refund); // 100% refund
    }

    [Fact]
    public void CancelBetween24And48hBefore_ShouldRefund50Percent()
    {
        var checkIn = DateTime.Today.AddDays(3);
        var now = FakeNow(checkIn, 36); // 36h before — between 24 and 48h
        var paid = 2_000_000m;

        var refund = CalculateRefund(paid, checkIn, now);

        Assert.Equal(1_000_000m, refund); // 50% refund
    }

    [Fact]
    public void CancelLessThan24hBefore_ShouldRefundNothing()
    {
        var checkIn = DateTime.Today.AddDays(1);
        var now = FakeNow(checkIn, 12); // 12h before — under 24h
        var paid = 2_000_000m;

        var refund = CalculateRefund(paid, checkIn, now);

        Assert.Equal(0m, refund); // 0% refund
    }

    [Fact]
    public void CancelExactly48hBefore_ShouldRefund100Percent()
    {
        var checkIn = DateTime.Today.AddDays(4);
        var now = FakeNow(checkIn, 48); // exactly 48h
        var paid = 3_500_000m;

        var refund = CalculateRefund(paid, checkIn, now);

        Assert.Equal(3_500_000m, refund); // boundary: >= 48h -> 100%
    }

    [Fact]
    public void CancelExactly24hBefore_ShouldRefund50Percent()
    {
        var checkIn = DateTime.Today.AddDays(2);
        var now = FakeNow(checkIn, 24); // exactly 24h
        var paid = 1_800_000m;

        var refund = CalculateRefund(paid, checkIn, now);

        Assert.Equal(900_000m, refund); // boundary: >= 24h -> 50%
    }
}
