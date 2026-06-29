$base = "$env:USERPROFILE\Desktop\AssetManagement"
$web  = "$base\AssetManagement.Web"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host "=== Stage 4: Controllers ===" -ForegroundColor Cyan

# ── 1. AssetController.cs ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$web\Controllers\AssetController.cs", @'
using AssetManagement.Application.Interfaces;
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
    public class AssetController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IWorkflowService _workflow;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IWebHostEnvironment _env;

        public AssetController(IAssetRepository repo, IWorkflowService workflow,
            UserManager<ApplicationUser> userManager, IWebHostEnvironment env)
        {
            _repo = repo; _workflow = workflow;
            _userManager = userManager; _env = env;
        }

        // ── Index ────────────────────────────────────────────────
        public async Task<IActionResult> Index(string? search, string? status, int? stage)
        {
            var user  = await _userManager.GetUserAsync(User);
            var roles = await _userManager.GetRolesAsync(user!);

            IEnumerable<Asset> assets = roles.Contains("SuperAdmin")
                ? await _repo.GetAllAsync()
                : await _workflow.GetAssetsByRoleAsync(user!.Id, roles);

            if (!string.IsNullOrWhiteSpace(search))
                assets = assets.Where(a =>
                    a.AssetName.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    a.AssetCode.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    (a.City ?? "").Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    (a.Location ?? "").Contains(search, StringComparison.OrdinalIgnoreCase));

            if (!string.IsNullOrWhiteSpace(status) &&
                Enum.TryParse<AssetStatus>(status, out var st))
                assets = assets.Where(a => a.Status == st);

            if (stage.HasValue)
                assets = assets.Where(a => a.CurrentStage == stage.Value);

            ViewBag.Search       = search;
            ViewBag.Status       = status;
            ViewBag.Stage        = stage;
            ViewBag.IsSuperAdmin = roles.Contains("SuperAdmin");

            var cards = assets.Select(a => new AssetCardViewModel
            {
                Id            = a.Id,
                AssetCode     = a.AssetCode,
                AssetName     = a.AssetName,
                Location      = a.Location,
                City          = a.City,
                PropertyType  = a.PropertyType,
                CurrentStage  = a.CurrentStage,
                Status        = a.Status,
                AssetType     = a.AssetType,
                PurchasePrice = a.PurchasePrice,
                Area          = a.Area,
                CreatedAt     = a.CreatedAt
            }).OrderBy(a => a.AssetCode).ToList();

            return View(cards);
        }

        // ── Full Details ─────────────────────────────────────────
        public async Task<IActionResult> FullDetails(int id)
        {
            var asset = await _workflow.GetAssetDetailAsync(id);
            if (asset == null) return NotFound();
            var user  = await _userManager.GetUserAsync(User);
            var roles = user != null ? await _userManager.GetRolesAsync(user) : new List<string>();
            ViewBag.Asset = asset;
            ViewBag.Roles = roles;
            return View();
        }

        // ── Details ──────────────────────────────────────────────
        public async Task<IActionResult> Details(int id)
        {
            var asset = await _workflow.GetAssetDetailAsync(id);
            if (asset == null) return NotFound();

            var user  = await _userManager.GetUserAsync(User);
            var roles = await _userManager.GetRolesAsync(user!);

            bool isSuperAdmin = roles.Contains("SuperAdmin");
            bool canAct = isSuperAdmin ||
                (StageDefinition.StageRoles.TryGetValue(asset.CurrentStage, out var sr)
                 && sr.Any(r => roles.Contains(r)));

            // مراحل الرفض في Workflow الجديد: 5 (الاعتماد النهائي) و 7 (المالية)
            bool canReject = (canAct || isSuperAdmin)
                && asset.CurrentStage is 5 or 7
                && asset.Status != AssetStatus.Rejected;

            var vm = new AssetDetailViewModel
            {
                Asset      = asset,
                CanAdvance = canAct
                             && asset.Status != AssetStatus.Rejected
                             && !StageDefinition.IsLastStage(asset.CurrentStage)
                             && asset.CurrentStage != 3   // 3 يُتحكم فيه من ValuationController
                             && asset.CurrentStage != 4   // 4 يُتحكم فيه من RequestsController
                             && asset.CurrentStage != 6,  // 6 يُتحكم فيه من ContractsController
                CanReject  = canReject,
                IsStage2   = asset.CurrentStage == 2,
                IsStage3   = asset.CurrentStage == 3,
                IsStage4   = asset.CurrentStage == 4,

                History = asset.StageHistories
                    .Select(h => new StageHistoryItem
                    {
                        FromStage   = h.FromStage,
                        ToStage     = h.ToStage,
                        Action      = h.Action,
                        Notes       = h.Notes,
                        PerformedBy = h.PerformedById,
                        PerformedAt = h.PerformedAt
                    }).ToList(),

                OptionalStages = new List<OptionalStageInfo>
                {
                    new() { StageKey="2a", StageName="التسويق",
                            IsCompleted=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2a"&&o.IsCompleted),
                            IsRequired=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2a"&&o.IsRequired),
                            RoleNeeded="Marketing" },
                    new() { StageKey="2b", StageName="الهندسة",
                            IsCompleted=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2b"&&o.IsCompleted),
                            IsRequired=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2b"&&o.IsRequired),
                            RoleNeeded="Engineering" },
                    new() { StageKey="2c", StageName="الشؤون الإدارية",
                            IsCompleted=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2c"&&o.IsCompleted),
                            IsRequired=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2c"&&o.IsRequired),
                            RoleNeeded="AdminAffairs" },
                },

                Valuations = asset.AssetValuations.Select(v => new ValuationItem
                {
                    Id             = v.Id,
                    EvaluationType = v.EvaluationType,
                    Value          = v.Value,
                    Comments       = v.Comments,
                    EvaluationDate = v.EvaluationDate,
                    UserId         = v.UserId
                }).ToList()
            };
            vm.AllOptionalDone = vm.OptionalStages.Where(o => o.IsRequired).All(o => o.IsCompleted);
            ViewBag.Roles = roles;
            return View(vm);
        }

        // ── Advance ──────────────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Advance(int id, string? notes)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var (ok, msg) = await _workflow.AdvanceStageAsync(id, userId, notes);
            TempData[ok ? "Success" : "Error"] = msg;
            return RedirectToAction("Details", new { id });
        }

        // ── Reject ───────────────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Reject(int id, string reason)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var (ok, msg) = await _workflow.RejectStageAsync(id, userId, reason);
            TempData[ok ? "Success" : "Error"] = msg;
            return RedirectToAction("Details", new { id });
        }

        // ── Complete Optional Stage ───────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> CompleteOptional(int id, string stageKey)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var (ok, msg) = await _workflow.CompleteOptionalStageAsync(id, stageKey, userId);
            TempData[ok ? "Success" : "Error"] = msg;
            return RedirectToAction("Details", new { id });
        }

        // ── Delete ───────────────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> Delete(int id)
        {
            var asset = await _repo.GetByIdAsync(id);
            if (asset != null)
            {
                var folder = Path.Combine(_env.WebRootPath, "uploads", "assets", id.ToString());
                if (Directory.Exists(folder)) Directory.Delete(folder, true);
                _repo.Remove(asset);
                await _repo.SaveChangesAsync();
                TempData["Success"] = "تم حذف الأصل بنجاح";
            }
            return RedirectToAction(nameof(Index));
        }
    }
}
'@, $utf8)
Write-Host "OK: AssetController.cs" -ForegroundColor Green

# ── 2. ValuationController.cs ─────────────────────────────────────
[System.IO.File]::WriteAllText("$web\Controllers\ValuationController.cs", @'
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    [Authorize(Roles = "Valuator,SuperAdmin")]
    public class ValuationController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;

        public ValuationController(IAssetRepository repo, IStageHistoryRepository history)
        { _repo = repo; _history = history; }

        // ── GET: شاشة التقييم (المرحلة 3) ──────────────────────
        [HttpGet]
        public async Task<IActionResult> Evaluate(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            if (asset.CurrentStage != 3)
            {
                TempData["Error"] = "هذا الأصل ليس في مرحلة التقييم حالياً";
                return RedirectToAction("Details", "Asset", new { id = assetId });
            }

            // تحميل أي تقييمات موجودة مسبقاً
            var vm = new ValuationViewModel { AssetId = assetId };
            foreach (var v in asset.AssetValuations)
            {
                switch (v.EvaluationType)
                {
                    case EvaluationType.Marketing:
                        vm.MarketingValue    = v.Value;
                        vm.MarketingComments = v.Comments;
                        break;
                    case EvaluationType.Finance:
                        vm.FinanceValue    = v.Value;
                        vm.FinanceComments = v.Comments;
                        break;
                    case EvaluationType.Expert:
                        vm.ExpertValue    = v.Value;
                        vm.ExpertComments = v.Comments;
                        break;
                }
            }
            vm.DispositionType = asset.AssetType;
            ViewBag.Asset = asset;
            return View(vm);
        }

        // ── POST: حفظ التقييمات الثلاثة + نوع التصرف ───────────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Evaluate(ValuationViewModel vm)
        {
            if (!ModelState.IsValid)
            {
                var asset2 = await _repo.GetByIdAsync(vm.AssetId);
                ViewBag.Asset = asset2;
                return View(vm);
            }

            var asset = await _repo.GetByIdAsync(vm.AssetId);
            if (asset == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;

            // ── حفظ / تحديث التقييمات الثلاثة ──────────────────
            UpsertValuation(asset, EvaluationType.Marketing, vm.MarketingValue, vm.MarketingComments, userId);
            UpsertValuation(asset, EvaluationType.Finance,   vm.FinanceValue,   vm.FinanceComments,   userId);
            UpsertValuation(asset, EvaluationType.Expert,    vm.ExpertValue,    vm.ExpertComments,    userId);

            // ── تحديث نوع التصرف ────────────────────────────────
            asset.AssetType  = vm.DispositionType;
            asset.UpdatedAt  = DateTime.Now;

            // ── الانتقال من مرحلة 3 إلى 4 ──────────────────────
            int fromStage = asset.CurrentStage;
            asset.CurrentStage = 4;
            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = 4;
                asset.AssetStage.StageName    = StageDefinition.GetName(4);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.AssignedToId = userId;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = vm.AssetId,
                FromStage     = fromStage,
                ToStage       = 4,
                Action        = "Valued",
                Notes         = string.Format(
                    "تسويق: {0:N0} | مالية: {1:N0} | خبراء: {2:N0} | نوع التصرف: {3}",
                    vm.MarketingValue, vm.FinanceValue, vm.ExpertValue, vm.DispositionType),
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            TempData["Success"] = "تم حفظ التقييمات وانتقل الأصل إلى مرحلة الطلب";
            return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
        }

        // ── Helper: أضف أو حدّث تقييم ──────────────────────────
        private static void UpsertValuation(Asset asset, EvaluationType type,
            decimal value, string? comments, string userId)
        {
            var existing = asset.AssetValuations
                .FirstOrDefault(v => v.EvaluationType == type);
            if (existing != null)
            {
                existing.Value          = value;
                existing.Comments       = comments;
                existing.EvaluationDate = DateTime.Now;
                existing.UserId         = userId;
            }
            else
            {
                asset.AssetValuations.Add(new AssetValuation
                {
                    AssetId        = asset.Id,
                    EvaluationType = type,
                    Value          = value,
                    Comments       = comments,
                    EvaluationDate = DateTime.Now,
                    UserId         = userId
                });
            }
        }
    }
}
'@, $utf8)
Write-Host "OK: ValuationController.cs" -ForegroundColor Green

# ── 3. RequestsController.cs ──────────────────────────────────────
[System.IO.File]::WriteAllText("$web\Controllers\RequestsController.cs", @'
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
    [Authorize(Roles = "Sales,Marketing,SuperAdmin")]
    public class RequestsController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;
        private readonly UserManager<ApplicationUser> _um;

        public RequestsController(IAssetRepository repo, IStageHistoryRepository history,
            UserManager<ApplicationUser> um)
        { _repo = repo; _history = history; _um = um; }

        // ── GET: طلب إيجار ───────────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> CreateRental(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

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

        // ── POST: طلب إيجار ──────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
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

            // المرحلة 4 → 5
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
                Notes         = string.Format("إيجار: {0:N0} جنيه / مدة: {1} سنة",
                                vm.ProposedRent, vm.ContractDurationYears),
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            TempData["Success"] = "تم تقديم طلب الإيجار بنجاح";
            return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
        }

        // ── GET: طلب بيع ─────────────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> CreateSale(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

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

        // ── POST: طلب بيع ────────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
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
                Notes         = string.Format("سعر: {0:N0} جنيه", vm.OfferedPrice),
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            TempData["Success"] = "تم تقديم طلب البيع بنجاح";
            return RedirectToAction("Details", "Asset", new { id = vm.AssetId });
        }

        // ── Print: طباعة الطلب مع التقييمات ─────────────────────
        [HttpGet]
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
'@, $utf8)
Write-Host "OK: RequestsController.cs" -ForegroundColor Green

# ── 4. ContractsController.cs ─────────────────────────────────────
[System.IO.File]::WriteAllText("$web\Controllers\ContractsController.cs", @'
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using AssetManagement.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class ContractsController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;
        private readonly UserManager<ApplicationUser> _um;
        private readonly IWebHostEnvironment _env;

        public ContractsController(IAssetRepository repo, IStageHistoryRepository history,
            UserManager<ApplicationUser> um, IWebHostEnvironment env)
        { _repo = repo; _history = history; _um = um; _env = env; }

        // ── Archive ───────────────────────────────────────────────
        [Authorize(Roles = "Legal,SuperAdmin,Marketing,Finance,Treasury")]
        public async Task<IActionResult> Archive()
        {
            var allAssets = await _repo.GetAllAsync();
            ViewBag.AllAssets = allAssets.Where(a => a.Contracts.Any()).ToList();
            return View();
        }

        // ── Details ───────────────────────────────────────────────
        [Authorize(Roles = "Legal,SuperAdmin,Marketing,Finance,Treasury")]
        public async Task<IActionResult> Details(int contractId)
        {
            var all   = await _repo.GetAllAsync();
            var asset = all.FirstOrDefault(a => a.Contracts.Any(c => c.Id == contractId));
            if (asset == null) return NotFound();

            var contract = asset.Contracts.First(c => c.Id == contractId);
            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;
            return View();
        }

        // ── Create GET (مرحلة 6) ─────────────────────────────────
        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpGet]
        public async Task<IActionResult> Create(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var rentalReq = asset.RentalRequests.OrderByDescending(r => r.CreatedAt).FirstOrDefault();
            var saleReq   = asset.SaleRequests.OrderByDescending(r => r.CreatedAt).FirstOrDefault();

            var vm = new ContractViewModel
            {
                AssetId       = assetId,
                AssetName     = asset.AssetName,
                AssetCode     = asset.AssetCode,
                AssetLocation = $"{asset.City} - {asset.Location}",
                AssetArea     = asset.Area,
                AreaUnit      = asset.AreaUnit,
            };

            // أولوية الإيجار على البيع لو AssetType = Both
            if (rentalReq != null)
            {
                vm.RentalRequestId    = rentalReq.Id;
                vm.ContractType       = "Rent";
                vm.PartyName          = rentalReq.TenantName;
                vm.PartyPhone         = rentalReq.TenantPhone;
                vm.PartyIdNumber      = rentalReq.TenantIdNumber;
                vm.Amount             = rentalReq.ProposedRent;
                vm.StartDate          = rentalReq.StartDate;
                vm.EndDate            = rentalReq.EndDate;
                // حقول الإيجار الجديدة — تُملأ تلقائياً
                vm.GracePeriod          = rentalReq.GracePeriod;
                vm.SecurityDeposit      = rentalReq.SecurityDeposit;
                vm.AnnualIncrease       = rentalReq.AnnualIncrease;
                vm.ContractDurationYears= rentalReq.ContractDurationYears;
            }
            else if (saleReq != null)
            {
                vm.SaleRequestId = saleReq.Id;
                vm.ContractType  = "Sale";
                vm.PartyName     = saleReq.BuyerName;
                vm.PartyPhone    = saleReq.BuyerPhone;
                vm.PartyIdNumber = saleReq.BuyerIdNumber;
                vm.Amount        = saleReq.OfferedPrice;
            }
            ViewBag.Asset = asset;
            return View(vm);
        }

        // ── Create POST (مرحلة 6 → 7) ────────────────────────────
        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ContractViewModel vm)
        {
            var asset = await _repo.GetByIdAsync(vm.AssetId);
            if (asset == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            int num    = asset.Contracts.Count + 1;
            string contractNo = asset.AssetCode + "-C" + num.ToString("D2");

            var contract = new Contract
            {
                AssetId         = vm.AssetId,
                ContractType    = vm.ContractType == "Rent" ? ContractType.Rent : ContractType.Sale,
                ContractNumber  = contractNo,
                PartyName       = vm.PartyName,
                PartyPhone      = vm.PartyPhone,
                PartyIdNumber   = vm.PartyIdNumber,
                Amount          = vm.Amount,
                StartDate       = vm.StartDate,
                EndDate         = vm.ContractType == "Sale" ? null : vm.EndDate,
                RentalRequestId = vm.RentalRequestId,
                SaleRequestId   = vm.SaleRequestId,
                Status          = ContractStatus.Draft,
                GeneratedById   = userId,
                CreatedAt       = DateTime.Now
            };

            asset.Contracts.Add(contract);

            // مرحلة 6 → 7 (المالية تراجع العقد)
            int from = asset.CurrentStage;
            asset.CurrentStage = 7;
            asset.UpdatedAt = DateTime.Now;
            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = 7;
                asset.AssetStage.StageName    = StageDefinition.GetName(7);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.AssignedToId = userId;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = vm.AssetId,
                FromStage     = from,
                ToStage       = 7,
                Action        = "ContractCreated",
                Notes         = contractNo,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            var savedContract = asset.Contracts.OrderByDescending(c => c.CreatedAt).First();
            TempData["Success"] = $"تم إنشاء العقد {contractNo} وإرساله للمراجعة المالية";
            return RedirectToAction("Details", new { contractId = savedContract.Id });
        }

        // ── Download Word ─────────────────────────────────────────
        public async Task<IActionResult> DownloadWord(int contractId)
        {
            var all   = await _repo.GetAllAsync();
            var asset = all.FirstOrDefault(a => a.Contracts.Any(c => c.Id == contractId));
            if (asset == null) return NotFound();
            var contract = asset.Contracts.First(c => c.Id == contractId);

            bool isSale = contract.ContractType == ContractType.Sale;
            bool isComm = !isSale && (asset.PropertyType ?? "").Contains("تجار") ||
                          (asset.AssetName.Contains("محل") || asset.AssetName.Contains("تجار"));

            string tplName = isSale ? "sell.docx"
                           : isComm ? "rent_commercial.docx"
                                    : "rent.docx";

            string tplPath = Path.Combine(_env.WebRootPath, "templates", tplName);
            if (!System.IO.File.Exists(tplPath))
                return BadRequest($"القالب غير موجود: {tplName}");

            var data = BuildContractData(asset, contract);
            var svc  = new WordContractService();
            byte[] bytes = svc.FillTemplate(tplPath, data);

            return File(bytes,
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                contract.ContractNumber + ".docx");
        }

        // ── Print ─────────────────────────────────────────────────
        public async Task<IActionResult> Print(int contractId)
        {
            var all   = await _repo.GetAllAsync();
            var asset = all.FirstOrDefault(a => a.Contracts.Any(c => c.Id == contractId));
            if (asset == null) return NotFound();
            var contract = asset.Contracts.First(c => c.Id == contractId);
            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;
            return View();
        }

        // ── Build Contract Data (Word placeholders) ───────────────
        private static Dictionary<string, string> BuildContractData(Asset asset, Contract contract)
        {
            // استخراج بيانات الإيجار من آخر طلب
            var lastRental = asset.RentalRequests
                .OrderByDescending(r => r.CreatedAt).FirstOrDefault();

            string securityDeposit = lastRental?.SecurityDeposit.HasValue == true
                ? lastRental.SecurityDeposit.Value.ToString("N0")
                : (contract.ContractType == ContractType.Sale
                    ? ((long)(contract.Amount * 0.05m)).ToString("N0")
                    : contract.Amount.ToString("N0"));

            string annualIncrease = lastRental?.AnnualIncrease.HasValue == true
                ? lastRental.AnnualIncrease.Value.ToString("N0") + "%"
                : "";

            string gracePeriod = lastRental?.GracePeriod.HasValue == true
                ? lastRental.GracePeriod.Value.ToString("N0") + " شهر"
                : "";

            string duration = lastRental?.ContractDurationYears.HasValue == true
                ? lastRental.ContractDurationYears.Value.ToString() + " سنة"
                : (contract.StartDate.HasValue && contract.EndDate.HasValue
                    ? ((int)((contract.EndDate.Value - contract.StartDate.Value).TotalDays / 365)).ToString() + " سنة"
                    : "");

            return new Dictionary<string, string>
            {
                ["CONTRACT_NUMBER"] = "",
                ["DEED_NUMBER"]     = "",
                ["PLOT_NUMBER"]     = "",
                ["CONTRACT_DATE"]   = DateTime.Now.ToString("yyyy/MM/dd"),
                ["PARTY_NAME"]      = contract.PartyName     ?? "",
                ["PARTY_ID"]        = contract.PartyIdNumber ?? "",
                ["PARTY_PHONE"]     = contract.PartyPhone    ?? "",
                ["ASSET_NAME"]      = asset.AssetName        ?? "",
                ["ASSET_LOCATION"]  = asset.Location         ?? "",
                ["ASSET_CITY"]      = asset.City             ?? "",
                ["ASSET_AREA"]      = asset.Area.HasValue
                                      ? asset.Area.Value.ToString("N0") + " " + asset.AreaUnit
                                      : "",
                ["AMOUNT"]          = contract.Amount.ToString("N0"),
                ["AMOUNT_TEXT"]     = "",
                ["START_DATE"]      = contract.StartDate?.ToString("yyyy/MM/dd") ?? "",
                ["END_DATE"]        = contract.EndDate?.ToString("yyyy/MM/dd")   ?? "",
                ["SECURITY_DEPOSIT"]= securityDeposit,
                ["ANNUAL_INCREASE"] = annualIncrease,
                ["GRACE_PERIOD"]    = gracePeriod,
                ["DURATION"]        = duration,
            };
        }
    }
}
'@, $utf8)
Write-Host "OK: ContractsController.cs" -ForegroundColor Green

# ── 5. FinanceController.cs (NEW — المرحلة 7) ────────────────────
[System.IO.File]::WriteAllText("$web\Controllers\FinanceController.cs", @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    /// <summary>
    /// المرحلة 7 — المالية تراجع العقد وتعتمده قبل التوقيع
    /// </summary>
    [Authorize(Roles = "Finance,SuperAdmin")]
    public class FinanceController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;

        public FinanceController(IAssetRepository repo, IStageHistoryRepository history)
        { _repo = repo; _history = history; }

        // ── GET: مراجعة العقد ────────────────────────────────────
        [HttpGet]
        public async Task<IActionResult> ReviewContract(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            if (contract == null)
            {
                TempData["Error"] = "لا يوجد عقد مرتبط بهذا الأصل";
                return RedirectToAction("Details", "Asset", new { id = assetId });
            }

            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;
            ViewBag.Valuations = asset.AssetValuations;
            return View();
        }

        // ── POST: اعتماد العقد (7 → 8) ──────────────────────────
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
                Notes         = notes ?? "اعتمدت المالية العقد",
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            TempData["Success"] = "تم اعتماد العقد وإرساله للتسويق لرفع النسخة الموقّعة";
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }

        // ── POST: رفض العقد ──────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> RejectContract(int assetId, string reason)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            asset.Status    = AssetStatus.Rejected;
            asset.UpdatedAt = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.Status          = StageStatus.Rejected;
                asset.AssetStage.RejectionReason = reason;
                asset.AssetStage.CompletedAt     = DateTime.Now;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = asset.CurrentStage,
                ToStage       = asset.CurrentStage,
                Action        = "ContractRejected",
                Notes         = reason,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            TempData["Error"] = "تم رفض العقد: " + reason;
            return RedirectToAction("Details", "Asset", new { id = assetId });
        }
    }
}
'@, $utf8)
Write-Host "OK: FinanceController.cs (NEW)" -ForegroundColor Green

# ── 6. MarketingUploadController.cs (NEW — المرحلة 8) ────────────
[System.IO.File]::WriteAllText("$web\Controllers\MarketingUploadController.cs", @'
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
    /// المرحلة 8 — التسويق يرفع العقد الموقّع (PDF أو Word)
    /// </summary>
    [Authorize(Roles = "Marketing,SuperAdmin")]
    public class MarketingUploadController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;
        private readonly IWebHostEnvironment _env;
        private readonly ApplicationDbContext _ctx;

        public MarketingUploadController(IAssetRepository repo, IStageHistoryRepository history,
            IWebHostEnvironment env, ApplicationDbContext ctx)
        { _repo = repo; _history = history; _env = env; _ctx = ctx; }

        // ── GET: شاشة رفع العقد الموقّع ─────────────────────────
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

        // ── POST: رفع الملف (8 → 9) ─────────────────────────────
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

            // ── التحقق من نوع الملف ────────────────────────────
            var ext         = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowed     = new[] { ".pdf", ".doc", ".docx" };
            if (!allowed.Contains(ext))
            {
                TempData["Error"] = "نوع الملف غير مسموح. يُقبل PDF و Word فقط";
                return RedirectToAction("UploadSigned", new { assetId });
            }

            string fileType = ext == ".pdf" ? "PDF" : "Word";

            // ── حفظ الملف ──────────────────────────────────────
            var folder = Path.Combine(_env.WebRootPath, "uploads", "contracts", assetId.ToString());
            Directory.CreateDirectory(folder);

            var safeName = $"{DateTime.Now:yyyyMMdd_HHmmss}_{Path.GetFileName(file.FileName)}";
            var fullPath = Path.Combine(folder, safeName);
            using (var stream = new FileStream(fullPath, FileMode.Create))
                await file.CopyToAsync(stream);

            var relativePath = $"/uploads/contracts/{assetId}/{safeName}";

            // ── حفظ السجل في ContractFiles ─────────────────────
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

            // ── الانتقال 8 → 9 (الخزنة) ───────────────────────
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
'@, $utf8)
Write-Host "OK: MarketingUploadController.cs (NEW)" -ForegroundColor Green

# ── 7. TreasuryController.cs ──────────────────────────────────────
[System.IO.File]::WriteAllText("$web\Controllers\TreasuryController.cs", @'
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

        // ── GET: تحصيل الخزنة (المرحلة 9) ──────────────────────
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

        // ── POST: تسجيل التحصيل (9 → 10 مكتمل) ─────────────────
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

            // 9 → 10 (مكتمل)
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
            var note = string.Format("تم تحصيل {0:N0} جنيه — {1} — إيصال: {2}",
                vm.Amount, vm.PaymentMethod, vm.ReceiptNumber ?? "—");
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
'@, $utf8)
Write-Host "OK: TreasuryController.cs" -ForegroundColor Green

Write-Host ""
Write-Host "=== Stage 4 Complete ===" -ForegroundColor Cyan
Write-Host "Files modified/created:"
Write-Host "  [M] Web/Controllers/AssetController.cs"
Write-Host "  [M] Web/Controllers/ValuationController.cs"
Write-Host "  [M] Web/Controllers/RequestsController.cs"
Write-Host "  [M] Web/Controllers/ContractsController.cs"
Write-Host "  [N] Web/Controllers/FinanceController.cs"
Write-Host "  [N] Web/Controllers/MarketingUploadController.cs"
Write-Host "  [M] Web/Controllers/TreasuryController.cs"
Write-Host ""

cd $base
dotnet build 2>&1 | Select-Object -Last 6

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build OK. Ready for Stage 5 (Views)." -ForegroundColor Green
} else {
    Write-Host "Build FAILED - check errors above" -ForegroundColor Red
}
