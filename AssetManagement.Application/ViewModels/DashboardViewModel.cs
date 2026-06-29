using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class DashboardViewModel
    {
        public string       UserName  { get; set; } = string.Empty;
        public List<string> Roles     { get; set; } = new();
        public List<AssetCardViewModel> PendingAssets { get; set; } = new();
        public List<AssetCardViewModel> AllAssets     { get; set; } = new();
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
        public string? PropertyType { get; set; }
        public int     CurrentStage { get; set; }

        public static readonly Dictionary<int, string> StageNames = new()
        {
            { 1,  "1 - رفع الأصول" },
            { 2,  "2 - المراحل الاختيارية" },
            { 3,  "3 - التقييم" },
            { 4,  "4 - طلب البيع / الإيجار" },
            { 5,  "5 - الاعتماد النهائي" },
            { 6,  "6 - القانونية / العقد" },
            { 7,  "7 - المالية (مراجعة العقد)" },
            { 8,  "8 - القانونية (عقد موقع)" },
            { 9,  "9 - الخزنة" },
            { 10, "10 - مكتمل" },
        };

        public string StageName =>
            StageNames.TryGetValue(CurrentStage, out var n) ? n : CurrentStage.ToString();

        public AssetStatus Status    { get; set; }
        public AssetType   AssetType { get; set; }

        public string StatusAr => Status switch
        {
            AssetStatus.Active   => "نشط",
            AssetStatus.Sold     => "تم البيع",
            AssetStatus.Rented   => "تم التأجير",
            AssetStatus.Rejected => "مرفوض",
            _                    => "قيد الانتظار"
        };

        public string StatusColor => Status switch
        {
            AssetStatus.Active   => "success",
            AssetStatus.Sold     => "primary",
            AssetStatus.Rented   => "info",
            AssetStatus.Rejected => "danger",
            _                    => "warning"
        };

        public string TypeAr => AssetType switch
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
