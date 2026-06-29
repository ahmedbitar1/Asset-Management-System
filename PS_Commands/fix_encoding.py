import os

BASE = r"C:\Users\ahmed.essamm\Desktop\AssetManagement"

files = {}

# ── StageDefinition.cs ──────────────────────────────────────────
files[r"AssetManagement.Domain\Entities\StageDefinition.cs"] = """namespace AssetManagement.Domain.Entities
{
    public static class StageDefinition
    {
        public static readonly System.Collections.Generic.Dictionary<int, string> Names = new()
        {
            { 1,  "1 - رفع الأصول"              },
            { 2,  "2 - المراحل الاختيارية"       },
            { 3,  "3 - التقييم"                  },
            { 4,  "4 - طلب البيع / الإيجار"     },
            { 5,  "5 - الاعتماد النهائي"         },
            { 6,  "6 - القانونية / العقد"        },
            { 7,  "7 - المالية (مراجعة العقد)"  },
            { 8,  "8 - التسويق (رفع موقع)"      },
            { 9,  "9 - الخزنة"                  },
            { 10, "10 - مكتمل"                  },
        };

        public static readonly System.Collections.Generic.Dictionary<int, string[]> StageRoles = new()
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
"""

# ── DashboardViewModel.cs ───────────────────────────────────────
files[r"AssetManagement.Application\ViewModels\DashboardViewModel.cs"] = """using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class DashboardViewModel
    {
        public string       UserName      { get; set; } = string.Empty;
        public System.Collections.Generic.List<string> Roles { get; set; } = new();
        public System.Collections.Generic.List<AssetCardViewModel> PendingAssets { get; set; } = new();
        public System.Collections.Generic.List<AssetCardViewModel> AllAssets     { get; set; } = new();
        public int TotalAssets    { get; set; }
        public int ActiveAssets   { get; set; }
        public int SoldAssets     { get; set; }
        public int RentedAssets   { get; set; }
        public int RejectedAssets { get; set; }
        public System.Collections.Generic.Dictionary<int, int> AssetsByStage { get; set; } = new();
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

        public static readonly System.Collections.Generic.Dictionary<int, string> StageNames = new()
        {
            { 1,  "1 - رفع الأصول"              },
            { 2,  "2 - المراحل الاختيارية"       },
            { 3,  "3 - التقييم"                  },
            { 4,  "4 - طلب البيع / الإيجار"     },
            { 5,  "5 - الاعتماد النهائي"         },
            { 6,  "6 - القانونية / العقد"        },
            { 7,  "7 - المالية (مراجعة العقد)"  },
            { 8,  "8 - التسويق (رفع موقع)"      },
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
        public System.DateTime CreatedAt { get; set; }
    }
}
"""

# ── AssetDetailViewModel.cs ─────────────────────────────────────
files[r"AssetManagement.Application\ViewModels\AssetDetailViewModel.cs"] = """using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class AssetDetailViewModel
    {
        public Asset Asset { get; set; } = null!;
        public System.Collections.Generic.List<StageHistoryItem>  History        { get; set; } = new();
        public System.Collections.Generic.List<OptionalStageInfo> OptionalStages { get; set; } = new();
        public System.Collections.Generic.List<ValuationItem>     Valuations     { get; set; } = new();
        public bool CanAdvance    { get; set; }
        public bool CanReject     { get; set; }
        public bool IsStage2      { get; set; }
        public bool IsStage3      { get; set; }
        public bool IsStage4      { get; set; }
        public bool AllOptionalDone { get; set; }
    }

    public class StageHistoryItem
    {
        public int     FromStage    { get; set; }
        public int     ToStage      { get; set; }
        public string? Action       { get; set; }
        public string? Notes        { get; set; }
        public string? PerformedBy  { get; set; }
        public System.DateTime PerformedAt { get; set; }

        private static readonly System.Collections.Generic.Dictionary<int, string> Names = new()
        {
            { 0,  "البداية"                  },
            { 1,  "رفع الأصول"               },
            { 2,  "المراحل الاختيارية"        },
            { 3,  "التقييم"                   },
            { 4,  "طلب البيع / الإيجار"      },
            { 5,  "الاعتماد النهائي"          },
            { 6,  "القانونية / العقد"         },
            { 7,  "المالية (مراجعة العقد)"   },
            { 8,  "التسويق (رفع موقع)"       },
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

    public class ValuationItem
    {
        public int            Id             { get; set; }
        public EvaluationType EvaluationType { get; set; }
        public decimal        Value          { get; set; }
        public string?        Comments       { get; set; }
        public System.DateTime EvaluationDate { get; set; }
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
"""

# ── WorkflowService.cs ─────────────────────────────────────────
files[r"AssetManagement.Application\Services\WorkflowService.cs"] = """using AssetManagement.Application.Interfaces;
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

        public async Task<(bool Success, string Message)> AdvanceStageAsync(
            int assetId, string userId, string? notes = null)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");

            if (StageDefinition.IsLastStage(asset.CurrentStage))
                return (false, "اكتمل سير العمل بالفعل");

            int from = asset.CurrentStage;

            if (from == 2)
            {
                var pending = asset.OptionalStageStatuses
                    .Where(o => o.IsRequired && !o.IsCompleted).ToList();
                if (pending.Any())
                    return (false, "لم يتم استكمال المراحل الاختيارية المطلوبة بعد");
            }

            if (from == 3)
            {
                if (!asset.AssetValuations.Any())
                    return (false, "يجب ادخال تقييم واحد على الاقل قبل المتابعة");
            }

            int to = from + 1;
            asset.CurrentStage = to;
            asset.UpdatedAt    = DateTime.Now;

            UpdateAssetStage(asset, to, userId);

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
            return (true, "تم الانتقال الى: " + StageDefinition.GetName(to));
        }

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
            return (true, "تم رفض الاصل بنجاح");
        }

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
            return (true, "تم اكمال المرحلة الاختيارية: " + stageKey);
        }

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

        private static void UpdateAssetStage(Asset asset, int toStage, string userId)
        {
            if (asset.AssetStage == null) return;
            asset.AssetStage.StageNumber  = toStage;
            asset.AssetStage.StageName    = StageDefinition.GetName(toStage);
            asset.AssetStage.Status       = StageDefinition.IsLastStage(toStage)
                                             ? StageStatus.Completed : StageStatus.InProgress;
            asset.AssetStage.StartedAt    = DateTime.Now;
            asset.AssetStage.CompletedAt  = StageDefinition.IsLastStage(toStage) ? DateTime.Now : null;
            asset.AssetStage.AssignedToId = userId;
        }

        private static void SetFinalStatus(Asset asset)
        {
            var lastContract = asset.Contracts
                .OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            asset.Status = lastContract?.ContractType switch
            {
                ContractType.Sale => AssetStatus.Sold,
                ContractType.Rent => AssetStatus.Rented,
                _                 => AssetStatus.Active
            };
        }
    }
}
"""

# ── ExcelImportService.cs ──────────────────────────────────────
files[r"AssetManagement.Application\Services\ExcelImportService.cs"] = """using AssetManagement.Application.Interfaces;
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
            int actualRows = 0;
            for (int r = 2; r <= lastRow; r++)
                if (!string.IsNullOrWhiteSpace(ws.Cells[r, 3].Text)) actualRows++;

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
                string? city         = ws.Cells[row, 1].Text?.Trim();
                string? district     = ws.Cells[row, 2].Text?.Trim();
                string? assetName    = ws.Cells[row, 3].Text?.Trim();
                string? description  = ws.Cells[row, 4].Text?.Trim();
                string? propertyType = ws.Cells[row, 5].Text?.Trim();
                string? landAreaStr  = ws.Cells[row, 6].Text?.Trim();
                string? buildAreaStr = ws.Cells[row, 7].Text?.Trim();
                string? deedType     = ws.Cells[row, 8].Text?.Trim();
                string? ownerCompany = ws.Cells[row, 9].Text?.Trim();
                string? occupancySt  = ws.Cells[row, 10].Text?.Trim();
                string? notes        = ws.Cells[row, 11].Text?.Trim();
                string? prevOffers   = ws.Cells[row, 12].Text?.Trim();

                if (string.IsNullOrWhiteSpace(assetName)) continue;

                var rowVm = new AssetImportRowViewModel { RowNumber = row };
                try
                {
                    decimal? landArea  = ParseArea(landAreaStr);
                    decimal? buildArea = ParseArea(buildAreaStr);
                    decimal? area      = landArea ?? buildArea;

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
                        AreaUnit         = "m2",
                        DeedType         = deedType,
                        OwnerCompany     = ownerCompany,
                        OccupancyStatus  = occupancySt,
                        Notes            = notes,
                        PreviousOffers   = prevOffers,
                        AssetType        = AssetType.Both,
                        Status           = AssetStatus.Pending,
                        CurrentStage     = 2,
                        CreatedById      = userId,
                        CreatedAt        = DateTime.Now,
                        UpdatedAt        = DateTime.Now,
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
                            new() { FromStage=0, ToStage=1, Action="Imported",
                                    Notes="تم الاستيراد من ملف Excel",
                                    PerformedById=userId, PerformedAt=DateTime.Now },
                            new() { FromStage=1, ToStage=2, Action="AutoAdvanced",
                                    Notes="انتقال تلقائي الى المراحل الاختيارية",
                                    PerformedById=userId, PerformedAt=DateTime.Now.AddSeconds(1) }
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

        private static decimal? ParseArea(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            var clean = System.Text.RegularExpressions.Regex
                .Replace(raw, @"[^\\d.]", "").Trim();
            if (decimal.TryParse(clean, out var val) && val > 0) return val;
            return null;
        }
    }
}
"""

# Print all file paths that will be written
for rel_path in files.keys():
    full = os.path.join(BASE, rel_path)
    print(f"Will write: {full}")

print(f"\nTotal: {len(files)} files")
print("Run this script on Windows with Python 3 to fix encoding.")

print("\nWriting files...")
for rel_path, content in files.items():
    full = os.path.join(BASE, rel_path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"OK: {rel_path}")

print("\nDone! Now run: dotnet build")
