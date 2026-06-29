$base = "$env:USERPROFILE\Desktop\AssetManagement"
$inf  = "$base\AssetManagement.Infrastructure"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host "=== Stage 2: Infrastructure ===" -ForegroundColor Cyan

# ── 1. ApplicationDbContext.cs ────────────────────────────────────
[System.IO.File]::WriteAllText("$inf\Data\ApplicationDbContext.cs", @'
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Infrastructure.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options) { }

        // ── Existing DbSets ──────────────────────────────────────
        public DbSet<Asset>               Assets               { get; set; }
        public DbSet<AssetCategory>       AssetCategories      { get; set; }
        public DbSet<AssetStage>          AssetStages          { get; set; }
        public DbSet<StageHistory>        StageHistories       { get; set; }
        public DbSet<OptionalStageDetail> OptionalStageDetails { get; set; }
        public DbSet<OptionalStageStatus> OptionalStageStatuses{ get; set; }
        public DbSet<RentalRequest>       RentalRequests       { get; set; }
        public DbSet<SaleRequest>         SaleRequests         { get; set; }
        public DbSet<Contract>            Contracts            { get; set; }

        // ── New DbSets ───────────────────────────────────────────
        public DbSet<AssetValuation> AssetValuations { get; set; }
        public DbSet<ContractFile>   ContractFiles   { get; set; }

        protected override void OnModelCreating(ModelBuilder b)
        {
            base.OnModelCreating(b);

            // ── Ignore navigation properties to AspNetUsers ──────
            b.Entity<AssetStage>   (e => e.Ignore(x => x.AssignedTo));
            b.Entity<StageHistory> (e => e.Ignore(x => x.PerformedBy));
            b.Entity<RentalRequest>(e => e.Ignore(x => x.CreatedBy));
            b.Entity<SaleRequest>  (e => e.Ignore(x => x.CreatedBy));
            b.Entity<Contract>     (e => e.Ignore(x => x.GeneratedBy));

            // ── Asset ────────────────────────────────────────────
            b.Entity<Asset>(e =>
            {
                e.Ignore(x => x.CreatedBy);
                e.Property(x => x.Area         ).HasColumnType("decimal(18,2)");
                e.Property(x => x.LandArea     ).HasColumnType("decimal(18,2)");
                e.Property(x => x.BuildingArea  ).HasColumnType("decimal(18,2)");
                e.Property(x => x.PurchasePrice ).HasColumnType("decimal(18,2)");
                e.Property(x => x.CurrentValue  ).HasColumnType("decimal(18,2)");
                // PropertyType: nvarchar(200) — ليس nvarchar(max)
                e.Property(x => x.PropertyType  ).HasMaxLength(200);
                e.Property(x => x.DeedType      ).HasMaxLength(200);
                e.Property(x => x.OccupancyStatus).HasMaxLength(100);
                e.Property(x => x.OwnerCompany  ).HasMaxLength(300);
            });

            // ── AssetStage: 1:1 Cascade ──────────────────────────
            b.Entity<AssetStage>(e =>
            {
                e.HasOne(x => x.Asset).WithOne(a => a.AssetStage)
                 .HasForeignKey<AssetStage>(x => x.AssetId)
                 .OnDelete(DeleteBehavior.Cascade);
            });

            // ── RentalRequest ────────────────────────────────────
            b.Entity<RentalRequest>(e =>
            {
                e.Property(x => x.ProposedRent    ).HasColumnType("decimal(18,2)");
                e.Property(x => x.GracePeriod     ).HasColumnType("decimal(18,2)");
                e.Property(x => x.SecurityDeposit ).HasColumnType("decimal(18,2)");
                e.Property(x => x.AnnualIncrease  ).HasColumnType("decimal(18,2)");
            });

            // ── SaleRequest ──────────────────────────────────────
            b.Entity<SaleRequest>(e =>
                e.Property(x => x.OfferedPrice).HasColumnType("decimal(18,2)"));

            // ── Contract ─────────────────────────────────────────
            b.Entity<Contract>(e =>
                e.Property(x => x.Amount).HasColumnType("decimal(18,2)"));

            // ── AssetValuation: NO Cascade Delete ────────────────
            b.Entity<AssetValuation>(e =>
            {
                e.HasOne(x => x.Asset)
                 .WithMany(a => a.AssetValuations)
                 .HasForeignKey(x => x.AssetId)
                 .OnDelete(DeleteBehavior.Restrict);   // لا Cascade
                e.Property(x => x.Value).HasColumnType("decimal(18,2)");
                e.Property(x => x.EvaluationType).HasConversion<string>();
            });

            // ── ContractFile: NO Cascade Delete ──────────────────
            b.Entity<ContractFile>(e =>
            {
                e.HasOne(x => x.Contract)
                 .WithMany()
                 .HasForeignKey(x => x.ContractId)
                 .OnDelete(DeleteBehavior.Restrict);   // لا Cascade

                e.HasOne(x => x.Asset)
                 .WithMany()
                 .HasForeignKey(x => x.AssetId)
                 .OnDelete(DeleteBehavior.Restrict);   // لا Cascade
            });
        }
    }
}
'@, $utf8)
Write-Host "OK: ApplicationDbContext.cs" -ForegroundColor Green

# ── 2. AssetRepository.cs ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$inf\Repository\AssetRepository.cs", @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace AssetManagement.Infrastructure.Repository
{
    public class AssetRepository : IAssetRepository
    {
        private readonly ApplicationDbContext _ctx;
        public AssetRepository(ApplicationDbContext ctx) => _ctx = ctx;

        // ── GetAllAsync: للقوائم العامة (بدون تفاصيل كثيرة) ──────
        public async Task<IEnumerable<Asset>> GetAllAsync() =>
            await _ctx.Assets
                      .Include(a => a.Category)
                      .Include(a => a.AssetStage)
                      .Include(a => a.Contracts)
                      .OrderByDescending(a => a.CreatedAt)
                      .ToListAsync();

        // ── GetByIdAsync: للتفاصيل الكاملة مع كل العلاقات ──────
        public async Task<Asset?> GetByIdAsync(int id) =>
            await _ctx.Assets
                      .Include(a => a.Category)
                      .Include(a => a.AssetStage)
                      .Include(a => a.StageHistories.OrderByDescending(h => h.PerformedAt))
                      .Include(a => a.OptionalStageStatuses)
                      .Include(a => a.OptionalStageDetails)
                      .Include(a => a.RentalRequests.OrderByDescending(r => r.CreatedAt))
                      .Include(a => a.SaleRequests.OrderByDescending(r => r.CreatedAt))
                      .Include(a => a.Contracts.OrderByDescending(c => c.CreatedAt))
                      .Include(a => a.AssetValuations.OrderBy(v => v.EvaluationType))
                      .FirstOrDefaultAsync(a => a.Id == id);

        public async Task AddAsync(Asset asset) =>
            await _ctx.Assets.AddAsync(asset);

        public Task UpdateAsync(Asset asset)
        {
            _ctx.Assets.Update(asset);
            return Task.CompletedTask;
        }

        public void Remove(Asset asset) => _ctx.Assets.Remove(asset);

        public async Task SaveChangesAsync() =>
            await _ctx.SaveChangesAsync();

        // ── GetByRolesAsync: Workflow الجديد (10 مراحل) ───────────
        public async Task<List<Asset>> GetByRolesAsync(IList<string> roles)
        {
            if (roles.Contains("SuperAdmin"))
                return await _ctx.Assets
                                 .Include(a => a.AssetStage)
                                 .Include(a => a.Contracts)
                                 .OrderByDescending(a => a.UpdatedAt ?? a.CreatedAt)
                                 .ToListAsync();

            // Stage-Role mapping حسب Workflow الجديد
            var stages = new List<int>();
            if (roles.Contains("DataEntry"))    stages.Add(1);
            if (roles.Contains("Marketing"))  { stages.Add(2); stages.Add(4); stages.Add(8); }
            if (roles.Contains("Engineering"))  stages.Add(2);
            if (roles.Contains("AdminAffairs")) stages.Add(2);
            // Board_Low: لا مرحلة في Workflow الجديد — يُبقى الدور بدون stages
            if (roles.Contains("Valuator"))     stages.Add(3);
            if (roles.Contains("Sales"))        stages.Add(4);
            if (roles.Contains("Board_High"))   stages.Add(5);
            if (roles.Contains("Legal"))        stages.Add(6);
            if (roles.Contains("Finance"))      stages.Add(7);
            if (roles.Contains("Treasury"))     stages.Add(9);

            stages = stages.Distinct().ToList();

            return await _ctx.Assets
                             .Include(a => a.AssetStage)
                             .Where(a => stages.Contains(a.CurrentStage)
                                      && a.Status != AssetStatus.Rejected)
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
'@, $utf8)
Write-Host "OK: AssetRepository.cs" -ForegroundColor Green

Write-Host ""
Write-Host "=== Stage 2 Complete ===" -ForegroundColor Cyan
Write-Host "Files modified:"
Write-Host "  [M] Infrastructure/Data/ApplicationDbContext.cs"
Write-Host "  [M] Infrastructure/Repository/AssetRepository.cs"
Write-Host ""
Write-Host "Now running build..." -ForegroundColor Yellow
cd $base
dotnet build 2>&1 | Select-Object -Last 5

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Build OK. Ready for Migration." -ForegroundColor Green
    Write-Host ""
    Write-Host "Run this to create the migration:" -ForegroundColor Yellow
    Write-Host "  cd AssetManagement.Infrastructure" -ForegroundColor White
    Write-Host "  dotnet ef migrations add AddNewWorkflowSchema --startup-project ..\AssetManagement.Web" -ForegroundColor White
    Write-Host "  dotnet ef database update --startup-project ..\AssetManagement.Web" -ForegroundColor White
} else {
    Write-Host "Build FAILED - check errors above" -ForegroundColor Red
}
