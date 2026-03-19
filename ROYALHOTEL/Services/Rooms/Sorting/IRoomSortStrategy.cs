using ROYALHOTEL.Models;

public interface IRoomSortStrategy
{
    IQueryable<Room> Apply(IQueryable<Room> query);
}
public class PriceAscSort : IRoomSortStrategy
{
    public IQueryable<Room> Apply(IQueryable<Room> query) => query.OrderBy(x => x.BasePricePerNight);
}
public class PriceDescSort : IRoomSortStrategy
{
    public IQueryable<Room> Apply(IQueryable<Room> query) => query.OrderByDescending(x => x.BasePricePerNight);
}
