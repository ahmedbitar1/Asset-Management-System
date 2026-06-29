$base = "$env:USERPROFILE\Desktop\AssetManagement"
$app  = "$base\AssetManagement.Application"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host "=== Stage 3: Application Layer ===" -ForegroundColor Cyan

# ── 1. WorkflowService.cs ─────────────────────────────────────────
[System.IO.File]::WriteAllText("$app\Services\WorkflowService.cs", @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;

namespace AssetManagement.Application.Services
{
    public class WorkflowService : IWorkflowService
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _historyRepo;

        public WorkflowService(IAssetRepository repo, IStageHistoryRepository historyRepo)
        {
            _repo        = repo;
            _historyRepo = historyRepo;
        }

        // ── Advance ──────────────────────────────────────────────
        public async Task<(bool Success, string Message)> AdvanceStageAsync(
            int assetId, string userId, string? notes = null)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");

            if (StageDefinition.IsLastStage(asset.CurrentStage))
                return (false, "Workflow already completed");

            int from = asset.CurrentStage;

            // المرحلة 2: تحقق من اكتمال المراحل الاختيارية الإلزامية
            if (from == 2)
            {
                var pending = asset.OptionalStageStatuses
                    .Where(o => o.IsRequired && !o.IsCompleted).ToList();
                if (pending.Any())
                    return (false, "لم يتم استكمال المراحل الاختيارية المطلوبة بعد");
            }

            // المرحلة 3: التقييم — يجب وجود تقييم واحد على الأقل قبل الانتقال
            if (from == 3)
            {
                if (!asset.AssetValuations.Any())
                    return (false, "يجب إدخال تقييم واحد على الأقل قبل المتابعة");
            }

            int to = from + 1;
            asset.CurrentStage = to;
            asset.UpdatedAt    = DateTime.Now;

            UpdateAssetStage(asset, to, userId);

            // المرحلة 10: مكتمل — تحديث حالة الأصل
            if (StageDefinition.IsLastStage(to))
                SetFinalStatus(asset);

            await _repo.UpdateAsync(asset);
            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = to,
                Action        = "Approved",
                Notes         = notes,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            return (true, "تم الانتقال إلى: " + StageDefinition.GetName(to));
        }

        // ── Reject ───────────────────────────────────────────────
        public async Task<(bool Success, string Message)> RejectStageAsync(
            int assetId, string userId, string reason)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");

            int from     = asset.CurrentStage;
            asset.Status = AssetStatus.Rejected;
            asset.UpdatedAt = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.Status          = StageStatus.Rejected;
                asset.AssetStage.RejectionReason = reason;
                asset.AssetStage.CompletedAt     = DateTime.Now;
            }

            await _repo.UpdateAsync(asset);
            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = from,
                Action        = "Rejected",
                Notes         = reason,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            return (true, "تم رفض الأصل بنجاح");
        }

        // ── Complete Optional Stage ───────────────────────────────
        public async Task<(bool Success, string Message)> CompleteOptionalStageAsync(
            int assetId, string userId, string stageKey)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");

            var opt = asset.OptionalStageStatuses.FirstOrDefault(o => o.StageKey == stageKey);
            if (opt == null) return (false, "Optional stage not found");

            opt.IsCompleted   = true;
            opt.CompletedAt   = DateTime.Now;
            opt.CompletedById = userId;

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();
            return (true, "تم إكمال المرحلة الاختيارية: " + stageKey);
        }

        // ── Get Assets By Role (Workflow الجديد) ─────────────────
        public async Task<List<Asset>> GetAssetsByRoleAsync(string userId, IList<string> roles)
        {
            var all = await _repo.GetAllAsync();
            if (roles.Contains("SuperAdmin"))
                return all.OrderByDescending(a => a.CreatedAt).ToList();

            return all.Where(a =>
            {
                if (a.Status == AssetStatus.Rejected) return false;
                if (!StageDefinition.StageRoles.TryGetValue(a.CurrentStage, out var sr)) return false;
                return sr.Any(r => roles.Contains(r));
            }).OrderByDescending(a => a.CreatedAt).ToList();
        }

        public async Task<Asset?> GetAssetDetailAsync(int id) =>
            await _repo.GetByIdAsync(id);

        // ── Private Helpers ───────────────────────────────────────
        private static void UpdateAssetStage(Asset asset, int toStage, string userId)
        {
            if (asset.AssetStage == null) return;
            asset.AssetStage.StageNumber  = toStage;
            asset.AssetStage.StageName    = StageDefinition.GetName(toStage);
            asset.AssetStage.Status       = StageDefinition.IsLastStage(toStage)
                                             ? StageStatus.Completed
                                             : StageStatus.InProgress;
            asset.AssetStage.StartedAt    = DateTime.Now;
            asset.AssetStage.CompletedAt  = StageDefinition.IsLastStage(toStage)
                                             ? DateTime.Now
                                             : null;
            asset.AssetStage.AssignedToId = userId;
        }

        private static void SetFinalStatus(Asset asset)
        {
            // تحديد الحالة النهائية بناءً على آخر عقد
            var lastContract = asset.Contracts
                .OrderByDescending(c => c.CreatedAt)
                .FirstOrDefault();

            asset.Status = lastContract?.ContractType switch
            {
                ContractType.Sale => AssetStatus.Sold,
                ContractType.Rent => AssetStatus.Rented,
                _                 => AssetStatus.Active
            };
        }
    }
}
'@, $utf8)
Write-Host "OK: WorkflowService.cs" -ForegroundColor Green

# ── 2. ExcelImportService.cs ──────────────────────────────────────
# كشف.xls: 12 عمود بالترتيب:
# 1=المحافظة(City) 2=قسم/شياخة(District) 3=اسم الأصل 4=وصف الأصل
# 5=نوع العقار(PropertyType) 6=مساحة الأرض(LandArea) 7=مساحة المباني(BuildingArea)
# 8=سند الملكية(DeedType) 9=ملك شركة(OwnerCompany) 10=الموقف(OccupancyStatus)
# 11=ملاحظات(Notes) 12=العروض السابقة(PreviousOffers)
[System.IO.File]::WriteAllText("$app\Services\ExcelImportService.cs", @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using OfficeOpenXml;

namespace AssetManagement.Application.Services
{
    public class ExcelImportService : IExcelImportService
    {
        private readonly IAssetRepository _repo;
        public ExcelImportService(IAssetRepository repo) => _repo = repo;

        public async Task<ImportResultViewModel> ImportAsync(Stream fileStream, string userId)
        {
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            var result = new ImportResultViewModel();

            using var package = new ExcelPackage(fileStream);
            var ws = package.Workbook.Worksheets.FirstOrDefault();
            if (ws == null)
            {
                result.ErrorCount = 1;
                result.Rows.Add(new AssetImportRowViewModel
                    { RowNumber = 0, IsSuccess = false, ErrorMessage = "No worksheet found" });
                return result;
            }

            int lastRow = ws.Dimension?.End.Row ?? 1;

            // حساب الصفوف التي بها بيانات فعلية (العمود 3 = اسم الأصل)
            int actualRows = 0;
            for (int r = 2; r <= lastRow; r++)
            {
                if (!string.IsNullOrWhiteSpace(ws.Cells[r, 3].Text)) actualRows++;
            }
            result.TotalRows = actualRows;

            if (actualRows == 0)
            {
                result.ErrorCount = 1;
                result.Rows.Add(new AssetImportRowViewModel
                    { RowNumber = 0, IsSuccess = false, ErrorMessage = "No data rows found" });
                return result;
            }

            int year       = DateTime.Now.Year;
            int baseCount  = await _repo.CountByYearAsync(year);
            int localCount = 0;

            for (int row = 2; row <= lastRow; row++)
            {
                // ── قراءة الأعمدة الـ 12 ────────────────────────
                string? city           = ws.Cells[row, 1].Text?.Trim();   // المحافظة
                string? district       = ws.Cells[row, 2].Text?.Trim();   // قسم / شياخة
                string? assetName      = ws.Cells[row, 3].Text?.Trim();   // اسم الأصل
                string? description    = ws.Cells[row, 4].Text?.Trim();   // وصف الأصل
                string? propertyType   = ws.Cells[row, 5].Text?.Trim();   // نوع العقار (فيزيائي)
                string? landAreaStr    = ws.Cells[row, 6].Text?.Trim();   // مساحة الأرض
                string? buildAreaStr   = ws.Cells[row, 7].Text?.Trim();   // مساحة المباني
                string? deedType       = ws.Cells[row, 8].Text?.Trim();   // سند الملكية
                string? ownerCompany   = ws.Cells[row, 9].Text?.Trim();   // ملك شركة
                string? occupancySt    = ws.Cells[row, 10].Text?.Trim();  // الموقف
                string? notes          = ws.Cells[row, 11].Text?.Trim();  // ملاحظات
                string? prevOffers     = ws.Cells[row, 12].Text?.Trim();  // العروض السابقة

                // تخطي الصفوف الفارغة
                if (string.IsNullOrWhiteSpace(assetName)) continue;

                var rowVm = new AssetImportRowViewModel { RowNumber = row };
                try
                {
                    if (string.IsNullOrWhiteSpace(assetName))
                        throw new Exception("اسم الأصل مطلوب");

                    // ── تحليل المساحات ──────────────────────────
                    decimal? landArea  = ParseArea(landAreaStr);
                    decimal? buildArea = ParseArea(buildAreaStr);

                    // Area الأصلي = مساحة الأرض إن وُجدت، وإلا مساحة المباني
                    decimal? area     = landArea ?? buildArea;
                    string   areaUnit = "م²";

                    localCount++;
                    string code = string.Format("AST-{0}-{1:D5}", year, baseCount + localCount);

                    var asset = new Asset
                    {
                        AssetCode        = code,
                        AssetName        = assetName,
                        City             = city,
                        District         = district,
                        AssetDescription = description,
                        PropertyType     = propertyType,
                        LandArea         = landArea,
                        BuildingArea     = buildArea,
                        Area             = area,
                        AreaUnit         = areaUnit,
                        DeedType         = deedType,
                        OwnerCompany     = ownerCompany,
                        OccupancyStatus  = occupancySt,
                        Notes            = notes,
                        PreviousOffers   = prevOffers,

                        // القيم الافتراضية
                        AssetType    = AssetType.Both,
                        Status       = AssetStatus.Pending,
                        CurrentStage = 2,       // يبدأ من المراحل الاختيارية
                        CreatedById  = userId,
                        CreatedAt    = DateTime.Now,
                        UpdatedAt    = DateTime.Now,

                        AssetStage = new AssetStage
                        {
                            StageNumber  = 2,
                            StageName    = "2 - المراحل الاختيارية",
                            Status       = StageStatus.InProgress,
                            AssignedToId = userId,
                            StartedAt    = DateTime.Now,
                        },
                        StageHistories = new List<StageHistory>
                        {
                            new()
                            {
                                FromStage     = 0,
                                ToStage       = 1,
                                Action        = "Imported",
                                Notes         = "تم الاستيراد من ملف Excel",
                                PerformedById = userId,
                                PerformedAt   = DateTime.Now
                            },
                            new()
                            {
                                FromStage     = 1,
                                ToStage       = 2,
                                Action        = "AutoAdvanced",
                                Notes         = "انتقال تلقائي إلى المراحل الاختيارية",
                                PerformedById = userId,
                                PerformedAt   = DateTime.Now.AddSeconds(1)
                            }
                        }
                    };

                    await _repo.AddAsync(asset);
                    await _repo.SaveChangesAsync();

                    rowVm.IsSuccess = true;
                    rowVm.AssetCode = code;
                    rowVm.AssetName = assetName;
                    rowVm.Location  = $"{city} - {district}";
                    result.SuccessCount++;
                }
                catch (Exception ex)
                {
                    rowVm.IsSuccess    = false;
                    rowVm.AssetName    = assetName;
                    rowVm.ErrorMessage = ex.InnerException?.Message ?? ex.Message;
                    result.ErrorCount++;
                }
                result.Rows.Add(rowVm);
            }
            return result;
        }

        // ── Helper: تحليل المساحة (يقبل "1528.6 م" أو "1537" أو " م 1528.6") ──
        private static decimal? ParseArea(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            // إزالة الأحرف غير الرقمية والنقطة العشرية
            var clean = System.Text.RegularExpressions.Regex
                .Replace(raw, @"[^\d.]", "").Trim();
            if (decimal.TryParse(clean, out var val) && val > 0) return val;
            return null;
        }
    }
}
'@, $utf8)
Write-Host "OK: ExcelImportService.cs" -ForegroundColor Green

# ── 3. DashboardViewModel.cs ──────────────────────────────────────
[System.IO.File]::WriteAllText("$app\ViewModels\DashboardViewModel.cs", @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class DashboardViewModel
    {
        public string       UserName      { get; set; } = string.Empty;
        public List<string> Roles         { get; set; } = new();
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
        public string? PropertyType { get; set; }   // NEW
        public int     CurrentStage { get; set; }

        // يتزامن مع StageDefinition.Names في Domain
        public static readonly Dictionary<int, string> StageNames = new()
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
'@, $utf8)
Write-Host "OK: DashboardViewModel.cs" -ForegroundColor Green

# ── 4. AssetDetailViewModel.cs ────────────────────────────────────
[System.IO.File]::WriteAllText("$app\ViewModels\AssetDetailViewModel.cs", @'
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class AssetDetailViewModel
    {
        public Asset Asset { get; set; } = null!;
        public List<StageHistoryItem>  History        { get; set; } = new();
        public List<OptionalStageInfo> OptionalStages { get; set; } = new();
        public List<ValuationItem>     Valuations     { get; set; } = new();   // NEW
        public bool CanAdvance    { get; set; }
        public bool CanReject     { get; set; }
        public bool IsStage2      { get; set; }
        public bool IsStage3      { get; set; }   // NEW: مرحلة التقييم
        public bool IsStage4      { get; set; }   // NEW: مرحلة الطلب
        public bool AllOptionalDone { get; set; }
    }

    public class StageHistoryItem
    {
        public int     FromStage    { get; set; }
        public int     ToStage      { get; set; }
        public string? Action       { get; set; }
        public string? Notes        { get; set; }
        public string? PerformedBy  { get; set; }
        public DateTime PerformedAt { get; set; }

        // يتزامن مع StageDefinition الجديد
        private static readonly Dictionary<int, string> Names = new()
        {
            { 0,  "البداية"                  },
            { 1,  "رفع الأصول"               },
            { 2,  "المراحل الاختيارية"        },
            { 3,  "التقييم"                   },
            { 4,  "طلب البيع / الإيجار"      },
            { 5,  "الاعتماد النهائي"          },
            { 6,  "القانونية / العقد"         },
            { 7,  "المالية (مراجعة العقد)"   },
            { 8,  "التسويق (رفع موقّع)"      },
            { 9,  "الخزنة"                   },
            { 10, "مكتمل"                    },
        };

        public string FromName =>
            Names.TryGetValue(FromStage, out var n) ? n : FromStage.ToString();
        public string ToName =>
            Names.TryGetValue(ToStage, out var n) ? n : ToStage.ToString();
    }

    public class OptionalStageInfo
    {
        public string StageKey    { get; set; } = string.Empty;
        public string StageName   { get; set; } = string.Empty;
        public bool   IsRequired  { get; set; }
        public bool   IsCompleted { get; set; }
        public string RoleNeeded  { get; set; } = string.Empty;
    }

    // NEW: عرض التقييمات الثلاثة في صفحة التفاصيل
    public class ValuationItem
    {
        public int            Id             { get; set; }
        public EvaluationType EvaluationType { get; set; }
        public decimal        Value          { get; set; }
        public string?        Comments       { get; set; }
        public DateTime       EvaluationDate { get; set; }
        public string?        UserId         { get; set; }

        public string TypeLabel => EvaluationType switch
        {
            EvaluationType.Marketing => "تقييم التسويق",
            EvaluationType.Finance   => "تقييم المالية",
            EvaluationType.Expert    => "تقييم مكاتب الخبراء",
            _                        => EvaluationType.ToString()
        };

        public string TypeColor => EvaluationType switch
        {
            EvaluationType.Marketing => "warning",
            EvaluationType.Finance   => "info",
            EvaluationType.Expert    => "success",
            _                        => "secondary"
        };
    }
}
'@, $utf8)
Write-Host "OK: AssetDetailViewModel.cs" -ForegroundColor Green

# ── 5. RequestViewModel.cs ────────────────────────────────────────
[System.IO.File]::WriteAllText("$app\ViewModels\RequestViewModel.cs", @'
using System.ComponentModel.DataAnnotations;

namespace AssetManagement.Application.ViewModels
{
    // ── Rental Request ────────────────────────────────────────────
    public class RentalRequestViewModel
    {
        public int    AssetId   { get; set; }
        public string AssetName { get; set; } = string.Empty;
        public string AssetCode { get; set; } = string.Empty;
        public string? AssetPropertyType { get; set; }   // للعرض فقط

        // بيانات المستأجر
        [Required(ErrorMessage = "اسم المستأجر مطلوب")]
        public string  TenantName     { get; set; } = string.Empty;
        public string? TenantPhone    { get; set; }
        public string? TenantEmail    { get; set; }
        public string? TenantIdNumber { get; set; }

        // بيانات الطلب
        [Required][Range(1, double.MaxValue, ErrorMessage = "الإيجار المقترح مطلوب")]
        public decimal ProposedRent { get; set; }

        // مدة العقد بالسنوات (الحقل الجديد)
        [Required][Range(1, 99, ErrorMessage = "مدة العقد يجب أن تكون بين 1 و 99 سنة")]
        public int ContractDurationYears { get; set; } = 1;

        // الحقل القديم — يُبقى للتوافق، يُحسب تلقائياً
        public int RentDurationMonths => ContractDurationYears * 12;

        // الحقول الجديدة
        [Range(0, 24, ErrorMessage = "فترة السماح يجب أن تكون بين 0 و 24 شهراً")]
        public decimal? GracePeriod     { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "مبلغ التأمين يجب أن يكون إيجابياً")]
        public decimal? SecurityDeposit { get; set; }

        [Range(0, 100, ErrorMessage = "الزيادة السنوية يجب أن تكون نسبة بين 0 و 100")]
        public decimal? AnnualIncrease  { get; set; }

        public DateTime? StartDate { get; set; } = DateTime.Today;
        public string?   Notes     { get; set; }
    }

    // ── Sale Request (بدون تغيير جوهري) ──────────────────────────
    public class SaleRequestViewModel
    {
        public int    AssetId   { get; set; }
        public string AssetName { get; set; } = string.Empty;
        public string AssetCode { get; set; } = string.Empty;
        public string? AssetPropertyType { get; set; }   // للعرض فقط

        [Required(ErrorMessage = "اسم المشتري مطلوب")]
        public string  BuyerName     { get; set; } = string.Empty;
        public string? BuyerPhone    { get; set; }
        public string? BuyerEmail    { get; set; }
        public string? BuyerIdNumber { get; set; }

        [Required][Range(1, double.MaxValue, ErrorMessage = "السعر المعروض مطلوب")]
        public decimal OfferedPrice  { get; set; }
        public string? PaymentMethod { get; set; }
        public string? Notes         { get; set; }
    }

    // ── Contract ──────────────────────────────────────────────────
    public class ContractViewModel
    {
        public int    AssetId       { get; set; }
        public string AssetName     { get; set; } = string.Empty;
        public string AssetCode     { get; set; } = string.Empty;
        public string AssetLocation { get; set; } = string.Empty;
        public decimal? AssetArea   { get; set; }
        public string?  AreaUnit    { get; set; }
        public int? RentalRequestId { get; set; }
        public int? SaleRequestId   { get; set; }
        public string ContractType  { get; set; } = string.Empty;
        public string PartyName     { get; set; } = string.Empty;
        public string? PartyPhone   { get; set; }
        public string? PartyIdNumber{ get; set; }
        public decimal Amount       { get; set; }
        public DateTime? StartDate  { get; set; }
        public DateTime? EndDate    { get; set; }
        // حقول الإيجار الجديدة — تُملأ تلقائياً من الطلب
        public decimal? GracePeriod     { get; set; }
        public decimal? SecurityDeposit { get; set; }
        public decimal? AnnualIncrease  { get; set; }
        public int?     ContractDurationYears { get; set; }
        public string?  Notes           { get; set; }
    }

    // ── Valuation ─────────────────────────────────────────────────
    public class ValuationViewModel
    {
        public int AssetId { get; set; }

        [Range(1, double.MaxValue, ErrorMessage = "قيمة التقييم مطلوبة")]
        public decimal MarketingValue { get; set; }
        public string? MarketingComments { get; set; }

        [Range(1, double.MaxValue, ErrorMessage = "قيمة التقييم مطلوبة")]
        public decimal FinanceValue { get; set; }
        public string? FinanceComments { get; set; }

        [Range(1, double.MaxValue, ErrorMessage = "قيمة التقييم مطلوبة")]
        public decimal ExpertValue { get; set; }
        public string? ExpertComments { get; set; }

        // نوع التصرف — يُحدَّث في هذه المرحلة
        [Required]
        public AssetManagement.Domain.Enums.AssetType DispositionType { get; set; }
            = AssetManagement.Domain.Enums.AssetType.Both;
    }
}
'@, $utf8)
Write-Host "OK: RequestViewModel.cs (+ ValuationViewModel)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Stage 3 Complete ===" -ForegroundColor Cyan
Write-Host "Files modified:"
Write-Host "  [M] Application/Services/WorkflowService.cs"
Write-Host "  [M] Application/Services/ExcelImportService.cs"
Write-Host "  [M] Application/ViewModels/DashboardViewModel.cs"
Write-Host "  [M] Application/ViewModels/AssetDetailViewModel.cs"
Write-Host "  [M] Application/ViewModels/RequestViewModel.cs (+ ValuationViewModel)"
Write-Host ""

cd $base
dotnet build 2>&1 | Select-Object -Last 5

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build OK. Ready for Stage 4 (Controllers)." -ForegroundColor Green
} else {
    Write-Host "Build FAILED - check errors above" -ForegroundColor Red
}
