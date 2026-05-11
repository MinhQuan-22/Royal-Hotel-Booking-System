using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Rooms;

namespace RoyalHotel.Tests;

/// <summary>
/// Tests for RoomPricingService + DbPricingRuleStrategy logic.
/// Uses a lightweight stub implementation of IRoomPricingStrategy
/// to avoid needing a real DbContext in unit tests.
/// </summary>
public class PricingRuleTests
{
    // ---------------------------------------------------------------
    // Stub: simulates a weekend pricing rule (+20%)
    // ---------------------------------------------------------------
    private class WeekendPricingStub : IRoomPricingStrategy
    {
        public int Priority => 10;

        public decimal GetMultiplier(Room room, DateTime date)
        {
            return date.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday
                ? 1.2m
                : 1m;
        }
    }

    // ---------------------------------------------------------------
    // Stub: simulates a high-priority promotion rule (-10%)
    // ---------------------------------------------------------------
    private class PromotionPricingStub : IRoomPricingStrategy
    {
        public int Priority => 5; // higher priority than weekend (smaller number wins)

        public decimal GetMultiplier(Room room, DateTime date) => 0.9m;
    }

    private static Room MakeRoom(decimal basePrice = 1_000_000m) => new Room
    {
        Id = 1,
        Code = "R001",
        Name = "Deluxe Room",
        RoomType = "Deluxe",
        BasePricePerNight = basePrice,
        MaxGuests = 2,
        IsActive = true,
        HotelId = 1,
        Hotel = new Hotel { Id = 1, Name = "Royal Ha Noi", Address = "Hanoi" }
    };

    [Fact]
    public void PricingService_NoRules_ShouldReturnBasePrice()
    {
        var service = new RoomPricingService(Enumerable.Empty<IRoomPricingStrategy>());
        var room = MakeRoom(1_000_000m);

        // Use a Monday so no weekend rule would fire anyway
        var monday = GetNextWeekday(DayOfWeek.Monday);
        var result = service.Calculate(room, monday, monday.AddDays(1));

        Assert.Equal(1_000_000m, result.TotalAmount);
        Assert.Equal(1, result.Nights);
    }

    [Fact]
    public void PricingService_WeekendRule_ShouldApply120PercentMultiplier()
    {
        var service = new RoomPricingService(new[] { new WeekendPricingStub() });
        var room = MakeRoom(1_000_000m);

        var saturday = GetNextWeekday(DayOfWeek.Saturday);
        var result = service.Calculate(room, saturday, saturday.AddDays(1)); // 1 night on Saturday

        Assert.Equal(1_200_000m, result.TotalAmount);
    }

    [Fact]
    public void PricingService_WeekendRule_ShouldNotApplyOnWeekday()
    {
        var service = new RoomPricingService(new[] { new WeekendPricingStub() });
        var room = MakeRoom(1_000_000m);

        var tuesday = GetNextWeekday(DayOfWeek.Tuesday);
        var result = service.Calculate(room, tuesday, tuesday.AddDays(1));

        Assert.Equal(1_000_000m, result.TotalAmount); // No multiplier on weekday
    }

    [Fact]
    public void PricingService_HigherPriorityPromotionRule_ShouldOverrideWeekendRule()
    {
        // Promotion has Priority=5 (higher), Weekend has Priority=10 (lower)
        // On a Saturday, ONLY the promotion rule should apply (not both stacked)
        var service = new RoomPricingService(new IRoomPricingStrategy[]
        {
            new WeekendPricingStub(),   // Priority 10 — lower priority
            new PromotionPricingStub()  // Priority 5  — higher priority, returns 0.9
        });

        var room = MakeRoom(1_000_000m);
        var saturday = GetNextWeekday(DayOfWeek.Saturday);
        var result = service.Calculate(room, saturday, saturday.AddDays(1));

        // GetEffectiveMultiplier picks the FIRST strategy (by priority) that != 1.
        // Promotion (Priority=5) is sorted before Weekend (Priority=10).
        // So the promotion 0.9 multiplier wins over the weekend 1.2.
        Assert.Equal(900_000m, result.TotalAmount);
    }

    [Fact]
    public void PricingService_MultiNight_ShouldAveragePerNightCorrectly()
    {
        // 2 nights: Friday (weekday, x1.0) + Saturday (weekend, x1.2)
        // Total = 1_000_000 + 1_200_000 = 2_200_000
        // Avg per night = 1_100_000
        var service = new RoomPricingService(new[] { new WeekendPricingStub() });
        var room = MakeRoom(1_000_000m);

        var friday = GetNextWeekday(DayOfWeek.Friday);
        var result = service.Calculate(room, friday, friday.AddDays(2)); // Fri + Sat

        Assert.Equal(2, result.Nights);
        Assert.Equal(2_200_000m, result.TotalAmount);
        Assert.Equal(1_100_000m, result.DisplayPricePerNight);
    }

    [Fact]
    public void PricingService_NullDates_ShouldReturnBasePrice()
    {
        var service = new RoomPricingService(new[] { new WeekendPricingStub() });
        var room = MakeRoom(800_000m);

        var result = service.Calculate(room, null, null);

        Assert.Equal(800_000m, result.BasePricePerNight);
    }

    // ---------------------------------------------------------------
    // Helper
    // ---------------------------------------------------------------
    private static DateTime GetNextWeekday(DayOfWeek day)
    {
        var date = DateTime.Today.AddDays(1);
        while (date.DayOfWeek != day)
            date = date.AddDays(1);
        return date;
    }
}
