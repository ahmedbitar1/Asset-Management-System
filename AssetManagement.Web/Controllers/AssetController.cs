using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
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
        private readonly ApplicationDbContext _ctx;

        public AssetController(IAssetRepository repo, IWorkflowService workflow,
            UserManager<ApplicationUser> userManager, IWebHostEnvironment env,
            ApplicationDbContext ctx)
        {
            _repo = repo; _workflow = workflow;
            _userManager = userManager; _env = env; _ctx = ctx;
        }

        // ── Index ────────────────────────────────────────────────
        public async Task<IActionResult> Index(string? search, string? status, int? stage)
        {
            var user  = await _userManager.GetUserAsync(User);
            var roles = await _userManager.GetRolesAsync(user!);
            IEnumerable<Asset> assets = roles.Contains("SuperAdmin") || roles.Contains("Legal") || roles.Contains("Board_High") || roles.Contains("Finance") || roles.Contains("Marketing") || roles.Contains("Board_High")
                ? await _repo.GetAllAsync()
                : await _workflow.GetAssetsByRoleAsync(user!.Id, roles);

            if (!string.IsNullOrWhiteSpace(search))
                assets = assets.Where(a =>
                    a.AssetName.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    a.AssetCode.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    (a.City ?? "").Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    (a.Location ?? "").Contains(search, StringComparison.OrdinalIgnoreCase));

            if (!string.IsNullOrWhiteSpace(status) &&
                Enum.TryParse<AssetManagement.Domain.Enums.AssetStatus>(status, out var st))
                assets = assets.Where(a => a.Status == st);

            if (stage.HasValue)
                assets = assets.Where(a => a.CurrentStage == stage.Value);

            ViewBag.Search       = search;
            ViewBag.Status       = status;
            ViewBag.Stage        = stage;
            ViewBag.IsSuperAdmin = roles.Contains("SuperAdmin") || roles.Contains("Legal") || roles.Contains("Board_High") || roles.Contains("Finance") || roles.Contains("Marketing") || roles.Contains("Board_High");

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
        [Authorize(Roles = "Finance,Legal,Marketing,Board_High,SuperAdmin")]
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
            bool isSuperAdmin = roles.Contains("SuperAdmin") || roles.Contains("Legal") || roles.Contains("Board_High") || roles.Contains("Finance") || roles.Contains("Marketing") || roles.Contains("Board_High");
            bool canAct = isSuperAdmin ||
                (StageDefinition.StageRoles.TryGetValue(asset.CurrentStage, out var sr)
                 && sr.Any(r => roles.Contains(r)));

            bool canReject = (canAct || isSuperAdmin)
                && asset.CurrentStage is 5 or 7
                && asset.Status != AssetManagement.Domain.Enums.AssetStatus.Rejected;

            var vm = new AssetDetailViewModel
            {
                Asset      = asset,
                CanAdvance = canAct
             && asset.Status != AssetStatus.Rejected
             && !StageDefinition.IsLastStage(asset.CurrentStage)
             && asset.CurrentStage != 3
             && asset.CurrentStage != 4
             && asset.CurrentStage != 6
             && (
                    asset.CurrentStage != 2
                    || roles.Contains("Marketing")
                    || roles.Contains("SuperAdmin")
                ),
                CanReject  = canReject,
                IsStage2   = asset.CurrentStage == 2,
                IsStage3   = asset.CurrentStage == 3,
                IsStage4   = asset.CurrentStage == 4,

                History = asset.StageHistories
                    .OrderByDescending(h => h.PerformedAt)
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
                    new() { StageKey="2a", StageName="\u0627\u0644\u062a\u0633\u0648\u064a\u0642",
                            IsCompleted=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2a"&&o.IsCompleted),
                            IsRequired=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2a"&&o.IsRequired),
                            RoleNeeded="Marketing" },
                    new() { StageKey="2b", StageName="\u0627\u0644\u0647\u0646\u062f\u0633\u0629",
                            IsCompleted=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2b"&&o.IsCompleted),
                            IsRequired=asset.OptionalStageStatuses.Any(o=>o.StageKey=="2b"&&o.IsRequired),
                            RoleNeeded="Engineering" },
                    new() { StageKey="2c", StageName="\u0627\u0644\u0634\u0624\u0648\u0646 \u0627\u0644\u0625\u062f\u0627\u0631\u064a\u0629",
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

        // ── Complete Optional ─────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> CompleteOptional(int id, string stageKey)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var (ok, msg) = await _workflow.CompleteOptionalStageAsync(id, stageKey, userId);
            TempData[ok ? "Success" : "Error"] = msg;
            return RedirectToAction("Details", new { id });
        }

        // ── Delete (single) ──────────────────────────────────────
        [HttpPost][ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,Legal")]
        public async Task<IActionResult> Delete(int id)
        {
            var asset = await _repo.GetByIdAsync(id);
            if (asset != null)
            {
                var folder = Path.Combine(_env.WebRootPath, "uploads", "assets", id.ToString());
                if (Directory.Exists(folder)) Directory.Delete(folder, true);
                _repo.Remove(asset);
                await _repo.SaveChangesAsync();
                TempData["Success"] = "\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0623\u0635\u0644 \u0628\u0646\u062c\u0627\u062d";
            }
            return RedirectToAction(nameof(Index));
        }

        // ── Delete ALL (SuperAdmin only) — \u0645\u0639 \u0625\u0639\u0627\u062f\u0629 \u062a\u0635\u0641\u064a\u0631 Identity ─────
        [HttpPost][ValidateAntiForgeryToken]
        [Authorize(Roles = "SuperAdmin,Legal")]
        public async Task<IActionResult> DeleteAll()
        {
            // 1. \u0645\u0639\u0627\u0644\u062c\u0629 Restrict FKs \u0623\u0648\u0644\u0627\u064b
            var cfiles = _ctx.ContractFiles.ToList();
            _ctx.ContractFiles.RemoveRange(cfiles);
            await _ctx.SaveChangesAsync();

            var vals = _ctx.AssetValuations.ToList();
            _ctx.AssetValuations.RemoveRange(vals);
            await _ctx.SaveChangesAsync();

            // 2. \u062d\u0630\u0641 \u0643\u0644 \u0627\u0644\u0623\u0635\u0648\u0644 (EF \u064a\u062a\u0648\u0644\u0649 \u0627\u0644\u0628\u0627\u0642\u064a Cascade)
            var all = await _repo.GetAllAsync();
            foreach (var asset in all.ToList())
            {
                var folder = Path.Combine(_env.WebRootPath, "uploads", "assets", asset.Id.ToString());
                if (Directory.Exists(folder)) Directory.Delete(folder, true);
                _repo.Remove(asset);
            }
            await _repo.SaveChangesAsync();

            // 3. \u0625\u0639\u0627\u062f\u0629 \u062a\u0635\u0641\u064a\u0631 \u0627\u0644\u0640 Identity \u0644\u0643\u0644 \u0627\u0644\u062c\u062f\u0627\u0648\u0644 \u0627\u0644\u0645\u062a\u0623\u062b\u0631\u0629
            var tablesToReseed = new[]
            {
                "Assets", "StageHistories", "AssetStages", "OptionalStageStatuses",
                "OptionalStageDetails", "RentalRequests", "SaleRequests",
                "Contracts", "ContractFiles", "AssetValuations"
            };

            var reseedErrors = new List<string>();
            foreach (var table in tablesToReseed)
            {
                try
                {
                    await _ctx.Database.ExecuteSqlRawAsync(
                        "DBCC CHECKIDENT ('" + table + "', RESEED, 0)");
                }
                catch (Exception ex)
                {
                    reseedErrors.Add(table + ": " + ex.Message);
                }
            }

            if (reseedErrors.Any())
            {
                TempData["Error"] = "\u062a\u0645 \u0627\u0644\u062d\u0630\u0641 \u0644\u0643\u0646 \u0641\u0634\u0644 \u062a\u0635\u0641\u064a\u0631 \u0627\u0644\u062a\u0631\u0642\u064a\u0645: " + string.Join(" | ", reseedErrors);
            }
            else
            {
                TempData["Success"] = "\u062a\u0645 \u062d\u0630\u0641 \u062c\u0645\u064a\u0639 \u0627\u0644\u0639\u0642\u0627\u0631\u0627\u062a \u0648\u0625\u0639\u0627\u062f\u0629 \u062a\u0631\u0642\u064a\u0645 \u0627\u0644\u062a\u0633\u0644\u0633\u0644 \u0644\u0644\u0628\u062f\u0627\u064a\u0629";
            }

            return RedirectToAction(nameof(Index));
        }

        // ── Create (manual asset entry) ─────────────────────────────
        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpGet]
        public IActionResult Create()
        {
            return View(new AssetFormViewModel());
        }

        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(AssetFormViewModel vm)
        {
            if (!ModelState.IsValid) return View(vm);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            int year = DateTime.Now.Year;
            int count = await _repo.CountByYearAsync(year);
            string code = "AST-" + year + "-" + (count + 1).ToString("D5");

            var asset = new Asset
            {
                AssetCode        = code,
                AssetName        = vm.AssetName,
                City             = vm.City,
                District         = vm.District,
                AssetDescription = vm.AssetDescription,
                PropertyType     = vm.PropertyType,
                LandArea         = vm.LandArea,
                BuildingArea     = vm.BuildingArea,
                Area             = vm.LandArea ?? vm.BuildingArea,
                AreaUnit         = "m2",
                DeedType         = vm.DeedType,
                OwnerCompany     = vm.OwnerCompany,
                OccupancyStatus  = vm.OccupancyStatus,
                Notes            = vm.Notes,
                PreviousOffers   = vm.PreviousOffers,
                AssetType        = AssetManagement.Domain.Enums.AssetType.Both,
                Status           = AssetManagement.Domain.Enums.AssetStatus.Pending,
                CurrentStage     = 2,
                CreatedById      = userId,
                CreatedAt        = DateTime.Now,
                UpdatedAt        = DateTime.Now,
                AssetStage = new AssetStage
                {
                    StageNumber  = 2,
                    StageName    = StageDefinition.GetName(2),
                    Status       = AssetManagement.Domain.Enums.StageStatus.InProgress,
                    AssignedToId = userId,
                    StartedAt    = DateTime.Now,
                },
                StageHistories = new List<StageHistory>
                {
                    new() { FromStage=0, ToStage=1, Action="Imported",
                            Notes="\u0625\u062f\u062e\u0627\u0644 \u064a\u062f\u0648\u064a", PerformedById=userId, PerformedAt=DateTime.Now },
                    new() { FromStage=1, ToStage=2, Action="AutoAdvanced",
                            Notes="\u0627\u0646\u062a\u0642\u0627\u0644 \u062a\u0644\u0642\u0627\u0626\u064a", PerformedById=userId, PerformedAt=DateTime.Now.AddSeconds(1) }
                }
            };

            await _repo.AddAsync(asset);
            await _repo.SaveChangesAsync();

            TempData["Success"] = "\u062a\u0645 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0623\u0635\u0644 " + code + " \u0628\u0646\u062c\u0627\u062d";
            return RedirectToAction(nameof(Index));
        }

        // ── Edit ────────────────────────────────────────────────
        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var asset = await _repo.GetByIdAsync(id);
            if (asset == null) return NotFound();

            var vm = new AssetFormViewModel
            {
                Id               = asset.Id,
                AssetCode        = asset.AssetCode,
                AssetName        = asset.AssetName,
                City             = asset.City ?? "",
                District         = asset.District ?? "",
                AssetDescription = asset.AssetDescription,
                PropertyType     = asset.PropertyType,
                LandArea         = asset.LandArea,
                BuildingArea     = asset.BuildingArea,
                DeedType         = asset.DeedType,
                OwnerCompany     = asset.OwnerCompany,
                OccupancyStatus  = asset.OccupancyStatus,
                Notes            = asset.Notes,
                PreviousOffers   = asset.PreviousOffers,
            };
            return View(vm);
        }

        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(AssetFormViewModel vm)
        {
            if (!ModelState.IsValid) return View(vm);

            var asset = await _repo.GetByIdAsync(vm.Id);
            if (asset == null) return NotFound();

            asset.AssetName        = vm.AssetName;
            asset.City              = vm.City;
            asset.District          = vm.District;
            asset.AssetDescription  = vm.AssetDescription;
            asset.PropertyType      = vm.PropertyType;
            asset.LandArea          = vm.LandArea;
            asset.BuildingArea      = vm.BuildingArea;
            asset.Area              = vm.LandArea ?? vm.BuildingArea ?? asset.Area;
            asset.DeedType          = vm.DeedType;
            asset.OwnerCompany      = vm.OwnerCompany;
            asset.OccupancyStatus   = vm.OccupancyStatus;
            asset.Notes             = vm.Notes;
            asset.PreviousOffers    = vm.PreviousOffers;
            asset.UpdatedAt         = DateTime.Now;

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();

            TempData["Success"] = "\u062a\u0645 \u062a\u062c\u062f\u064a\u062f \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0623\u0635\u0644 \u0628\u0646\u062c\u0627\u062d";
            return RedirectToAction("Details", new { id = asset.Id });
        }
    }
}

