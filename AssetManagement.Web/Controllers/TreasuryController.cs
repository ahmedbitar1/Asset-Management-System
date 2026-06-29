using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    [Authorize(Roles = "Treasury,SuperAdmin")]
    public class TreasuryController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;

        public TreasuryController(IAssetRepository repo, IStageHistoryRepository history)
        { _repo = repo; _history = history; }

        // â”€â”€ GET: تحصيل الخزنة (المرحلة 9) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpGet]
        public async Task<IActionResult> Collect(int assetId)
        {
            var asset    = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            var vm = new TreasuryViewModel
            {
                AssetId        = assetId,
                AssetName      = asset.AssetName,
                AssetCode      = asset.AssetCode,
                PartyName      = contract?.PartyName,
                Amount         = contract?.Amount > 0
                                 ? contract.Amount
                                 : (asset.CurrentValue ?? asset.PurchasePrice ?? 0),
                ContractType   = contract?.ContractType.ToString() ?? "Sale",
                CollectionDate = DateTime.Today
            };
            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;
            return View(vm);
        }

        // â”€â”€ POST: تسجيل التحصيل (9 â†’ 10 مكتمل) ─â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Collect(TreasuryViewModel vm)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage);
                TempData["Error"] = "خطأ في التحقق: " + string.Join("، ", errors);
                return View(vm);
            }

            var asset  = await _repo.GetByIdAsync(vm.AssetId);
            if (asset == null) return NotFound();

            var userId   = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();

            // تحديث حالة العقد والأصل
            if (contract != null)
            {
                contract.Status = ContractStatus.Active;
                asset.Status    = contract.ContractType == ContractType.Sale
                                  ? AssetStatus.Sold
                                  : AssetStatus.Rented;
            }
            else
            {
                asset.Status = AssetStatus.Active;
            }

            // 9 â†’ 10 (مكتمل)
            int from = asset.CurrentStage;
            asset.CurrentStage = 10;
            asset.UpdatedAt    = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber = 10;
                asset.AssetStage.StageName   = StageDefinition.GetName(10);
                asset.AssetStage.Status      = StageStatus.Completed;
                asset.AssetStage.CompletedAt = DateTime.Now;
            }

            await _repo.UpdateAsync(asset);
            var note = string.Format("تم تحصيل {0:N0} جنيه — {1} â€” إيصال: {2}",
                vm.Amount, vm.PaymentMethod, vm.ReceiptNumber ?? "â€”");
            await _history.AddAsync(new StageHistory
            {
                AssetId       = vm.AssetId,
                FromStage     = from,
                ToStage       = 10,
                Action        = "Collected",
                Notes         = note,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            TempData["Success"] = "تم تسجيل التحصيل واكتمل سير العمل للأصل";
            return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
        }
    }
}