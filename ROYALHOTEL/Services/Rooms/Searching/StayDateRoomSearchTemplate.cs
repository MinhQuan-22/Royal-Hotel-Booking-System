namespace ROYALHOTEL.Services.Rooms;

public sealed class StayDateRoomSearchTemplate : RoomSearchTemplate
{
    public StayDateRoomSearchTemplate(
        IRoomRepository repo,
        ROYALHOTEL.Data.RoyalHotelDbContext db,
        RoomPricingService pricingService)
        : base(repo, db, pricingService)
    {
    }

    protected override IEnumerable<RoomSearchItem> BuildPricingItems(IReadOnlyCollection<ROYALHOTEL.Models.Room> rooms, RoomSearchQuery criteria)
    {
        _ = HasValidStay(criteria, out var checkIn, out var checkOut);

        return rooms.Select(room => new RoomSearchItem
        {
            Room = room,
            Pricing = PricingService.Calculate(room, checkIn, checkOut)
        });
    }
}
