using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class OptionalStagesController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;
        private readonly IWebHostEnvironment _env;

        public OptionalStagesController(IAssetRepository repo, IStageHistoryRepository history, IWebHostEnvironment env)
        { _repo = repo; _history = history; _env = env; }

        // ── Marketing (2a) ─────────────────────────────
        [HttpGet][Authorize(Roles = "Marketing,SuperAdmin")]
        public async Task<IActionResult> Marketing(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            // تحميل آخر سجل سابق لإظهاره في النموذج
            var last = asset.OptionalStageDetails
                .Where(d => d.StageKey == "2a" && d.AssetId == assetId)
                .OrderByDescending(d => d.CreatedAt).FirstOrDefault();
            ViewBag.PrevDetails = last?.Details;
            ViewBag.PrevNotes   = last?.Notes;

            ViewBag.Asset   = asset;
            ViewBag.History = asset.OptionalStageDetails
                .Where(d => d.StageKey == "2a").OrderByDescending(d => d.CreatedAt).ToList();

            var imgFolder = Path.Combine(_env.WebRootPath, "uploads", "assets", assetId.ToString());
            ViewBag.Images = Directory.Exists(imgFolder)
                ? Directory.GetFiles(imgFolder).Select(f => Path.GetFileName(f)).ToList()
                : new List<string>();
            return View();
        }

        [HttpPost][ValidateAntiForgeryToken][Authorize(Roles = "Marketing,SuperAdmin")]
        public async Task<IActionResult> Marketing(int assetId, string? adText, string? notes, List<IFormFile>? photos)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;

            if (photos != null && photos.Any())
            {
                var folder = Path.Combine(_env.WebRootPath, "uploads", "assets", assetId.ToString());
                Directory.CreateDirectory(folder);
                var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
                int c = 0;
                foreach (var f in photos)
                {
                    var ext = Path.GetExtension(f.FileName).ToLower();
                    if (!allowed.Contains(ext)) continue;
                    var name = $"{DateTime.Now.Ticks}_{c++}{ext}";
                    using var stream = new FileStream(Path.Combine(folder, name), FileMode.Create);
                    await f.CopyToAsync(stream);
                }
            }

            // تحديث سجل موجود أو إضافة جديد
            var existing = asset.OptionalStageDetails
                .Where(d => d.StageKey == "2a").OrderByDescending(d => d.CreatedAt).FirstOrDefault();
            if (existing != null)
            {
                existing.Details   = adText;
                existing.Notes     = notes;
                existing.CreatedAt = DateTime.Now;
            }
            else
            {
                asset.OptionalStageDetails.Add(new OptionalStageDetail
                { AssetId=assetId, StageKey="2a", Details=adText, Notes=notes, CreatedAt=DateTime.Now });
            }

            var status = asset.OptionalStageStatuses.FirstOrDefault(o => o.StageKey == "2a");
            if (status == null)
                asset.OptionalStageStatuses.Add(new OptionalStageStatus { StageKey="2a", IsCompleted=true, CompletedAt=DateTime.Now });
            else { status.IsCompleted = true; status.CompletedAt = DateTime.Now; }

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();
            TempData["Success"] = "تم حفظ بيانات التسويق بنجاح";
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }

        // ── Engineering (2b) ───────────────────────────
        [HttpGet][Authorize(Roles = "Engineering,SuperAdmin")]
        public async Task<IActionResult> Engineering(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var last = asset.OptionalStageDetails
                .Where(d => d.StageKey == "2b").OrderByDescending(d => d.CreatedAt).FirstOrDefault();

            // تحليل التفاصيل السابقة
            ViewBag.PrevBuildingType = "";
            ViewBag.PrevArea         = "";
            ViewBag.PrevStructure    = "";
            ViewBag.PrevNotes        = "";
            if (last != null && !string.IsNullOrEmpty(last.Details))
            {
                foreach (var p in last.Details.Split('|'))
                {
                    var kv = p.Split(':', 2);
                    if (kv.Length != 2) continue;
                    switch (kv[0].Trim().ToLower())
                    {
                        case "building": ViewBag.PrevBuildingType = kv[1].Trim(); break;
                        case "area":     ViewBag.PrevArea         = kv[1].Trim(); break;
                        case "structure":ViewBag.PrevStructure    = kv[1].Trim(); break;
                    }
                }
                ViewBag.PrevNotes = last.Notes ?? "";
            }

            ViewBag.Asset = asset;
            return View();
        }

        [HttpPost][ValidateAntiForgeryToken][Authorize(Roles = "Engineering,SuperAdmin")]
        public async Task<IActionResult> Engineering(int assetId, string? buildingType, string? area, string? structure, string? notes, List<IFormFile>? drawings)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            if (drawings != null && drawings.Any())
            {
                var folder = Path.Combine(_env.WebRootPath, "uploads", "assets", assetId.ToString(), "engineering");
                Directory.CreateDirectory(folder);
                int c = 0;
                foreach (var f in drawings)
                {
                    var name = $"{DateTime.Now.Ticks}_{c++}{Path.GetExtension(f.FileName)}";
                    using var stream = new FileStream(Path.Combine(folder, name), FileMode.Create);
                    await f.CopyToAsync(stream);
                }
            }

            var details = $"Building:{buildingType}|Area:{area}|Structure:{structure}";
            var existing = asset.OptionalStageDetails
                .Where(d => d.StageKey == "2b").OrderByDescending(d => d.CreatedAt).FirstOrDefault();
            if (existing != null)
            {
                existing.Details = details; existing.Notes = notes; existing.CreatedAt = DateTime.Now;
            }
            else
            {
                asset.OptionalStageDetails.Add(new OptionalStageDetail
                { AssetId=assetId, StageKey="2b", Details=details, Notes=notes, CreatedAt=DateTime.Now });
            }

            var status = asset.OptionalStageStatuses.FirstOrDefault(o => o.StageKey == "2b");
            if (status == null)
                asset.OptionalStageStatuses.Add(new OptionalStageStatus { StageKey="2b", IsCompleted=true, CompletedAt=DateTime.Now });
            else { status.IsCompleted = true; status.CompletedAt = DateTime.Now; }

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();
            TempData["Success"] = "تم حفظ بيانات الهندسة بنجاح";
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }

        // ── Admin Affairs (2c) ─────────────────────────
        [HttpGet][Authorize(Roles = "AdminAffairs,SuperAdmin")]
        public async Task<IActionResult> AdminAffairs(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var last = asset.OptionalStageDetails
                .Where(d => d.StageKey == "2c").OrderByDescending(d => d.CreatedAt).FirstOrDefault();

            ViewBag.PrevElectricity = "";
            ViewBag.PrevWater       = "";
            ViewBag.PrevGas         = "";
            ViewBag.PrevOther       = "";
            ViewBag.PrevNotes       = "";

            if (last != null && !string.IsNullOrEmpty(last.Details))
            {
                var parts = last.Details.Split('|');
                foreach (var p in parts)
                {
                    var kv = p.Split(':', 2);
                    if (kv.Length != 2) continue;
                    switch (kv[0].Trim().ToLower())
                    {
                        case "electricity": ViewBag.PrevElectricity = kv[1].Trim(); break;
                        case "water":       ViewBag.PrevWater       = kv[1].Trim(); break;
                        case "gas":         ViewBag.PrevGas         = kv[1].Trim(); break;
                        case "other":       ViewBag.PrevOther       = kv[1].Trim(); break;
                    }
                }
                ViewBag.PrevNotes = last.Notes ?? "";
            }

            ViewBag.Asset = asset;
            return View();
        }

        [HttpPost][ValidateAntiForgeryToken][Authorize(Roles = "AdminAffairs,SuperAdmin")]
        public async Task<IActionResult> AdminAffairs(int assetId, string? electricity, string? water, string? gas, string? other, string? notes)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var details = $"Electricity:{electricity}|Water:{water}|Gas:{gas}|Other:{other}";
            var existing = asset.OptionalStageDetails
                .Where(d => d.StageKey == "2c").OrderByDescending(d => d.CreatedAt).FirstOrDefault();
            if (existing != null)
            {
                existing.Details = details; existing.Notes = notes; existing.CreatedAt = DateTime.Now;
            }
            else
            {
                asset.OptionalStageDetails.Add(new OptionalStageDetail
                { AssetId=assetId, StageKey="2c", Details=details, Notes=notes, CreatedAt=DateTime.Now });
            }

            var status = asset.OptionalStageStatuses.FirstOrDefault(o => o.StageKey == "2c");
            if (status == null)
                asset.OptionalStageStatuses.Add(new OptionalStageStatus { StageKey="2c", IsCompleted=true, CompletedAt=DateTime.Now });
            else { status.IsCompleted = true; status.CompletedAt = DateTime.Now; }

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();
            TempData["Success"] = "تم حفظ بيانات الشؤون الإدارية بنجاح";
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }
    }
}
