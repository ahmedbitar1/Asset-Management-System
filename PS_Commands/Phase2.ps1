# ============================================================
# Phase2.ps1 - Workflow + Dashboard + Asset Management
# ============================================================

$base = "$env:USERPROFILE\Desktop\AssetManagement"
$web   = "$base\AssetManagement.Web"
$app   = "$base\AssetManagement.Application"
$infra = "$base\AssetManagement.Infrastructure"
$domain= "$base\AssetManagement.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "  created: $(Split-Path $path -Leaf)" -ForegroundColor Green
}

Write-Host "`n==> Phase 2: Workflow + Dashboard + Assets" -ForegroundColor Cyan

# ============================================================
# 1. DOMAIN - IWorkflowService Interface
# ============================================================
Write-File "$domain\Interfaces\IWorkflowService.cs" @'
using AssetManagement.Domain.Entities;

namespace AssetManagement.Domain.Interfaces
{
    public interface IWorkflowService
    {
        Task<(bool Success, string Message)> AdvanceStageAsync(int assetId, string userId, string? notes = null);
        Task<(bool Success, string Message)> RejectStageAsync(int assetId, string userId, string reason);
        Task<(bool Success, string Message)> CompleteOptionalStageAsync(int assetId, string stageKey, string userId);
        Task<List<Asset>> GetAssetsByRoleAsync(string userId, IList<string> roles);
        Task<Asset?> GetAssetDetailAsync(int assetId);
    }
}
'@

# ============================================================
# 2. DOMAIN - Stage Names Helper
# ============================================================
Write-File "$domain\Entities\StageDefinition.cs" @'
namespace AssetManagement.Domain.Entities
{
    public static class StageDefinition
    {
        public static readonly Dictionary<int, string> Names = new()
        {
            { 1,  "تسجيل الأصل" },
            { 2,  "المراحل الاختيارية" },
            { 3,  "اعتماد مجلس الإدارة" },
            { 4,  "تقييم السعر" },
            { 5,  "المراجعة المالية" },
            { 6,  "رفع الإعلانات والصور" },
            { 7,  "تسجيل طلب الإيجار/البيع" },
            { 8,  "المراجعة القانونية والمالية" },
            { 9,  "الاعتماد النهائي" },
            { 10, "توليد العقد" },
            { 11, "التحصيل من الخزينة" },
        };

        public static readonly Dictionary<int, string[]> StageRoles = new()
        {
            { 1,  new[] { "DataEntry", "SuperAdmin" } },
            { 2,  new[] { "Marketing", "Engineering", "AdminAffairs", "SuperAdmin" } },
            { 3,  new[] { "Board_Low", "SuperAdmin" } },
            { 4,  new[] { "Valuator", "SuperAdmin" } },
            { 5,  new[] { "Finance", "SuperAdmin" } },
            { 6,  new[] { "Marketing", "SuperAdmin" } },
            { 7,  new[] { "Sales", "SuperAdmin" } },
            { 8,  new[] { "Legal", "Finance", "SuperAdmin" } },
            { 9,  new[] { "Board_High", "SuperAdmin" } },
            { 10, new[] { "Legal", "SuperAdmin" } },
            { 11, new[] { "Treasury", "SuperAdmin" } },
        };

        public static string GetName(int stage) =>
            Names.TryGetValue(stage, out var n) ? n : $"مرحلة {stage}";
    }
}
'@

# ============================================================
# 3. APPLICATION - ViewModels
# ============================================================
Write-File "$app\ViewModels\DashboardViewModel.cs" @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class DashboardViewModel
    {
        public string UserName      { get; set; } = string.Empty;
        public List<string> Roles   { get; set; } = new();
        public List<AssetCardViewModel> PendingAssets  { get; set; } = new();
        public List<AssetCardViewModel> AllAssets       { get; set; } = new();

        // إحصائيات للـ SuperAdmin
        public int TotalAssets    { get; set; }
        public int ActiveAssets   { get; set; }
        public int SoldAssets     { get; set; }
        public int RentedAssets   { get; set; }
        public int RejectedAssets { get; set; }
        public Dictionary<int, int> AssetsByStage { get; set; } = new();
    }

    public class AssetCardViewModel
    {
        public int     Id           { get; set; }
        public string  AssetCode    { get; set; } = string.Empty;
        public string  AssetName    { get; set; } = string.Empty;
        public string? Location     { get; set; }
        public string? City         { get; set; }
        public int     CurrentStage { get; set; }
        public string  StageName    => AssetManagement.Domain.Entities.StageDefinition.GetName(CurrentStage);
        public AssetStatus Status   { get; set; }
        public string  StatusAr     => Status switch
        {
            AssetStatus.Active   => "نشط",
            AssetStatus.Sold     => "مباع",
            AssetStatus.Rented   => "مؤجر",
            AssetStatus.Rejected => "مرفوض",
            _                    => "قيد الإجراء"
        };
        public string StatusColor => Status switch
        {
            AssetStatus.Active   => "success",
            AssetStatus.Sold     => "primary",
            AssetStatus.Rented   => "info",
            AssetStatus.Rejected => "danger",
            _                    => "warning"
        };
        public AssetType   AssetType { get; set; }
        public string      TypeAr    => AssetType switch
        {
            AssetType.Sale => "بيع",
            AssetType.Rent => "إيجار",
            _              => "بيع وإيجار"
        };
        public decimal? PurchasePrice { get; set; }
        public decimal? Area          { get; set; }
        public DateTime CreatedAt     { get; set; }
    }
}
'@

Write-File "$app\ViewModels\AssetDetailViewModel.cs" @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class AssetDetailViewModel
    {
        public Asset Asset { get; set; } = null!;
        public List<StageHistoryItem> History { get; set; } = new();
        public bool CanAdvance  { get; set; }
        public bool CanReject   { get; set; }
        public List<OptionalStageInfo> OptionalStages { get; set; } = new();
        public bool IsStage2     { get; set; }
        public bool AllOptionalDone { get; set; }
    }

    public class StageHistoryItem
    {
        public int     FromStage   { get; set; }
        public int     ToStage     { get; set; }
        public string  FromName    => StageDefinition.GetName(FromStage);
        public string  ToName      => StageDefinition.GetName(ToStage);
        public string? Action      { get; set; }
        public string? Notes       { get; set; }
        public string? PerformedBy { get; set; }
        public DateTime PerformedAt { get; set; }
    }

    public class OptionalStageInfo
    {
        public string StageKey   { get; set; } = string.Empty;
        public string StageName  { get; set; } = string.Empty;
        public bool   IsRequired { get; set; }
        public bool   IsCompleted{ get; set; }
        public string RoleNeeded { get; set; } = string.Empty;
    }
}
'@

# ============================================================
# 4. APPLICATION - WorkflowService
# ============================================================
Write-File "$app\Services\WorkflowService.cs" @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AssetManagement.Application.Services
{
    public class WorkflowService : IWorkflowService
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _historyRepo;

        public WorkflowService(IAssetRepository repo, IStageHistoryRepository historyRepo)
        {
            _repo = repo;
            _historyRepo = historyRepo;
        }

        public async Task<(bool Success, string Message)> AdvanceStageAsync(
            int assetId, string userId, string? notes = null)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "الأصل غير موجود");

            int from = asset.CurrentStage;

            // المرحلة 2: تحقق من اكتمال المراحل الاختيارية المطلوبة
            if (from == 2)
            {
                var required = asset.OptionalStageStatuses
                    .Where(o => o.IsRequired && !o.IsCompleted).ToList();
                if (required.Any())
                    return (false, "يوجد مراحل اختيارية إلزامية لم تكتمل بعد");
            }

            int to = GetNextStage(asset);
            asset.CurrentStage = to;
            asset.UpdatedAt    = DateTime.Now;

            // تحديث سجل المرحلة
            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = to;
                asset.AssetStage.StageName    = StageDefinition.GetName(to);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.CompletedAt  = null;
                asset.AssetStage.AssignedToId = userId;
            }

            // تحديث حالة الأصل عند الانتهاء
            if (to > 11)
            {
                asset.Status = AssetStatus.Active;
                if (asset.AssetStage != null)
                {
                    asset.AssetStage.Status      = StageStatus.Completed;
                    asset.AssetStage.CompletedAt = DateTime.Now;
                }
            }

            await _repo.UpdateAsync(asset);

            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = to,
                Action        = "Approved",
                Notes         = notes,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });

            await _repo.SaveChangesAsync();
            return (true, $"تم الانتقال إلى {StageDefinition.GetName(to)}");
        }

        public async Task<(bool Success, string Message)> RejectStageAsync(
            int assetId, string userId, string reason)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "الأصل غير موجود");

            int from = asset.CurrentStage;
            asset.Status    = AssetStatus.Rejected;
            asset.UpdatedAt = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.Status          = StageStatus.Rejected;
                asset.AssetStage.CompletedAt     = DateTime.Now;
                asset.AssetStage.RejectionReason = reason;
            }

            await _repo.UpdateAsync(asset);
            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = from,
                Action        = "Rejected",
                Notes         = reason,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });

            await _repo.SaveChangesAsync();
            return (true, "تم رفض الأصل");
        }

        public async Task<(bool Success, string Message)> CompleteOptionalStageAsync(
            int assetId, string stageKey, string userId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "الأصل غير موجود");

            var opt = asset.OptionalStageStatuses
                .FirstOrDefault(o => o.StageKey == stageKey);

            if (opt == null)
            {
                asset.OptionalStageStatuses.Add(new OptionalStageStatus
                {
                    AssetId      = assetId,
                    StageKey     = stageKey,
                    IsRequired   = false,
                    IsCompleted  = true,
                    CompletedAt  = DateTime.Now,
                    CompletedById= userId
                });
            }
            else
            {
                opt.IsCompleted  = true;
                opt.CompletedAt  = DateTime.Now;
                opt.CompletedById= userId;
            }

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();

            string name = stageKey switch
            {
                "2a" => "التسويق",
                "2b" => "الهندسة",
                "2c" => "الشؤون الإدارية",
                _    => stageKey
            };

            return (true, $"تم إكمال مرحلة {name}");
        }

        public async Task<List<Asset>> GetAssetsByRoleAsync(
            string userId, IList<string> roles)
        {
            return await _repo.GetByRolesAsync(roles);
        }

        public async Task<Asset?> GetAssetDetailAsync(int assetId)
        {
            return await _repo.GetByIdAsync(assetId);
        }

        private static int GetNextStage(Asset asset)
        {
            // المرحلة 2 اختيارية — إذا مفيش مراحل اختيارية مطلوبة ننتقل لـ 3
            if (asset.CurrentStage == 1) return 2;
            if (asset.CurrentStage == 2) return 3;
            return asset.CurrentStage + 1;
        }
    }
}
'@

# ============================================================
# 5. DOMAIN - IStageHistoryRepository
# ============================================================
Write-File "$domain\Interfaces\IStageHistoryRepository.cs" @'
using AssetManagement.Domain.Entities;

namespace AssetManagement.Domain.Interfaces
{
    public interface IStageHistoryRepository
    {
        Task AddAsync(StageHistory history);
    }
}
'@

# ============================================================
# 6. DOMAIN - Update IAssetRepository
# ============================================================
Write-File "$domain\Interfaces\IAssetRepository.cs" @'
using AssetManagement.Domain.Entities;

namespace AssetManagement.Domain.Interfaces
{
    public interface IAssetRepository
    {
        Task<IEnumerable<Asset>> GetAllAsync();
        Task<Asset?> GetByIdAsync(int id);
        Task AddAsync(Asset asset);
        Task UpdateAsync(Asset asset);
        Task SaveChangesAsync();
        Task<List<Asset>> GetByRolesAsync(IList<string> roles);
        Task<int>  CountByYearAsync(int year);
        Task<Dictionary<int, int>> GetStageCountsAsync();
    }
}
'@

# ============================================================
# 7. INFRASTRUCTURE - AssetRepository (updated)
# ============================================================
Write-File "$infra\Repository\AssetRepository.cs" @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace AssetManagement.Infrastructure.Repository
{
    public class AssetRepository : IAssetRepository
    {
        private readonly ApplicationDbContext _ctx;
        public AssetRepository(ApplicationDbContext ctx) => _ctx = ctx;

        public async Task<IEnumerable<Asset>> GetAllAsync() =>
            await _ctx.Assets
                      .Include(a => a.Category)
                      .Include(a => a.AssetStage)
                      .OrderByDescending(a => a.CreatedAt)
                      .ToListAsync();

        public async Task<Asset?> GetByIdAsync(int id) =>
            await _ctx.Assets
                      .Include(a => a.Category)
                      .Include(a => a.AssetStage)
                      .Include(a => a.StageHistories)
                      .Include(a => a.OptionalStageStatuses)
                      .Include(a => a.RentalRequests)
                      .Include(a => a.SaleRequests)
                      .FirstOrDefaultAsync(a => a.Id == id);

        public async Task AddAsync(Asset asset) =>
            await _ctx.Assets.AddAsync(asset);

        public Task UpdateAsync(Asset asset)
        {
            _ctx.Assets.Update(asset);
            return Task.CompletedTask;
        }

        public async Task SaveChangesAsync() =>
            await _ctx.SaveChangesAsync();

        public async Task<List<Asset>> GetByRolesAsync(IList<string> roles)
        {
            // SuperAdmin يشوف الكل
            if (roles.Contains("SuperAdmin"))
                return await _ctx.Assets
                                 .Include(a => a.AssetStage)
                                 .OrderByDescending(a => a.UpdatedAt ?? a.CreatedAt)
                                 .ToListAsync();

            var stages = new List<int>();
            if (roles.Contains("DataEntry"))    stages.Add(1);
            if (roles.Contains("Marketing"))    { stages.Add(2); stages.Add(6); }
            if (roles.Contains("Engineering"))  stages.Add(2);
            if (roles.Contains("AdminAffairs")) stages.Add(2);
            if (roles.Contains("Board_Low"))    stages.Add(3);
            if (roles.Contains("Valuator"))     stages.Add(4);
            if (roles.Contains("Finance"))      { stages.Add(5); stages.Add(8); }
            if (roles.Contains("Sales"))        stages.Add(7);
            if (roles.Contains("Legal"))        { stages.Add(8); stages.Add(10); }
            if (roles.Contains("Board_High"))   stages.Add(9);
            if (roles.Contains("Treasury"))     stages.Add(11);

            stages = stages.Distinct().ToList();

            return await _ctx.Assets
                             .Include(a => a.AssetStage)
                             .Where(a => stages.Contains(a.CurrentStage)
                                      && a.Status != AssetManagement.Domain.Enums.AssetStatus.Rejected)
                             .OrderByDescending(a => a.UpdatedAt ?? a.CreatedAt)
                             .ToListAsync();
        }

        public async Task<int> CountByYearAsync(int year) =>
            await _ctx.Assets.CountAsync(a => a.CreatedAt.Year == year);

        public async Task<Dictionary<int, int>> GetStageCountsAsync() =>
            await _ctx.Assets
                      .GroupBy(a => a.CurrentStage)
                      .ToDictionaryAsync(g => g.Key, g => g.Count());
    }
}
'@

# ============================================================
# 8. INFRASTRUCTURE - StageHistoryRepository
# ============================================================
Write-File "$infra\Repository\StageHistoryRepository.cs" @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;

namespace AssetManagement.Infrastructure.Repository
{
    public class StageHistoryRepository : IStageHistoryRepository
    {
        private readonly ApplicationDbContext _ctx;
        public StageHistoryRepository(ApplicationDbContext ctx) => _ctx = ctx;

        public async Task AddAsync(StageHistory history)
        {
            await _ctx.StageHistories.AddAsync(history);
        }
    }
}
'@

# ============================================================
# 9. APPLICATION - IWorkflowService في Application أيضاً
# ============================================================
Write-File "$app\Interfaces\IWorkflowService.cs" @'
using AssetManagement.Domain.Entities;

namespace AssetManagement.Application.Interfaces
{
    public interface IWorkflowService
    {
        Task<(bool Success, string Message)> AdvanceStageAsync(int assetId, string userId, string? notes = null);
        Task<(bool Success, string Message)> RejectStageAsync(int assetId, string userId, string reason);
        Task<(bool Success, string Message)> CompleteOptionalStageAsync(int assetId, string stageKey, string userId);
        Task<List<Asset>> GetAssetsByRoleAsync(string userId, IList<string> roles);
        Task<Asset?> GetAssetDetailAsync(int assetId);
    }
}
'@

# ============================================================
# 10. WEB - DashboardController
# ============================================================
Write-File "$web\Controllers\DashboardController.cs" @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using AssetManagement.Infrastructure.Data;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class DashboardController : Controller
    {
        private readonly IWorkflowService _workflow;
        private readonly IAssetRepository _assetRepo;
        private readonly UserManager<AppIdentityUser> _userManager;

        public DashboardController(
            IWorkflowService workflow,
            IAssetRepository assetRepo,
            UserManager<AppIdentityUser> userManager)
        {
            _workflow    = workflow;
            _assetRepo   = assetRepo;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            var user  = await _userManager.GetUserAsync(User);
            var roles = await _userManager.GetRolesAsync(user!);

            var pendingAssets = await _workflow.GetAssetsByRoleAsync(user!.Id, roles);
            var allAssets     = roles.Contains("SuperAdmin")
                ? await _assetRepo.GetAllAsync()
                : pendingAssets;

            var vm = new DashboardViewModel
            {
                UserName      = user.FullName,
                Roles         = roles.ToList(),
                PendingAssets = pendingAssets.Select(ToCard).ToList(),
                AllAssets     = allAssets.Select(ToCard).ToList(),
            };

            if (roles.Contains("SuperAdmin"))
            {
                var all = await _assetRepo.GetAllAsync();
                vm.TotalAssets    = all.Count();
                vm.ActiveAssets   = all.Count(a => a.Status == AssetStatus.Active);
                vm.SoldAssets     = all.Count(a => a.Status == AssetStatus.Sold);
                vm.RentedAssets   = all.Count(a => a.Status == AssetStatus.Rented);
                vm.RejectedAssets = all.Count(a => a.Status == AssetStatus.Rejected);
                vm.AssetsByStage  = await _assetRepo.GetStageCountsAsync();
            }

            return View(vm);
        }

        private static AssetCardViewModel ToCard(AssetManagement.Domain.Entities.Asset a) => new()
        {
            Id            = a.Id,
            AssetCode     = a.AssetCode,
            AssetName     = a.AssetName,
            Location      = a.Location,
            City          = a.City,
            CurrentStage  = a.CurrentStage,
            Status        = a.Status,
            AssetType     = a.AssetType,
            PurchasePrice = a.PurchasePrice,
            Area          = a.Area,
            CreatedAt     = a.CreatedAt
        };
    }
}
'@

# ============================================================
# 11. WEB - AssetController
# ============================================================
Write-File "$web\Controllers\AssetController.cs" @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
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
        private readonly UserManager<AppIdentityUser> _userManager;

        public AssetController(
            IAssetRepository repo,
            IWorkflowService workflow,
            UserManager<AppIdentityUser> userManager)
        {
            _repo        = repo;
            _workflow    = workflow;
            _userManager = userManager;
        }

        // ── قائمة الأصول ─────────────────────────────────
        public async Task<IActionResult> Index(string? search, string? status, int? stage)
        {
            var user  = await _userManager.GetUserAsync(User);
            var roles = await _userManager.GetRolesAsync(user!);

            IEnumerable<Asset> assets;

            if (roles.Contains("SuperAdmin"))
                assets = await _repo.GetAllAsync();
            else
                assets = await _workflow.GetAssetsByRoleAsync(user!.Id, roles);

            // فلترة
            if (!string.IsNullOrWhiteSpace(search))
                assets = assets.Where(a =>
                    a.AssetName.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    a.AssetCode.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    (a.Location ?? "").Contains(search, StringComparison.OrdinalIgnoreCase));

            if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<AssetManagement.Domain.Enums.AssetStatus>(status, out var st))
                assets = assets.Where(a => a.Status == st);

            if (stage.HasValue)
                assets = assets.Where(a => a.CurrentStage == stage.Value);

            ViewBag.Search = search;
            ViewBag.Status = status;
            ViewBag.Stage  = stage;
            ViewBag.IsSuperAdmin = roles.Contains("SuperAdmin");

            var cards = assets.Select(a => new AssetCardViewModel
            {
                Id            = a.Id,
                AssetCode     = a.AssetCode,
                AssetName     = a.AssetName,
                Location      = a.Location,
                City          = a.City,
                CurrentStage  = a.CurrentStage,
                Status        = a.Status,
                AssetType     = a.AssetType,
                PurchasePrice = a.PurchasePrice,
                Area          = a.Area,
                CreatedAt     = a.CreatedAt
            }).ToList();

            return View(cards);
        }

        // ── تفاصيل الأصل ─────────────────────────────────
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

            var vm = new AssetDetailViewModel
            {
                Asset      = asset,
                CanAdvance = canAct && asset.Status != Domain.Enums.AssetStatus.Rejected,
                CanReject  = (canAct || isSuperAdmin)
                             && asset.CurrentStage is 3 or 9
                             && asset.Status != Domain.Enums.AssetStatus.Rejected,
                IsStage2   = asset.CurrentStage == 2,
                History    = asset.StageHistories.OrderByDescending(h => h.PerformedAt)
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
                    new() { StageKey="2a", StageName="التسويق",           RoleNeeded="Marketing",    IsRequired=false,
                            IsCompleted = asset.OptionalStageStatuses.Any(o => o.StageKey=="2a" && o.IsCompleted) },
                    new() { StageKey="2b", StageName="الهندسة",           RoleNeeded="Engineering",  IsRequired=false,
                            IsCompleted = asset.OptionalStageStatuses.Any(o => o.StageKey=="2b" && o.IsCompleted) },
                    new() { StageKey="2c", StageName="الشؤون الإدارية",   RoleNeeded="AdminAffairs", IsRequired=false,
                            IsCompleted = asset.OptionalStageStatuses.Any(o => o.StageKey=="2c" && o.IsCompleted) },
                }
            };
            vm.AllOptionalDone = vm.OptionalStages
                .Where(o => o.IsRequired).All(o => o.IsCompleted);

            ViewBag.Roles = roles;
            return View(vm);
        }

        // ── تقديم المرحلة (Advance) ──────────────────────
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Advance(int id, string? notes)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var (ok, msg) = await _workflow.AdvanceStageAsync(id, userId, notes);
            TempData[ok ? "Success" : "Error"] = msg;
            return RedirectToAction("Details", new { id });
        }

        // ── رفض الأصل ────────────────────────────────────
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Reject(int id, string reason)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var (ok, msg) = await _workflow.RejectStageAsync(id, userId, reason);
            TempData[ok ? "Success" : "Error"] = msg;
            return RedirectToAction("Details", new { id });
        }

        // ── إكمال مرحلة اختيارية ─────────────────────────
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CompleteOptional(int id, string stageKey)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var (ok, msg) = await _workflow.CompleteOptionalStageAsync(id, stageKey, userId);
            TempData[ok ? "Success" : "Error"] = msg;
            return RedirectToAction("Details", new { id });
        }
    }
}
'@

# ============================================================
# 12. VIEWS - Dashboard/Index.cshtml
# ============================================================
New-Item -ItemType Directory -Force -Path "$web\Views\Dashboard" | Out-Null
Write-File "$web\Views\Dashboard\Index.cshtml" @'
@model AssetManagement.Application.ViewModels.DashboardViewModel
@{
    ViewData["Title"] = "لوحة التحكم";
}

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="fw-bold mb-1">مرحباً، @Model.UserName 👋</h4>
        <div class="d-flex gap-2 flex-wrap">
            @foreach (var r in Model.Roles)
            {
                <span class="badge bg-primary">@r</span>
            }
        </div>
    </div>
    <a asp-controller="AssetImport" asp-action="Index" class="btn btn-success">
        <i class="bi bi-file-earmark-excel me-1"></i> استيراد أصول
    </a>
</div>

@* ── إحصائيات SuperAdmin ──────────────────────── *@
@if (Model.Roles.Contains("SuperAdmin"))
{
    <div class="row g-3 mb-4">
        <div class="col-6 col-md-2">
            <div class="card border-0 shadow-sm text-center h-100">
                <div class="card-body py-3">
                    <div class="fs-2 fw-bold text-primary">@Model.TotalAssets</div>
                    <div class="small text-muted">إجمالي الأصول</div>
                </div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="card border-0 shadow-sm text-center h-100 bg-success bg-opacity-10">
                <div class="card-body py-3">
                    <div class="fs-2 fw-bold text-success">@Model.ActiveAssets</div>
                    <div class="small text-muted">نشط</div>
                </div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="card border-0 shadow-sm text-center h-100 bg-primary bg-opacity-10">
                <div class="card-body py-3">
                    <div class="fs-2 fw-bold text-primary">@Model.SoldAssets</div>
                    <div class="small text-muted">مباع</div>
                </div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="card border-0 shadow-sm text-center h-100 bg-info bg-opacity-10">
                <div class="card-body py-3">
                    <div class="fs-2 fw-bold text-info">@Model.RentedAssets</div>
                    <div class="small text-muted">مؤجر</div>
                </div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="card border-0 shadow-sm text-center h-100 bg-danger bg-opacity-10">
                <div class="card-body py-3">
                    <div class="fs-2 fw-bold text-danger">@Model.RejectedAssets</div>
                    <div class="small text-muted">مرفوض</div>
                </div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="card border-0 shadow-sm text-center h-100 bg-warning bg-opacity-10">
                <div class="card-body py-3">
                    <div class="fs-2 fw-bold text-warning">@Model.PendingAssets.Count</div>
                    <div class="small text-muted">قيد الإجراء</div>
                </div>
            </div>
        </div>
    </div>
}

@* ── الأصول في انتظار دورك ───────────────────── *@
<div class="card border-0 shadow-sm mb-4">
    <div class="card-header bg-warning bg-opacity-10 border-0 d-flex justify-content-between align-items-center">
        <h6 class="mb-0 fw-bold">
            <span class="badge bg-warning text-dark me-2">@Model.PendingAssets.Count</span>
            الأصول في انتظار دورك
        </h6>
        <a asp-controller="Asset" asp-action="Index" class="btn btn-sm btn-outline-secondary">
            عرض الكل
        </a>
    </div>
    <div class="card-body p-0">
        @if (!Model.PendingAssets.Any())
        {
            <div class="text-center py-5 text-muted">
                <i class="bi bi-check-circle fs-1 text-success"></i>
                <p class="mt-2">لا توجد أصول في انتظار دورك الآن</p>
            </div>
        }
        else
        {
            <div class="table-responsive">
                <table class="table table-hover mb-0 align-middle">
                    <thead class="table-light">
                        <tr>
                            <th>الكود</th>
                            <th>الاسم</th>
                            <th>الموقع</th>
                            <th>المرحلة الحالية</th>
                            <th>النوع</th>
                            <th>الحالة</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach (var a in Model.PendingAssets.Take(10))
                        {
                            <tr>
                                <td><code class="text-primary">@a.AssetCode</code></td>
                                <td class="fw-semibold">@a.AssetName</td>
                                <td>@a.City @a.Location</td>
                                <td>
                                    <span class="badge rounded-pill bg-warning text-dark">
                                        @a.CurrentStage - @a.StageName
                                    </span>
                                </td>
                                <td><span class="badge bg-secondary">@a.TypeAr</span></td>
                                <td>
                                    <span class="badge bg-@a.StatusColor">@a.StatusAr</span>
                                </td>
                                <td>
                                    <a asp-controller="Asset" asp-action="Details"
                                       asp-route-id="@a.Id"
                                       class="btn btn-sm btn-primary">
                                        <i class="bi bi-arrow-left-circle me-1"></i>اتخاذ إجراء
                                    </a>
                                </td>
                            </tr>
                        }
                    </tbody>
                </table>
            </div>
        }
    </div>
</div>
'@

# ============================================================
# 13. VIEWS - Asset/Index.cshtml
# ============================================================
New-Item -ItemType Directory -Force -Path "$web\Views\Asset" | Out-Null
Write-File "$web\Views\Asset\Index.cshtml" @'
@model List<AssetManagement.Application.ViewModels.AssetCardViewModel>
@{
    ViewData["Title"] = "قائمة الأصول";
}

<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="fw-bold mb-0">
        <i class="bi bi-building me-2 text-primary"></i>قائمة الأصول
        <span class="badge bg-secondary ms-2">@Model.Count</span>
    </h5>
    @if ((bool)(ViewBag.IsSuperAdmin ?? false))
    {
        <a asp-controller="AssetImport" asp-action="Index" class="btn btn-success btn-sm">
            <i class="bi bi-upload me-1"></i> استيراد جديد
        </a>
    }
</div>

@* فلتر البحث *@
<div class="card border-0 shadow-sm mb-3">
    <div class="card-body py-2">
        <form method="get" class="row g-2 align-items-end">
            <div class="col-md-4">
                <input name="search" value="@ViewBag.Search" class="form-control"
                       placeholder="بحث بالاسم أو الكود أو الموقع..." />
            </div>
            <div class="col-md-3">
                <select name="status" class="form-select">
                    <option value="">-- كل الحالات --</option>
                    <option value="Pending"  selected="@(ViewBag.Status=="Pending")">قيد الإجراء</option>
                    <option value="Active"   selected="@(ViewBag.Status=="Active")">نشط</option>
                    <option value="Sold"     selected="@(ViewBag.Status=="Sold")">مباع</option>
                    <option value="Rented"   selected="@(ViewBag.Status=="Rented")">مؤجر</option>
                    <option value="Rejected" selected="@(ViewBag.Status=="Rejected")">مرفوض</option>
                </select>
            </div>
            <div class="col-md-2">
                <select name="stage" class="form-select">
                    <option value="">-- كل المراحل --</option>
                    @for (int i = 1; i <= 11; i++)
                    {
                        <option value="@i" selected="@(ViewBag.Stage?.ToString()==i.ToString())">
                            مرحلة @i
                        </option>
                    }
                </select>
            </div>
            <div class="col-md-3 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-grow-1">
                    <i class="bi bi-search me-1"></i>بحث
                </button>
                <a asp-action="Index" class="btn btn-outline-secondary">مسح</a>
            </div>
        </form>
    </div>
</div>

@if (!Model.Any())
{
    <div class="text-center py-5 text-muted">
        <i class="bi bi-inbox fs-1"></i>
        <p class="mt-2">لا توجد أصول تطابق البحث</p>
    </div>
}
else
{
    <div class="card border-0 shadow-sm">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-dark">
                        <tr>
                            <th>#</th>
                            <th>الكود</th>
                            <th>الاسم</th>
                            <th>الموقع</th>
                            <th>المساحة</th>
                            <th>السعر</th>
                            <th>النوع</th>
                            <th>المرحلة</th>
                            <th>الحالة</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach (var (a, i) in Model.Select((a, i) => (a, i + 1)))
                        {
                            <tr>
                                <td class="text-muted small">@i</td>
                                <td><code class="text-primary small">@a.AssetCode</code></td>
                                <td class="fw-semibold">@a.AssetName</td>
                                <td class="text-muted small">@a.City @a.Location</td>
                                <td class="small">@(a.Area.HasValue ? $"{a.Area:N0} م²" : "-")</td>
                                <td class="small">@(a.PurchasePrice.HasValue ? $"{a.PurchasePrice:N0}" : "-")</td>
                                <td><span class="badge bg-secondary">@a.TypeAr</span></td>
                                <td>
                                    <span class="badge rounded-pill bg-warning text-dark small">
                                        @a.CurrentStage - @a.StageName
                                    </span>
                                </td>
                                <td>
                                    <span class="badge bg-@a.StatusColor">@a.StatusAr</span>
                                </td>
                                <td>
                                    <a asp-action="Details" asp-route-id="@a.Id"
                                       class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                </td>
                            </tr>
                        }
                    </tbody>
                </table>
            </div>
        </div>
    </div>
}
'@

# ============================================================
# 14. VIEWS - Asset/Details.cshtml
# ============================================================
Write-File "$web\Views\Asset\Details.cshtml" @'
@model AssetManagement.Application.ViewModels.AssetDetailViewModel
@{
    ViewData["Title"] = "تفاصيل الأصل";
    var a = Model.Asset;
    var roles = (IList<string>)(ViewBag.Roles ?? new List<string>());
}

@* Alerts *@
@if (TempData["Success"] != null)
{
    <div class="alert alert-success alert-dismissible fade show">
        <i class="bi bi-check-circle me-2"></i>@TempData["Success"]
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
}
@if (TempData["Error"] != null)
{
    <div class="alert alert-danger alert-dismissible fade show">
        <i class="bi bi-exclamation-triangle me-2"></i>@TempData["Error"]
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
}

<div class="d-flex justify-content-between align-items-center mb-3">
    <div>
        <h5 class="fw-bold mb-1">@a.AssetName</h5>
        <code class="text-primary">@a.AssetCode</code>
    </div>
    <div class="d-flex gap-2">
        <span class="badge bg-warning text-dark fs-6 px-3 py-2">
            المرحلة @a.CurrentStage — @AssetManagement.Domain.Entities.StageDefinition.GetName(a.CurrentStage)
        </span>
        <span class="badge fs-6 px-3 py-2
            @(a.Status == AssetManagement.Domain.Enums.AssetStatus.Rejected ? "bg-danger" :
              a.Status == AssetManagement.Domain.Enums.AssetStatus.Active ? "bg-success" :
              a.Status == AssetManagement.Domain.Enums.AssetStatus.Sold ? "bg-primary" :
              a.Status == AssetManagement.Domain.Enums.AssetStatus.Rented ? "bg-info" : "bg-secondary")">
            @(a.Status == AssetManagement.Domain.Enums.AssetStatus.Active ? "نشط" :
              a.Status == AssetManagement.Domain.Enums.AssetStatus.Sold ? "مباع" :
              a.Status == AssetManagement.Domain.Enums.AssetStatus.Rented ? "مؤجر" :
              a.Status == AssetManagement.Domain.Enums.AssetStatus.Rejected ? "مرفوض" : "قيد الإجراء")
        </span>
        <a asp-action="Index" class="btn btn-sm btn-outline-secondary">
            <i class="bi bi-arrow-right me-1"></i>رجوع
        </a>
    </div>
</div>

<div class="row g-3">

    @* ── بيانات الأصل ── *@
    <div class="col-md-7">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-header bg-light fw-bold">
                <i class="bi bi-info-circle me-2 text-primary"></i>بيانات الأصل
            </div>
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-6">
                        <div class="text-muted small">الاسم</div>
                        <div class="fw-semibold">@a.AssetName</div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted small">الكود</div>
                        <div class="fw-semibold"><code>@a.AssetCode</code></div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted small">الموقع</div>
                        <div>@a.Location</div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted small">المدينة / الحي</div>
                        <div>@a.City @a.District</div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted small">المساحة</div>
                        <div>@(a.Area.HasValue ? $"{a.Area:N0} {a.AreaUnit}" : "—")</div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted small">النوع</div>
                        <div>
                            @(a.AssetType == AssetManagement.Domain.Enums.AssetType.Sale ? "بيع" :
                              a.AssetType == AssetManagement.Domain.Enums.AssetType.Rent ? "إيجار" : "بيع وإيجار")
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted small">سعر الشراء</div>
                        <div class="fw-semibold text-success">
                            @(a.PurchasePrice.HasValue ? $"{a.PurchasePrice:N0} ج.م" : "—")
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted small">القيمة الحالية</div>
                        <div class="fw-semibold text-primary">
                            @(a.CurrentValue.HasValue ? $"{a.CurrentValue:N0} ج.م" : "—")
                        </div>
                    </div>
                    @if (!string.IsNullOrEmpty(a.DeedNumber))
                    {
                        <div class="col-6">
                            <div class="text-muted small">رقم الصك</div>
                            <div>@a.DeedNumber</div>
                        </div>
                    }
                    @if (!string.IsNullOrEmpty(a.LegalDepartmentData))
                    {
                        <div class="col-12">
                            <div class="text-muted small">البيانات القانونية</div>
                            <div class="p-2 bg-light rounded small">@a.LegalDepartmentData</div>
                        </div>
                    }
                    @if (!string.IsNullOrEmpty(a.Notes))
                    {
                        <div class="col-12">
                            <div class="text-muted small">ملاحظات</div>
                            <div class="p-2 bg-light rounded small">@a.Notes</div>
                        </div>
                    }
                </div>
            </div>
        </div>
    </div>

    @* ── إجراءات المرحلة ── *@
    <div class="col-md-5">

        @* المراحل الاختيارية (Stage 2) *@
        @if (Model.IsStage2)
        {
            <div class="card border-0 shadow-sm mb-3">
                <div class="card-header bg-info bg-opacity-10 fw-bold">
                    <i class="bi bi-diagram-3 me-2"></i>المراحل الاختيارية
                </div>
                <div class="card-body">
                    @foreach (var opt in Model.OptionalStages)
                    {
                        <div class="d-flex justify-content-between align-items-center mb-3 p-2
                                    @(opt.IsCompleted ? "bg-success bg-opacity-10" : "bg-light") rounded">
                            <div>
                                <div class="fw-semibold">@opt.StageName</div>
                                <small class="text-muted">@opt.RoleNeeded</small>
                            </div>
                            @if (opt.IsCompleted)
                            {
                                <span class="badge bg-success">
                                    <i class="bi bi-check-lg"></i> مكتملة
                                </span>
                            }
                            else if (roles.Contains(opt.RoleNeeded) || roles.Contains("SuperAdmin"))
                            {
                                <form asp-action="CompleteOptional" method="post">
                                    @Html.AntiForgeryToken()
                                    <input type="hidden" name="id" value="@a.Id" />
                                    <input type="hidden" name="stageKey" value="@opt.StageKey" />
                                    <button type="submit" class="btn btn-sm btn-outline-success">
                                        <i class="bi bi-check-circle me-1"></i>إكمال
                                    </button>
                                </form>
                            }
                            else
                            {
                                <span class="badge bg-secondary">في الانتظار</span>
                            }
                        </div>
                    }
                </div>
            </div>
        }

        @* إجراءات التقديم والرفض *@
        @if (Model.CanAdvance || Model.CanReject)
        {
            <div class="card border-0 shadow-sm mb-3">
                <div class="card-header bg-primary bg-opacity-10 fw-bold">
                    <i class="bi bi-gear me-2"></i>إجراء المرحلة
                </div>
                <div class="card-body">
                    @if (Model.CanAdvance)
                    {
                        <form asp-action="Advance" method="post" class="mb-3">
                            @Html.AntiForgeryToken()
                            <input type="hidden" name="id" value="@a.Id" />
                            <div class="mb-2">
                                <textarea name="notes" class="form-control form-control-sm"
                                          rows="2" placeholder="ملاحظات (اختياري)"></textarea>
                            </div>
                            <button type="submit" class="btn btn-success w-100">
                                <i class="bi bi-arrow-left-circle me-2"></i>
                                @(Model.IsStage2 ? "الانتقال للمرحلة 3 (اعتماد المجلس)" :
                                  a.CurrentStage >= 11 ? "إنهاء الأصل" :
                                  $"التقديم للمرحلة {a.CurrentStage + 1}")
                            </button>
                        </form>
                    }

                    @if (Model.CanReject)
                    {
                        <form asp-action="Reject" method="post">
                            @Html.AntiForgeryToken()
                            <input type="hidden" name="id" value="@a.Id" />
                            <div class="mb-2">
                                <textarea name="reason" class="form-control form-control-sm border-danger"
                                          rows="2" placeholder="سبب الرفض..." required></textarea>
                            </div>
                            <button type="submit" class="btn btn-danger w-100"
                                    onclick="return confirm('هل أنت متأكد من رفض هذا الأصل؟')">
                                <i class="bi bi-x-circle me-2"></i>رفض الأصل
                            </button>
                        </form>
                    }
                </div>
            </div>
        }

        @* خط الوقت للمراحل *@
        <div class="card border-0 shadow-sm">
            <div class="card-header bg-light fw-bold">
                <i class="bi bi-clock-history me-2"></i>سجل المراحل
            </div>
            <div class="card-body p-2" style="max-height:320px;overflow-y:auto;">
                @if (!Model.History.Any())
                {
                    <p class="text-center text-muted small py-3">لا يوجد سجل بعد</p>
                }
                @foreach (var h in Model.History)
                {
                    <div class="d-flex gap-2 mb-3">
                        <div class="mt-1">
                            <i class="bi @(h.Action=="Rejected" ? "bi-x-circle-fill text-danger" :
                                           h.Action=="Approved" || h.Action=="Imported" ? "bi-check-circle-fill text-success" :
                                           "bi-circle-fill text-primary") fs-6"></i>
                        </div>
                        <div class="flex-grow-1">
                            <div class="fw-semibold small">
                                @h.FromName → @h.ToName
                            </div>
                            @if (!string.IsNullOrEmpty(h.Notes))
                            {
                                <div class="text-muted small">@h.Notes</div>
                            }
                            <div class="text-muted" style="font-size:11px;">
                                @h.PerformedAt.ToString("yyyy/MM/dd HH:mm")
                            </div>
                        </div>
                        <div>
                            <span class="badge @(h.Action=="Rejected" ? "bg-danger" :
                                                 h.Action=="Imported" ? "bg-secondary" : "bg-success") small">
                                @(h.Action == "Approved" ? "اعتماد" :
                                  h.Action == "Rejected" ? "رفض" :
                                  h.Action == "Imported" ? "استيراد" : h.Action)
                            </span>
                        </div>
                    </div>
                }
            </div>
        </div>

    </div>
</div>
'@

# ============================================================
# 15. WEB - Updated Program.cs (with all DI)
# ============================================================
Write-File "$web\Program.cs" @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.Services;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using AssetManagement.Infrastructure.Repository;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ── DbContext ────────────────────────────────────
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ── Identity ─────────────────────────────────────
builder.Services.AddIdentity<AppIdentityUser, IdentityRole>(options =>
{
    options.Password.RequireDigit           = false;
    options.Password.RequiredLength         = 4;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase       = false;
    options.Password.RequireLowercase       = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

builder.Services.ConfigureApplicationCookie(o =>
{
    o.LoginPath        = "/Account/Login";
    o.AccessDeniedPath = "/Account/AccessDenied";
});

// ── Repositories ─────────────────────────────────
builder.Services.AddScoped<IAssetRepository,        AssetRepository>();
builder.Services.AddScoped<IStageHistoryRepository, StageHistoryRepository>();

// ── Services ──────────────────────────────────────
builder.Services.AddScoped<IExcelImportService, ExcelImportService>();
builder.Services.AddScoped<IWorkflowService,    WorkflowService>();

builder.Services.AddControllersWithViews();

var app = builder.Build();

// ── Seed ──────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var svc         = scope.ServiceProvider;
    var userManager = svc.GetRequiredService<UserManager<AppIdentityUser>>();
    var roleManager = svc.GetRequiredService<RoleManager<IdentityRole>>();

    string[] roles = {
        "SuperAdmin","DataEntry","Marketing","Engineering",
        "AdminAffairs","Board_Low","Valuator","Finance",
        "Sales","Legal","Board_High","Treasury"
    };
    foreach (var role in roles)
        if (!await roleManager.RoleExistsAsync(role))
            await roleManager.CreateAsync(new IdentityRole(role));

    var admin = await userManager.FindByNameAsync("admin");
    if (admin == null)
    {
        admin = new AppIdentityUser
        {
            UserName       = "admin",
            Email          = "admin@system.com",
            FullName       = "مدير النظام",
            EmailConfirmed = true
        };
        await userManager.CreateAsync(admin, "1234");
        await userManager.AddToRoleAsync(admin, "SuperAdmin");
    }
    else
    {
        var token = await userManager.GeneratePasswordResetTokenAsync(admin);
        await userManager.ResetPasswordAsync(admin, token, "1234");
    }
}

// ── Middleware ────────────────────────────────────
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Dashboard}/{action=Index}/{id?}");

app.Run();
'@

# ============================================================
# 16. WEB - Updated _Layout.cshtml
# ============================================================
Write-File "$web\Views\Shared\_Layout.cshtml" @'
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@(ViewData["Title"]) - نظام إدارة الأصول</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" />
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap" rel="stylesheet" />
    <style>
        * { font-family: "Cairo", sans-serif; }
        body { background: #f0f2f5; }
        .topbar { background: #1a56db; }
        .sidebar { background: #1e3a5f; width: 240px; min-width: 240px; min-height: 100vh; position: sticky; top: 56px; }
        .sidebar .nav-item a { color: #94a3b8; display: flex; align-items: center; gap: 10px;
            padding: 10px 16px; border-radius: 8px; margin: 3px 8px; text-decoration: none;
            font-size: 14px; transition: all .2s; }
        .sidebar .nav-item a:hover { background: #2d5986; color: #fff; }
        .sidebar .nav-item a.active { background: #1a56db; color: #fff; }
        .sidebar .nav-section { color: #64748b; font-size: 11px; padding: 12px 20px 4px;
            text-transform: uppercase; letter-spacing: 1px; }
        .main { flex: 1; padding: 24px; min-width: 0; }
        .topbar-brand { color: #fff; font-weight: 700; font-size: 1.1rem; }
    </style>
</head>
<body>

<nav class="navbar topbar sticky-top shadow-sm" style="height:56px;">
    <div class="container-fluid">
        <span class="topbar-brand">
            <i class="bi bi-buildings me-2"></i>نظام إدارة الأصول العقارية
        </span>
        @if (User.Identity?.IsAuthenticated == true)
        {
            <div class="d-flex align-items-center gap-3">
                <span class="text-white small">
                    <i class="bi bi-person-circle me-1"></i>@User.Identity.Name
                </span>
                <form asp-controller="Account" asp-action="Logout" method="post" class="d-inline">
                    @Html.AntiForgeryToken()
                    <button class="btn btn-outline-light btn-sm">
                        <i class="bi bi-box-arrow-left me-1"></i>خروج
                    </button>
                </form>
            </div>
        }
    </div>
</nav>

<div class="d-flex">
    @if (User.Identity?.IsAuthenticated == true)
    {
        <div class="sidebar">
            <nav class="nav flex-column pt-2">
                <div class="nav-section">القائمة الرئيسية</div>
                <div class="nav-item">
                    <a asp-controller="Dashboard" asp-action="Index"
                       class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Dashboard" ? "active" : "")">
                        <i class="bi bi-speedometer2"></i> لوحة التحكم
                    </a>
                </div>
                <div class="nav-item">
                    <a asp-controller="Asset" asp-action="Index"
                       class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Asset" ? "active" : "")">
                        <i class="bi bi-building"></i> الأصول
                    </a>
                </div>

                <div class="nav-section mt-2">الاستيراد</div>
                <div class="nav-item">
                    <a asp-controller="AssetImport" asp-action="Index"
                       class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="AssetImport" ? "active" : "")">
                        <i class="bi bi-file-earmark-excel"></i> استيراد من Excel
                    </a>
                </div>
            </nav>
        </div>
    }

    <div class="main">
        @if (TempData["Success"] != null)
        {
            <div class="alert alert-success alert-dismissible fade show mb-3">
                <i class="bi bi-check-circle me-2"></i>@TempData["Success"]
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        }
        @RenderBody()
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
@await RenderSectionAsync("Scripts", required: false)
</body>
</html>
'@

# ============================================================
# 17. WEB - Updated _ViewImports.cshtml
# ============================================================
Write-File "$web\Views\_ViewImports.cshtml" @'
@using AssetManagement.Web
@using AssetManagement.Web.Models
@using AssetManagement.Application.ViewModels
@using AssetManagement.Domain.Entities
@using AssetManagement.Domain.Enums
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
'@

# ============================================================
# 18. WEB - HomeController redirect to Dashboard
# ============================================================
Write-File "$web\Controllers\HomeController.cs" @'
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        public IActionResult Index() =>
            RedirectToAction("Index", "Dashboard");

        public IActionResult Error() => View();
    }
}
'@

# ============================================================
# 19. FIX - ExcelImportService: remove ApplicationUser reference
# ============================================================
Write-File "$app\Services\ExcelImportService.cs" @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using OfficeOpenXml;

namespace AssetManagement.Application.Services
{
    public class ExcelImportService : IExcelImportService
    {
        private readonly IAssetRepository _repo;
        public ExcelImportService(IAssetRepository repo) => _repo = repo;

        public async Task<ImportResultViewModel> ImportAsync(Stream fileStream, string userId)
        {
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            var result = new ImportResultViewModel();

            using var package = new ExcelPackage(fileStream);
            var ws = package.Workbook.Worksheets.FirstOrDefault();

            if (ws == null)
            {
                result.ErrorCount = 1;
                result.Rows.Add(new AssetImportRowViewModel
                    { RowNumber=0, IsSuccess=false, ErrorMessage="الملف لا يحتوي على أي ورقة بيانات" });
                return result;
            }

            int lastRow = ws.Dimension?.End.Row ?? 1;
            result.TotalRows = lastRow - 1;

            for (int row = 2; row <= lastRow; row++)
            {
                var rowVm = new AssetImportRowViewModel { RowNumber = row };
                try
                {
                    string? assetName = ws.Cells[row, 1].Text?.Trim();
                    string? location  = ws.Cells[row, 2].Text?.Trim();
                    string? city      = ws.Cells[row, 3].Text?.Trim();
                    string? district  = ws.Cells[row, 4].Text?.Trim();
                    string? areaStr   = ws.Cells[row, 5].Text?.Trim();
                    string? areaUnit  = ws.Cells[row, 6].Text?.Trim();
                    string? typeTxt   = ws.Cells[row, 7].Text?.Trim();
                    string? deedNum   = ws.Cells[row, 8].Text?.Trim();
                    string? plotNum   = ws.Cells[row, 9].Text?.Trim();
                    string? legalData = ws.Cells[row, 10].Text?.Trim();
                    string? purchDate = ws.Cells[row, 11].Text?.Trim();
                    string? purchPrc  = ws.Cells[row, 12].Text?.Trim();
                    string? notes     = ws.Cells[row, 13].Text?.Trim();

                    if (string.IsNullOrWhiteSpace(assetName)) throw new Exception("اسم الأصل مطلوب");
                    if (string.IsNullOrWhiteSpace(location))  throw new Exception("الموقع مطلوب");

                    decimal? area = null;
                    if (!string.IsNullOrWhiteSpace(areaStr))
                    {
                        if (!decimal.TryParse(areaStr, out var pa)) throw new Exception("قيمة المساحة غير صحيحة");
                        area = pa;
                    }

                    AssetType type = typeTxt?.ToLower() switch
                    {
                        "بيع"  or "sale" => AssetType.Sale,
                        "إيجار" or "rent" => AssetType.Rent,
                        _                 => AssetType.Both
                    };

                    DateTime? purchaseDate = null;
                    if (!string.IsNullOrWhiteSpace(purchDate) && DateTime.TryParse(purchDate, out var pd))
                        purchaseDate = pd;

                    decimal? purchasePrice = null;
                    if (!string.IsNullOrWhiteSpace(purchPrc))
                    {
                        if (!decimal.TryParse(purchPrc, out var pp)) throw new Exception("سعر الشراء غير صحيح");
                        purchasePrice = pp;
                    }

                    int year  = DateTime.Now.Year;
                    int count = await _repo.CountByYearAsync(year) + 1;
                    string code = $"AST-{year}-{count:D5}";

                    var asset = new Asset
                    {
                        AssetCode           = code,
                        AssetName           = assetName,
                        Location            = location,
                        City                = city,
                        District            = district,
                        Area                = area,
                        AreaUnit            = string.IsNullOrWhiteSpace(areaUnit) ? "م²" : areaUnit,
                        AssetType           = type,
                        DeedNumber          = deedNum,
                        PlotNumber          = plotNum,
                        LegalDepartmentData = legalData,
                        PurchaseDate        = purchaseDate,
                        PurchasePrice       = purchasePrice,
                        Notes               = notes,
                        CurrentStage        = 1,
                        Status              = AssetStatus.Pending,
                        CreatedById         = userId,
                        CreatedAt           = DateTime.Now,
                        AssetStage = new AssetStage
                        {
                            StageNumber  = 1,
                            StageName    = "تسجيل الأصل",
                            Status       = StageStatus.Completed,
                            AssignedToId = userId,
                            StartedAt    = DateTime.Now,
                            CompletedAt  = DateTime.Now
                        },
                        StageHistories = new List<StageHistory>
                        {
                            new()
                            {
                                FromStage     = 0,
                                ToStage       = 1,
                                Action        = "Imported",
                                Notes         = "تم الاستيراد من Excel",
                                PerformedById = userId,
                                PerformedAt   = DateTime.Now
                            }
                        }
                    };

                    await _repo.AddAsync(asset);
                    await _repo.SaveChangesAsync();

                    rowVm.IsSuccess = true;
                    rowVm.AssetCode = code;
                    rowVm.AssetName = assetName;
                    rowVm.Location  = location;
                    result.SuccessCount++;
                }
                catch (Exception ex)
                {
                    rowVm.IsSuccess    = false;
                    rowVm.ErrorMessage = ex.Message;
                    rowVm.AssetName    = ws.Cells[row, 1].Text;
                    result.ErrorCount++;
                }
                result.Rows.Add(rowVm);
            }
            return result;
        }
    }
}
'@

Write-Host "`n==> All Phase 2 files created!" -ForegroundColor Green
Write-Host ""
Write-Host "==> Now run:" -ForegroundColor Yellow
Write-Host "    cd $base" -ForegroundColor White
Write-Host "    dotnet build" -ForegroundColor White
Write-Host "    cd AssetManagement.Web" -ForegroundColor White
Write-Host "    dotnet run" -ForegroundColor White