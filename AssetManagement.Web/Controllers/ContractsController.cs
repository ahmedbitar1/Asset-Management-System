using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using AssetManagement.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class ContractsController : Controller
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _history;
        private readonly UserManager<ApplicationUser> _um;
        private readonly IWebHostEnvironment _env;

        public ContractsController(IAssetRepository repo, IStageHistoryRepository history,
            UserManager<ApplicationUser> um, IWebHostEnvironment env)
        { _repo = repo; _history = history; _um = um; _env = env; }

        // â”€â”€ Archive â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [Authorize(Roles = "Legal,SuperAdmin,Marketing,Finance,Treasury")]
        public async Task<IActionResult> Archive()
        {
            var allAssets = await _repo.GetAllAsync();
            ViewBag.AllAssets = allAssets.Where(a => a.Contracts.Any()).ToList();
            return View();
        }

        // â”€â”€ Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [Authorize(Roles = "Legal,SuperAdmin,Marketing,Finance,Treasury")]
        public async Task<IActionResult> Details(int contractId)
        {
            var all   = await _repo.GetAllAsync();
            var asset = all.FirstOrDefault(a => a.Contracts.Any(c => c.Id == contractId));
            if (asset == null) return NotFound();

            var contract = asset.Contracts.First(c => c.Id == contractId);
            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;
            return View();
        }

        // â”€â”€ Create GET (مرحلة 6) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpGet]
        public async Task<IActionResult> Create(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();

            var rentalReq = asset.RentalRequests.OrderByDescending(r => r.CreatedAt).FirstOrDefault();
            var saleReq   = asset.SaleRequests.OrderByDescending(r => r.CreatedAt).FirstOrDefault();

            var vm = new ContractViewModel
            {
                AssetId       = assetId,
                AssetName     = asset.AssetName,
                AssetCode     = asset.AssetCode,
                AssetLocation = $"{asset.City} - {asset.Location}",
                AssetArea     = asset.Area,
                AreaUnit      = asset.AreaUnit,
            };

            // أولوية الإيجار على البيع لو AssetType = Both
            if (rentalReq != null)
            {
                vm.RentalRequestId    = rentalReq.Id;
                vm.ContractType       = "Rent";
                vm.PartyName          = rentalReq.TenantName;
                vm.PartyPhone         = rentalReq.TenantPhone;
                vm.PartyIdNumber      = rentalReq.TenantIdNumber;
                vm.Amount             = rentalReq.ProposedRent;
                vm.StartDate          = rentalReq.StartDate;
                vm.EndDate            = rentalReq.EndDate;
                // حقول الإيجار الجديدة â€” تُملأ تلقائياً
                vm.GracePeriod          = rentalReq.GracePeriod;
                vm.SecurityDeposit      = rentalReq.SecurityDeposit;
                vm.AnnualIncrease       = rentalReq.AnnualIncrease;
                vm.ContractDurationYears= rentalReq.ContractDurationYears;
            }
            else if (saleReq != null)
            {
                vm.SaleRequestId = saleReq.Id;
                vm.ContractType  = "Sale";
                vm.PartyName     = saleReq.BuyerName;
                vm.PartyPhone    = saleReq.BuyerPhone;
                vm.PartyIdNumber = saleReq.BuyerIdNumber;
                vm.Amount        = saleReq.OfferedPrice;
            }
            ViewBag.Asset = asset;
            return View(vm);
        }

        // â”€â”€ Create POST (مرحلة 6 â†’ 7) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        [Authorize(Roles = "Legal,SuperAdmin")]
        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ContractViewModel vm)
        {
            var asset = await _repo.GetByIdAsync(vm.AssetId);
            if (asset == null) return NotFound();

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
            int num    = asset.Contracts.Count + 1;
            string contractNo = asset.AssetCode + "-C" + num.ToString("D2");

            var contract = new Contract
            {
                AssetId         = vm.AssetId,
                ContractType    = vm.ContractType == "Rent" ? ContractType.Rent : ContractType.Sale,
                ContractNumber  = contractNo,
                PartyName       = vm.PartyName,
                PartyPhone      = vm.PartyPhone,
                PartyIdNumber   = vm.PartyIdNumber,
                Amount          = vm.Amount,
                StartDate       = vm.StartDate,
                EndDate         = vm.ContractType == "Sale" ? null : vm.EndDate,
                RentalRequestId = vm.RentalRequestId,
                SaleRequestId   = vm.SaleRequestId,
                Status          = ContractStatus.Draft,
                GeneratedById   = userId,
                CreatedAt       = DateTime.Now
            };

            asset.Contracts.Add(contract);

            // مرحلة 6 â†’ 7 (المالية تراجع العقد)
            int from = asset.CurrentStage;
            asset.CurrentStage = 7;
            asset.UpdatedAt = DateTime.Now;
            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = 7;
                asset.AssetStage.StageName    = StageDefinition.GetName(7);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.AssignedToId = userId;
            }

            await _repo.UpdateAsync(asset);
            await _history.AddAsync(new StageHistory
            {
                AssetId       = vm.AssetId,
                FromStage     = from,
                ToStage       = 7,
                Action        = "ContractCreated",
                Notes         = contractNo,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            var savedContract = asset.Contracts.OrderByDescending(c => c.CreatedAt).First();
            TempData["Success"] = $"تم إنشاء العقد {contractNo} وإرساله للمراجعة المالية";
            return RedirectToAction("Details", new { contractId = savedContract.Id });
        }

        // â”€â”€ Download Word â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public async Task<IActionResult> DownloadWord(int contractId)
        {
            var all    = await _repo.GetAllAsync();
            var tmp    = all.FirstOrDefault(a => a.Contracts.Any(c => c.Id == contractId));
            if (tmp == null) return NotFound();
            var asset  = await _repo.GetByIdAsync(tmp.Id) ?? tmp;
            var contract = asset.Contracts.First(c => c.Id == contractId);

            bool isSale = contract.ContractType == ContractType.Sale;

            // تحديد نوع الوحدة (سكني/تجاري) بناءً على PropertyType المدخل من Excel
            string propType = (asset.PropertyType ?? "").Trim();
            string[] commercialKeywords = { "تجاري", "محل", "مكتب", "إداري", "معرض", "مول", "مصنع", "مخزن" };
            bool isComm = !isSale && commercialKeywords.Any(k =>
                propType.Contains(k, StringComparison.OrdinalIgnoreCase) ||
                asset.AssetName.Contains(k, StringComparison.OrdinalIgnoreCase));

            string tplName = isSale ? "sell.docx"
                           : isComm ? "rent_commercial.docx"
                                    : "rent.docx";

            string tplPath = Path.Combine(_env.WebRootPath, "templates", tplName);
            if (!System.IO.File.Exists(tplPath))
                return BadRequest($"القالب غير موجود: {tplName}");

            var data = BuildContractData(asset, contract);
            var svc  = new WordContractService();
            byte[] bytes = svc.FillTemplate(tplPath, data);

            string safeAssetName = string.Join("_", asset.AssetName.Split(' ', StringSplitOptions.RemoveEmptyEntries));
            string downloadName  = $"\u0639\u0642\u062f_{safeAssetName}-{asset.AssetCode}.docx";

            return File(bytes,
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                downloadName);
        }

        // â”€â”€ Print â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        public async Task<IActionResult> Print(int contractId)
        {
            var all   = await _repo.GetAllAsync();
            var asset = all.FirstOrDefault(a => a.Contracts.Any(c => c.Id == contractId));
            if (asset == null) return NotFound();
            var contract = asset.Contracts.First(c => c.Id == contractId);
            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;
            return View();
        }

        // â”€â”€ Build Contract Data (Word placeholders) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        private static Dictionary<string, string> BuildContractData(Asset asset, Contract contract)
        {
            // استخراج بيانات الإيجار من آخر طلب
            var lastRental = asset.RentalRequests
                .OrderByDescending(r => r.CreatedAt).FirstOrDefault();

            // SecurityDeposit MUST come from rental request, NOT from contract amount
            string securityDeposit = "";
            if (lastRental?.SecurityDeposit.HasValue == true)
                securityDeposit = lastRental.SecurityDeposit.Value.ToString("N0");
            else if (contract.ContractType == ContractType.Sale)
                securityDeposit = "";
            // For rent with no SecurityDeposit entered, leave blank

            string annualIncrease = lastRental?.AnnualIncrease.HasValue == true
                ? lastRental.AnnualIncrease.Value.ToString("N0") + "%"
                : "";

            string gracePeriod = lastRental?.GracePeriod.HasValue == true
                ? ((int)lastRental.GracePeriod.Value).ToString()
                : "";

            string duration = lastRental?.ContractDurationYears.HasValue == true
                ? lastRental.ContractDurationYears.Value.ToString() + " سنة"
                : (contract.StartDate.HasValue && contract.EndDate.HasValue
                    ? ((int)((contract.EndDate.Value - contract.StartDate.Value).TotalDays / 365)).ToString() + " سنة"
                    : "");

            return new Dictionary<string, string>
            {
                ["CONTRACT_NUMBER"] = "",
                ["DEED_NUMBER"]     = "",
                ["PLOT_NUMBER"]     = "",
                ["CONTRACT_DATE"]   = DateTime.Now.ToString("yyyy/MM/dd"),
                ["PARTY_NAME"]      = contract.PartyName     ?? "",
                ["PARTY_ID"]        = contract.PartyIdNumber ?? "",
                ["PARTY_PHONE"]     = contract.PartyPhone    ?? "",
                ["ASSET_NAME"]      = asset.AssetName        ?? "",
                ["ASSET_LOCATION"]  = asset.Location         ?? "",
                ["ASSET_CITY"]      = asset.City             ?? "",
                ["ASSET_AREA"]      = asset.Area.HasValue
                                      ? asset.Area.Value.ToString("N0") + " " + asset.AreaUnit
                                      : "",
                ["AMOUNT"]          = contract.Amount.ToString("N0"),
                ["AMOUNT_TEXT"]     = "",
                ["START_DATE"]      = contract.StartDate?.ToString("yyyy/MM/dd") ?? "",
                ["END_DATE"]        = contract.EndDate?.ToString("yyyy/MM/dd")   ?? "",
                ["SECURITY_DEPOSIT"]= securityDeposit,
                ["ANNUAL_INCREASE"] = annualIncrease,
                ["GRACE_PERIOD"]    = gracePeriod,
                ["DURATION"]        = duration,
            };
        }
    }
}