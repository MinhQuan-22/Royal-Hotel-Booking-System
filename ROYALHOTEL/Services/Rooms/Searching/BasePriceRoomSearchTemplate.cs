namespace ROYALHOTEL.Services.Rooms;

public sealed class BasePriceRoomSearchTemplate : RoomSearchTemplate
{
    public BasePriceRoomSearchTemplate(
        IRoomRepository repo,
        ROYALHOTEL.Data.RoyalHotelDbContext db,
        RoomPricingService pricingService)
        : base(repo, db, pricingService)
    {
    }

    protected override IEnumerable<RoomSearchItem> BuildPricingItems(IReadOnlyCollection<ROYALHOTEL.Models.Room> rooms, RoomSearchQuery criteria)
    {
        return rooms.Select(room => new RoomSearchItem
        {
            Room = room,
            Pricing = RoomPricingSummary.FromBase(room.BasePricePerNight)
        });
    }
}
