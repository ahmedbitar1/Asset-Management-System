using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Text.Json;

namespace AssetManagement.Web.Controllers
{
    [Authorize(Roles = "Legal,SuperAdmin")]
    public class AssetImportController : Controller
    {
        private readonly IExcelImportService _importService;
        public AssetImportController(IExcelImportService svc) => _importService = svc;

        [HttpGet]
        public IActionResult Index() => View();

        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Upload(IFormFile file)
        {
            if (file == null || file.Length == 0)
            { TempData["Error"] = "يرجى اختيار ملف"; return RedirectToAction("Index"); }
            if (!Path.GetExtension(file.FileName).Equals(".xlsx", StringComparison.OrdinalIgnoreCase))
            { TempData["Error"] = "يُقبل ملفات .xlsx فقط"; return RedirectToAction("Index"); }

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            using var stream = file.OpenReadStream();
            var result = await _importService.ImportAsync(stream, userId);

            // Store in Session (not TempData/cookie) to avoid HTTP 431
            HttpContext.Session.SetString("ImportResult", JsonSerializer.Serialize(result));
            return RedirectToAction("Result");
        }

        [HttpGet]
        public IActionResult Result()
        {
            var json = HttpContext.Session.GetString("ImportResult");
            if (string.IsNullOrEmpty(json))
                return RedirectToAction("Index");

            HttpContext.Session.Remove("ImportResult");
            var result = JsonSerializer.Deserialize<ImportResultViewModel>(json);
            return View(result);
        }
    }
}
