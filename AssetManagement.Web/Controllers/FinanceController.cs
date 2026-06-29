using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    /// <summary>
    /// \u0627\u0644\u0645\u0631\u062d\u0644\u0629 7 \u2014 \u0627\u0644\u0645\u0627\u0644\u064a\u0629 \u062a\u0631\u0627\u062c\u0639 \u0627\u0644\u0639\u0642\u062f \u0648\u062a\u0639\u062a\u0645\u062f\u0647 \u0642\u0628\u0644 \u0627\u0644\u062a\u0648\u0642\u064a\u0639
    /// </summary>
    [Authorize(Roles = "Finance,SuperAdmin")]
    public class FinanceController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;

        public FinanceController(IAssetRepository repo, IStageHistoryRepository history)
        { _repo = repo; _history = history; }

        // ── GET: \u0645\u0631\u0627\u062c\u0639\u0629 \u0627\u0644\u0639\u0642\u062f ──────────────────────────────
        [HttpGet]
        public async Task<IActionResult> ReviewContract(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            if (contract == null)
            {
                TempData["Error"] = "\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0642\u062f \u0645\u0631\u062a\u0628\u0637 \u0628\u0647\u0630\u0627 \u0627\u0644\u0623\u0635\u0644";
                return RedirectToAction("Details", "Asset", new { id = assetId });
            }

            ViewBag.Asset       = asset;
            ViewBag.Contract    = contract;
            ViewBag.Valuations  = asset.AssetValuations;
            return View();
        }

        // ── POST: \u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0639\u0642\u062f (7 \u2192 8) ──────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> ApproveContract(int assetId, string? notes)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var userId   = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            if (contract != null)
                contract.Status = ContractStatus.Signed;

            int from = asset.CurrentStage;
            asset.CurrentStage = 8;
            asset.UpdatedAt    = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = 8;
                asset.AssetStage.StageName    = StageDefinition.GetName(8);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.AssignedToId = userId;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = 8,
                Action        = "ContractApproved",
                Notes         = notes ?? "\u0627\u0639\u062a\u0645\u062f\u062a \u0627\u0644\u0645\u0627\u0644\u064a\u0629 \u0627\u0644\u0639\u0642\u062f",
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            TempData["Success"] = "\u062a\u0645 \u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0639\u0642\u062f \u0648\u0625\u0631\u0633\u0627\u0644\u0647 \u0644\u0644\u062a\u0633\u0648\u064a\u0642 \u0644\u0631\u0641\u0639 \u0627\u0644\u0646\u0633\u062e\u0629 \u0627\u0644\u0645\u0648\u0642\u0651\u0639\u0629";
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }

        // ── POST: \u0631\u0641\u0636 \u0627\u0644\u0639\u0642\u062f \u2014 \u064a\u0631\u062c\u0639 \u0627\u0644\u0623\u0635\u0644 \u0644\u0645\u0631\u062d\u0644\u0629 4 \u0644\u0639\u0645\u0644 \u0637\u0644\u0628 \u062c\u062f\u064a\u062f ─────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> RejectContract(int assetId, string reason)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            int from   = asset.CurrentStage;

            // \u0627\u0644\u0639\u0642\u062f \u0627\u0644\u062d\u0627\u0644\u064a \u064a\u064f\u0639\u0644\u0651\u0645 \u0643\u0645\u0631\u0641\u0648\u0636
            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            if (contract != null)
                contract.Status = ContractStatus.Terminated;

            // \u0627\u0644\u0631\u062c\u0648\u0639 \u0644\u0645\u0631\u062d\u0644\u0629 4 \u0644\u0639\u0645\u0644 \u0637\u0644\u0628 \u062c\u062f\u064a\u062f \u0628\u062f\u0644\u0627\u064b \u0645\u0646 \u0627\u0644\u062a\u0648\u0642\u0641 \u0627\u0644\u0646\u0647\u0627\u0626\u064a
            asset.CurrentStage = 4;
            asset.Status        = AssetStatus.Pending;
            asset.UpdatedAt      = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber      = 4;
                asset.AssetStage.StageName        = StageDefinition.GetName(4);
                asset.AssetStage.Status           = StageStatus.InProgress;
                asset.AssetStage.StartedAt        = DateTime.Now;
                asset.AssetStage.CompletedAt      = null;
                asset.AssetStage.AssignedToId     = userId;
                asset.AssetStage.RejectionReason  = null;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = 4,
                Action        = "ContractRejected",
                Notes         = reason,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            TempData["Error"] = "\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0639\u0642\u062f \u0648\u0639\u0627\u062f \u0627\u0644\u0623\u0635\u0644 \u0644\u0645\u0631\u062d\u0644\u0629 4 \u0644\u0639\u0645\u0644 \u0637\u0644\u0628 \u062c\u062f\u064a\u062f: " + reason;
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }
    }
}
