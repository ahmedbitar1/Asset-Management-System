using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    /// <summary>
    /// المرحلة 8 â€” التسويق يرفع العقد الموقّع (PDF أو Word)
    /// </summary>
    [Authorize(Roles = "Legal,SuperAdmin")]
    public class MarketingUploadController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;
        private readonly IWebHostEnvironment _env;
        private readonly ApplicationDbContext _ctx;

        public MarketingUploadController(IAssetRepository repo, IStageHistoryRepository history,
            IWebHostEnvironment env, ApplicationDbContext ctx)
        { _repo = repo; _history = history; _env = env; _ctx = ctx; }

        // â”€â”€ GET: شاشة رفع العقد الموقّع â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpGet]
        public async Task<IActionResult> UploadSigned(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;

            // الملفات المرفوعة مسبقاً
            var existingFiles = _ctx.ContractFiles
                .Where(f => f.AssetId == assetId)
                .OrderByDescending(f => f.UploadedAt)
                .ToList();
            ViewBag.Files = existingFiles;

            return View();
        }

        // â”€â”€ POST: رفع الملف (8 â†’ 9) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> UploadSigned(int assetId, IFormFile file, string? notes)
        {
            if (file == null || file.Length == 0)
            {
                TempData["Error"] = "يرجى اختيار ملف PDF أو Word";
                return RedirectToAction("UploadSigned", new { assetId });
            }

            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            if (contract == null)
            {
                TempData["Error"] = "لا يوجد عقد مرتبط";
                return RedirectToAction("Details", "Asset", new { id = assetId });
            }

            // â”€â”€ التحقق من نوع الملف â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            var ext         = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed     = new[] { ".pdf", ".doc", ".docx" };
            if (!allowed.Contains(ext))
            {
                TempData["Error"] = "نوع الملف غير مسموح. يُقبل PDF و Word فقط";
                return RedirectToAction("UploadSigned", new { assetId });
            }

            string fileType = ext == ".pdf" ? "PDF" : "Word";

            // â”€â”€ حفظ الملف â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            var folder = Path.Combine(_env.WebRootPath, "uploads", "contracts", assetId.ToString());
            Directory.CreateDirectory(folder);

            var safeName = $"{DateTime.Now:yyyyMMdd_HHmmss}_{Path.GetFileName(file.FileName)}";
            var fullPath = Path.Combine(folder, safeName);
            using (var stream = new FileStream(fullPath, FileMode.Create))
                await file.CopyToAsync(stream);

            var relativePath = $"/uploads/contracts/{assetId}/{safeName}";

            // â”€â”€ حفظ السجل في ContractFiles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var contractFile = new ContractFile
            {
                ContractId   = contract.Id,
                AssetId      = assetId,
                FileName     = file.FileName,
                FilePath     = relativePath,
                FileType     = fileType,
                FileSize     = file.Length,
                ContentType  = file.ContentType,
                UploadedById = userId,
                UploadedAt   = DateTime.Now
            };
            _ctx.ContractFiles.Add(contractFile);

            // â”€â”€ الانتقال 8 → 9 (الخزنة) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            int from = asset.CurrentStage;
            asset.CurrentStage = 9;
            asset.UpdatedAt    = DateTime.Now;
            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = 9;
                asset.AssetStage.StageName    = StageDefinition.GetName(9);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.AssignedToId = userId;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = 9,
                Action        = "SignedContractUploaded",
                Notes         = $"تم رفع: {file.FileName} ({fileType}). {notes}",
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            await _ctx.SaveChangesAsync();

            TempData["Success"] = "تم رفع العقد الموقّع بنجاح وإرساله للخزنة";
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }
    }
}