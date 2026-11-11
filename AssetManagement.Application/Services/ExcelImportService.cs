using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using OfficeOpenXml;
using System.Globalization;
using System.Text.RegularExpressions;

namespace AssetManagement.Application.Services
{
    /// <summary>
    /// استيراد الأصول من Excel. بيتعرف على شكل الشيت من أسماء الأعمدة:
    ///  - الشكل القديم: 12 عمود (المحافظة ... العروض السابقة) في الصف الأول.
    ///  - شكل "بالتقييمات": بيان الأصول (المبنى - الباخرة / الأصل / مساحة الأصل / الموقف ...).
    /// ولو الملف فيه أكتر من شيت بيختار أول شيت شكله معروف.
    /// </summary>
    public class ExcelImportService : IExcelImportService
    {
        private readonly IAssetRepository _repo;
        public ExcelImportService(IAssetRepository repo) => _repo = repo;

        // ── مفاتيح العناوين (بعد التطبيع) ───────────────────────────
        private static readonly string K_GOV      = NormAr("\u0627\u0644\u0645\u062d\u0627\u0641\u0638\u0629");
        private static readonly string K_ASSET    = NormAr("\u0627\u0633\u0645 \u0627\u0644\u0627\u0635\u0644");
        private static readonly string K_BUILDING = NormAr("\u0627\u0644\u0645\u0628\u0646\u0649");
        private static readonly string K_UNIT     = NormAr("\u0627\u0644\u0627\u0635\u0644");
        private static readonly string K_AREA     = NormAr("\u0645\u0633\u0627\u062d\u0629 \u0627\u0644\u0627\u0635\u0644");
        private static readonly string K_ACTIVITY = NormAr("\u0627\u0644\u0646\u0634\u0627\u0637");
        private static readonly string K_STATUS   = NormAr("\u0627\u0644\u0645\u0648\u0642\u0641");
        private static readonly string K_LEGAL    = NormAr("\u0627\u0644\u0645\u0648\u0642\u0641 \u0627\u0644\u0642\u0627\u0646\u0648\u0646\u064a");
        private static readonly string K_COST     = NormAr("\u0627\u0644\u062a\u0643\u0644\u0641\u0629");
        private static readonly string K_OFFER    = NormAr("\u0627\u062e\u0631 \u0639\u0631\u0636");
        private static readonly string K_COMPANY  = NormAr("\u0627\u0644\u0634\u0631\u0643\u0629");
        private static readonly string K_RENTVAL = NormAr("\u062a\u0642\u064a\u064a\u0645 \u0627\u0644\u0627\u064a\u062c\u0627\u0631");
        private static readonly string K_YIELD   = NormAr("\u0627\u0644\u0639\u0627\u0626\u062f \u0627\u0644\u0633\u0646\u0648\u064a");
        private static readonly string K_MARKET  = NormAr("\u0627\u0644\u0642\u064a\u0645\u0629 \u0627\u0644\u0633\u0648\u0642\u064a\u0629 \u0648\u0641\u0642\u0627 \u0644\u0644\u0627\u0633\u0627\u0633");
        private const string FEDDAN = "\u0641\u062f\u0627\u0646";
        private const decimal FEDDAN_M2 = 4200.83m;

        // خريطة أعمدة الشيت (0 = العمود مش موجود)
        private sealed class Layout
        {
            public ExcelWorksheet Sheet = null!;
            public int FirstRow;
            public int City, District, Name, Desc, PType, Land, Build, Deed, Owner, Occup, Notes, Offers, Cost, Rent, Yield, Market;
            public bool IsUnitsSheet;          // شكل "بالتقييمات"
            public string? RepeatedHeaderKey;  // صفوف العناوين المكررة جوه الشيت
        }

        public async Task<ImportResultViewModel> ImportAsync(Stream fileStream, string userId)
        {
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            var result = new ImportResultViewModel();
            using var package = new ExcelPackage(fileStream);

            var layout = DetectLayout(package);
            if (layout == null)
            {
                result.ErrorCount = 1;
                result.Rows.Add(new AssetImportRowViewModel { RowNumber = 0, IsSuccess = false, ErrorMessage = "No worksheet found" });
                return result;
            }

            var ws = layout.Sheet;
            int lastRow = ws.Dimension?.End.Row ?? 1;
            int actualRows = 0;
            for (int r = layout.FirstRow; r <= lastRow; r++)
                if (IsAssetRow(layout, r, out _)) actualRows++;

            result.TotalRows = actualRows;
            if (actualRows == 0)
            {
                result.ErrorCount = 1;
                result.Rows.Add(new AssetImportRowViewModel { RowNumber = 0, IsSuccess = false, ErrorMessage = "No data rows" });
                return result;
            }

            // الأصول الموجودة (لمنع التكرار)
            var existingAssets = (await _repo.GetAllAsync()).ToList();

            int year = DateTime.Now.Year;
            int baseCount = await _repo.CountByYearAsync(year);
            int localCount = 0;

            for (int row = layout.FirstRow; row <= lastRow; row++)
            {
                if (!IsAssetRow(layout, row, out var assetName)) continue;

                string? city         = Txt(ws, row, layout.City);
                string? district     = Txt(ws, row, layout.District);
                string? description  = Txt(ws, row, layout.Desc);
                string? propertyType = Txt(ws, row, layout.PType);
                string? deedType     = Txt(ws, row, layout.Deed);
                string? ownerCompany = Txt(ws, row, layout.Owner);
                string? occupancySt  = Txt(ws, row, layout.Occup);
                string? prevOffers   = Txt(ws, row, layout.Offers);
                decimal? cost        = Money(ws, row, layout.Cost);
                decimal? rentVal     = Money(ws, row, layout.Rent);
                decimal? annualYield = Money(ws, row, layout.Yield);
                decimal? marketVal   = Money(ws, row, layout.Market);

                // المساحات
                string? landRaw  = Raw(ws, row, layout.Land);
                string? buildRaw = Raw(ws, row, layout.Build);
                decimal? landArea;
                decimal? buildArea;
                string? areaNote = null;
                if (layout.IsUnitsSheet)
                {
                    (landArea, buildArea) = ParseCombinedArea(landRaw);
                    if (NeedsAreaNote(landRaw))
                        areaNote = "\u0627\u0644\u0645\u0633\u0627\u062d\u0629 \u0627\u0644\u0623\u0635\u0644\u064a\u0629 \u0641\u064a \u0627\u0644\u0634\u064a\u062a: " + landRaw;
                }
                else
                {
                    landArea  = ParseArea(landRaw);
                    buildArea = ParseArea(buildRaw);
                }
                string? notes = Join(" | ", Txt(ws, row, layout.Notes), areaNote);

                var rowVm = new AssetImportRowViewModel { RowNumber = row };
                string location = Join(" - ", city, district) ?? propertyType ?? "";

                // ── منع التكرار ───────────────────────────────────────
                // نفس المبنى بيتكرر بوحدات مختلفة (دور/وصف/مساحة) — فالمفتاح لازم يشمل كل ده
                bool isDuplicate = existingAssets.Any(a =>
                    Norm(a.AssetName) == Norm(assetName) &&
                    Norm(a.City) == Norm(city) &&
                    Norm(a.District) == Norm(district) &&
                    Norm(a.AssetDescription) == Norm(description) &&
                    Norm(a.PropertyType) == Norm(propertyType) &&
                    a.LandArea == landArea &&
                    a.BuildingArea == buildArea);

                if (isDuplicate)
                {
                    rowVm.IsSuccess    = false;
                    rowVm.AssetName    = assetName;
                    rowVm.Location     = location;
                    rowVm.ErrorMessage = "\u0645\u0648\u062c\u0648\u062f \u0645\u0633\u0628\u0642\u0627\u064b - \u062a\u0645 \u062a\u062c\u0627\u0647\u0644\u0647";
                    result.ErrorCount++;
                    result.Rows.Add(rowVm);
                    continue;
                }

                try
                {
                    decimal? area = landArea ?? buildArea;

                    localCount++;
                    string code = $"AST-{year}-{(baseCount + localCount):D5}";

                    bool leased = IsLeased(occupancySt);
                    var asset = new Asset
                    {
                        AssetCode        = code,
                        AssetName        = assetName!,
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
                        PurchasePrice    = cost,
                        RentalValuation  = rentVal,
                        AnnualYield      = annualYield,
                        MarketValue      = marketVal,
                        AssetType        = AssetType.Both,
                        Status           = leased ? AssetStatus.Rented : AssetStatus.Pending,
                        CurrentStage     = leased ? 10 : 2,
                        CreatedById      = userId,
                        CreatedAt        = DateTime.Now,
                        UpdatedAt        = DateTime.Now,
                        AssetStage = new AssetStage
                        {
                            StageNumber  = leased ? 10 : 2,
                            StageName    = leased ? "10 - \u0645\u0643\u062a\u0645\u0644" : "2 - \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629",
                            Status       = leased ? StageStatus.Completed : StageStatus.InProgress,
                            AssignedToId = userId,
                            StartedAt    = DateTime.Now,
                            CompletedAt  = leased ? DateTime.Now : null,
                        },
                        StageHistories = new List<StageHistory>
                        {
                            new() { FromStage=0, ToStage=1, Action="Imported",
                                    Notes="Imported from Excel", PerformedById=userId, PerformedAt=DateTime.Now },
                            new() { FromStage=1, ToStage=leased ? 10 : 2, Action="AutoAdvanced",
                                    Notes=leased ? "\u0623\u0635\u0644 \u0645\u0624\u062c\u0631 \u0628\u0627\u0644\u0641\u0639\u0644 - \u0644\u0627 \u064a\u062d\u062a\u0627\u062c \u0645\u0631\u0627\u062d\u0644" : "Auto-advanced", PerformedById=userId, PerformedAt=DateTime.Now.AddSeconds(1) }
                        }
                    };
                    await _repo.AddAsync(asset);
                    await _repo.SaveChangesAsync();
                    existingAssets.Add(asset);

                    rowVm.IsSuccess = true;
                    rowVm.AssetCode = code;
                    rowVm.AssetName = assetName;
                    rowVm.Location  = location;
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

        // الأصل المؤجر فعلاً بيتعرض في السيستم بدون مراحل
        private static bool IsLeased(string? occupancy) =>
            !string.IsNullOrWhiteSpace(occupancy) && NormAr(occupancy).StartsWith(NormAr("\u0645\u0624\u062c\u0631"));

        // ── اكتشاف الشكل ──────────────────────────────────────────────
        private static Layout? DetectLayout(ExcelPackage package)
        {
            ExcelWorksheet? first = null;
            foreach (var ws in package.Workbook.Worksheets)
            {
                first ??= ws;
                if (ws.Dimension == null) continue;
                int maxRow = Math.Min(ws.Dimension.End.Row, 12);
                int maxCol = Math.Min(ws.Dimension.End.Column, 40);

                for (int r = 1; r <= maxRow; r++)
                {
                    var h = new Dictionary<string, int>();
                    for (int c = 1; c <= maxCol; c++)
                    {
                        var key = NormAr(ws.Cells[r, c].Text);
                        if (key.Length > 0 && !h.ContainsKey(key)) h[key] = c;
                    }

                    // الشكل القديم (12 عمود)
                    if (h.ContainsKey(K_GOV) && h.ContainsKey(K_ASSET))
                    {
                        return new Layout
                        {
                            Sheet = ws, FirstRow = r + 1,
                            City = 1, District = 2, Name = 3, Desc = 4, PType = 5, Land = 6, Build = 7,
                            Deed = 8, Owner = 9, Occup = 10, Notes = 11, Offers = 12, Cost = 0,
                            IsUnitsSheet = false, RepeatedHeaderKey = null
                        };
                    }

                    // شكل "بالتقييمات"
                    int building = Find(h, k => k.StartsWith(K_BUILDING));
                    int area     = Find(h, k => k == K_AREA);
                    int legal    = Find(h, k => k.StartsWith(K_LEGAL));
                    if (building > 0 && area > 0 && legal > 0)
                    {
                        return new Layout
                        {
                            Sheet = ws, FirstRow = r + 1,
                            Name = building,
                            Desc = Find(h, k => k == K_UNIT),
                            PType = Find(h, k => k == K_ACTIVITY),
                            Land = area,
                            Deed = legal,
                            Owner = Find(h, k => k == K_COMPANY),
                            Occup = Find(h, k => k == K_STATUS),
                            Offers = Find(h, k => k.StartsWith(K_OFFER)),
                            Cost = Find(h, k => k == K_COST),
                            Rent = Find(h, k => k.StartsWith(K_RENTVAL)),
                            Yield = Find(h, k => k.StartsWith(K_YIELD)),
                            Market = Find(h, k => k.StartsWith(K_MARKET)),
                            IsUnitsSheet = true,
                            RepeatedHeaderKey = NormAr(ws.Cells[r, building].Text)
                        };
                    }
                }
            }

            // مفيش شكل معروف: نفس السلوك القديم (أول شيت بأعمدة الـ12 بالترتيب)
            if (first == null) return null;
            return new Layout
            {
                Sheet = first, FirstRow = 2,
                City = 1, District = 2, Name = 3, Desc = 4, PType = 5, Land = 6, Build = 7,
                Deed = 8, Owner = 9, Occup = 10, Notes = 11, Offers = 12, Cost = 0,
                IsUnitsSheet = false, RepeatedHeaderKey = null
            };
        }

        private static int Find(Dictionary<string, int> headers, Func<string, bool> pred)
        {
            foreach (var kv in headers) if (pred(kv.Key)) return kv.Value;
            return 0;
        }

        private static bool IsAssetRow(Layout L, int row, out string? name)
        {
            name = Txt(L.Sheet, row, L.Name);
            if (string.IsNullOrWhiteSpace(name)) return false;
            // صف عناوين مكرر جوه الشيت (الشكل الجديد بيكرر العناوين لكل شركة)
            if (L.RepeatedHeaderKey != null && NormAr(name) == L.RepeatedHeaderKey) return false;
            return true;
        }

        // ── قراءة الخلايا ──────────────────────────────────────────────
        private static string? Raw(ExcelWorksheet ws, int row, int col) =>
            col == 0 ? null : ws.Cells[row, col].Text?.Trim();

        private static string? Txt(ExcelWorksheet ws, int row, int col)
        {
            if (col == 0) return null;
            var t = (ws.Cells[row, col].Text ?? "").Trim();
            if (t.Length == 0 || t == "-" || t == "—") return null;
            return Regex.Replace(t, @"\s*[\r\n]+\s*", " - ");
        }

        private static decimal? Money(ExcelWorksheet ws, int row, int col)
        {
            if (col == 0) return null;
            var v = ws.Cells[row, col].Value;
            if (v is double d) return (decimal)d;
            if (v is decimal m) return m;
            if (v is int i) return i;
            var mt = Regex.Match(ws.Cells[row, col].Text ?? "", @"[0-9][0-9,]*(?:\.[0-9]+)?");
            return mt.Success ? ToDecimal(mt.Value, false) : null;
        }

        private static string? Join(string sep, params string?[] parts)
        {
            var j = string.Join(sep, parts.Where(p => !string.IsNullOrWhiteSpace(p)));
            return j.Length == 0 ? null : j;
        }

        // ── المساحات ───────────────────────────────────────────────────
        private const string NUM = @"[0-9][0-9,]*(?:\.[0-9]+)?";

        private static decimal? ToDecimal(string s, bool feddan)
        {
            if (!decimal.TryParse(s.Replace(",", ""), NumberStyles.Number, CultureInfo.InvariantCulture, out var v) || v <= 0)
                return null;
            return feddan ? Math.Round(v * FEDDAN_M2, 2) : v;
        }

        // أول رقم في النص (بيتجاهل الرقم الملزوق بحرف م زي "م2") وبيحوّل الفدان لمتر مربع
        private static decimal? ParseArea(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            var m = Regex.Match(raw, @"(?<![0-9.,م])" + NUM);
            if (!m.Success) return null;
            return ToDecimal(m.Value, NormAr(raw).Contains(FEDDAN));
        }

        // "مساحة الارض : 40000 مساحة المباني : 10787" → أرض + مباني، غير كده → أرض
        private static (decimal? Land, decimal? Build) ParseCombinedArea(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return (null, null);
            var t = NormAr(raw);
            bool fed = t.Contains(FEDDAN);
            var mLand  = Regex.Match(t, @"الارض\D*?(" + NUM + ")");
            var mBuild = Regex.Match(t, @"المباني\D*?(" + NUM + ")");
            if (mLand.Success || mBuild.Success)
                return (mLand.Success  ? ToDecimal(mLand.Groups[1].Value, fed)  : null,
                        mBuild.Success ? ToDecimal(mBuild.Groups[1].Value, fed) : null);
            return (ParseArea(raw), null);
        }

        // لو المساحة مش رقم بسيط (فدان / نص / أرض+مباني) بنحفظ النص الأصلي في الملاحظات
        private static bool NeedsAreaNote(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw) || raw.Trim() == "-") return false;
            return !Regex.IsMatch(NormAr(raw), @"^" + NUM + @"\s*(م|م\s*[2²]|متر)?$");
        }

        // ── التطبيع ────────────────────────────────────────────────────
        private static string NormAr(string? s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            var t = s.Replace("ـ", "")
                     .Replace('أ', 'ا').Replace('إ', 'ا').Replace('آ', 'ا')
                     .Replace('ى', 'ي').Replace('ة', 'ه');
            return Regex.Replace(t, @"\s+", " ").Trim().ToLowerInvariant();
        }

        private static string Norm(string? s) =>
            Regex.Replace((s ?? "").Trim(), @"\s+", " ").ToLowerInvariant();
    }
}
