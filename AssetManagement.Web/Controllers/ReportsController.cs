using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using ClosedXML.Excel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    [Authorize(Roles = "SuperAdmin,Finance,Legal,Marketing")]
    public class ReportsController : Controller
    {
        private readonly IAssetRepository _repo;
        public ReportsController(IAssetRepository repo) => _repo = repo;

        public async Task<IActionResult> Index(
            string? city, string? propertyType, string? status,
            string? assetType, int? stage, string? search)
        {
            var all = (await _repo.GetAllAsync()).ToList();

            // Apply filters
            var filtered = all.AsEnumerable();
            if (!string.IsNullOrWhiteSpace(search))
                filtered = filtered.Where(a =>
                    a.AssetName.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                    a.AssetCode.Contains(search, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(city))
                filtered = filtered.Where(a => (a.City ?? "").Contains(city, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(propertyType))
                filtered = filtered.Where(a => (a.PropertyType ?? "").Contains(propertyType, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<AssetStatus>(status, out var st))
                filtered = filtered.Where(a => a.Status == st);
            if (!string.IsNullOrWhiteSpace(assetType) && Enum.TryParse<AssetType>(assetType, out var at))
                filtered = filtered.Where(a => a.AssetType == at);
            if (stage.HasValue)
                filtered = filtered.Where(a => a.CurrentStage == stage.Value);

            var list = filtered.OrderBy(a => a.AssetCode).ToList();

            // Stats (on filtered)
            ViewBag.Total         = list.Count;
            ViewBag.Active        = list.Count(a => a.Status == AssetStatus.Active);
            ViewBag.Sold          = list.Count(a => a.Status == AssetStatus.Sold);
            ViewBag.Rented        = list.Count(a => a.Status == AssetStatus.Rented);
            ViewBag.Rejected      = list.Count(a => a.Status == AssetStatus.Rejected);
            ViewBag.Pending       = list.Count(a => a.Status == AssetStatus.Pending);
            ViewBag.TotalValue    = list.Sum(a => a.CurrentValue ?? 0);
            ViewBag.TotalPurchase = list.Sum(a => a.PurchasePrice ?? 0);
            ViewBag.ByStage       = list.GroupBy(a => a.CurrentStage).ToDictionary(g => g.Key, g => g.Count());
            ViewBag.Assets        = list;

            // Filter options from ALL data
            ViewBag.Cities         = all.Where(a => !string.IsNullOrEmpty(a.City)).Select(a => a.City).Distinct().OrderBy(x => x).ToList();
            ViewBag.PropertyTypes  = all.Where(a => !string.IsNullOrEmpty(a.PropertyType)).Select(a => a.PropertyType).Distinct().OrderBy(x => x).ToList();

            // Current filters
            ViewBag.CurCity        = city;
            ViewBag.CurPropertyType= propertyType;
            ViewBag.CurStatus      = status;
            ViewBag.CurAssetType   = assetType;
            ViewBag.CurStage       = stage;
            ViewBag.CurSearch      = search;

            return View();
        }

        public async Task<IActionResult> ExportExcel(
            string? city, string? propertyType, string? status,
            string? assetType, int? stage, string? search)
        {
            var all = (await _repo.GetAllAsync()).ToList();
            var filtered = all.AsEnumerable();
            if (!string.IsNullOrWhiteSpace(search))
                filtered = filtered.Where(a => a.AssetName.Contains(search, StringComparison.OrdinalIgnoreCase) || a.AssetCode.Contains(search, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(city))
                filtered = filtered.Where(a => (a.City ?? "").Contains(city, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(propertyType))
                filtered = filtered.Where(a => (a.PropertyType ?? "").Contains(propertyType, StringComparison.OrdinalIgnoreCase));
            if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<AssetStatus>(status, out var st))
                filtered = filtered.Where(a => a.Status == st);
            if (!string.IsNullOrWhiteSpace(assetType) && Enum.TryParse<AssetType>(assetType, out var at))
                filtered = filtered.Where(a => a.AssetType == at);
            if (stage.HasValue) filtered = filtered.Where(a => a.CurrentStage == stage.Value);
            var assets = filtered.OrderBy(a => a.AssetCode).ToList();

            // نفس أعمدة وترتيب شيت الاستيراد بالظبط (12 عمود) عشان يتعمله استيراد تاني بدون تعديل
            using var wb = new XLWorkbook();
            var ws = wb.Worksheets.Add("Sheet1");
            var headers = new[] { "\u0627\u0644\u0645\u062d\u0627\u0641\u0638\u0647", "\u0642\u0633\u0645 / \u0634\u064a\u0627\u062e\u0647", "\u0627\u0633\u0645 \u0627\u0644\u0627\u0635\u0644", "\u0648\u0635\u0641 \u0627\u0644\u0627\u0635\u0644", "\u0646\u0648\u0639 \u0627\u0644\u0639\u0642\u0627\u0631", "\u0645\u0633\u0627\u062d\u0647 \u0627\u0644\u0627\u0631\u0636 \u0628\u0627\u0644\u0645\u062a\u0631 \u062a\u0642\u0631\u064a\u0628\u0627", "\u0645\u0633\u0627\u062d\u0647 \u0627\u0644\u0645\u0628\u0627\u0646\u0649 \u06452 \u062a\u0642\u0631\u064a\u0628\u0627", "\u0633\u0646\u062f \u0627\u0644\u0645\u0644\u0643\u064a\u0647", "\u0645\u0644\u0643 \u0634\u0631\u0643\u0647", "\u0627\u0644\u0645\u0648\u0642\u0641", "\u0645\u0644\u0627\u062d\u0638\u0627\u062a", "\u0627\u0644\u0639\u0631\u0648\u0636 \u0627\u0644\u0633\u0627\u0628\u0642\u0647" };
            for (int i = 0; i < headers.Length; i++)
            {
                ws.Cell(1, i + 1).Value = headers[i];
                ws.Cell(1, i + 1).Style.Font.Bold = true;
                ws.Cell(1, i + 1).Style.Fill.BackgroundColor = XLColor.FromHtml("#1a56db");
                ws.Cell(1, i + 1).Style.Font.FontColor = XLColor.White;
            }
            for (int i = 0; i < assets.Count; i++)
            {
                var a = assets[i]; int r = i + 2;
                ws.Cell(r, 1).Value  = a.City ?? "";
                ws.Cell(r, 2).Value  = a.District ?? "";
                ws.Cell(r, 3).Value  = a.AssetName ?? "";
                ws.Cell(r, 4).Value  = a.AssetDescription ?? "";
                ws.Cell(r, 5).Value  = a.PropertyType ?? "";
                if (a.LandArea.HasValue)     ws.Cell(r, 6).Value = (double)a.LandArea.Value;
                if (a.BuildingArea.HasValue) ws.Cell(r, 7).Value = (double)a.BuildingArea.Value;
                ws.Cell(r, 8).Value  = a.DeedType ?? "";
                ws.Cell(r, 9).Value  = a.OwnerCompany ?? "";
                ws.Cell(r, 10).Value = a.OccupancyStatus ?? "";
                ws.Cell(r, 11).Value = a.Notes ?? "";
                ws.Cell(r, 12).Value = a.PreviousOffers ?? "";
            }
            ws.Columns().AdjustToContents();
            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return File(ms.ToArray(),
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                $"Assets_{DateTime.Now:yyyyMMdd_HHmm}.xlsx");
        }
    }
}
