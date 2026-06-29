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