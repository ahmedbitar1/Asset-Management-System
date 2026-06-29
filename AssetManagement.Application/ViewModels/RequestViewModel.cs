using System.ComponentModel.DataAnnotations;

namespace AssetManagement.Application.ViewModels
{
    public class RentalRequestViewModel
    {
        public int    AssetId          { get; set; }
        public string AssetName        { get; set; } = string.Empty;
        public string AssetCode        { get; set; } = string.Empty;
        public string? AssetPropertyType { get; set; }

        [Required(ErrorMessage = "اسم المستأجر مطلوب")]
        public string  TenantName      { get; set; } = string.Empty;
        public string? TenantPhone     { get; set; }
        public string? TenantEmail     { get; set; }
        public string? TenantIdNumber  { get; set; }
        public string? TenantNationality { get; set; }

        [Required(ErrorMessage = "الإيجار الشهري مطلوب")]
        [Range(1, double.MaxValue, ErrorMessage = "الإيجار المقترح مطلوب")]
        public decimal ProposedRent    { get; set; }

        [Required(ErrorMessage = "مدة العقد مطلوبة")]
        [Range(1, 99, ErrorMessage = "مدة العقد يجب أن تكون بين 1 و 99 سنة")]
        public int ContractDurationYears { get; set; } = 1;

        public int RentDurationMonths => ContractDurationYears * 12;

        [Range(0, 24, ErrorMessage = "فترة السماح يجب أن تكون بين 0 و 24 شهراً")]
        public decimal? GracePeriod    { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "مبلغ التأمين يجب أن يكون إيجابياً")]
        public decimal? SecurityDeposit { get; set; }

        [Range(0, 100, ErrorMessage = "الزيادة السنوية يجب أن تكون نسبة بين 0 و 100")]
        public decimal? AnnualIncrease  { get; set; }

        public DateTime? StartDate     { get; set; } = DateTime.Today;
        public string?   PaymentMethod { get; set; }
        public string?   Notes         { get; set; }
    }

    public class SaleRequestViewModel
    {
        public int    AssetId          { get; set; }
        public string AssetName        { get; set; } = string.Empty;
        public string AssetCode        { get; set; } = string.Empty;
        public string? AssetPropertyType { get; set; }

        [Required(ErrorMessage = "اسم المشتري مطلوب")]
        public string  BuyerName       { get; set; } = string.Empty;
        public string? BuyerPhone      { get; set; }
        public string? BuyerEmail      { get; set; }
        public string? BuyerIdNumber   { get; set; }
        public string? BuyerNationality { get; set; }

        [Required(ErrorMessage = "السعر المعروض مطلوب")]
        [Range(1, double.MaxValue, ErrorMessage = "السعر المعروض مطلوب")]
        public decimal OfferedPrice    { get; set; }
        public string? PaymentMethod   { get; set; }
        public string? Notes           { get; set; }
    }

    public class ContractViewModel
    {
        public int      AssetId              { get; set; }
        public string   AssetName            { get; set; } = string.Empty;
        public string   AssetCode            { get; set; } = string.Empty;
        public string   AssetLocation        { get; set; } = string.Empty;
        public decimal? AssetArea            { get; set; }
        public string?  AreaUnit             { get; set; }
        public int?     RentalRequestId      { get; set; }
        public int?     SaleRequestId        { get; set; }
        public string   ContractType         { get; set; } = string.Empty;
        public string   PartyName            { get; set; } = string.Empty;
        public string?  PartyPhone           { get; set; }
        public string?  PartyIdNumber        { get; set; }
        public decimal  Amount               { get; set; }
        public DateTime? StartDate           { get; set; }
        public DateTime? EndDate             { get; set; }
        public decimal? GracePeriod          { get; set; }
        public decimal? SecurityDeposit      { get; set; }
        public decimal? AnnualIncrease       { get; set; }
        public int?     ContractDurationYears { get; set; }
        public string?  Notes                { get; set; }
    }

    public class ValuationViewModel
    {
        public int AssetId { get; set; }

        [Range(1, double.MaxValue, ErrorMessage = "قيمة التقييم مطلوبة")]
        public decimal MarketingValue    { get; set; }
        public string? MarketingComments { get; set; }

        [Range(1, double.MaxValue, ErrorMessage = "قيمة التقييم مطلوبة")]
        public decimal FinanceValue      { get; set; }
        public string? FinanceComments   { get; set; }

        [Range(1, double.MaxValue, ErrorMessage = "قيمة التقييم مطلوبة")]
        public decimal ExpertValue       { get; set; }
        public string? ExpertComments    { get; set; }

        // kept as DispositionType to match controller and view
        [Required]
        public AssetManagement.Domain.Enums.AssetType DispositionType { get; set; }
            = AssetManagement.Domain.Enums.AssetType.Both;

        public string? Notes { get; set; }
    }
}
