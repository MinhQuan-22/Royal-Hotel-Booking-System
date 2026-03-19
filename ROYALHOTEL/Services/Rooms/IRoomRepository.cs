using ROYALHOTEL.Models;

public interface IRoomRepository
{
    IQueryable<Room> Query();
    Task<Room?> GetByIdAsync(int id);
}
