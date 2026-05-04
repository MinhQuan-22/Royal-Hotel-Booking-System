using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.Security;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminAccountsController : Controller
    {
        private readonly RoyalHotelDbContext _context;

        public AdminAccountsController(RoyalHotelDbContext context)
        {
            _context = context;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return !string.IsNullOrWhiteSpace(role) && role.ToLower() == "admin";
        }

        private static readonly List<string> AllowedRoles = new() { "admin", "user" };
        private static readonly List<string> AllowedStatuses = new() { "active", "locked" };

        [HttpGet]
        public async Task<IActionResult> Index(string? keyword, string? role, string? status)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var query = _context.Accounts
                .Select(a => new AdminAccountItemViewModel
                {
                    Id = a.Id,
                    FullName = a.FullName,
                    Email = a.Email,
                    Phone = a.Phone,
                    Role = a.Role,
                    Status = a.Status,
                    CreatedAt = a.CreatedAt
                });

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                keyword = keyword.Trim();

                query = query.Where(x =>
                    x.FullName.Contains(keyword) ||
                    x.Email.Contains(keyword) ||
                    (x.Phone != null && x.Phone.Contains(keyword)));
            }

            if (!string.IsNullOrWhiteSpace(role))
            {
                query = query.Where(x => x.Role == role);
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(x => x.Status == status);
            }

            var items = await query
                .OrderByDescending(x => x.Id)
                .ToListAsync();

            ViewBag.Keyword = keyword;
            ViewBag.Role = role;
            ViewBag.Status = status;
            ViewBag.RoleOptions = AllowedRoles;
            ViewBag.StatusOptions = AllowedStatuses;

            return View(items);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateRole(int id, string role)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            if (string.IsNullOrWhiteSpace(role) || !AllowedRoles.Contains(role))
            {
                TempData["Error"] = "Invalid account role.";
                return RedirectToAction(nameof(Index));
            }

            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Id == id);
            if (account == null)
            {
                TempData["Error"] = "Account not found.";
                return RedirectToAction(nameof(Index));
            }

            account.Role = role;
            account.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();

            TempData["Success"] = "Account role updated successfully.";
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateStatus(int id, string status)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            if (string.IsNullOrWhiteSpace(status) || !AllowedStatuses.Contains(status))
            {
                TempData["Error"] = "Invalid account status.";
                return RedirectToAction(nameof(Index));
            }

            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Id == id);
            if (account == null)
            {
                TempData["Error"] = "Account not found.";
                return RedirectToAction(nameof(Index));
            }

            account.Status = status;
            account.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();

            TempData["Success"] = "Account status updated successfully.";
            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public IActionResult Create()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            return View(new AdminCreateAccountViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(AdminCreateAccountViewModel vm)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            vm.Role = (vm.Role ?? "user").Trim().ToLower();
            vm.Status = (vm.Status ?? "active").Trim().ToLower();

            if (!AllowedRoles.Contains(vm.Role))
            {
                ModelState.AddModelError("Role", "Role must be admin or user.");
            }

            if (!AllowedStatuses.Contains(vm.Status))
            {
                ModelState.AddModelError("Status", "Status must be active or locked.");
            }

            var emailExists = await _context.Accounts.AnyAsync(x => x.Email == vm.Email);
            if (emailExists)
            {
                ModelState.AddModelError("Email", "Email already exists.");
            }

            if (!ModelState.IsValid)
            {
                return View(vm);
            }

            var (hash, salt) = CryptoHelper.HashPassword(vm.Password);

            var account = new Account
            {
                FullName = vm.FullName,
                Email = vm.Email,
                Phone = vm.Phone,
                PasswordHash = hash,
                PasswordSalt = salt,
                Role = vm.Role,
                Status = vm.Status,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _context.Accounts.Add(account);
            await _context.SaveChangesAsync();

            TempData["Success"] = "Account created successfully.";
            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var acc = await _context.Accounts.FirstOrDefaultAsync(x => x.Id == id);

            if (acc == null)
            {
                TempData["Error"] = "Account not found.";
                return RedirectToAction(nameof(Index));
            }

            var vm = new AdminAccountFormViewModel
            {
                Id = acc.Id,
                FullName = acc.FullName ?? "",
                Email = acc.Email ?? "",
                Phone = acc.Phone ?? "",
                Role = string.IsNullOrWhiteSpace(acc.Role) ? "user" : acc.Role,
                Status = string.IsNullOrWhiteSpace(acc.Status) ? "active" : acc.Status
            };

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(AdminAccountFormViewModel vm)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            if (!ModelState.IsValid)
            {
                return View(vm);
            }

            var acc = await _context.Accounts.FirstOrDefaultAsync(x => x.Id == vm.Id);

            if (acc == null)
            {
                TempData["Error"] = "Account not found.";
                return RedirectToAction(nameof(Index));
            }

            var email = (vm.Email ?? "").Trim().ToLowerInvariant();

            var emailExists = await _context.Accounts
                .AnyAsync(x => x.Id != vm.Id && x.Email == email);

            if (emailExists)
            {
                TempData["Error"] = "Email already exists.";
                return View(vm);
            }

            acc.FullName = (vm.FullName ?? "").Trim();
            acc.Email = email;
            acc.Phone = (vm.Phone ?? "").Trim();
            acc.Role = (vm.Role ?? "user").Trim().ToLower();
            acc.Status = (vm.Status ?? "active").Trim().ToLower();
            acc.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            TempData["Success"] = "Account updated successfully.";
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

            var account = await _context.Accounts.FirstOrDefaultAsync(a => a.Id == id);
            if (account == null)
            {
                TempData["Error"] = "Account not found.";
                return RedirectToAction(nameof(Index));
            }

            // Prevent self-deletion
            var currentUserId = HttpContext.Session.GetInt32("USER_ID");
            if (currentUserId == id)
            {
                TempData["Error"] = "You cannot delete your own account.";
                return RedirectToAction("Edit", new { id });
            }

            _context.Accounts.Remove(account);
            await _context.SaveChangesAsync();

            TempData["Success"] = "Account deleted successfully.";
            return RedirectToAction(nameof(Index));
        }
    }
}