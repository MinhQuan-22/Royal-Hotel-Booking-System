using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Models;
using ROYALHOTEL.Data;

public class EfRoomRepository : IRoomRepository
{
    private readonly RoyalHotelDbContext _db;
    public EfRoomRepository(RoyalHotelDbContext db) => _db = db;

    public IQueryable<Room> Query()
        => _db.Rooms
              .AsNoTracking()
              .Include(r => r.Images)
              .Include(r => r.RoomAmenities).ThenInclude(ra => ra.Amenity)
              .Where(r => r.IsActive);

    public Task<Room?> GetByIdAsync(int id)
        => Query().FirstOrDefaultAsync(r => r.Id == id);
}
