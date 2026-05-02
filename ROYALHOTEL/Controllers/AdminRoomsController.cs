using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using Microsoft.Data.SqlClient;
using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels;
using ROYALHOTEL.Services.Catalog;

namespace ROYALHOTEL.Controllers
{
    public class AdminRoomsController : Controller
    {
        private readonly RoyalHotelDbContext _context;
        private readonly CatalogSyncService _catalogSync;

        public AdminRoomsController(
            RoyalHotelDbContext context,
            CatalogSyncService catalogSync)
        {
            _context = context;
            _catalogSync = catalogSync;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        private async Task LoadAmenityOptions(AdminRoomFormViewModel vm)
        {
            vm.AmenityOptions = await _context.Amenities
                .OrderBy(a => a.Name)
                .Select(a => new SelectListItem
                {
                    Value = a.Id.ToString(),
                    Text = a.Name,
                    Selected = vm.SelectedAmenityIds.Contains(a.Id)
                })
                .ToListAsync();
        }

        private async Task LoadHotelOptions(AdminRoomFormViewModel vm)
        {
            vm.HotelOptions = await _context.Hotels
                .OrderBy(h => h.Id)
                .Select(h => new SelectListItem
                {
                    Value = h.Id.ToString(),
                    Text = $"{h.City} — {h.Name}",
                    Selected = h.Id == vm.HotelId
                })
                .ToListAsync();
        }

        private void NormalizeRoomForm(AdminRoomFormViewModel vm)
        {
            vm.Code = vm.Code?.Trim() ?? string.Empty;
            vm.Name = vm.Name?.Trim() ?? string.Empty;
            vm.RoomType = vm.RoomType?.Trim() ?? string.Empty;
            vm.Description = vm.Description?.Trim();
            vm.CoverImageUrl = vm.CoverImageUrl?.Trim();
        }

        private static bool IsDuplicateKeyException(DbUpdateException ex)
        {
            if (ex.InnerException is SqlException sqlEx)
            {
                return sqlEx.Number == 2601 || sqlEx.Number == 2627;
            }

            if (ex.InnerException?.InnerException is SqlException nestedSqlEx)
            {
                return nestedSqlEx.Number == 2601 || nestedSqlEx.Number == 2627;
            }

            return false;
        }
        public async Task<IActionResult> Index(string? keyword, int? hotelId)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var query = _context.Rooms.AsQueryable();

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                query = query.Where(r =>
                    r.Code.Contains(keyword) ||
                    r.Name.Contains(keyword) ||
                    r.RoomType.Contains(keyword));
            }

            if (hotelId.HasValue)
                query = query.Where(r => r.HotelId == hotelId.Value);

            var rooms = await query
                .Include(r => r.Hotel)
                .OrderBy(r => r.HotelId)
                .ThenBy(r => r.Id)
                .ToListAsync();

            var hotels = await _context.Hotels.OrderBy(h => h.Id).ToListAsync();
            ViewBag.Keyword = keyword;
            ViewBag.SelectedHotelId = hotelId;
            ViewBag.Hotels = hotels;
            return View(rooms);
        }

        [HttpGet]
        public async Task<IActionResult> Create()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var vm = new AdminRoomFormViewModel
            {
                IsActive = true
            };

            await LoadAmenityOptions(vm);
            await LoadHotelOptions(vm);
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(AdminRoomFormViewModel vm)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            NormalizeRoomForm(vm);

            var codeExists = await _context.Rooms
                .AnyAsync(r => r.Code == vm.Code);

            if (codeExists)
            {
                ModelState.AddModelError(nameof(vm.Code),
                    "This room code already exists. Please enter a different room code.");
            }

            if (!ModelState.IsValid)
            {
                await LoadAmenityOptions(vm);
                await LoadHotelOptions(vm);
                return View(vm);
            }

            var room = new Room
            {
                Code = vm.Code,
                Name = vm.Name,
                RoomType = vm.RoomType,
                BasePricePerNight = vm.BasePricePerNight,
                MaxGuests = vm.MaxGuests,
                IsActive = vm.IsActive,
                Description = vm.Description,
                CoverImageUrl = vm.CoverImageUrl,
                HotelId = vm.HotelId,
                Rate = vm.BasePricePerNight
            };

            _context.Rooms.Add(room);

            try
            {
                await _context.SaveChangesAsync();

                if (vm.SelectedAmenityIds != null && vm.SelectedAmenityIds.Any())
                {
                    var roomAmenities = vm.SelectedAmenityIds
                        .Distinct()
                        .Select(amenityId => new RoomAmenity
                        {
                            RoomId = room.Id,
                            AmenityId = amenityId
                        })
                        .ToList();

                    _context.RoomAmenities.AddRange(roomAmenities);
                    await _context.SaveChangesAsync();
                }

                TempData["Success"] = "Room created successfully.";

                // Sync sang MongoDB (fire-and-forget)
                _ = Task.Run(async () =>
                {
                    try { await _catalogSync.SyncRoomToMongoAsync(room.Id); }
                    catch (Exception ex) { Console.WriteLine($"[WARN] Mongo sync failed: {ex.Message}"); }
                });

                return RedirectToAction(nameof(Index));
            }
            catch (DbUpdateException ex) when (IsDuplicateKeyException(ex))
            {
                ModelState.AddModelError(nameof(vm.Code),
                    "This room code already exists. Please enter a different room code.");

                await LoadAmenityOptions(vm);
                return View(vm);
            }
        }
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var room = await _context.Rooms
                .Include(r => r.RoomAmenities)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (room == null)
            {
                return NotFound();
            }

            var vm = new AdminRoomFormViewModel
            {
                Id = room.Id,
                Code = room.Code,
                Name = room.Name,
                RoomType = room.RoomType,
                BasePricePerNight = room.BasePricePerNight,
                MaxGuests = room.MaxGuests,
                IsActive = room.IsActive,
                Description = room.Description,
                CoverImageUrl = room.CoverImageUrl,
                HotelId = room.HotelId,
                SelectedAmenityIds = room.RoomAmenities
                    .Select(x => x.AmenityId)
                    .ToList()
            };

            await LoadAmenityOptions(vm);
            await LoadHotelOptions(vm);
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(AdminRoomFormViewModel vm)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            NormalizeRoomForm(vm);

            var codeExists = await _context.Rooms
                .AnyAsync(r => r.Code == vm.Code && r.Id != vm.Id);

            if (codeExists)
            {
                ModelState.AddModelError(nameof(vm.Code),
                    "This room code already exists. Please enter a different room code.");
            }

            if (!ModelState.IsValid)
            {
                await LoadAmenityOptions(vm);
                await LoadHotelOptions(vm);
                return View(vm);
            }

            var room = await _context.Rooms
                .Include(r => r.RoomAmenities)
                .FirstOrDefaultAsync(r => r.Id == vm.Id);

            if (room == null)
            {
                return NotFound();
            }

            room.Code = vm.Code;
            room.Name = vm.Name;
            room.RoomType = vm.RoomType;
            room.BasePricePerNight = vm.BasePricePerNight;
            room.MaxGuests = vm.MaxGuests;
            room.IsActive = vm.IsActive;
            room.Description = vm.Description;
            room.CoverImageUrl = vm.CoverImageUrl;
            room.HotelId = vm.HotelId;
            room.Rate = vm.BasePricePerNight;

            _context.RoomAmenities.RemoveRange(room.RoomAmenities);

            if (vm.SelectedAmenityIds != null && vm.SelectedAmenityIds.Any())
            {
                var roomAmenities = vm.SelectedAmenityIds
                    .Distinct()
                    .Select(amenityId => new RoomAmenity
                    {
                        RoomId = room.Id,
                        AmenityId = amenityId
                    })
                    .ToList();

                _context.RoomAmenities.AddRange(roomAmenities);
            }

            try
            {
                await _context.SaveChangesAsync();

                TempData["Success"] = "Room updated successfully.";

                // Sync sang MongoDB (fire-and-forget)
                _ = Task.Run(async () =>
                {
                    try { await _catalogSync.SyncRoomToMongoAsync(room.Id); }
                    catch (Exception ex) { Console.WriteLine($"[WARN] Mongo sync failed: {ex.Message}"); }
                });

                return RedirectToAction(nameof(Index));
            }
            catch (DbUpdateException ex) when (IsDuplicateKeyException(ex))
            {
                ModelState.AddModelError(nameof(vm.Code),
                    "This room code already exists. Please enter a different room code.");

                await LoadAmenityOptions(vm);
                await LoadHotelOptions(vm);
                return View(vm);
            }
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var room = await _context.Rooms.FirstOrDefaultAsync(r => r.Id == id);
            if (room == null)
            {
                return NotFound();
            }

            _context.Rooms.Remove(room);
            await _context.SaveChangesAsync();

            TempData["Success"] = "Room deleted successfully.";
            return RedirectToAction(nameof(Index));
        }
    }
}