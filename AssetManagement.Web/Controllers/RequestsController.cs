using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class RequestsController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;
        private readonly UserManager<ApplicationUser> _um;

        public RequestsController(IAssetRepository repo, IStageHistoryRepository history,
            UserManager<ApplicationUser> um)
        { _repo = repo; _history = history; _um = um; }

        // â”€â”€ GET: طلب إيجار â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpGet]
        [Authorize(Roles = "Marketing,SuperAdmin")]
        public async Task<IActionResult> CreateRental(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            if (asset.CurrentStage != 4)
            {
                TempData["Error"] = "\u062a\u0645 \u062a\u0646\u0641\u064a\u0630 \u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621 \u0628\u0627\u0644\u0641\u0639\u0644 \u0623\u0648 \u0623\u0646 \u0627\u0644\u0623\u0635\u0644 \u0644\u064a\u0633 \u0641\u064a \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629 \u0644\u0647";
                return RedirectToAction("Details", "Asset", new { id = assetId });
            }

            var vm = new RentalRequestViewModel
            {
                AssetId          = assetId,
                AssetName        = asset.AssetName,
                AssetCode        = asset.AssetCode,
                AssetPropertyType= asset.PropertyType,
                StartDate        = DateTime.Today
            };
            ViewBag.Asset      = asset;
            ViewBag.Valuations = asset.AssetValuations;
            return View(vm);
        }

        // â”€â”€ POST: طلب إيجار â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpPost][ValidateAntiForgeryToken]
        [Authorize(Roles = "Marketing,SuperAdmin")]
        public async Task<IActionResult> CreateRental(RentalRequestViewModel vm)
        {
            if (!ModelState.IsValid)
            {
                var a = await _repo.GetByIdAsync(vm.AssetId);
                ViewBag.Asset      = a;
                ViewBag.Valuations = a?.AssetValuations;
                return View(vm);
            }
            var asset = await _repo.GetByIdAsync(vm.AssetId);
            if (asset == null) return NotFound();
            if (asset.CurrentStage != 4)
            {
                TempData["Error"] = "\u062a\u0645 \u062a\u0646\u0641\u064a\u0630 \u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621 \u0628\u0627\u0644\u0641\u0639\u0644 \u0623\u0648 \u0623\u0646 \u0627\u0644\u0623\u0635\u0644 \u0644\u064a\u0633 \u0641\u064a \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629 \u0644\u0647";
                return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
            }

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            int durationMonths = vm.ContractDurationYears * 12;

            var req = new RentalRequest
            {
                AssetId              = vm.AssetId,
                TenantName           = vm.TenantName,
                TenantPhone          = vm.TenantPhone,
                TenantEmail          = vm.TenantEmail,
                TenantIdNumber       = vm.TenantIdNumber,
                ProposedRent         = vm.ProposedRent,
                ContractDurationYears= vm.ContractDurationYears,
                RentDurationMonths   = durationMonths,
                GracePeriod          = vm.GracePeriod,
                SecurityDeposit      = vm.SecurityDeposit,
                AnnualIncrease       = vm.AnnualIncrease,
                StartDate            = vm.StartDate,
                EndDate              = vm.StartDate?.AddYears(vm.ContractDurationYears),
                Notes                = vm.Notes,
                Status               = RequestStatus.Pending,
                CreatedById          = userId,
                CreatedAt            = DateTime.Now
            };
            asset.RentalRequests.Add(req);

            // المرحلة 4 â†’ 5
            int from = asset.CurrentStage;
            asset.CurrentStage = 5;
            asset.UpdatedAt = DateTime.Now;
            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = 5;
                asset.AssetStage.StageName    = StageDefinition.GetName(5);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.AssignedToId = userId;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = vm.AssetId,
                FromStage     = from,
                ToStage       = 5,
                Action        = "RentalRequest",
                Notes = string.Format("\u0625\u064a\u062c\u0627\u0631: {0:N0} \u062c\u0646\u064a\u0647 / \u0645\u062f\u0629: {1} \u0633\u0646\u0629", vm.ProposedRent, vm.ContractDurationYears),
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            TempData["Success"] = "تم تقديم طلب الإيجار بنجاح";
            TempData["AutoPrint"] = vm.AssetId;
            return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
        }

        // â”€â”€ GET: طلب بيع â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpGet]
        [Authorize(Roles = "Marketing,SuperAdmin")]
        public async Task<IActionResult> CreateSale(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            if (asset.CurrentStage != 4)
            {
                TempData["Error"] = "\u062a\u0645 \u062a\u0646\u0641\u064a\u0630 \u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621 \u0628\u0627\u0644\u0641\u0639\u0644 \u0623\u0648 \u0623\u0646 \u0627\u0644\u0623\u0635\u0644 \u0644\u064a\u0633 \u0641\u064a \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629 \u0644\u0647";
                return RedirectToAction("Details", "Asset", new { id = assetId });
            }

            // السعر الافتراضي: متوسط التقييمات إن وجدت
            decimal defaultPrice = 0;
            if (asset.AssetValuations.Any())
                defaultPrice = asset.AssetValuations.Average(v => v.Value);

            var vm = new SaleRequestViewModel
            {
                AssetId          = assetId,
                AssetName        = asset.AssetName,
                AssetCode        = asset.AssetCode,
                AssetPropertyType= asset.PropertyType,
                OfferedPrice     = defaultPrice
            };
            ViewBag.Asset      = asset;
            ViewBag.Valuations = asset.AssetValuations;
            return View(vm);
        }

        // â”€â”€ POST: طلب بيع â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpPost][ValidateAntiForgeryToken]
        [Authorize(Roles = "Marketing,SuperAdmin")]
        public async Task<IActionResult> CreateSale(SaleRequestViewModel vm)
        {
            if (!ModelState.IsValid)
            {
                var a = await _repo.GetByIdAsync(vm.AssetId);
                ViewBag.Asset      = a;
                ViewBag.Valuations = a?.AssetValuations;
                return View(vm);
            }
            var asset = await _repo.GetByIdAsync(vm.AssetId);
            if (asset == null) return NotFound();
            if (asset.CurrentStage != 4)
            {
                TempData["Error"] = "\u062a\u0645 \u062a\u0646\u0641\u064a\u0630 \u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621 \u0628\u0627\u0644\u0641\u0639\u0644 \u0623\u0648 \u0623\u0646 \u0627\u0644\u0623\u0635\u0644 \u0644\u064a\u0633 \u0641\u064a \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629 \u0644\u0647";
                return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
            }

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var req = new SaleRequest
            {
                AssetId       = vm.AssetId,
                BuyerName     = vm.BuyerName,
                BuyerPhone    = vm.BuyerPhone,
                BuyerEmail    = vm.BuyerEmail,
                BuyerIdNumber = vm.BuyerIdNumber,
                OfferedPrice  = vm.OfferedPrice,
                PaymentMethod = vm.PaymentMethod,
                Notes         = vm.Notes,
                Status        = RequestStatus.Pending,
                CreatedById   = userId,
                CreatedAt     = DateTime.Now
            };
            asset.SaleRequests.Add(req);

            int from = asset.CurrentStage;
            asset.CurrentStage = 5;
            asset.UpdatedAt = DateTime.Now;
            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = 5;
                asset.AssetStage.StageName    = StageDefinition.GetName(5);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.AssignedToId = userId;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = vm.AssetId,
                FromStage     = from,
                ToStage       = 5,
                Action        = "SaleRequest",
                Notes = string.Format("\u0633\u0639\u0631 \u0627\u0644\u0628\u064a\u0639: {0:N0} \u062c\u0646\u064a\u0647", vm.OfferedPrice),
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            TempData["Success"] = "تم تقديم طلب البيع بنجاح";
            TempData["AutoPrint"] = vm.AssetId;

            return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
        }

        // â”€â”€ Print: طباعة الطلب مع التقييمات â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [HttpGet]
        [Authorize(Roles = "Marketing,Finance,SuperAdmin")]
        public async Task<IActionResult> PrintRequest(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            ViewBag.Asset      = asset;
            ViewBag.Valuations = asset.AssetValuations;
            ViewBag.Rental     = asset.RentalRequests.OrderByDescending(r => r.CreatedAt).FirstOrDefault();
            ViewBag.Sale       = asset.SaleRequests.OrderByDescending(r => r.CreatedAt).FirstOrDefault();
            return View();
        }
    }
}