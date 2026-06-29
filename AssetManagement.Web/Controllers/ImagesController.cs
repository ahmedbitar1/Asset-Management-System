using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    [Authorize(Roles = "Marketing,SuperAdmin")]
    public class ImagesController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IWebHostEnvironment _env;

        public ImagesController(IAssetRepository repo, IWebHostEnvironment env)
        { _repo = repo; _env = env; }

        [HttpGet]
        public async Task<IActionResult> Index(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            var folder = Path.Combine(_env.WebRootPath, "uploads", "assets", assetId.ToString());
            var images = Directory.Exists(folder)
                ? Directory.GetFiles(folder).Select(f => Path.GetFileName(f)).ToList()
                : new List<string>();
            ViewBag.AssetId   = assetId;
            ViewBag.AssetName = asset.AssetName;
            ViewBag.AssetCode = asset.AssetCode;
            ViewBag.Images    = images;
            return View();
        }

        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Upload(int assetId, List<IFormFile> files)
        {
            if (files == null || !files.Any())
            {
                TempData["Error"] = "لم يتم اختيار أي ملف";
                return RedirectToAction(nameof(Index), new { assetId });
            }
            var folder = Path.Combine(_env.WebRootPath, "uploads", "assets", assetId.ToString());
            Directory.CreateDirectory(folder);
            int count = 0;
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            foreach (var file in files)
            {
                var ext = Path.GetExtension(file.FileName).ToLower();
                if (!allowed.Contains(ext)) continue;
                var name = string.Format("{0}_{1}{2}", DateTime.Now.Ticks, count++, ext);
                var path = Path.Combine(folder, name);
                using var stream = new FileStream(path, FileMode.Create);
                await file.CopyToAsync(stream);
            }
            TempData["Success"] = string.Format("{0} images uploaded", count);
            return RedirectToAction(nameof(Index), new { assetId });
        }

        [HttpPost][ValidateAntiForgeryToken]
        public IActionResult Delete(int assetId, string fileName)
        {
            var path = Path.Combine(_env.WebRootPath, "uploads", "assets", assetId.ToString(), fileName);
            if (System.IO.File.Exists(path))
                System.IO.File.Delete(path);
            TempData["Success"] = "تم حذف الصورة";
            return RedirectToAction(nameof(Index), new { assetId });
        }
    }
}