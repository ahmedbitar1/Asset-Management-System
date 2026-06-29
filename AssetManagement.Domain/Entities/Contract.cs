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