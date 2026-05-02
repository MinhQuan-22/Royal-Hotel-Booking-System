using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

public abstract class RoomSearchTemplate
{
    protected readonly IRoomRepository Repo;
    protected readonly RoyalHotelDbContext Db;
    protected readonly RoomPricingService PricingService;

    protected RoomSearchTemplate(
        IRoomRepository repo,
        RoyalHotelDbContext db,
        RoomPricingService pricingService)
    {
        Repo = repo;
        Db = db;
        PricingService = pricingService;
    }

    public async Task<List<Room>> ExecuteAsync(RoomSearchQuery criteria)
    {
        var query = BuildBaseQuery();
        query = ApplyCandidateFilter(query, criteria);
        query = ApplyHotelFilter(query, criteria);   // [NEW] Filter theo chi nhánh
        query = ApplyGuestFilter(query, criteria);
        query = ApplyRoomTypeFilter(query, criteria);
        query = ApplyAmenityFilter(query, criteria);
        query = await ApplyAvailabilityFilterAsync(query, criteria);

        var rooms = await LoadRoomsAsync(query);
        var pricingItems = BuildPricingItems(rooms, criteria);
        pricingItems = ApplyPriceFilter(pricingItems, criteria);
        pricingItems = ApplySort(pricingItems, criteria);

        return pricingItems.Select(x => x.Room).ToList();
    }

    protected virtual IQueryable<Room> BuildBaseQuery()
        => Repo.Query();

    /// <summary>
    /// Filter theo chi nhánh khách sạn (HotelId).
    /// Nếu HotelId null → hiển thị tất cả chi nhánh.
    /// </summary>
    protected IQueryable<Room> ApplyHotelFilter(IQueryable<Room> query, RoomSearchQuery criteria)
    {
        if (!criteria.HotelId.HasValue)
            return query;

        return query.Where(r => r.HotelId == criteria.HotelId.Value);
    }

    /// <summary>
    /// Nếu có RoomIdCandidates từ MongoDB (bước 1), filter SQL chỉ trong tập đó.
    /// Nếu candidates rỗng (không có kết quả MongoDB) → trả empty query ngay.
    /// </summary>
    protected IQueryable<Room> ApplyCandidateFilter(IQueryable<Room> query, RoomSearchQuery criteria)
    {
        if (criteria.RoomIdCandidates == null)
            return query; // Không có MongoDB filter → giữ nguyên

        if (criteria.RoomIdCandidates.Count == 0)
            return query.Where(r => r.Id == -1); // Không có phòng thỏa mãn → trả rỗng

        var ids = criteria.RoomIdCandidates;
        return query.Where(r => ids.Contains(r.Id));
    }

    protected virtual IQueryable<Room> ApplyGuestFilter(IQueryable<Room> query, RoomSearchQuery criteria)
    {
        if (criteria.Guests > 0)
            query = query.Where(r => r.MaxGuests >= criteria.Guests);

        return query;
    }

    protected virtual IQueryable<Room> ApplyRoomTypeFilter(IQueryable<Room> query, RoomSearchQuery criteria)
    {
        if (criteria.RoomTypes == null || criteria.RoomTypes.Count == 0)
            return query;

        var selectedTypes = criteria.RoomTypes
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (selectedTypes.Count == 0)
            return query;

        return query.Where(r =>
            !string.IsNullOrWhiteSpace(r.RoomType) &&
            selectedTypes.Contains(r.RoomType.Trim()));
    }

    protected virtual IQueryable<Room> ApplyAmenityFilter(IQueryable<Room> query, RoomSearchQuery criteria)
    {
        if (criteria.AmenityKeys == null || criteria.AmenityKeys.Count == 0)
            return query;

        var selectedAmenityKeys = criteria.AmenityKeys
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        return query.Where(r =>
            r.RoomAmenities.Any(ra => selectedAmenityKeys.Contains(ra.Amenity.AmenityKey)));
    }

    protected virtual async Task<IQueryable<Room>> ApplyAvailabilityFilterAsync(IQueryable<Room> query, RoomSearchQuery criteria)
    {
        if (!HasValidStay(criteria, out var checkIn, out var checkOut))
            return query;

        var blockedRoomIds = await Db.Bookings
            .AsNoTracking()
            .Where(b =>
                (b.Status == "Confirmed" || b.Status == "CheckedIn") &&
                b.CheckIn < checkOut &&
                b.CheckOut > checkIn)
            .Select(b => b.RoomId)
            .Distinct()
            .ToListAsync();

        return query.Where(r => !blockedRoomIds.Contains(r.Id));
    }

    protected virtual Task<List<Room>> LoadRoomsAsync(IQueryable<Room> query)
        => query.ToListAsync();

    protected virtual IEnumerable<RoomSearchItem> ApplyPriceFilter(IEnumerable<RoomSearchItem> items, RoomSearchQuery criteria)
    {
        if (criteria.MinPrice.HasValue)
            items = items.Where(x => x.Pricing.DisplayPricePerNight >= criteria.MinPrice.Value);

        if (criteria.MaxPrice.HasValue)
            items = items.Where(x => x.Pricing.DisplayPricePerNight <= criteria.MaxPrice.Value);

        return items;
    }

    protected virtual IEnumerable<RoomSearchItem> ApplySort(IEnumerable<RoomSearchItem> items, RoomSearchQuery criteria)
    {
        var sorter = RoomSortStrategyFactory.Create(criteria.Sort);
        return sorter.Apply(items);
    }

    protected static bool HasValidStay(RoomSearchQuery criteria, out DateTime checkIn, out DateTime checkOut)
    {
        checkIn = default;
        checkOut = default;

        if (!criteria.CheckIn.HasValue || !criteria.CheckOut.HasValue)
            return false;

        checkIn = criteria.CheckIn.Value.ToDateTime(TimeOnly.MinValue);
        checkOut = criteria.CheckOut.Value.ToDateTime(TimeOnly.MinValue);

        return checkOut > checkIn;
    }

    protected abstract IEnumerable<RoomSearchItem> BuildPricingItems(IReadOnlyCollection<Room> rooms, RoomSearchQuery criteria);
}
