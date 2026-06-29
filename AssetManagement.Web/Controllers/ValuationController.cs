using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    /// <summary>
    /// \u0635\u0641\u062d\u0629 \u0630\u0643\u064a\u0629: \u0643\u0644 \u062f\u0648\u0631 \u064a\u0634\u0648\u0641 \u0648\u064a\u062f\u062e\u0644 \u062a\u0642\u064a\u064a\u0645\u0647 \u0641\u0642\u0637.
    /// \u0644\u0645\u0627 \u064a\u0643\u062a\u0645\u0644 \u0627\u0644\u062b\u0644\u0627\u062b\u0629 \u2192 \u064a\u0646\u062a\u0642\u0644 \u0627\u0644\u0623\u0635\u0644 \u062a\u0644\u0642\u0627\u0626\u064a\u0627\u064b \u0644\u0645\u0631\u062d\u0644\u0629 4.
    /// </summary>
    [Authorize(Roles = "Marketing,Finance,Legal,SuperAdmin")]
    public class ValuationController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;

        public ValuationController(IAssetRepository repo, IStageHistoryRepository history)
        { _repo = repo; _history = history; }

        // \u2500\u2500 GET \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
        [HttpGet]
        public async Task<IActionResult> Evaluate(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            if (asset.CurrentStage != 3)
            {
                TempData["Error"] = "\u0647\u0630\u0627 \u0627\u0644\u0623\u0635\u0644 \u0644\u064a\u0633 \u0641\u064a \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0642\u064a\u064a\u0645 \u062d\u0627\u0644\u064a\u0627\u064b";
                return RedirectToAction("Details", "Asset", new { id = assetId });
            }

            var vm = new ValuationViewModel { AssetId = assetId };
            foreach (var v in asset.AssetValuations)
            {
                switch (v.EvaluationType)
                {
                    case EvaluationType.Marketing: vm.MarketingValue = v.Value; vm.MarketingComments = v.Comments; break;
                    case EvaluationType.Finance:   vm.FinanceValue   = v.Value; vm.FinanceComments   = v.Comments; break;
                    case EvaluationType.Expert:    vm.ExpertValue    = v.Value; vm.ExpertComments    = v.Comments; break;
                }
            }
            vm.DispositionType = asset.AssetType;

            ViewBag.Asset           = asset;
            ViewBag.UserRole        = GetValuationRole(User);
            ViewBag.HasMarketing    = asset.AssetValuations.Any(v => v.EvaluationType == EvaluationType.Marketing);
            ViewBag.HasFinance      = asset.AssetValuations.Any(v => v.EvaluationType == EvaluationType.Finance);
            ViewBag.HasExpert       = asset.AssetValuations.Any(v => v.EvaluationType == EvaluationType.Expert);
            ViewBag.AllComplete     = (bool)ViewBag.HasMarketing && (bool)ViewBag.HasFinance && (bool)ViewBag.HasExpert;
            return View(vm);
        }

        // \u2500\u2500 POST \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Evaluate(ValuationViewModel vm)
        {
            var asset = await _repo.GetByIdAsync(vm.AssetId);
            if (asset == null) return NotFound();

            var userId   = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var userRole = GetValuationRole(User);
            bool isSuperAdmin = User.IsInRole("SuperAdmin");

            // \u062d\u0641\u0638 \u062a\u0642\u064a\u064a\u0645 \u0627\u0644\u062f\u0648\u0631 \u0627\u0644\u062d\u0627\u0644\u064a \u0641\u0642\u0637 (\u0623\u0648 \u0643\u0644\u0647\u0627 \u0644\u0648 SuperAdmin)
            if (userRole == "Marketing" || isSuperAdmin)
                UpsertValuation(asset, EvaluationType.Marketing, vm.MarketingValue, vm.MarketingComments, userId);

            if (userRole == "Finance" || isSuperAdmin)
                UpsertValuation(asset, EvaluationType.Finance, vm.FinanceValue, vm.FinanceComments, userId);

            if (userRole == "Legal" || isSuperAdmin)
                UpsertValuation(asset, EvaluationType.Expert, vm.ExpertValue, vm.ExpertComments, userId);

            // \u062a\u062d\u062f\u064a\u062b \u0646\u0648\u0639 \u0627\u0644\u062a\u0635\u0631\u0641 \u0644\u0648 SuperAdmin
            if (isSuperAdmin)
                asset.AssetType = vm.DispositionType;

            asset.UpdatedAt = DateTime.Now;

            // \u062a\u062d\u0642\u0642 \u0647\u0644 \u0627\u0643\u062a\u0645\u0644\u062a \u0627\u0644\u062b\u0644\u0627\u062b\u0629 \u062a\u0642\u064a\u064a\u0645\u0627\u062a
            bool hasMarketing = asset.AssetValuations.Any(v => v.EvaluationType == EvaluationType.Marketing);
            bool hasFinance   = asset.AssetValuations.Any(v => v.EvaluationType == EvaluationType.Finance);
            bool hasExpert    = asset.AssetValuations.Any(v => v.EvaluationType == EvaluationType.Expert);
            bool allDone      = hasMarketing && hasFinance && hasExpert;

            int fromStage = asset.CurrentStage;

            if (allDone)
            {
                // \u062c\u0645\u064a\u0639 \u0627\u0644\u062a\u0642\u064a\u064a\u0645\u0627\u062a \u0645\u0643\u062a\u0645\u0644\u0629 \u2192 \u0627\u0646\u062a\u0642\u0644 \u0644\u0645\u0631\u062d\u0644\u0629 4
                asset.CurrentStage = 4;
                if (asset.AssetStage != null)
                {
                    asset.AssetStage.StageNumber  = 4;
                    asset.AssetStage.StageName    = StageDefinition.GetName(4);
                    asset.AssetStage.Status       = AssetManagement.Domain.Enums.StageStatus.InProgress;
                    asset.AssetStage.StartedAt    = DateTime.Now;
                    asset.AssetStage.AssignedToId = userId;
                }

                var mkt = asset.AssetValuations.FirstOrDefault(v => v.EvaluationType == EvaluationType.Marketing);
                var fin = asset.AssetValuations.FirstOrDefault(v => v.EvaluationType == EvaluationType.Finance);
                var exp = asset.AssetValuations.FirstOrDefault(v => v.EvaluationType == EvaluationType.Expert);

                await _repo.UpdateAsync(asset);
                await _history.AddAsync(new StageHistory
                {
                    AssetId       = vm.AssetId,
                    FromStage     = fromStage,
                    ToStage       = 4,
                    Action        = "Valued",
                    Notes         = string.Format("\u062a\u0633\u0648\u064a\u0642: {0:N0} | \u0645\u0627\u0644\u064a\u0629: {1:N0} | \u062e\u0628\u0631\u0627\u0621: {2:N0}",
                                    mkt?.Value ?? 0, fin?.Value ?? 0, exp?.Value ?? 0),
                    PerformedById = userId,
                    PerformedAt   = DateTime.Now
                });
                await _repo.SaveChangesAsync();

                TempData["Success"] = "\u062a\u0645 \u0627\u0643\u062a\u0645\u0627\u0644 \u0627\u0644\u062a\u0642\u064a\u064a\u0645\u0627\u062a \u0627\u0644\u062b\u0644\u0627\u062b\u0629 \u2014 \u0627\u0646\u062a\u0642\u0644 \u0627\u0644\u0623\u0635\u0644 \u0644\u0645\u0631\u062d\u0644\u0629 \u0637\u0644\u0628 \u0627\u0644\u0628\u064a\u0639 / \u0627\u0644\u0625\u064a\u062c\u0627\u0631";
            }
            else
            {
                await _repo.UpdateAsync(asset);
                await _repo.SaveChangesAsync();
                int done = (hasMarketing ? 1 : 0) + (hasFinance ? 1 : 0) + (hasExpert ? 1 : 0);
                TempData["Success"] = $"\u062a\u0645 \u062d\u0641\u0638 \u062a\u0642\u064a\u064a\u0645\u0643 ({done}/3 \u0645\u0643\u062a\u0645\u0644\u0629) \u2014 \u064a\u0646\u062a\u0638\u0631 \u062a\u0642\u064a\u064a\u0645\u0627\u062a \u0627\u0644\u0628\u0627\u0642\u064a";
            }

            return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
        }

        private static string GetValuationRole(System.Security.Claims.ClaimsPrincipal user)
        {
            if (user.IsInRole("Marketing")) return "Marketing";
            if (user.IsInRole("Finance"))   return "Finance";
            if (user.IsInRole("Legal"))     return "Legal";
            return "SuperAdmin";
        }

        private static void UpsertValuation(Asset asset, EvaluationType type,
            decimal value, string? comments, string userId)
        {
            if (value <= 0) return; // \u0644\u0627 \u062a\u062d\u0641\u0638 \u0642\u064a\u0645\u0629 \u0641\u0627\u0631\u063a\u0629
            var existing = asset.AssetValuations.FirstOrDefault(v => v.EvaluationType == type);
            if (existing != null)
            {
                existing.Value = value; existing.Comments = comments;
                existing.EvaluationDate = DateTime.Now; existing.UserId = userId;
            }
            else
            {
                asset.AssetValuations.Add(new AssetValuation
                {
                    AssetId = asset.Id, EvaluationType = type,
                    Value = value, Comments = comments,
                    EvaluationDate = DateTime.Now, UserId = userId
                });
            }
        }
    }
}
