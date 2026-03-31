using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

public interface IRoomRepository
{
    IQueryable<Room> Query();
    Task<Room?> GetByIdAsync(int id);
}
