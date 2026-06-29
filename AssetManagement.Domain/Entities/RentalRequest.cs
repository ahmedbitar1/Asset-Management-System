using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class RentalRequest
    {
        public int   Id      { get; set; }
        public int   AssetId { get; set; }
        public Asset Asset   { get; set; } = null!;

        // â”€â”€ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø³ØªØ£Ø¬Ø± â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public string  TenantName     { get; set; } = string.Empty;
        public string? TenantPhone    { get; set; }
        public string? TenantEmail    { get; set; }
        public string? TenantIdNumber { get; set; }

        // â”€â”€ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø·Ù„Ø¨ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public decimal   ProposedRent       { get; set; }
        public int       RentDurationMonths { get; set; }   // Ø§Ù„Ø­Ù‚Ù„ Ø§Ù„Ø£ØµÙ„ÙŠ â€” ÙŠÙØ¨Ù‚Ù‰
        public int?      ContractDurationYears { get; set; } // NEW: Ù…Ø¯Ø© Ø§Ù„Ø¹Ù‚Ø¯ Ø¨Ø§Ù„Ø³Ù†ÙˆØ§Øª

        // â”€â”€ Ø§Ù„Ø­Ù‚ÙˆÙ„ Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø© (Ù…Ø·Ù„ÙˆØ¨Ø© ÙÙŠ Ø§Ù„Ø¹Ù‚Ø¯) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        /// <summary>ÙØªØ±Ø© Ø§Ù„Ø³Ù…Ø§Ø­ Ù‚Ø¨Ù„ Ø¨Ø¯Ø¡ Ø³Ø±ÙŠØ§Ù† Ø§Ù„Ø¥ÙŠØ¬Ø§Ø± (Ø¨Ø§Ù„Ø£Ø´Ù‡Ø±)</summary>
        public decimal? GracePeriod      { get; set; }   // NEW
        /// <summary>Ù…Ø¨Ù„Øº Ø§Ù„ØªØ£Ù…ÙŠÙ†</summary>
        public decimal? SecurityDeposit  { get; set; }   // NEW
        /// <summary>Ù†Ø³Ø¨Ø© Ø§Ù„Ø²ÙŠØ§Ø¯Ø© Ø§Ù„Ø³Ù†ÙˆÙŠØ© %</summary>
        public decimal? AnnualIncrease   { get; set; }   // NEW

        // â”€â”€ Ø§Ù„ØªÙˆØ§Ø±ÙŠØ® â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate   { get; set; }

        // â”€â”€ Ø§Ù„Ø­Ø§Ù„Ø© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public RequestStatus Status { get; set; } = RequestStatus.Pending;
        public string?       Notes  { get; set; }

        public string?          CreatedById { get; set; }
        public ApplicationUser? CreatedBy   { get; set; }
        public DateTime         CreatedAt   { get; set; } = DateTime.Now;
    }
}