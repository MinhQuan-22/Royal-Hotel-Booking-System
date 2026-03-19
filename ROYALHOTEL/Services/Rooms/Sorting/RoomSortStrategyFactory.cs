public static class RoomSortStrategyFactory
{
    public static IRoomSortStrategy Create(string? sort)
        => sort switch
        {
            "price_desc" => new PriceDescSort(),
            _ => new PriceAscSort()
        };
}
