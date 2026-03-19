using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminAmenitiesController : Controller
    {
        private readonly RoyalHotelDbContext _context;

        public AdminAmenitiesController(RoyalHotelDbContext context)
        {
            _context = context;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return !string.IsNullOrWhiteSpace(role) && role.ToLower() == "admin";
        }

        [HttpGet]
        public async Task<IActionResult> Index(string? keyword)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var query = _context.Amenities.Select(a => new AdminAmenityItemViewModel
            {
                Id = a.Id,
                AmenityKey = a.AmenityKey,
                Name = a.Name,
                IconClass = a.IconClass,
                Category = a.Category
            });

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                keyword = keyword.Trim();

                query = query.Where(x =>
                    x.AmenityKey.Contains(keyword) ||
                    x.Name.Contains(keyword) ||
                    (x.IconClass != null && x.IconClass.Contains(keyword)) ||
                    (x.Category != null && x.Category.Contains(keyword)));
            }

            var items = await query
                .OrderBy(x => x.Id)
                .ToListAsync();

            ViewBag.Keyword = keyword;
            return View(items);
        }

        [HttpGet]
        public IActionResult Create()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            return View(new AdminAmenityFormViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(AdminAmenityFormViewModel vm)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            vm.AmenityKey = vm.AmenityKey.Trim();
            vm.Name = vm.Name.Trim();

            if (await _context.Amenities.AnyAsync(x => x.AmenityKey == vm.AmenityKey))
            {
                ModelState.AddModelError("AmenityKey", "Amenity key already exists.");
            }

            if (!ModelState.IsValid)
            {
                return View(vm);
            }

            var amenity = new Amenity
            {
                AmenityKey = vm.AmenityKey,
                Name = vm.Name,
                IconClass = vm.IconClass,
                Category = vm.Category
            };

            _context.Amenities.Add(amenity);
            await _context.SaveChangesAsync();

            TempData["Success"] = "Amenity created successfully.";
            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var amenity = await _context.Amenities.FirstOrDefaultAsync(x => x.Id == id);
            if (amenity == null)
            {
                return NotFound();
            }

            var vm = new AdminAmenityFormViewModel
            {
                Id = amenity.Id,
                AmenityKey = amenity.AmenityKey,
                Name = amenity.Name,
                IconClass = amenity.IconClass,
                Category = amenity.Category
            };

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(AdminAmenityFormViewModel vm)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            vm.AmenityKey = vm.AmenityKey.Trim();
            vm.Name = vm.Name.Trim();

            if (await _context.Amenities.AnyAsync(x => x.AmenityKey == vm.AmenityKey && x.Id != vm.Id))
            {
                ModelState.AddModelError("AmenityKey", "Amenity key already exists.");
            }

            if (!ModelState.IsValid)
            {
                return View(vm);
            }

            var amenity = await _context.Amenities.FirstOrDefaultAsync(x => x.Id == vm.Id);
            if (amenity == null)
            {
                return NotFound();
            }

            amenity.AmenityKey = vm.AmenityKey;
            amenity.Name = vm.Name;
            amenity.IconClass = vm.IconClass;
            amenity.Category = vm.Category;

            await _context.SaveChangesAsync();

            TempData["Success"] = "Amenity updated successfully.";
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var amenity = await _context.Amenities.FirstOrDefaultAsync(x => x.Id == id);
            if (amenity == null)
            {
                TempData["Error"] = "Amenity not found.";
                return RedirectToAction(nameof(Index));
            }

            _context.Amenities.Remove(amenity);
            await _context.SaveChangesAsync();

            TempData["Success"] = "Amenity deleted successfully.";
            return RedirectToAction(nameof(Index));
        }
    }
}