using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

public class EfRoomRepository : IRoomRepository
{
    private readonly RoyalHotelDbContext _db;

    public EfRoomRepository(RoyalHotelDbContext db)
    {
        _db = db;
    }

    public IQueryable<Room> Query()
        => _db.Rooms
              .AsNoTracking()
              .Where(r => r.IsActive)
              .Include(r => r.Images)
              .Include(r => r.RoomAmenities)
                  .ThenInclude(ra => ra.Amenity);

    public Task<Room?> GetByIdAsync(int id)
        => _db.Rooms
              .AsNoTracking()
              .Include(r => r.Hotel)          // Chi nhánh — hiển thị ở Detail page
              .Include(r => r.Images)
              .Include(r => r.RoomAmenities)
                  .ThenInclude(ra => ra.Amenity)
              .FirstOrDefaultAsync(r => r.Id == id && r.IsActive);
}
