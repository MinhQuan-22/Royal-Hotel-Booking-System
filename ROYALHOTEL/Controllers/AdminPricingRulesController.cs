using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Rooms;

namespace ROYALHOTEL.Controllers;

public class AdminPricingRulesController : Controller
{
    private readonly IPricingRuleAdminService _service;
    private readonly RoomQueryService _roomQueryService;

    public AdminPricingRulesController(
        IPricingRuleAdminService service,
        RoomQueryService roomQueryService)
    {
        _service = service;
        _roomQueryService = roomQueryService;
    }

    private bool IsAdmin()
    {
        var role = HttpContext.Session.GetString("USER_ROLE");
        return !string.IsNullOrWhiteSpace(role) &&
               role.Equals("admin", StringComparison.OrdinalIgnoreCase);
    }

    private async Task LoadFormOptionsAsync(string? selectedRoomType = null)
    {
        ViewBag.RuleTypeOptions = new List<string> { "promotion", "holiday", "weekend" };
        ViewBag.RoomTypeOptions = await _roomQueryService.GetAllRoomTypesAsync();
        ViewBag.SelectedRoomType = selectedRoomType;
    }

    public async Task<IActionResult> Index()
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        var rules = await _service.GetAllAsync();
        return View(rules);
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        var model = new PricingRule
        {
            RuleType = "promotion",
            Multiplier = 1m,
            Priority = 100,
            IsActive = true
        };

        await LoadFormOptionsAsync(model.RoomType);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(PricingRule model)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        if (!ModelState.IsValid)
        {
            await LoadFormOptionsAsync(model.RoomType);
            return View(model);
        }

        try
        {
            await _service.CreateAsync(model, HttpContext.Session.GetString("USER_EMAIL"));
            TempData["Success"] = "Tạo pricing rule thành công.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", ex.Message);
            await LoadFormOptionsAsync(model.RoomType);
            return View(model);
        }
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        var rule = await _service.GetByIdAsync(id);
        if (rule == null) return NotFound();

        await LoadFormOptionsAsync(rule.RoomType);
        return View(rule);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(PricingRule model)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        if (!ModelState.IsValid)
        {
            await LoadFormOptionsAsync(model.RoomType);
            return View(model);
        }

        try
        {
            await _service.UpdateAsync(model, HttpContext.Session.GetString("USER_EMAIL"));
            TempData["Success"] = "Cập nhật pricing rule thành công.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", ex.Message);
            await LoadFormOptionsAsync(model.RoomType);
            return View(model);
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        await _service.DeleteAsync(id, HttpContext.Session.GetString("USER_EMAIL"));
        TempData["Success"] = "Xóa pricing rule thành công.";
        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> History(int id)
    {
        if (!IsAdmin()) return RedirectToAction("Login", "Account");

        var histories = await _service.GetHistoriesAsync(id);
        ViewBag.RuleId = id;
        return View(histories);
    }
}
