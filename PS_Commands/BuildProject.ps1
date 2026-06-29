# ============================================================
# BuildProject.ps1 - Asset Management System - Clean Architecture
# شغّله بـ: powershell -ExecutionPolicy Bypass -File BuildProject.ps1
# ============================================================

$root = "AssetManagement"

Write-Host "==> Creating solution structure..." -ForegroundColor Cyan

# ── إنشاء المجلد الرئيسي والدخول إليه ───────────────────
New-Item -ItemType Directory -Force -Path $root | Out-Null
Push-Location $root

# بعد Push-Location، كل الأوامر تعمل من داخل $root
# فالمتغيرات تبدأ من هنا بدون $root
$domain = "AssetManagement.Domain"
$app    = "AssetManagement.Application"
$infra  = "AssetManagement.Infrastructure"
$web    = "AssetManagement.Web"

# ── إنشاء الـ Solution ────────────────────────────────────
dotnet new sln -n AssetManagement

# ── إنشاء الـ Projects ───────────────────────────────────
dotnet new classlib -n AssetManagement.Domain         -o AssetManagement.Domain         --framework net8.0
dotnet new classlib -n AssetManagement.Application    -o AssetManagement.Application    --framework net8.0
dotnet new classlib -n AssetManagement.Infrastructure -o AssetManagement.Infrastructure --framework net8.0
dotnet new mvc      -n AssetManagement.Web            -o AssetManagement.Web            --framework net8.0

# ── إضافة Projects للـ Solution ──────────────────────────
dotnet sln add AssetManagement.Domain\AssetManagement.Domain.csproj
dotnet sln add AssetManagement.Application\AssetManagement.Application.csproj
dotnet sln add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj
dotnet sln add AssetManagement.Web\AssetManagement.Web.csproj

# ── References بين المشاريع ──────────────────────────────
dotnet add AssetManagement.Application\AssetManagement.Application.csproj    reference AssetManagement.Domain\AssetManagement.Domain.csproj
dotnet add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj reference AssetManagement.Domain\AssetManagement.Domain.csproj
dotnet add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj reference AssetManagement.Application\AssetManagement.Application.csproj
dotnet add AssetManagement.Web\AssetManagement.Web.csproj                    reference AssetManagement.Application\AssetManagement.Application.csproj
dotnet add AssetManagement.Web\AssetManagement.Web.csproj                    reference AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj

# ── NuGet Packages ────────────────────────────────────────
Write-Host "==> Installing NuGet packages..." -ForegroundColor Yellow

# Domain - لا يحتاج packages خارجية

# Application
dotnet add AssetManagement.Application\AssetManagement.Application.csproj package EPPlus --version 7.3.2

# Infrastructure
dotnet add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj package Microsoft.AspNetCore.Identity.EntityFrameworkCore --version 8.0.0
dotnet add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj package Microsoft.EntityFrameworkCore.SqlServer            --version 8.0.0
dotnet add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj package Microsoft.EntityFrameworkCore.Tools               --version 8.0.0
dotnet add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj package ClosedXML                                         --version 0.102.3
dotnet add AssetManagement.Infrastructure\AssetManagement.Infrastructure.csproj package DinkToPdf                                         --version 1.0.8

# Web
dotnet add AssetManagement.Web\AssetManagement.Web.csproj package Microsoft.AspNetCore.Identity.UI --version 8.0.0

# ── حذف Class1.cs الافتراضية ──────────────────────────────
Remove-Item -Force -ErrorAction SilentlyContinue "$domain\Class1.cs"
Remove-Item -Force -ErrorAction SilentlyContinue "$app\Class1.cs"
Remove-Item -Force -ErrorAction SilentlyContinue "$infra\Class1.cs"

# ============================================================
Write-Host "==> Creating folders..." -ForegroundColor Cyan
# ============================================================

# Domain Folders
$folders = @(
    "$domain\Entities",
    "$domain\Enums",
    "$domain\Interfaces",
    "$app\Interfaces",
    "$app\Services",
    "$app\ViewModels",
    "$infra\Data",
    "$infra\Migrations",
    "$infra\Repository",
    "$infra\Services",
    "$web\Controllers",
    "$web\Views\Shared",
    "$web\Views\Home",
    "$web\Views\Account",
    "$web\Views\AssetImport",
    "$web\wwwroot\css",
    "$web\wwwroot\js",
    "$web\wwwroot\templates"
)
foreach ($f in $folders) {
    New-Item -ItemType Directory -Force -Path $f -ErrorAction Stop | Out-Null
}

# ============================================================
Write-Host "==> Writing source files..." -ForegroundColor Cyan
# ============================================================

# ── helper ────────────────────────────────────────────────
function Write-File($path, $content) {
    $absolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
    [System.IO.File]::WriteAllText($absolutePath, $content, [System.Text.Encoding]::UTF8)
}

# ============================================================
# DOMAIN\Enums\Enums.cs
# ============================================================
Write-File "$domain\Enums\Enums.cs" @'
namespace AssetManagement.Domain.Enums
{
    public enum AssetType   { Sale, Rent, Both }
    public enum AssetStatus { Active, Sold, Rented, Rejected, Pending }
    public enum StageStatus { Pending, InProgress, Completed, Rejected, Skipped }
    public enum RequestStatus { Pending, UnderReview, Approved, Rejected }
    public enum ContractType   { Sale, Rent }
    public enum ContractStatus { Draft, Signed, Active, Expired, Terminated }
}
'@

# ============================================================
# DOMAIN\Entities\ApplicationUser.cs
# ============================================================
Write-File "$domain\Entities\ApplicationUser.cs" @'
using Microsoft.AspNetCore.Identity;

namespace AssetManagement.Domain.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public string FullName    { get; set; } = string.Empty;
        public string? Department { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public bool IsActive      { get; set; } = true;
    }
}
'@

# ============================================================
# DOMAIN\Entities\AssetCategory.cs
# ============================================================
Write-File "$domain\Entities\AssetCategory.cs" @'
namespace AssetManagement.Domain.Entities
{
    public class AssetCategory
    {
        public int     Id          { get; set; }
        public string  Name        { get; set; } = string.Empty;
        public string? Description { get; set; }
        public ICollection<Asset> Assets { get; set; } = new List<Asset>();
    }
}
'@

# ============================================================
# DOMAIN\Entities\Asset.cs
# ============================================================
Write-File "$domain\Entities\Asset.cs" @'
using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class Asset
    {
        public int     Id        { get; set; }
        public string  AssetCode { get; set; } = string.Empty;
        public string  AssetName { get; set; } = string.Empty;

        public int?  CategoryId { get; set; }
        public AssetCategory? Category { get; set; }

        public string? Location { get; set; }
        public string? City     { get; set; }
        public string? District { get; set; }
        public string? Address  { get; set; }

        public decimal? Area     { get; set; }
        public string?  AreaUnit { get; set; }

        public string? LegalDepartmentData { get; set; }
        public string? DeedNumber          { get; set; }
        public string? PlotNumber          { get; set; }

        public DateTime? PurchaseDate  { get; set; }
        public decimal?  PurchasePrice { get; set; }
        public decimal?  CurrentValue  { get; set; }

        public AssetType   AssetType { get; set; } = AssetType.Both;
        public AssetStatus Status    { get; set; } = AssetStatus.Pending;
        public int CurrentStage      { get; set; } = 1;

        public string?   Notes       { get; set; }
        public string?   CreatedById { get; set; }
        public ApplicationUser? CreatedBy { get; set; }
        public DateTime  CreatedAt   { get; set; } = DateTime.Now;
        public DateTime? UpdatedAt   { get; set; }

        public AssetStage? AssetStage { get; set; }
        public ICollection<StageHistory>       StageHistories       { get; set; } = new List<StageHistory>();
        public ICollection<OptionalStageStatus> OptionalStageStatuses { get; set; } = new List<OptionalStageStatus>();
        public ICollection<RentalRequest>      RentalRequests       { get; set; } = new List<RentalRequest>();
        public ICollection<SaleRequest>        SaleRequests         { get; set; } = new List<SaleRequest>();
        public ICollection<Contract>           Contracts            { get; set; } = new List<Contract>();
    }
}
'@

# ============================================================
# DOMAIN\Entities\AssetStage.cs
# ============================================================
Write-File "$domain\Entities\AssetStage.cs" @'
using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class AssetStage
    {
        public int    Id          { get; set; }
        public int    AssetId     { get; set; }
        public Asset  Asset       { get; set; } = null!;

        public int         StageNumber { get; set; }
        public string      StageName   { get; set; } = string.Empty;
        public StageStatus Status      { get; set; } = StageStatus.Pending;

        public string?          AssignedToId { get; set; }
        public ApplicationUser? AssignedTo   { get; set; }

        public DateTime? StartedAt       { get; set; }
        public DateTime? CompletedAt     { get; set; }
        public string?   Notes           { get; set; }
        public string?   RejectionReason { get; set; }
    }
}
'@

# ============================================================
# DOMAIN\Entities\StageHistory.cs
# ============================================================
Write-File "$domain\Entities\StageHistory.cs" @'
namespace AssetManagement.Domain.Entities
{
    public class StageHistory
    {
        public int   Id        { get; set; }
        public int   AssetId   { get; set; }
        public Asset Asset     { get; set; } = null!;

        public int     FromStage    { get; set; }
        public int     ToStage      { get; set; }
        public string? Action       { get; set; }
        public string? Notes        { get; set; }

        public string?          PerformedById { get; set; }
        public ApplicationUser? PerformedBy   { get; set; }
        public DateTime         PerformedAt   { get; set; } = DateTime.Now;
    }
}
'@

# ============================================================
# DOMAIN\Entities\OptionalStageStatus.cs
# ============================================================
Write-File "$domain\Entities\OptionalStageStatus.cs" @'
namespace AssetManagement.Domain.Entities
{
    public class OptionalStageStatus
    {
        public int    Id          { get; set; }
        public int    AssetId     { get; set; }
        public Asset  Asset       { get; set; } = null!;

        public string   StageKey      { get; set; } = string.Empty;
        public bool     IsRequired    { get; set; } = false;
        public bool     IsCompleted   { get; set; } = false;
        public DateTime? CompletedAt  { get; set; }
        public string?  CompletedById { get; set; }
    }
}
'@

# ============================================================
# DOMAIN\Entities\RentalRequest.cs
# ============================================================
Write-File "$domain\Entities\RentalRequest.cs" @'
using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class RentalRequest
    {
        public int   Id      { get; set; }
        public int   AssetId { get; set; }
        public Asset Asset   { get; set; } = null!;

        public string  TenantName     { get; set; } = string.Empty;
        public string? TenantPhone    { get; set; }
        public string? TenantEmail    { get; set; }
        public string? TenantIdNumber { get; set; }

        public decimal  ProposedRent       { get; set; }
        public int      RentDurationMonths { get; set; }
        public DateTime? StartDate         { get; set; }
        public DateTime? EndDate           { get; set; }

        public RequestStatus Status { get; set; } = RequestStatus.Pending;
        public string?       Notes  { get; set; }

        public string?          CreatedById { get; set; }
        public ApplicationUser? CreatedBy   { get; set; }
        public DateTime         CreatedAt   { get; set; } = DateTime.Now;
    }
}
'@

# ============================================================
# DOMAIN\Entities\SaleRequest.cs
# ============================================================
Write-File "$domain\Entities\SaleRequest.cs" @'
using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class SaleRequest
    {
        public int   Id      { get; set; }
        public int   AssetId { get; set; }
        public Asset Asset   { get; set; } = null!;

        public string  BuyerName     { get; set; } = string.Empty;
        public string? BuyerPhone    { get; set; }
        public string? BuyerEmail    { get; set; }
        public string? BuyerIdNumber { get; set; }

        public decimal OfferedPrice   { get; set; }
        public string? PaymentMethod  { get; set; }
        public string? Notes          { get; set; }

        public RequestStatus Status { get; set; } = RequestStatus.Pending;

        public string?          CreatedById { get; set; }
        public ApplicationUser? CreatedBy   { get; set; }
        public DateTime         CreatedAt   { get; set; } = DateTime.Now;
    }
}
'@

# ============================================================
# DOMAIN\Entities\Contract.cs
# ============================================================
Write-File "$domain\Entities\Contract.cs" @'
using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class Contract
    {
        public int   Id      { get; set; }
        public int   AssetId { get; set; }
        public Asset Asset   { get; set; } = null!;

        public ContractType   ContractType { get; set; }
        public ContractStatus Status       { get; set; } = ContractStatus.Draft;
        public string         ContractNumber { get; set; } = string.Empty;

        public string  PartyName     { get; set; } = string.Empty;
        public string? PartyPhone    { get; set; }
        public string? PartyIdNumber { get; set; }

        public decimal   Amount    { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate   { get; set; }

        public string? PdfPath        { get; set; }
        public int?    RentalRequestId { get; set; }
        public int?    SaleRequestId   { get; set; }

        public string?          GeneratedById { get; set; }
        public ApplicationUser? GeneratedBy   { get; set; }
        public DateTime         CreatedAt     { get; set; } = DateTime.Now;
    }
}
'@

# ============================================================
# DOMAIN\Interfaces\IAssetRepository.cs
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
    }
}
'@

# ============================================================
# APPLICATION\ViewModels\ImportResultViewModel.cs
# ============================================================
Write-File "$app\ViewModels\ImportResultViewModel.cs" @'
namespace AssetManagement.Application.ViewModels
{
    public class ImportResultViewModel
    {
        public int TotalRows    { get; set; }
        public int SuccessCount { get; set; }
        public int ErrorCount   { get; set; }
        public List<AssetImportRowViewModel> Rows { get; set; } = new();
    }

    public class AssetImportRowViewModel
    {
        public int     RowNumber    { get; set; }
        public string? AssetName    { get; set; }
        public string? Location     { get; set; }
        public bool    IsSuccess    { get; set; }
        public string? ErrorMessage { get; set; }
        public string? AssetCode    { get; set; }
    }
}
'@

# ============================================================
# APPLICATION\Interfaces\IExcelImportService.cs
# ============================================================
Write-File "$app\Interfaces\IExcelImportService.cs" @'
using AssetManagement.Application.ViewModels;

namespace AssetManagement.Application.Interfaces
{
    public interface IExcelImportService
    {
        Task<ImportResultViewModel> ImportAsync(Stream fileStream, string userId);
    }
}
'@

# ============================================================
# APPLICATION\Services\ExcelImportService.cs
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
                    { RowNumber = 0, IsSuccess = false, ErrorMessage = "الملف لا يحتوي على أي ورقة بيانات" });
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

                    string code = await GenerateCodeAsync();

                    var asset = new Asset
                    {
                        AssetCode     = code,
                        AssetName     = assetName,
                        Location      = location,
                        City          = city,
                        District      = district,
                        Area          = area,
                        AreaUnit      = string.IsNullOrWhiteSpace(areaUnit) ? "م²" : areaUnit,
                        AssetType     = type,
                        DeedNumber    = deedNum,
                        PlotNumber    = plotNum,
                        LegalDepartmentData = legalData,
                        PurchaseDate  = purchaseDate,
                        PurchasePrice = purchasePrice,
                        Notes         = notes,
                        CurrentStage  = 1,
                        Status        = AssetStatus.Pending,
                        CreatedById   = userId,
                        CreatedAt     = DateTime.Now,
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
                            new StageHistory
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

        private async Task<string> GenerateCodeAsync()
        {
            // سيتم تمرير العداد من الـ Repository لاحقاً
            return $"AST-{DateTime.Now.Year}-{Guid.NewGuid().ToString()[..5].ToUpper()}";
        }
    }
}
'@

# ============================================================
# INFRASTRUCTURE\Data\ApplicationDbContext.cs
# ============================================================
Write-File "$infra\Data\ApplicationDbContext.cs" @'
using AssetManagement.Domain.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace AssetManagement.Infrastructure.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options) { }

        public DbSet<Asset>               Assets                { get; set; }
        public DbSet<AssetCategory>       AssetCategories       { get; set; }
        public DbSet<AssetStage>          AssetStages           { get; set; }
        public DbSet<StageHistory>        StageHistories        { get; set; }
        public DbSet<RentalRequest>       RentalRequests        { get; set; }
        public DbSet<SaleRequest>         SaleRequests          { get; set; }
        public DbSet<Contract>            Contracts             { get; set; }
        public DbSet<OptionalStageStatus> OptionalStageStatuses { get; set; }

        protected override void OnModelCreating(ModelBuilder b)
        {
            base.OnModelCreating(b);

            b.Entity<Asset>(e =>
            {
                e.HasKey(x => x.Id);
                e.Property(x => x.AssetCode).IsRequired().HasMaxLength(50);
                e.Property(x => x.AssetName).IsRequired().HasMaxLength(200);
                e.Property(x => x.PurchasePrice).HasColumnType("decimal(18,2)");
                e.Property(x => x.CurrentValue).HasColumnType("decimal(18,2)");
                e.Property(x => x.Area).HasColumnType("decimal(18,2)");
                e.HasIndex(x => x.AssetCode).IsUnique();

                e.HasOne(x => x.CreatedBy)
                 .WithMany().HasForeignKey(x => x.CreatedById)
                 .OnDelete(DeleteBehavior.Restrict);

                e.HasOne(x => x.Category)
                 .WithMany(c => c.Assets).HasForeignKey(x => x.CategoryId)
                 .OnDelete(DeleteBehavior.SetNull);
            });

            b.Entity<AssetStage>(e =>
            {
                e.HasOne(x => x.Asset).WithOne(a => a.AssetStage)
                 .HasForeignKey<AssetStage>(x => x.AssetId)
                 .OnDelete(DeleteBehavior.Cascade);

                e.HasOne(x => x.AssignedTo).WithMany()
                 .HasForeignKey(x => x.AssignedToId)
                 .OnDelete(DeleteBehavior.Restrict);
            });

            b.Entity<StageHistory>(e =>
            {
                e.HasOne(x => x.Asset).WithMany(a => a.StageHistories)
                 .HasForeignKey(x => x.AssetId).OnDelete(DeleteBehavior.Cascade);

                e.HasOne(x => x.PerformedBy).WithMany()
                 .HasForeignKey(x => x.PerformedById).OnDelete(DeleteBehavior.Restrict);
            });

            b.Entity<RentalRequest>(e =>
            {
                e.Property(x => x.ProposedRent).HasColumnType("decimal(18,2)");
                e.HasOne(x => x.Asset).WithMany(a => a.RentalRequests)
                 .HasForeignKey(x => x.AssetId).OnDelete(DeleteBehavior.Cascade);
            });

            b.Entity<SaleRequest>(e =>
            {
                e.Property(x => x.OfferedPrice).HasColumnType("decimal(18,2)");
                e.HasOne(x => x.Asset).WithMany(a => a.SaleRequests)
                 .HasForeignKey(x => x.AssetId).OnDelete(DeleteBehavior.Cascade);
            });

            b.Entity<Contract>(e =>
            {
                e.Property(x => x.Amount).HasColumnType("decimal(18,2)");
                e.HasOne(x => x.Asset).WithMany(a => a.Contracts)
                 .HasForeignKey(x => x.AssetId).OnDelete(DeleteBehavior.Cascade);
            });

            b.Entity<OptionalStageStatus>(e =>
            {
                e.HasOne(x => x.Asset).WithMany(a => a.OptionalStageStatuses)
                 .HasForeignKey(x => x.AssetId).OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
'@

# ============================================================
# INFRASTRUCTURE\Data\DbSeeder.cs
# ============================================================
Write-File "$infra\Data\DbSeeder.cs" @'
using AssetManagement.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;

namespace AssetManagement.Infrastructure.Data
{
    public static class DbSeeder
    {
        public static async Task SeedAsync(IServiceProvider services)
        {
            var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
            var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

            string[] roles =
            {
                "SuperAdmin","DataEntry","Marketing","Engineering",
                "AdminAffairs","Board_Low","Valuator","Finance",
                "Sales","Legal","Board_High","Treasury"
            };

            foreach (var role in roles)
                if (!await roleManager.RoleExistsAsync(role))
                    await roleManager.CreateAsync(new IdentityRole(role));

            const string adminEmail = "admin@asset.com";
            var admin = await userManager.FindByEmailAsync(adminEmail);
            if (admin == null)
            {
                admin = new ApplicationUser
                {
                    UserName         = "admin",
                    Email            = adminEmail,
                    FullName         = "مدير النظام",
                    Department       = "الإدارة العليا",
                    EmailConfirmed   = true
                };
                var res = await userManager.CreateAsync(admin, "Admin@1234");
                if (res.Succeeded)
                    await userManager.AddToRoleAsync(admin, "SuperAdmin");
            }
        }
    }
}
'@

# ============================================================
# INFRASTRUCTURE\Repository\AssetRepository.cs
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
            await _ctx.Assets.Include(a => a.Category).ToListAsync();

        public async Task<Asset?> GetByIdAsync(int id) =>
            await _ctx.Assets
                      .Include(a => a.Category)
                      .Include(a => a.AssetStage)
                      .Include(a => a.StageHistories)
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
    }
}
'@

# ============================================================
# WEB\Controllers\AccountController.cs
# ============================================================
Write-File "$web\Controllers\AccountController.cs" @'
using AssetManagement.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    public class AccountController : Controller
    {
        private readonly SignInManager<ApplicationUser> _signIn;
        public AccountController(SignInManager<ApplicationUser> signIn)
            => _signIn = signIn;

        [HttpGet]
        public IActionResult Login(string? returnUrl = null)
        {
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(string username, string password, string? returnUrl = null)
        {
            var result = await _signIn.PasswordSignInAsync(username, password, false, false);
            if (result.Succeeded)
                return LocalRedirect(returnUrl ?? "/");

            ModelState.AddModelError("", "اسم المستخدم أو كلمة المرور غير صحيحة");
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await _signIn.SignOutAsync();
            return RedirectToAction("Login");
        }

        public IActionResult AccessDenied() => View();
    }
}
'@

# ============================================================
# WEB\Controllers\HomeController.cs
# ============================================================
Write-File "$web\Controllers\HomeController.cs" @'
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        public IActionResult Index() => View();
    }
}
'@

# ============================================================
# WEB\Controllers\AssetImportController.cs
# ============================================================
Write-File "$web\Controllers\AssetImportController.cs" @'
using AssetManagement.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    [Authorize(Roles = "DataEntry,SuperAdmin")]
    public class AssetImportController : Controller
    {
        private readonly IExcelImportService _importService;
        public AssetImportController(IExcelImportService importService)
            => _importService = importService;

        [HttpGet]
        public IActionResult Index() => View();

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Upload(IFormFile file)
        {
            if (file == null || file.Length == 0)
            { ModelState.AddModelError("", "يرجى اختيار ملف Excel"); return View("Index"); }

            if (!Path.GetExtension(file.FileName).Equals(".xlsx", StringComparison.OrdinalIgnoreCase))
            { ModelState.AddModelError("", "يُقبل فقط ملفات .xlsx"); return View("Index"); }

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            using var stream = file.OpenReadStream();
            var result = await _importService.ImportAsync(stream, userId);
            return View("Result", result);
        }

        [HttpGet]
        public IActionResult DownloadTemplate()
        {
            var path = Path.Combine(Directory.GetCurrentDirectory(),
                "wwwroot", "templates", "AssetImportTemplate.xlsx");
            if (!System.IO.File.Exists(path)) return NotFound("القالب غير موجود");
            return PhysicalFile(path,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "AssetImportTemplate.xlsx");
        }
    }
}
'@

# ============================================================
# WEB\Program.cs
# ============================================================
Write-File "$web\Program.cs" @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.Services;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using AssetManagement.Infrastructure.Repository;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<ApplicationDbContext>(o =>
    o.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddIdentity<ApplicationUser, IdentityRole>(o =>
{
    o.Password.RequiredLength        = 8;
    o.Password.RequireNonAlphanumeric = true;
    o.Password.RequireUppercase       = true;
    o.Password.RequireDigit           = true;
    o.SignIn.RequireConfirmedAccount  = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

builder.Services.ConfigureApplicationCookie(o =>
{
    o.LoginPath       = "/Account/Login";
    o.LogoutPath      = "/Account/Logout";
    o.AccessDeniedPath = "/Account/AccessDenied";
});

// DI
builder.Services.AddScoped<IAssetRepository,    AssetRepository>();
builder.Services.AddScoped<IExcelImportService, ExcelImportService>();

builder.Services.AddControllersWithViews();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{ app.UseExceptionHandler("/Home/Error"); app.UseHsts(); }

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}");

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    await db.Database.MigrateAsync();
    await DbSeeder.SeedAsync(scope.ServiceProvider);
}

app.Run();
'@

# ============================================================
# WEB\appsettings.json
# ============================================================
Write-File "$web\appsettings.json" @'
{
  "ConnectionStrings": {
    "Default": "Server=10.10.200.23\\bek_sql2;Database=AssetManagementDB;User Id=sa;Password=20@dminPa$$13;Encrypt=False;MultipleActiveResultSets=True;TrustServerCertificate=True;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
'@

# ============================================================
# WEB\Views\Shared\_Layout.cshtml
# ============================================================
Write-File "$web\Views\Shared\_Layout.cshtml" @'
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - نظام إدارة الأصول العقارية</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"/>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&family=Inter:wght@400;600&display=swap" rel="stylesheet"/>
    <style>
        body { font-family: "Cairo", sans-serif; background: #f5f7fa; }
        .sidebar { min-height: calc(100vh - 56px); background: #1e3a5f; }
        .sidebar .nav-link { color: rgba(255,255,255,.75); padding:.6rem 1rem; border-radius:8px; }
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color:#fff; background:rgba(255,255,255,.15); }
    </style>
    @await RenderSectionAsync("Styles", required: false)
</head>
<body>
<nav class="navbar navbar-dark bg-primary sticky-top shadow-sm">
    <div class="container-fluid">
        <a class="navbar-brand fw-bold" href="/"><i class="bi bi-buildings me-2"></i>نظام إدارة الأصول العقارية</a>
        <div class="d-flex align-items-center gap-2">
            @if (User.Identity?.IsAuthenticated == true)
            {
                <span class="text-white small"><i class="bi bi-person-circle me-1"></i>@User.Identity.Name</span>
                <form asp-controller="Account" asp-action="Logout" method="post" class="d-inline">
                    @Html.AntiForgeryToken()
                    <button type="submit" class="btn btn-outline-light btn-sm"><i class="bi bi-box-arrow-left me-1"></i>خروج</button>
                </form>
            }
        </div>
    </div>
</nav>
<div class="container-fluid">
    <div class="row">
        @if (User.Identity?.IsAuthenticated == true)
        {
            <div class="col-md-2 px-0 sidebar">
                <nav class="nav flex-column p-3 gap-1">
                    <a class="nav-link" asp-controller="Home" asp-action="Index"><i class="bi bi-house me-2"></i>الرئيسية</a>
                    @if (User.IsInRole("DataEntry") || User.IsInRole("SuperAdmin"))
                    {
                        <a class="nav-link" asp-controller="AssetImport" asp-action="Index"><i class="bi bi-file-earmark-excel me-2"></i>استيراد أصول</a>
                    }
                </nav>
            </div>
            <main class="col-md-10 py-3">@RenderBody()</main>
        }
        else
        {
            <main class="col-12 py-3">@RenderBody()</main>
        }
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
@await RenderSectionAsync("Scripts", required: false)
</body>
</html>
'@

# ============================================================
# WEB\Views\Shared\_ViewImports.cshtml
# ============================================================
Write-File "$web\Views\_ViewImports.cshtml" @'
@using AssetManagement.Web
@using AssetManagement.Application.ViewModels
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers
'@

# ============================================================
# WEB\Views\_ViewStart.cshtml
# ============================================================
Write-File "$web\Views\_ViewStart.cshtml" @'
@{
    Layout = "_Layout";
}
'@

# ============================================================
# WEB\Views\Home\Index.cshtml
# ============================================================
Write-File "$web\Views\Home\Index.cshtml" @'
@{
    ViewData["Title"] = "الرئيسية";
}
<div class="container-fluid mt-4">
    <div class="card shadow-sm border-0">
        <div class="card-body text-center py-5">
            <i class="bi bi-buildings display-1 text-primary"></i>
            <h2 class="mt-3">مرحباً بك في نظام إدارة الأصول العقارية</h2>
            <p class="text-muted">اختر من القائمة الجانبية للبدء</p>
        </div>
    </div>
</div>
'@

# ============================================================
# WEB\Views\Account\Login.cshtml
# ============================================================
Write-File "$web\Views\Account\Login.cshtml" @'
@{
    ViewData["Title"] = "تسجيل الدخول";
    Layout = null;
}
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8"/>
    <title>تسجيل الدخول</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css"/>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;700&display=swap" rel="stylesheet"/>
    <style>body{font-family:"Cairo",sans-serif;background:#f0f4f8;}</style>
</head>
<body>
<div class="min-vh-100 d-flex align-items-center justify-content-center">
    <div class="card shadow border-0" style="width:400px">
        <div class="card-header bg-primary text-white text-center py-4">
            <i class="bi bi-buildings fs-1"></i>
            <h5 class="mt-2 mb-0">نظام إدارة الأصول العقارية</h5>
        </div>
        <div class="card-body p-4">
            @if (!ViewData.ModelState.IsValid)
            {
                <div class="alert alert-danger">
                    @foreach (var e in ViewData.ModelState.Values.SelectMany(v => v.Errors))
                    { <p class="mb-0">@e.ErrorMessage</p> }
                </div>
            }
            <form method="post" asp-action="Login" asp-controller="Account">
                @Html.AntiForgeryToken()
                <input type="hidden" name="returnUrl" value="@ViewData["ReturnUrl"]"/>
                <div class="mb-3">
                    <label class="form-label fw-semibold">اسم المستخدم</label>
                    <input type="text" name="username" class="form-control" required autofocus/>
                </div>
                <div class="mb-4">
                    <label class="form-label fw-semibold">كلمة المرور</label>
                    <input type="password" name="password" class="form-control" required/>
                </div>
                <div class="d-grid">
                    <button type="submit" class="btn btn-primary btn-lg">
                        <i class="bi bi-box-arrow-in-right me-2"></i>دخول
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
'@

# ============================================================
# WEB\Views\AssetImport\Index.cshtml
# ============================================================
Write-File "$web\Views\AssetImport\Index.cshtml" @'
@{
    ViewData["Title"] = "استيراد الأصول من Excel";
}
<div class="container-fluid mt-4">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card shadow-sm border-0">
                <div class="card-header bg-primary text-white">
                    <h5 class="mb-0"><i class="bi bi-file-earmark-excel me-2"></i>استيراد الأصول من ملف Excel</h5>
                </div>
                <div class="card-body">
                    @if (!ViewData.ModelState.IsValid)
                    {
                        <div class="alert alert-danger">
                            @foreach (var e in ViewData.ModelState.Values.SelectMany(v => v.Errors))
                            { <p class="mb-0">@e.ErrorMessage</p> }
                        </div>
                    }
                    <div class="alert alert-info">
                        <i class="bi bi-info-circle me-2"></i>
                        استخدم القالب المخصص:
                        <a asp-action="DownloadTemplate" class="alert-link fw-bold">تحميل القالب</a>
                    </div>
                    <form asp-action="Upload" method="post" enctype="multipart/form-data">
                        @Html.AntiForgeryToken()
                        <div class="mb-4">
                            <label class="form-label fw-semibold">اختر ملف Excel (.xlsx)</label>
                            <input type="file" name="file" class="form-control form-control-lg" accept=".xlsx" required/>
                        </div>
                        <div class="d-grid">
                            <button type="submit" class="btn btn-primary btn-lg">
                                <i class="bi bi-upload me-2"></i>رفع واستيراد
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
'@

# ============================================================
# WEB\Views\AssetImport\Result.cshtml
# ============================================================
Write-File "$web\Views\AssetImport\Result.cshtml" @'
@model AssetManagement.Application.ViewModels.ImportResultViewModel
@{
    ViewData["Title"] = "نتيجة الاستيراد";
}
<div class="container-fluid mt-4">
    <h4 class="mb-4"><i class="bi bi-clipboard-check me-2"></i>نتيجة استيراد الأصول</h4>
    <div class="row g-3 mb-4">
        <div class="col-md-4">
            <div class="card text-center border-0 shadow-sm">
                <div class="card-body"><h2 class="text-primary fw-bold">@Model.TotalRows</h2><p class="mb-0 text-muted">إجمالي الصفوف</p></div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center border-0 shadow-sm bg-success bg-opacity-10">
                <div class="card-body"><h2 class="text-success fw-bold">@Model.SuccessCount</h2><p class="mb-0 text-muted">تم بنجاح</p></div>
            </div>
        </div>
        <div class="col-md-4">
            <div class="card text-center border-0 shadow-sm bg-danger bg-opacity-10">
                <div class="card-body"><h2 class="text-danger fw-bold">@Model.ErrorCount</h2><p class="mb-0 text-muted">أخطاء</p></div>
            </div>
        </div>
    </div>
    <div class="card shadow-sm border-0">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-dark">
                        <tr><th>#</th><th>الصف</th><th>الأصل</th><th>الموقع</th><th>الكود</th><th>الحالة</th><th>ملاحظة</th></tr>
                    </thead>
                    <tbody>
                        @foreach (var item in Model.Rows.Select((r, i) => new { Row = r, Index = i + 1 }))
                        {
                            <tr class="@(item.Row.IsSuccess ? "" : "table-danger")">
                                <td>@item.Index</td>
                                <td>@item.Row.RowNumber</td>
                                <td>@item.Row.AssetName</td>
                                <td>@item.Row.Location</td>
                                <td>@if(item.Row.IsSuccess){<span class="badge bg-primary">@item.Row.AssetCode</span>}</td>
                                <td>
                                    @if(item.Row.IsSuccess){<span class="badge bg-success"><i class="bi bi-check-circle me-1"></i>نجح</span>}
                                    else{<span class="badge bg-danger"><i class="bi bi-x-circle me-1"></i>خطأ</span>}
                                </td>
                                <td>@item.Row.ErrorMessage</td>
                            </tr>
                        }
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="mt-3">
        <a asp-action="Index" class="btn btn-outline-primary"><i class="bi bi-arrow-right me-1"></i>استيراد آخر</a>
        <a asp-controller="Home" asp-action="Index" class="btn btn-secondary ms-2">الرئيسية</a>
    </div>
</div>
'@

# ============================================================
# تحديث Domain .csproj لإضافة Identity reference
# ============================================================
$domainCsproj = Get-Content "$domain\AssetManagement.Domain.csproj" -Raw
$domainCsproj = $domainCsproj -replace '</Project>', @'
  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.Identity" Version="2.2.0" />
  </ItemGroup>
</Project>
'@
Set-Content "$domain\AssetManagement.Domain.csproj" $domainCsproj

# ============================================================
# Migration + Run
# ============================================================
Write-Host ""
Write-Host "==> All files created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "==> Next steps:" -ForegroundColor Yellow
Write-Host "    cd AssetManagement.Infrastructure" -ForegroundColor White
Write-Host "    dotnet ef migrations add InitialCreate --startup-project ..\AssetManagement.Web" -ForegroundColor White
Write-Host "    dotnet ef database update --startup-project ..\AssetManagement.Web" -ForegroundColor White
Write-Host "    cd ..\AssetManagement.Web" -ForegroundColor White
Write-Host "    dotnet run" -ForegroundColor White
Write-Host ""
Write-Host "==> Login: username=admin | password=Admin@1234" -ForegroundColor Cyan

Pop-Location