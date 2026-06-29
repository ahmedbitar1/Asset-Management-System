import os, sys

BASE = r"C:\Users\ahmed.essamm\Desktop\AssetManagement"
WEB  = os.path.join(BASE, "AssetManagement.Web")
APP  = os.path.join(BASE, "AssetManagement.Application")
DOM  = os.path.join(BASE, "AssetManagement.Domain")

files = {}

# ════════════════════════════════════════════════════════
# DOMAIN
# ════════════════════════════════════════════════════════

files[DOM + r"\Entities\StageDefinition.cs"] = \
"""namespace AssetManagement.Domain.Entities
{
    public static class StageDefinition
    {
        public static readonly Dictionary<int, string> Names = new()
        {
            { 1,  "1 - \u0631\u0641\u0639 \u0627\u0644\u0623\u0635\u0648\u0644" },
            { 2,  "2 - \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629" },
            { 3,  "3 - \u0627\u0644\u062a\u0642\u064a\u064a\u0645" },
            { 4,  "4 - \u0637\u0644\u0628 \u0627\u0644\u0628\u064a\u0639 / \u0627\u0644\u0625\u064a\u062c\u0627\u0631" },
            { 5,  "5 - \u0627\u0644\u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0646\u0647\u0627\u0626\u064a" },
            { 6,  "6 - \u0627\u0644\u0642\u0627\u0646\u0648\u0646\u064a\u0629 / \u0627\u0644\u0639\u0642\u062f" },
            { 7,  "7 - \u0627\u0644\u0645\u0627\u0644\u064a\u0629 (\u0645\u0631\u0627\u062c\u0639\u0629 \u0627\u0644\u0639\u0642\u062f)" },
            { 8,  "8 - \u0627\u0644\u062a\u0633\u0648\u064a\u0642 (\u0631\u0641\u0639 \u0645\u0648\u0642\u0639)" },
            { 9,  "9 - \u0627\u0644\u062e\u0632\u0646\u0629" },
            { 10, "10 - \u0645\u0643\u062a\u0645\u0644" },
        };

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
"""

files[APP + r"\ViewModels\DashboardViewModel.cs"] = \
"""using AssetManagement.Domain.Entities;
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
            { 1,  "1 - \u0631\u0641\u0639 \u0627\u0644\u0623\u0635\u0648\u0644" },
            { 2,  "2 - \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629" },
            { 3,  "3 - \u0627\u0644\u062a\u0642\u064a\u064a\u0645" },
            { 4,  "4 - \u0637\u0644\u0628 \u0627\u0644\u0628\u064a\u0639 / \u0627\u0644\u0625\u064a\u062c\u0627\u0631" },
            { 5,  "5 - \u0627\u0644\u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0646\u0647\u0627\u0626\u064a" },
            { 6,  "6 - \u0627\u0644\u0642\u0627\u0646\u0648\u0646\u064a\u0629 / \u0627\u0644\u0639\u0642\u062f" },
            { 7,  "7 - \u0627\u0644\u0645\u0627\u0644\u064a\u0629 (\u0645\u0631\u0627\u062c\u0639\u0629 \u0627\u0644\u0639\u0642\u062f)" },
            { 8,  "8 - \u0627\u0644\u062a\u0633\u0648\u064a\u0642 (\u0631\u0641\u0639 \u0645\u0648\u0642\u0639)" },
            { 9,  "9 - \u0627\u0644\u062e\u0632\u0646\u0629" },
            { 10, "10 - \u0645\u0643\u062a\u0645\u0644" },
        };

        public string StageName =>
            StageNames.TryGetValue(CurrentStage, out var n) ? n : CurrentStage.ToString();

        public AssetStatus Status    { get; set; }
        public AssetType   AssetType { get; set; }

        public string StatusAr => Status switch
        {
            AssetStatus.Active   => "\u0646\u0634\u0637",
            AssetStatus.Sold     => "\u062a\u0645 \u0627\u0644\u0628\u064a\u0639",
            AssetStatus.Rented   => "\u062a\u0645 \u0627\u0644\u062a\u0623\u062c\u064a\u0631",
            AssetStatus.Rejected => "\u0645\u0631\u0641\u0648\u0636",
            _                    => "\u0642\u064a\u062f \u0627\u0644\u0627\u0646\u062a\u0638\u0627\u0631"
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
            AssetType.Sale => "\u0628\u064a\u0639",
            AssetType.Rent => "\u0625\u064a\u062c\u0627\u0631",
            _              => "\u0628\u064a\u0639 \u0648\u0625\u064a\u062c\u0627\u0631"
        };

        public decimal? PurchasePrice { get; set; }
        public decimal? Area          { get; set; }
        public DateTime CreatedAt     { get; set; }
    }
}
"""

files[APP + r"\ViewModels\AssetDetailViewModel.cs"] = \
"""using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class AssetDetailViewModel
    {
        public Asset Asset { get; set; } = null!;
        public List<StageHistoryItem>  History        { get; set; } = new();
        public List<OptionalStageInfo> OptionalStages { get; set; } = new();
        public List<ValuationItem>     Valuations     { get; set; } = new();
        public bool CanAdvance     { get; set; }
        public bool CanReject      { get; set; }
        public bool IsStage2       { get; set; }
        public bool IsStage3       { get; set; }
        public bool IsStage4       { get; set; }
        public bool AllOptionalDone{ get; set; }
    }

    public class StageHistoryItem
    {
        public int     FromStage    { get; set; }
        public int     ToStage      { get; set; }
        public string? Action       { get; set; }
        public string? Notes        { get; set; }
        public string? PerformedBy  { get; set; }
        public DateTime PerformedAt { get; set; }

        private static readonly Dictionary<int, string> Names = new()
        {
            { 0,  "\u0627\u0644\u0628\u062f\u0627\u064a\u0629" },
            { 1,  "\u0631\u0641\u0639 \u0627\u0644\u0623\u0635\u0648\u0644" },
            { 2,  "\u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629" },
            { 3,  "\u0627\u0644\u062a\u0642\u064a\u064a\u0645" },
            { 4,  "\u0637\u0644\u0628 \u0627\u0644\u0628\u064a\u0639 / \u0627\u0644\u0625\u064a\u062c\u0627\u0631" },
            { 5,  "\u0627\u0644\u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0646\u0647\u0627\u0626\u064a" },
            { 6,  "\u0627\u0644\u0642\u0627\u0646\u0648\u0646\u064a\u0629 / \u0627\u0644\u0639\u0642\u062f" },
            { 7,  "\u0627\u0644\u0645\u0627\u0644\u064a\u0629 (\u0645\u0631\u0627\u062c\u0639\u0629 \u0627\u0644\u0639\u0642\u062f)" },
            { 8,  "\u0627\u0644\u062a\u0633\u0648\u064a\u0642 (\u0631\u0641\u0639 \u0645\u0648\u0642\u0639)" },
            { 9,  "\u0627\u0644\u062e\u0632\u0646\u0629" },
            { 10, "\u0645\u0643\u062a\u0645\u0644" },
        };

        public string FromName => Names.TryGetValue(FromStage, out var n) ? n : FromStage.ToString();
        public string ToName   => Names.TryGetValue(ToStage,   out var n) ? n : ToStage.ToString();
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
        public DateTime       EvaluationDate { get; set; }
        public string?        UserId         { get; set; }

        public string TypeLabel => EvaluationType switch
        {
            EvaluationType.Marketing => "\u062a\u0642\u064a\u064a\u0645 \u0627\u0644\u062a\u0633\u0648\u064a\u0642",
            EvaluationType.Finance   => "\u062a\u0642\u064a\u064a\u0645 \u0627\u0644\u0645\u0627\u0644\u064a\u0629",
            EvaluationType.Expert    => "\u062a\u0642\u064a\u064a\u0645 \u0645\u0643\u0627\u062a\u0628 \u0627\u0644\u062e\u0628\u0631\u0627\u0621",
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

# WorkflowService - English messages only (no Arabic needed in logic)
files[APP + r"\Services\WorkflowService.cs"] = \
"""using AssetManagement.Application.Interfaces;
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
        { _repo = repo; _historyRepo = historyRepo; }

        public async Task<(bool Success, string Message)> AdvanceStageAsync(
            int assetId, string userId, string? notes = null)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");
            if (StageDefinition.IsLastStage(asset.CurrentStage))
                return (false, "Workflow already completed");

            int from = asset.CurrentStage;

            if (from == 2)
            {
                var pending = asset.OptionalStageStatuses
                    .Where(o => o.IsRequired && !o.IsCompleted).ToList();
                if (pending.Any())
                    return (false, "\u0644\u0645 \u064a\u062a\u0645 \u0627\u0633\u062a\u0643\u0645\u0627\u0644 \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629 \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629");
            }
            if (from == 3 && !asset.AssetValuations.Any())
                return (false, "\u064a\u062c\u0628 \u0625\u062f\u062e\u0627\u0644 \u062a\u0642\u064a\u064a\u0645 \u0648\u0627\u062d\u062f \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644 \u0642\u0628\u0644 \u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629");

            int to = from + 1;
            asset.CurrentStage = to;
            asset.UpdatedAt    = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = to;
                asset.AssetStage.StageName    = StageDefinition.GetName(to);
                asset.AssetStage.Status       = StageDefinition.IsLastStage(to)
                    ? StageStatus.Completed : StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.CompletedAt  = StageDefinition.IsLastStage(to) ? DateTime.Now : null;
                asset.AssetStage.AssignedToId = userId;
            }

            if (StageDefinition.IsLastStage(to))
            {
                var last = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
                asset.Status = last?.ContractType switch
                {
                    ContractType.Sale => AssetStatus.Sold,
                    ContractType.Rent => AssetStatus.Rented,
                    _                 => AssetStatus.Active
                };
            }

            await _repo.UpdateAsync(asset);
            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId = assetId, FromStage = from, ToStage = to,
                Action = "Approved", Notes = notes,
                PerformedById = userId, PerformedAt = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            return (true, "Advanced to: " + StageDefinition.GetName(to));
        }

        public async Task<(bool Success, string Message)> RejectStageAsync(
            int assetId, string userId, string reason)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");
            int from = asset.CurrentStage;
            asset.Status    = AssetStatus.Rejected;
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
                AssetId = assetId, FromStage = from, ToStage = from,
                Action = "Rejected", Notes = reason,
                PerformedById = userId, PerformedAt = DateTime.Now
            });
            await _repo.SaveChangesAsync();
            return (true, "Asset rejected");
        }

        public async Task<(bool Success, string Message)> CompleteOptionalStageAsync(
            int assetId, string userId, string stageKey)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");
            var opt = asset.OptionalStageStatuses.FirstOrDefault(o => o.StageKey == stageKey);
            if (opt == null) return (false, "Optional stage not found");
            opt.IsCompleted = true; opt.CompletedAt = DateTime.Now; opt.CompletedById = userId;
            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();
            return (true, "Completed: " + stageKey);
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

        public async Task<Asset?> GetAssetDetailAsync(int id) => await _repo.GetByIdAsync(id);
    }
}
"""

# ExcelImportService - fix stage name string only
files[APP + r"\Services\ExcelImportService.cs"] = \
"""using AssetManagement.Application.Interfaces;
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
                result.Rows.Add(new AssetImportRowViewModel { RowNumber=0, IsSuccess=false, ErrorMessage="No worksheet found" });
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
                result.Rows.Add(new AssetImportRowViewModel { RowNumber=0, IsSuccess=false, ErrorMessage="No data rows" });
                return result;
            }
            int year = DateTime.Now.Year;
            int baseCount = await _repo.CountByYearAsync(year);
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
                    string code = $"AST-{year}-{(baseCount + localCount):D5}";
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
                            StageName    = "2 - \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629",
                            Status       = StageStatus.InProgress,
                            AssignedToId = userId,
                            StartedAt    = DateTime.Now,
                        },
                        StageHistories = new List<StageHistory>
                        {
                            new() { FromStage=0, ToStage=1, Action="Imported",
                                    Notes="Imported from Excel", PerformedById=userId, PerformedAt=DateTime.Now },
                            new() { FromStage=1, ToStage=2, Action="AutoAdvanced",
                                    Notes="Auto-advanced to optional stages", PerformedById=userId, PerformedAt=DateTime.Now.AddSeconds(1) }
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
            var clean = System.Text.RegularExpressions.Regex.Replace(raw, @"[^\\d.]", "").Trim();
            if (decimal.TryParse(clean, out var val) && val > 0) return val;
            return null;
        }
    }
}
"""

# ════════════════════════════════════════════════════════
# _Layout.cshtml - use CDN bootstrap RTL (Arabic HTML)
# ════════════════════════════════════════════════════════
files[WEB + r"\Views\Shared\_Layout.cshtml"] = \
"""<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@(ViewData["Title"]) - \u0646\u0638\u0627\u0645 \u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0623\u0635\u0648\u0644</title>
    <link rel="stylesheet" href="~/lib/bootstrap/dist/css/bootstrap.rtl.min.css"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"/>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap" rel="stylesheet"/>
    <style>
        * { font-family: "Cairo", sans-serif; }
        body { background: #f0f2f5; }
        .topbar { background: #1a56db; }
        .sidebar { background: #1e3a5f; width: 220px; min-width: 220px; min-height: calc(100vh - 56px); }
        .sidebar a { color: #94a3b8; display: flex; align-items: center; gap: 8px;
            padding: 9px 14px; border-radius: 8px; margin: 3px 6px;
            text-decoration: none; font-size: 14px; transition: all .2s; }
        .sidebar a:hover { background: #2d5986; color: #fff; }
        .sidebar a.active { background: #1a56db; color: #fff; }
        .sidebar .sec { color: #64748b; font-size: 11px; padding: 10px 18px 4px; }
        .main { flex: 1; padding: 20px; min-width: 0; overflow-x: hidden; }
    </style>
</head>
<body>
<nav class="navbar topbar sticky-top shadow-sm" style="height:56px;">
    <div class="container-fluid">
        <span class="text-white fw-bold">
            <i class="bi bi-buildings me-2"></i>\u0646\u0638\u0627\u0645 \u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0623\u0635\u0648\u0644
        </span>
        @if (User.Identity?.IsAuthenticated == true)
        {
        <div class="d-flex align-items-center gap-2">
            <span class="text-white small"><i class="bi bi-person-circle me-1"></i>@User.Identity.Name</span>
            <form asp-controller="Account" asp-action="Logout" method="post" class="d-inline">
                @Html.AntiForgeryToken()
                <button class="btn btn-outline-light btn-sm">
                    <i class="bi bi-box-arrow-left me-1"></i>\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c
                </button>
            </form>
        </div>
        }
    </div>
</nav>
<div class="d-flex" style="min-height:calc(100vh - 56px);">
    @if (User.Identity?.IsAuthenticated == true)
    {
    <div class="sidebar">
        <nav class="nav flex-column pt-2">
            <div class="sec">\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629</div>
            <a asp-controller="Dashboard" asp-action="Index"
               class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Dashboard"?"active":"")">
                <i class="bi bi-speedometer2"></i>\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629
            </a>
            <a asp-controller="Asset" asp-action="Index"
               class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Asset"?"active":"")">
                <i class="bi bi-building"></i>\u0627\u0644\u0639\u0642\u0627\u0631\u0627\u062a
            </a>
            <div class="sec">\u0627\u0644\u0623\u062f\u0648\u0627\u062a</div>
            <a asp-controller="AssetImport" asp-action="Index"
               class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="AssetImport"?"active":"")">
                <i class="bi bi-file-earmark-excel"></i>\u0627\u0633\u062a\u064a\u0631\u0627\u062f Excel
            </a>
            @if (User.IsInRole("SuperAdmin") || User.IsInRole("Finance"))
            {
            <a asp-controller="Reports" asp-action="Index"
               class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Reports"?"active":"")">
                <i class="bi bi-bar-chart"></i>\u0627\u0644\u062a\u0642\u0627\u0631\u064a\u0631
            </a>
            <a asp-controller="Contracts" asp-action="Archive"
               class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Contracts"?"active":"")">
                <i class="bi bi-archive"></i>\u0627\u0644\u0639\u0642\u0648\u062f
            </a>
            }
            @if (User.IsInRole("SuperAdmin"))
            {
            <div class="sec">\u0627\u0644\u0625\u062f\u0627\u0631\u0629</div>
            <a asp-controller="Users" asp-action="Index"
               class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Users"?"active":"")">
                <i class="bi bi-people"></i>\u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645\u0648\u0646
            </a>
            }
        </nav>
    </div>
    }
    <div class="main">
        @if (TempData["Success"] != null)
        {
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="bi bi-check-circle me-2"></i>@TempData["Success"]
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        }
        @if (TempData["Error"] != null)
        {
        <div class="alert alert-danger alert-dismissible fade show mb-3">
            <i class="bi bi-exclamation-triangle me-2"></i>@TempData["Error"]
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        }
        @RenderBody()
    </div>
</div>
<script src="~/lib/bootstrap/dist/js/bootstrap.bundle.min.js"></script>
@await RenderSectionAsync("Scripts", required: false)
</body>
</html>
"""

# ════════════════════════════════════
# Asset/Index.cshtml - fix Arabic text
# ════════════════════════════════════
files[WEB + r"\Views\Asset\Index.cshtml"] = \
"""@model List<AssetManagement.Application.ViewModels.AssetCardViewModel>
@{
    ViewData["Title"] = "\u0627\u0644\u0639\u0642\u0627\u0631\u0627\u062a";
    int? selectedStage = ViewBag.Stage != null ? (int?)int.Parse(ViewBag.Stage.ToString()) : null;
    string selectedStatus = ViewBag.Status ?? "";
}

<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
            <div class="modal-body text-center px-4 py-4">
                <i class="bi bi-trash3-fill text-danger fs-1 mb-3 d-block"></i>
                <h5 class="fw-bold">\u062d\u0630\u0641 \u0627\u0644\u0639\u0642\u0627\u0631\u061f</h5>
                <p class="text-muted">\u0623\u0646\u062a \u0639\u0644\u0649 \u0648\u0634\u0643 \u062d\u0630\u0641 <strong id="deleteAssetName" class="text-danger"></strong></p>
            </div>
            <div class="modal-footer border-0 justify-content-center gap-3 pb-4">
                <button type="button" class="btn btn-light px-4 rounded-pill" data-bs-dismiss="modal">\u0625\u0644\u063a\u0627\u0621</button>
                <form id="deleteForm" method="post">
                    @Html.AntiForgeryToken()
                    <button type="submit" class="btn btn-danger px-4 rounded-pill">\u0646\u0639\u0645\u060c \u0627\u062d\u0630\u0641</button>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="fw-bold mb-0">
        <i class="bi bi-building me-2 text-primary"></i>\u0627\u0644\u0639\u0642\u0627\u0631\u0627\u062a
        <span class="badge bg-secondary ms-2">@Model.Count</span>
    </h5>
</div>

<div class="card border-0 shadow-sm mb-3">
    <div class="card-body py-2">
        <form method="get" class="row g-2 align-items-end">
            <div class="col-md-4">
                <input name="search" value="@ViewBag.Search" class="form-control"
                       placeholder="\u0628\u062d\u062b \u0628\u0627\u0644\u0627\u0633\u0645 \u0623\u0648 \u0627\u0644\u0643\u0648\u062f \u0623\u0648 \u0627\u0644\u0645\u0648\u0642\u0639..."/>
            </div>
            <div class="col-md-3">
                <select name="status" class="form-select">
                    <option value="">-- \u0643\u0644 \u0627\u0644\u062d\u0627\u0644\u0627\u062a --</option>
                    @foreach (var s in new[]{"Pending","Active","Sold","Rented","Rejected"})
                    {
                        var label = s == "Pending" ? "\u0645\u0639\u0644\u0642" : s == "Active" ? "\u0646\u0634\u0637" :
                                    s == "Sold"    ? "\u0645\u0628\u0627\u0639" : s == "Rented" ? "\u0645\u0624\u062c\u0631" : "\u0645\u0631\u0641\u0648\u0636";
                        if (selectedStatus == s)
                        { <option value="@s" selected>@label</option> }
                        else
                        { <option value="@s">@label</option> }
                    }
                </select>
            </div>
            <div class="col-md-3">
                <select name="stage" class="form-select">
                    <option value="">-- \u0643\u0644 \u0627\u0644\u0645\u0631\u0627\u062d\u0644 --</option>
                    @foreach (var kv in AssetManagement.Application.ViewModels.AssetCardViewModel.StageNames)
                    {
                        if (selectedStage == kv.Key)
                        { <option value="@kv.Key" selected>@kv.Value</option> }
                        else
                        { <option value="@kv.Key">@kv.Value</option> }
                    }
                </select>
            </div>
            <div class="col-md-2 d-flex gap-2">
                <button type="submit" class="btn btn-primary flex-grow-1">
                    <i class="bi bi-search me-1"></i>\u0628\u062d\u062b
                </button>
                <a asp-action="Index" class="btn btn-outline-secondary">\u0645\u0633\u062d</a>
            </div>
        </form>
    </div>
</div>

@if (!Model.Any())
{
    <div class="text-center py-5 text-muted">
        <i class="bi bi-inbox fs-1"></i>
        <p class="mt-2">\u0644\u0627 \u062a\u0648\u062c\u062f \u0639\u0642\u0627\u0631\u0627\u062a</p>
    </div>
}
else
{
<div class="card border-0 shadow-sm">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-dark">
                <tr>
                    <th>#</th>
                    <th>\u0627\u0644\u0643\u0648\u062f</th>
                    <th>\u0627\u0644\u0627\u0633\u0645</th>
                    <th>\u0627\u0644\u0645\u062f\u064a\u0646\u0629</th>
                    <th>\u0646\u0648\u0639 \u0627\u0644\u0639\u0642\u0627\u0631</th>
                    <th>\u0627\u0644\u0645\u0633\u0627\u062d\u0629</th>
                    <th>\u0646\u0648\u0639 \u0627\u0644\u062a\u0635\u0631\u0641</th>
                    <th>\u0627\u0644\u0645\u0631\u062d\u0644\u0629</th>
                    <th>\u0627\u0644\u062d\u0627\u0644\u0629</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @foreach (var (a, i) in Model.Select((a, i) => (a, i + 1)))
                {
                <tr>
                    <td class="text-muted small">@i</td>
                    <td><code class="text-primary small">@a.AssetCode</code></td>
                    <td class="fw-semibold">@a.AssetName</td>
                    <td class="text-muted small">@a.City</td>
                    <td class="small text-muted">@a.PropertyType</td>
                    <td class="small">@(a.Area.HasValue ? a.Area.Value.ToString("N0") + " m\u00b2" : "-")</td>
                    <td><span class="badge bg-secondary">@a.TypeAr</span></td>
                    <td><span class="badge rounded-pill bg-warning text-dark small">@a.StageName</span></td>
                    <td><span class="badge bg-@a.StatusColor">@a.StatusAr</span></td>
                    <td>
                        <div class="d-flex gap-1">
                            <a asp-action="FullDetails" asp-route-id="@a.Id" class="btn btn-sm btn-outline-info">
                                <i class="bi bi-info-circle"></i>
                            </a>
                            <a asp-action="Details" asp-route-id="@a.Id" class="btn btn-sm btn-outline-primary">
                                <i class="bi bi-eye"></i>
                            </a>
                            @if (User.IsInRole("SuperAdmin"))
                            {
                            <button type="button" class="btn btn-sm btn-outline-danger"
                                    onclick="confirmDelete(@a.Id,'@a.AssetName.Replace("'","\\'")' )">
                                <i class="bi bi-trash"></i>
                            </button>
                            }
                        </div>
                    </td>
                </tr>
                }
            </tbody>
        </table>
    </div>
</div>
}

@section Scripts {
<script>
function confirmDelete(id, name) {
    document.getElementById('deleteAssetName').textContent = name;
    document.getElementById('deleteForm').action = '/Asset/Delete/' + id;
    new bootstrap.Modal(document.getElementById('deleteModal')).show();
}
</script>
}
"""

# Write all files
print(f"Writing {len(files)} files...")
ok = 0
for path, content in files.items():
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  OK: {os.path.basename(path)}")
        ok += 1
    except Exception as e:
        print(f"  FAIL: {path} -> {e}")

print(f"\nDone: {ok}/{len(files)} files written")
print("Now run: dotnet build")
