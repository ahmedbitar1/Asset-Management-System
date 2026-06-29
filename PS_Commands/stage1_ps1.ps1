$base = "$env:USERPROFILE\Desktop\AssetManagement"
$dom  = "$base\AssetManagement.Domain"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host "=== Stage 1: Domain Entities ===" -ForegroundColor Cyan

# ── 1. Enums.cs ───────────────────────────────────────────────────
[System.IO.File]::WriteAllText("$dom\Enums\Enums.cs", @'
namespace AssetManagement.Domain.Enums
{
    public enum AssetType     { Sale, Rent, Both }
    public enum AssetStatus   { Active, Sold, Rented, Rejected, Pending }
    public enum StageStatus   { Pending, InProgress, Completed, Rejected, Skipped }
    public enum RequestStatus { Pending, UnderReview, Approved, Rejected }
    public enum ContractType  { Sale, Rent }
    public enum ContractStatus { Draft, Signed, Active, Expired, Terminated }

    // نوع التقييم — يُستخدم في جدول AssetValuations
    public enum EvaluationType { Marketing, Finance, Expert }
}
'@, $utf8)
Write-Host "OK: Enums.cs" -ForegroundColor Green

# ── 2. StageDefinition.cs ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$dom\Entities\StageDefinition.cs", @'
namespace AssetManagement.Domain.Entities
{
    /// <summary>
    /// تعريف مراحل سير العمل الجديد (10 مراحل بعد حذف المرحلة 3 القديمة والمرحلة 5 القديمة)
    /// </summary>
    public static class StageDefinition
    {
        public static readonly Dictionary<int, string> Names = new()
        {
            { 1,  "1 - رفع الأصول"              },
            { 2,  "2 - المراحل الاختيارية"       },
            { 3,  "3 - التقييم"                  },
            { 4,  "4 - طلب البيع / الإيجار"     },
            { 5,  "5 - الاعتماد النهائي"         },
            { 6,  "6 - القانونية / العقد"        },
            { 7,  "7 - المالية (مراجعة العقد)"  },
            { 8,  "8 - التسويق (رفع موقّع)"     },
            { 9,  "9 - الخزنة"                  },
            { 10, "10 - مكتمل"                  },
        };

        /// <summary>
        /// الأدوار المسموح لها بالتصرف في كل مرحلة
        /// الأسماء يجب أن تطابق أسماء الـ Roles المسجلة في AspNetRoles
        /// </summary>
        public static readonly Dictionary<int, string[]> StageRoles = new()
        {
            { 1,  new[] { "DataEntry",   "SuperAdmin" } },
            { 2,  new[] { "Marketing",   "Engineering", "AdminAffairs", "SuperAdmin" } },
            { 3,  new[] { "Valuator",    "SuperAdmin" } },
            { 4,  new[] { "Sales",       "Marketing", "SuperAdmin" } },
            { 5,  new[] { "Board_High",  "SuperAdmin" } },
            { 6,  new[] { "Legal",       "SuperAdmin" } },
            { 7,  new[] { "Finance",     "SuperAdmin" } },
            { 8,  new[] { "Marketing",   "SuperAdmin" } },
            { 9,  new[] { "Treasury",    "SuperAdmin" } },
        };

        public static string GetName(int stage) =>
            Names.TryGetValue(stage, out var n) ? n : stage.ToString();

        public static bool IsLastStage(int stage) => stage >= 10;
    }
}
'@, $utf8)
Write-Host "OK: StageDefinition.cs" -ForegroundColor Green

# ── 3. Asset.cs ───────────────────────────────────────────────────
[System.IO.File]::WriteAllText("$dom\Entities\Asset.cs", @'
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

        // ── الموقع ──────────────────────────────────────────────
        public string? Location { get; set; }
        public string? City     { get; set; }
        public string? District { get; set; }
        public string? Address  { get; set; }

        // ── المساحة ─────────────────────────────────────────────
        public decimal? Area         { get; set; }   // الحقل الأصلي — يُبقى للتوافق
        public string?  AreaUnit     { get; set; }
        public decimal? LandArea     { get; set; }   // NEW: مساحة الأرض من Excel
        public decimal? BuildingArea { get; set; }   // NEW: مساحة المباني من Excel

        // ── البيانات القانونية ────────────────────────────────────
        public string? LegalDepartmentData { get; set; }
        public string? DeedNumber          { get; set; }
        public string? DeedType            { get; set; }   // NEW: نوع سند الملكية
        public string? PlotNumber          { get; set; }

        // ── بيانات الاستيراد الجديدة (من Excel) ─────────────────
        /// <summary>النوع الفيزيائي للأصل: محلات، شقق، أرض، مخزن...</summary>
        public string? PropertyType { get; set; }          // NEW: nvarchar(200)
        /// <summary>وصف الأصل أو الوحدة داخله</summary>
        public string? AssetDescription { get; set; }      // NEW
        /// <summary>اسم الشركة المالكة</summary>
        public string? OwnerCompany { get; set; }          // NEW
        /// <summary>الموقف الحالي: مستغل / غير مستغل / مؤجر (نص)</summary>
        public string? OccupancyStatus { get; set; }       // NEW: nvarchar — ليس Enum
        /// <summary>العروض السابقة (نص حر)</summary>
        public string? PreviousOffers { get; set; }        // NEW

        // ── المالي ───────────────────────────────────────────────
        public DateTime? PurchaseDate  { get; set; }
        public decimal?  PurchasePrice { get; set; }
        public decimal?  CurrentValue  { get; set; }

        // ── التصنيف وسير العمل ───────────────────────────────────
        public AssetType   AssetType    { get; set; } = AssetType.Both;
        public AssetStatus Status       { get; set; } = AssetStatus.Pending;
        public int         CurrentStage { get; set; } = 1;

        // ── عامة ─────────────────────────────────────────────────
        public string?          Notes       { get; set; }
        public string?          CreatedById { get; set; }
        public ApplicationUser? CreatedBy   { get; set; }
        public DateTime         CreatedAt   { get; set; } = DateTime.Now;
        public DateTime?        UpdatedAt   { get; set; }

        // ── العلاقات ─────────────────────────────────────────────
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
'@, $utf8)
Write-Host "OK: Asset.cs" -ForegroundColor Green

# ── 4. RentalRequest.cs ───────────────────────────────────────────
[System.IO.File]::WriteAllText("$dom\Entities\RentalRequest.cs", @'
using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class RentalRequest
    {
        public int   Id      { get; set; }
        public int   AssetId { get; set; }
        public Asset Asset   { get; set; } = null!;

        // ── بيانات المستأجر ───────────────────────────────────────
        public string  TenantName     { get; set; } = string.Empty;
        public string? TenantPhone    { get; set; }
        public string? TenantEmail    { get; set; }
        public string? TenantIdNumber { get; set; }

        // ── بيانات الطلب ─────────────────────────────────────────
        public decimal   ProposedRent       { get; set; }
        public int       RentDurationMonths { get; set; }   // الحقل الأصلي — يُبقى
        public int?      ContractDurationYears { get; set; } // NEW: مدة العقد بالسنوات

        // ── الحقول الجديدة (مطلوبة في العقد) ───────────────────
        /// <summary>فترة السماح قبل بدء سريان الإيجار (بالأشهر)</summary>
        public decimal? GracePeriod      { get; set; }   // NEW
        /// <summary>مبلغ التأمين</summary>
        public decimal? SecurityDeposit  { get; set; }   // NEW
        /// <summary>نسبة الزيادة السنوية %</summary>
        public decimal? AnnualIncrease   { get; set; }   // NEW

        // ── التواريخ ──────────────────────────────────────────────
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate   { get; set; }

        // ── الحالة ───────────────────────────────────────────────
        public RequestStatus Status { get; set; } = RequestStatus.Pending;
        public string?       Notes  { get; set; }

        public string?          CreatedById { get; set; }
        public ApplicationUser? CreatedBy   { get; set; }
        public DateTime         CreatedAt   { get; set; } = DateTime.Now;
    }
}
'@, $utf8)
Write-Host "OK: RentalRequest.cs" -ForegroundColor Green

# ── 5. AssetValuation.cs (NEW) ────────────────────────────────────
[System.IO.File]::WriteAllText("$dom\Entities\AssetValuation.cs", @'
using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    /// <summary>
    /// يحفظ التقييمات الثلاثة المستقلة لكل أصل:
    /// Marketing (تسويق) / Finance (مالية) / Expert (مكاتب خبراء)
    /// </summary>
    public class AssetValuation
    {
        public int Id      { get; set; }
        public int AssetId { get; set; }
        public Asset Asset { get; set; } = null!;

        /// <summary>نوع التقييم: Marketing / Finance / Expert</summary>
        public EvaluationType EvaluationType { get; set; }

        /// <summary>القيمة التقديرية بالجنيه المصري</summary>
        public decimal Value { get; set; }

        /// <summary>تعليقات اختيارية على التقييم</summary>
        public string? Comments { get; set; }   // nullable — ليست إجبارية

        public DateTime EvaluationDate { get; set; } = DateTime.Now;

        /// <summary>Id المستخدم الذي أجرى التقييم</summary>
        public string? UserId { get; set; }
    }
}
'@, $utf8)
Write-Host "OK: AssetValuation.cs (NEW)" -ForegroundColor Green

# ── 6. ContractFile.cs (NEW) ──────────────────────────────────────
[System.IO.File]::WriteAllText("$dom\Entities\ContractFile.cs", @'
namespace AssetManagement.Domain.Entities
{
    /// <summary>
    /// ملفات العقد المرفوعة (PDF / Word) من قِبل التسويق بعد التوقيع
    /// </summary>
    public class ContractFile
    {
        public int Id         { get; set; }
        public int ContractId { get; set; }
        public Contract Contract { get; set; } = null!;

        public int AssetId { get; set; }
        public Asset Asset { get; set; } = null!;

        /// <summary>اسم الملف الأصلي</summary>
        public string FileName { get; set; } = string.Empty;

        /// <summary>المسار النسبي داخل wwwroot</summary>
        public string FilePath { get; set; } = string.Empty;

        /// <summary>نوع الملف: PDF أو Word</summary>
        public string FileType { get; set; } = string.Empty;

        /// <summary>حجم الملف بالبايت</summary>
        public long FileSize { get; set; }

        /// <summary>MIME type مثل application/pdf أو application/vnd.openxmlformats...</summary>
        public string ContentType { get; set; } = string.Empty;

        public string?   UploadedById { get; set; }
        public DateTime  UploadedAt   { get; set; } = DateTime.Now;
    }
}
'@, $utf8)
Write-Host "OK: ContractFile.cs (NEW)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Stage 1 Complete ===" -ForegroundColor Cyan
Write-Host "Files modified/created:"
Write-Host "  [M] Domain/Enums/Enums.cs"
Write-Host "  [M] Domain/Entities/StageDefinition.cs"
Write-Host "  [M] Domain/Entities/Asset.cs"
Write-Host "  [M] Domain/Entities/RentalRequest.cs"
Write-Host "  [N] Domain/Entities/AssetValuation.cs"
Write-Host "  [N] Domain/Entities/ContractFile.cs"
Write-Host ""
Write-Host "Next: run 'dotnet build' to verify, then proceed to Stage 2" -ForegroundColor Yellow
