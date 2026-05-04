using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminHotelsController : Controller
    {
        private readonly RoyalHotelDbContext _context;

        public AdminHotelsController(RoyalHotelDbContext context)
        {
            _context = context;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        // ── GET: Trang quản lý chi nhánh ────────────────────────────────────
        public async Task<IActionResult> Index()
        {
            if (!IsAdmin())
                return RedirectToAction("Login", "Account");

            var hotels = await _context.Hotels
                .AsNoTracking()
                .OrderBy(h => h.Id)
                .ToListAsync();

            // Tính số phòng active cho từng hotel
            var roomCounts = await _context.Rooms
                .AsNoTracking()
                .Where(r => r.Status == "ACTIVE" && r.IsActive)
                .GroupBy(r => r.HotelId)
                .Select(g => new { HotelId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.HotelId, x => x.Count);

            var vms = hotels.Select(h => new AdminHotelViewModel
            {
                Id = h.Id,
                Name = h.Name,
                Address = h.Address,
                City = h.City,
                Country = h.Country,
                ActiveRoomCount = roomCounts.TryGetValue(h.Id, out var cnt) ? cnt : 0
            }).ToList();

            return View(vms);
        }

        // ── AJAX GET: Lấy dữ liệu 1 hotel để sửa ───────────────────────────
        [HttpGet]
        public async Task<IActionResult> GetHotel(int id)
        {
            if (!IsAdmin())
                return Unauthorized(new { success = false, message = "Unauthorized" });

            var hotel = await _context.Hotels.FindAsync(id);
            if (hotel == null)
                return NotFound(new { success = false, message = "Không tìm thấy chi nhánh." });

            return Json(new
            {
                success = true,
                hotel = new
                {
                    hotel.Id,
                    hotel.Name,
                    hotel.Address,
                    hotel.City,
                    hotel.Country
                }
            });
        }

        // ── AJAX POST: Tạo chi nhánh mới ────────────────────────────────────
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([FromBody] AdminHotelViewModel vm)
        {
            if (!IsAdmin())
                return Unauthorized(new { success = false, message = "Unauthorized" });

            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();
                return BadRequest(new { success = false, errors });
            }

            // Kiểm tra trùng tên
            var nameExists = await _context.Hotels
                .AnyAsync(h => h.Name.ToLower() == vm.Name.ToLower().Trim());
            if (nameExists)
                return BadRequest(new { success = false, message = "Tên chi nhánh đã tồn tại." });

            var hotel = new Hotel
            {
                Name = vm.Name.Trim(),
                Address = vm.Address.Trim(),
                City = vm.City.Trim(),
                Country = vm.Country.Trim()
            };

            _context.Hotels.Add(hotel);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = $"Đã tạo chi nhánh '{hotel.Name}' thành công!",
                hotel = new
                {
                    hotel.Id,
                    hotel.Name,
                    hotel.Address,
                    hotel.City,
                    hotel.Country,
                    ActiveRoomCount = 0
                }
            });
        }

        // ── AJAX PUT: Cập nhật chi nhánh ────────────────────────────────────
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit([FromBody] AdminHotelViewModel vm)
        {
            if (!IsAdmin())
                return Unauthorized(new { success = false, message = "Unauthorized" });

            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();
                return BadRequest(new { success = false, errors });
            }

            var hotel = await _context.Hotels.FindAsync(vm.Id);
            if (hotel == null)
                return NotFound(new { success = false, message = "Không tìm thấy chi nhánh." });

            // Kiểm tra trùng tên (ngoại trừ chính nó)
            var nameExists = await _context.Hotels
                .AnyAsync(h => h.Name.ToLower() == vm.Name.ToLower().Trim() && h.Id != vm.Id);
            if (nameExists)
                return BadRequest(new { success = false, message = "Tên chi nhánh đã tồn tại." });

            hotel.Name = vm.Name.Trim();
            hotel.Address = vm.Address.Trim();
            hotel.City = vm.City.Trim();
            hotel.Country = vm.Country.Trim();

            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = $"Đã cập nhật chi nhánh '{hotel.Name}' thành công!",
                hotel = new
                {
                    hotel.Id,
                    hotel.Name,
                    hotel.Address,
                    hotel.City,
                    hotel.Country
                }
            });
        }

        // ── AJAX DELETE: Xóa chi nhánh ──────────────────────────────────────
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete([FromBody] int id)
        {
            if (!IsAdmin())
                return Unauthorized(new { success = false, message = "Unauthorized" });

            var hotel = await _context.Hotels.FindAsync(id);
            if (hotel == null)
                return NotFound(new { success = false, message = "Không tìm thấy chi nhánh." });

            // Kiểm tra có phòng đang gắn không — không cho xóa
            var hasRooms = await _context.Rooms.AnyAsync(r => r.HotelId == id);
            if (hasRooms)
                return BadRequest(new
                {
                    success = false,
                    message = $"Không thể xóa chi nhánh '{hotel.Name}' vì còn phòng đang thuộc chi nhánh này. Hãy chuyển hoặc xóa phòng trước."
                });

            _context.Hotels.Remove(hotel);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = $"Đã xóa chi nhánh '{hotel.Name}' thành công!"
            });
        }

        // ── AJAX GET: Lấy danh sách hotels (JSON) cho các trang khác dùng realtime ──
        [HttpGet]
        public async Task<IActionResult> List()
        {
            if (!IsAdmin())
                return Unauthorized();

            var hotels = await _context.Hotels
                .AsNoTracking()
                .OrderBy(h => h.Id)
                .Select(h => new { h.Id, h.Name, h.City, h.Address, h.Country })
                .ToListAsync();

            return Json(hotels);
        }
    }
}
