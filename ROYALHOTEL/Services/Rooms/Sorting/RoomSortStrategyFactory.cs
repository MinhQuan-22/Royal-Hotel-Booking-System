namespace ROYALHOTEL.Services.Rooms;

public static class RoomSortStrategyFactory
{
    public static IRoomSortStrategy Create(string? sort)
        => sort switch
        {
            "price_desc" => new PriceDescSortStrategy(),
            _ => new PriceAscSortStrategy()
        };
}
