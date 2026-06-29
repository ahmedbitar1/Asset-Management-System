using AssetManagement.Domain.Entities;
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.ViewModels;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using AssetManagement.Infrastructure.Data;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class DashboardController : Controller
    {
        private readonly AssetManagement.Application.Interfaces.IWorkflowService _workflow;
        private readonly IAssetRepository _assetRepo;
        private readonly UserManager<ApplicationUser> _userManager;

        public DashboardController(
            AssetManagement.Application.Interfaces.IWorkflowService workflow,
            IAssetRepository assetRepo,
            UserManager<ApplicationUser> userManager)
        {
            _workflow    = workflow;
            _assetRepo   = assetRepo;
            _userManager = userManager;
        }

        public async Task<IActionResult> Index()
        {
            var user  = await _userManager.GetUserAsync(User);
            var roles = await _userManager.GetRolesAsync(user!);

            var pendingAssets = await _workflow.GetAssetsByRoleAsync(user!.Id, roles);
            var allAssets     = roles.Contains("SuperAdmin") || roles.Contains("Legal") || roles.Contains("Board_High")
                ? await _assetRepo.GetAllAsync()
                : pendingAssets;

            var vm = new DashboardViewModel
            {
                UserName      = user.UserName ?? "",
                Roles         = roles.ToList(),
                PendingAssets = pendingAssets.OrderBy(a => a.AssetCode).ToList().Select(ToCard).ToList(),
                AllAssets     = allAssets.Select(ToCard).ToList(),
            };

            if (roles.Contains("SuperAdmin") || roles.Contains("Legal") || roles.Contains("Board_High"))
            {
                var all = await _assetRepo.GetAllAsync();
                vm.TotalAssets    = all.Count();
                vm.ActiveAssets   = all.Count(a => a.Status == AssetStatus.Active);
                vm.SoldAssets     = all.Count(a => a.Status == AssetStatus.Sold);
                vm.RentedAssets   = all.Count(a => a.Status == AssetStatus.Rented);
                vm.RejectedAssets = all.Count(a => a.Status == AssetStatus.Rejected);
                vm.AssetsByStage  = await _assetRepo.GetStageCountsAsync();
            }

            return View(vm);
        }

        private static AssetCardViewModel ToCard(AssetManagement.Domain.Entities.Asset a) => new()
        {
            Id            = a.Id,
            AssetCode     = a.AssetCode,
            AssetName     = a.AssetName,
            Location      = a.Location,
            City          = a.City,
            CurrentStage  = a.CurrentStage,
            Status        = a.Status,
            AssetType     = a.AssetType,
            PurchasePrice = a.PurchasePrice,
            Area          = a.Area,
            CreatedAt     = a.CreatedAt
        };
    }
}
