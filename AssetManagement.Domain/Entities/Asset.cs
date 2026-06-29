using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class Asset
    {
        public int    Id        { get; set; }
        public string AssetCode { get; set; } = string.Empty;
        public string AssetName { get; set; } = string.Empty;

        public int?           CategoryId { get; set; }
        public AssetCategory? Category   { get; set; }

        // â”€â”€ Ø§Ù„Ù…ÙˆÙ‚Ø¹ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public string? Location { get; set; }
        public string? City     { get; set; }
        public string? District { get; set; }
        public string? Address  { get; set; }

        // â”€â”€ Ø§Ù„Ù…Ø³Ø§Ø­Ø© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public decimal? Area         { get; set; }   // Ø§Ù„Ø­Ù‚Ù„ Ø§Ù„Ø£ØµÙ„ÙŠ â€” ÙŠÙØ¨Ù‚Ù‰ Ù„Ù„ØªÙˆØ§ÙÙ‚
        public string?  AreaUnit     { get; set; }
        public decimal? LandArea     { get; set; }   // NEW: Ù…Ø³Ø§Ø­Ø© Ø§Ù„Ø£Ø±Ø¶ Ù…Ù† Excel
        public decimal? BuildingArea { get; set; }   // NEW: Ù…Ø³Ø§Ø­Ø© Ø§Ù„Ù…Ø¨Ø§Ù†ÙŠ Ù…Ù† Excel

        // â”€â”€ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù‚Ø§Ù†ÙˆÙ†ÙŠØ© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public string? LegalDepartmentData { get; set; }
        public string? DeedNumber          { get; set; }
        public string? DeedType            { get; set; }   // NEW: Ù†ÙˆØ¹ Ø³Ù†Ø¯ Ø§Ù„Ù…Ù„ÙƒÙŠØ©
        public string? PlotNumber          { get; set; }

        // â”€â”€ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø§Ø³ØªÙŠØ±Ø§Ø¯ Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø© (Ù…Ù† Excel) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// <summary>Ø§Ù„Ù†ÙˆØ¹ Ø§Ù„ÙÙŠØ²ÙŠØ§Ø¦ÙŠ Ù„Ù„Ø£ØµÙ„: Ù…Ø­Ù„Ø§ØªØŒ Ø´Ù‚Ù‚ØŒ Ø£Ø±Ø¶ØŒ Ù…Ø®Ø²Ù†...</summary>
        public string? PropertyType { get; set; }          // NEW: nvarchar(200)
        /// <summary>ÙˆØµÙ Ø§Ù„Ø£ØµÙ„ Ø£Ùˆ Ø§Ù„ÙˆØ­Ø¯Ø© Ø¯Ø§Ø®Ù„Ù‡</summary>
        public string? AssetDescription { get; set; }      // NEW
        /// <summary>Ø§Ø³Ù… Ø§Ù„Ø´Ø±ÙƒØ© Ø§Ù„Ù…Ø§Ù„ÙƒØ©</summary>
        public string? OwnerCompany { get; set; }          // NEW
        /// <summary>Ø§Ù„Ù…ÙˆÙ‚Ù Ø§Ù„Ø­Ø§Ù„ÙŠ: Ù…Ø³ØªØºÙ„ / ØºÙŠØ± Ù…Ø³ØªØºÙ„ / Ù…Ø¤Ø¬Ø± (Ù†Øµ)</summary>
        public string? OccupancyStatus { get; set; }       // NEW: nvarchar â€” Ù„ÙŠØ³ Enum
        /// <summary>Ø§Ù„Ø¹Ø±ÙˆØ¶ Ø§Ù„Ø³Ø§Ø¨Ù‚Ø© (Ù†Øµ Ø­Ø±)</summary>
        public string? PreviousOffers { get; set; }        // NEW

        // â”€â”€ Ø§Ù„Ù…Ø§Ù„ÙŠ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public DateTime? PurchaseDate  { get; set; }
        public decimal?  PurchasePrice { get; set; }
        public decimal?  CurrentValue  { get; set; }

        // â”€â”€ Ø§Ù„ØªØµÙ†ÙŠÙ ÙˆØ³ÙŠØ± Ø§Ù„Ø¹Ù…Ù„ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public AssetType   AssetType    { get; set; } = AssetType.Both;
        public AssetStatus Status       { get; set; } = AssetStatus.Pending;
        public int         CurrentStage { get; set; } = 1;

        // â”€â”€ Ø¹Ø§Ù…Ø© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public string?          Notes       { get; set; }
        public string?          CreatedById { get; set; }
        public ApplicationUser? CreatedBy   { get; set; }
        public DateTime         CreatedAt   { get; set; } = DateTime.Now;
        public DateTime?        UpdatedAt   { get; set; }

        // â”€â”€ Ø§Ù„Ø¹Ù„Ø§Ù‚Ø§Øª â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public AssetStage? AssetStage { get; set; }
        public ICollection<StageHistory>        StageHistories        { get; set; } = new List<StageHistory>();
        public ICollection<OptionalStageDetail> OptionalStageDetails  { get; set; } = new List<OptionalStageDetail>();
        public ICollection<OptionalStageStatus> OptionalStageStatuses { get; set; } = new List<OptionalStageStatus>();
        public ICollection<RentalRequest>       RentalRequests        { get; set; } = new List<RentalRequest>();
        public ICollection<SaleRequest>         SaleRequests          { get; set; } = new List<SaleRequest>();
        public ICollection<Contract>            Contracts             { get; set; } = new List<Contract>();
        public ICollection<AssetValuation>      AssetValuations       { get; set; } = new List<AssetValuation>();
    }
}