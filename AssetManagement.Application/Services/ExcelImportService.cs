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

            // Load existing assets for duplicate check
            var existingAssets = (await _repo.GetAllAsync()).ToList();

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

                // ── Duplicate Check ──────────────────────────────────────
                bool isDuplicate = existingAssets.Any(a =>
                    string.Equals(a.AssetName?.Trim(), assetName, StringComparison.OrdinalIgnoreCase) &&
                    string.Equals(a.City?.Trim(), city, StringComparison.OrdinalIgnoreCase) &&
                    string.Equals(a.District?.Trim(), district, StringComparison.OrdinalIgnoreCase));

                if (isDuplicate)
                {
                    rowVm.IsSuccess    = false;
                    rowVm.AssetName    = assetName;
                    rowVm.Location     = $"{city} - {district}";
                    rowVm.ErrorMessage = "\u0645\u0648\u062c\u0648\u062f \u0645\u0633\u0628\u0642\u0627\u064b - \u062a\u0645 \u062a\u062c\u0627\u0647\u0644\u0647";
                    result.ErrorCount++;
                    result.Rows.Add(rowVm);
                    continue;
                }

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
                                    Notes="Auto-advanced", PerformedById=userId, PerformedAt=DateTime.Now.AddSeconds(1) }
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
            var clean = System.Text.RegularExpressions.Regex.Replace(raw, @"[^\d.]", "").Trim();
            if (decimal.TryParse(clean, out var val) && val > 0) return val;
            return null;
        }
    }
}
