using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using Microsoft.Extensions.Caching.Memory;

namespace ROYALHOTEL.Controllers;

/// <summary>
/// Admin controller for managing configurable hotel policies (P1-1)
/// Policies are used by the AI chat system for policy-related questions.
/// </summary>
public class AdminPoliciesController : Controller
{
    private readonly RoyalHotelDbContext _context;
    private readonly IMemoryCache _cache;
    private readonly ILogger<AdminPoliciesController> _logger;

    public AdminPoliciesController(
        RoyalHotelDbContext context,
        IMemoryCache cache,
        ILogger<AdminPoliciesController> logger)
    {
        _context = context;
        _cache = cache;
        _logger = logger;
    }

    private bool IsAdmin()
    {
        var role = HttpContext.Session.GetString("USER_ROLE");
        return role != null && role.ToLower() == "admin";
    }

    // GET /AdminPolicies
    [HttpGet]
    public async Task<IActionResult> Index()
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        var policies = await _context.HotelPolicies
            .OrderBy(p => p.Category)
            .ThenBy(p => p.SortOrder)
            .ToListAsync();

        return View(policies);
    }

    // GET /AdminPolicies/Create
    [HttpGet]
    public IActionResult Create()
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");
        return View(new HotelPolicy());
    }

    // POST /AdminPolicies/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(HotelPolicy policy)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        // Check for duplicate key
        if (await _context.HotelPolicies.AnyAsync(p => p.PolicyKey == policy.PolicyKey))
        {
            ModelState.AddModelError("PolicyKey", "Policy key này đã tồn tại");
            return View(policy);
        }

        if (!ModelState.IsValid) return View(policy);

        policy.CreatedAt = DateTime.UtcNow;
        policy.UpdatedAt = DateTime.UtcNow;

        _context.HotelPolicies.Add(policy);
        await _context.SaveChangesAsync();

        // Invalidate cache
        _cache.Remove($"faq_{policy.Category}");

        _logger.LogInformation("Admin created policy: {PolicyKey}", policy.PolicyKey);
        TempData["Success"] = $"Đã tạo chính sách '{policy.PolicyName}'";
        return RedirectToAction("Index");
    }

    // GET /AdminPolicies/Edit/{id}
    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        var policy = await _context.HotelPolicies.FindAsync(id);
        if (policy == null) return NotFound();

        return View(policy);
    }

    // POST /AdminPolicies/Edit/{id}
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, HotelPolicy policy)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");
        if (id != policy.Id) return BadRequest();

        // Check for duplicate key (excluding self)
        if (await _context.HotelPolicies.AnyAsync(p => p.PolicyKey == policy.PolicyKey && p.Id != id))
        {
            ModelState.AddModelError("PolicyKey", "Policy key này đã tồn tại");
            return View(policy);
        }

        if (!ModelState.IsValid) return View(policy);

        var existing = await _context.HotelPolicies.FindAsync(id);
        if (existing == null) return NotFound();

        existing.PolicyKey = policy.PolicyKey;
        existing.PolicyName = policy.PolicyName;
        existing.Content = policy.Content;
        existing.Category = policy.Category;
        existing.SortOrder = policy.SortOrder;
        existing.IsActive = policy.IsActive;
        existing.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        // Invalidate cache for this category
        _cache.Remove($"faq_{policy.Category}");
        _cache.Remove($"faq_Policies");

        _logger.LogInformation("Admin updated policy: {PolicyKey}", policy.PolicyKey);
        TempData["Success"] = $"Đã cập nhật chính sách '{policy.PolicyName}'";
        return RedirectToAction("Index");
    }

    // POST /AdminPolicies/Delete/{id}
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        var policy = await _context.HotelPolicies.FindAsync(id);
        if (policy == null) return NotFound();

        var category = policy.Category;
        _context.HotelPolicies.Remove(policy);
        await _context.SaveChangesAsync();

        // Invalidate cache
        _cache.Remove($"faq_{category}");
        _cache.Remove($"faq_Policies");

        _logger.LogInformation("Admin deleted policy: {PolicyKey}", policy.PolicyKey);
        TempData["Success"] = $"Đã xóa chính sách '{policy.PolicyName}'";
        return RedirectToAction("Index");
    }

    // POST /AdminPolicies/Toggle/{id}
    [HttpPost]
    public async Task<IActionResult> Toggle(int id)
    {
        if (!IsAdmin()) return Unauthorized(new { success = false });

        var policy = await _context.HotelPolicies.FindAsync(id);
        if (policy == null) return NotFound(new { success = false });

        policy.IsActive = !policy.IsActive;
        policy.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _cache.Remove($"faq_{policy.Category}");
        _cache.Remove($"faq_Policies");

        return Ok(new { success = true, isActive = policy.IsActive });
    }

    // GET /AdminPolicies/SeedDefaults — Seeds default policies if table is empty
    [HttpPost]
    public async Task<IActionResult> SeedDefaults()
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        if (await _context.HotelPolicies.AnyAsync())
        {
            TempData["Warning"] = "Bảng HotelPolicies đã có dữ liệu. Không seed lại.";
            return RedirectToAction("Index");
        }

        var defaults = new List<HotelPolicy>
        {
            new() { PolicyKey = "checkin",      PolicyName = "Check-in",         Category = "Policies", SortOrder = 1, Content = "Thời gian check-in: 14:00 (02:00 PM)\nNếu đến sớm, hành lý có thể gửi tại quầy lễ tân miễn phí." },
            new() { PolicyKey = "checkout",     PolicyName = "Check-out",         Category = "Policies", SortOrder = 2, Content = "Thời gian check-out: 12:00 (12:00 PM)\nCheck-out muộn có thể được yêu cầu tùy thuộc vào tình trạng phòng (phụ phí có thể áp dụng)." },
            new() { PolicyKey = "cancellation", PolicyName = "Hủy phòng",         Category = "Policies", SortOrder = 3, Content = "- Hủy trước 24 giờ so với ngày check-in: Hoàn tiền 100%\n- Hủy trong vòng 24 giờ: Hoàn tiền 50%\n- Không đến (No-show): Không hoàn tiền" },
            new() { PolicyKey = "payment",      PolicyName = "Thanh toán",         Category = "Policies", SortOrder = 4, Content = "- Chấp nhận: Thẻ tín dụng Visa/Mastercard, thẻ ghi nợ, tiền mặt\n- Thanh toán khi check-in hoặc trước khi check-out\n- Đặt cọc có thể được yêu cầu" },
            new() { PolicyKey = "children",     PolicyName = "Trẻ em",             Category = "Policies", SortOrder = 5, Content = "- Trẻ em dưới 6 tuổi: Miễn phí (chia sẻ giường với bố mẹ, không cần giường phụ)\n- Trẻ em 6-12 tuổi: 50% giá phòng\n- Trẻ em trên 12 tuổi: Tính như người lớn" },
            new() { PolicyKey = "smoking",      PolicyName = "Hút thuốc",          Category = "Policies", SortOrder = 6, Content = "Khách sạn là môi trường hoàn toàn không hút thuốc. Hút thuốc chỉ được phép tại khu vực được chỉ định bên ngoài tòa nhà." },
            new() { PolicyKey = "pets",         PolicyName = "Thú cưng",           Category = "Policies", SortOrder = 7, Content = "Không chấp nhận thú cưng tại khách sạn. Vui lòng liên hệ trước nếu có nhu cầu đặc biệt." },
        };

        foreach (var p in defaults)
        {
            p.CreatedAt = DateTime.UtcNow;
            p.UpdatedAt = DateTime.UtcNow;
        }

        _context.HotelPolicies.AddRange(defaults);
        await _context.SaveChangesAsync();

        _cache.Remove("faq_Policies");

        TempData["Success"] = $"Đã seed {defaults.Count} chính sách mặc định";
        return RedirectToAction("Index");
    }
}
