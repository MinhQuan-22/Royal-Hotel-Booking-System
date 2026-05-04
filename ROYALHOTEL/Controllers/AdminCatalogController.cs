using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Services.Catalog;

namespace ROYALHOTEL.Controllers;

/// <summary>
/// Admin controller để quản lý MongoDB HotelCatalog sync.
/// </summary>
public class AdminCatalogController : Controller
{
    private readonly CatalogSyncService _catalogSync;

    public AdminCatalogController(CatalogSyncService catalogSync)
    {
        _catalogSync = catalogSync;
    }

    private bool IsAdmin()
    {
        var role = HttpContext.Session.GetString("USER_ROLE");
        return role != null && role.ToLower() == "admin";
    }

    /// <summary>
    /// Hiển thị trang quản lý catalog sync.
    /// </summary>
    public IActionResult Index()
    {
        if (!IsAdmin())
        {
            return RedirectToAction("Login", "Account");
        }

        return View();
    }

    /// <summary>
    /// Sync toàn bộ hotels từ SQL Server sang MongoDB.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SyncAllToMongo()
    {
        if (!IsAdmin())
        {
            return Unauthorized();
        }

        try
        {
            await _catalogSync.SyncAllHotelsAsync();
            TempData["Success"] = "Đã đồng bộ thành công tất cả hotels sang MongoDB.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Lỗi khi đồng bộ: {ex.Message}";
        }

        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Sync một room cụ thể sang MongoDB.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SyncRoomToMongo(int roomId)
    {
        if (!IsAdmin())
        {
            return Unauthorized();
        }

        try
        {
            await _catalogSync.SyncRoomToMongoAsync(roomId);
            TempData["Success"] = $"Đã đồng bộ thành công Room ID {roomId} sang MongoDB.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = $"Lỗi khi đồng bộ Room ID {roomId}: {ex.Message}";
        }

        return RedirectToAction("Index", "AdminRooms");
    }
}
