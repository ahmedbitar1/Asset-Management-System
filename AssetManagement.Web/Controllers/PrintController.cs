using AssetManagement.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    [AllowAnonymous]
    public class PrintController : Controller
    {
        private readonly IAssetRepository _repo;
        public PrintController(IAssetRepository repo) { _repo = repo; }

        [HttpGet]
        public async Task<IActionResult> Contract(int assetId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return NotFound();
            var contract = asset.Contracts.OrderByDescending(c => c.CreatedAt).FirstOrDefault();
            if (contract == null) return Content("No contract found for this asset.");
            ViewBag.Asset    = asset;
            ViewBag.Contract = contract;
            return View();
        }
    }
}