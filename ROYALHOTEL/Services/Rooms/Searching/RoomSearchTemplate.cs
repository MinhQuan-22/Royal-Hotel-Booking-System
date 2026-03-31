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
