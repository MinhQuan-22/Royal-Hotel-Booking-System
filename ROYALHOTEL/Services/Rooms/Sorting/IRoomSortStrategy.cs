namespace ROYALHOTEL.Services.Rooms;

public interface IRoomSortStrategy
{
    IEnumerable<RoomSearchItem> Apply(IEnumerable<RoomSearchItem> items);
}

public sealed class PriceAscSortStrategy : IRoomSortStrategy
{
    public IEnumerable<RoomSearchItem> Apply(IEnumerable<RoomSearchItem> items)
        => items.OrderBy(x => x.Pricing.DisplayPricePerNight)
                .ThenBy(x => x.Room.Id);
}

public sealed class PriceDescSortStrategy : IRoomSortStrategy
{
    public IEnumerable<RoomSearchItem> Apply(IEnumerable<RoomSearchItem> items)
        => items.OrderByDescending(x => x.Pricing.DisplayPricePerNight)
                .ThenBy(x => x.Room.Id);
}
