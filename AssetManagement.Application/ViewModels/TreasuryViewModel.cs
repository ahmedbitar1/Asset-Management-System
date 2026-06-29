using System.ComponentModel.DataAnnotations;

namespace AssetManagement.Application.ViewModels
{
    public class TreasuryViewModel
    {
        public int     AssetId      { get; set; }
        public string  AssetName    { get; set; } = string.Empty;
        public string  AssetCode    { get; set; } = string.Empty;
        public string? PartyName    { get; set; }
        public decimal Amount       { get; set; }
        public string  ContractType { get; set; } = "Sale"; // not required - hidden

        [Required]
        public string  PaymentMethod { get; set; } = string.Empty;
        public string? ReceiptNumber { get; set; }
        public string? Notes         { get; set; }
        public DateTime CollectionDate { get; set; } = DateTime.Today;
    }
}