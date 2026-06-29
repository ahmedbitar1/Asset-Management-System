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

        // â”€â”€ Existing DbSets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public DbSet<Asset>               Assets               { get; set; }
        public DbSet<AssetCategory>       AssetCategories      { get; set; }
        public DbSet<AssetStage>          AssetStages          { get; set; }
        public DbSet<StageHistory>        StageHistories       { get; set; }
        public DbSet<OptionalStageDetail> OptionalStageDetails { get; set; }
        public DbSet<OptionalStageStatus> OptionalStageStatuses{ get; set; }
        public DbSet<RentalRequest>       RentalRequests       { get; set; }
        public DbSet<SaleRequest>         SaleRequests         { get; set; }
        public DbSet<Contract>            Contracts            { get; set; }

        // â”€â”€ New DbSets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public DbSet<AssetValuation> AssetValuations { get; set; }
        public DbSet<ContractFile>   ContractFiles   { get; set; }

        protected override void OnModelCreating(ModelBuilder b)
        {
            base.OnModelCreating(b);

            // â”€â”€ Ignore navigation properties to AspNetUsers â”€â”€â”€â”€â”€â”€
            b.Entity<AssetStage>   (e => e.Ignore(x => x.AssignedTo));
            b.Entity<StageHistory> (e => e.Ignore(x => x.PerformedBy));
            b.Entity<RentalRequest>(e => e.Ignore(x => x.CreatedBy));
            b.Entity<SaleRequest>  (e => e.Ignore(x => x.CreatedBy));
            b.Entity<Contract>     (e => e.Ignore(x => x.GeneratedBy));

            // â”€â”€ Asset â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            b.Entity<Asset>(e =>
            {
                e.Ignore(x => x.CreatedBy);
                e.Property(x => x.Area         ).HasColumnType("decimal(18,2)");
                e.Property(x => x.LandArea     ).HasColumnType("decimal(18,2)");
                e.Property(x => x.BuildingArea  ).HasColumnType("decimal(18,2)");
                e.Property(x => x.PurchasePrice ).HasColumnType("decimal(18,2)");
                e.Property(x => x.CurrentValue  ).HasColumnType("decimal(18,2)");
                // PropertyType: nvarchar(200) â€” Ù„ÙŠØ³ nvarchar(max)
                e.Property(x => x.PropertyType  ).HasMaxLength(200);
                e.Property(x => x.DeedType      ).HasMaxLength(200);
                e.Property(x => x.OccupancyStatus).HasMaxLength(100);
                e.Property(x => x.OwnerCompany  ).HasMaxLength(300);
            });

            // â”€â”€ AssetStage: 1:1 Cascade â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            b.Entity<AssetStage>(e =>
            {
                e.HasOne(x => x.Asset).WithOne(a => a.AssetStage)
                 .HasForeignKey<AssetStage>(x => x.AssetId)
                 .OnDelete(DeleteBehavior.Cascade);
            });

            // â”€â”€ RentalRequest â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            b.Entity<RentalRequest>(e =>
            {
                e.Property(x => x.ProposedRent    ).HasColumnType("decimal(18,2)");
                e.Property(x => x.GracePeriod     ).HasColumnType("decimal(18,2)");
                e.Property(x => x.SecurityDeposit ).HasColumnType("decimal(18,2)");
                e.Property(x => x.AnnualIncrease  ).HasColumnType("decimal(18,2)");
            });

            // â”€â”€ SaleRequest â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            b.Entity<SaleRequest>(e =>
                e.Property(x => x.OfferedPrice).HasColumnType("decimal(18,2)"));

            // â”€â”€ Contract â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            b.Entity<Contract>(e =>
                e.Property(x => x.Amount).HasColumnType("decimal(18,2)"));

            // â”€â”€ AssetValuation: NO Cascade Delete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            b.Entity<AssetValuation>(e =>
            {
                e.HasOne(x => x.Asset)
                 .WithMany(a => a.AssetValuations)
                 .HasForeignKey(x => x.AssetId)
                 .OnDelete(DeleteBehavior.Restrict);   // Ù„Ø§ Cascade
                e.Property(x => x.Value).HasColumnType("decimal(18,2)");
                e.Property(x => x.EvaluationType).HasConversion<string>();
            });

            // â”€â”€ ContractFile: NO Cascade Delete â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            b.Entity<ContractFile>(e =>
            {
                e.HasOne(x => x.Contract)
                 .WithMany()
                 .HasForeignKey(x => x.ContractId)
                 .OnDelete(DeleteBehavior.Restrict);   // Ù„Ø§ Cascade

                e.HasOne(x => x.Asset)
                 .WithMany()
                 .HasForeignKey(x => x.AssetId)
                 .OnDelete(DeleteBehavior.Restrict);   // Ù„Ø§ Cascade
            });
        }
    }
}