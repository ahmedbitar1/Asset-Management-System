using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace AssetManagement.Infrastructure.Repository
{
    public class AssetRepository : IAssetRepository
    {
        private readonly ApplicationDbContext _ctx;
        public AssetRepository(ApplicationDbContext ctx) => _ctx = ctx;

        public async Task<IEnumerable<Asset>> GetAllAsync() =>
            await _ctx.Assets
                      .Include(a => a.Category)
                      .Include(a => a.AssetStage)
                      .Include(a => a.Contracts)
                      .OrderByDescending(a => a.CreatedAt)
                      .ToListAsync();

        public async Task<Asset?> GetByIdAsync(int id) =>
            await _ctx.Assets
                      .Include(a => a.Category)
                      .Include(a => a.AssetStage)
                      .Include(a => a.StageHistories.OrderByDescending(h => h.PerformedAt))
                      .Include(a => a.OptionalStageStatuses)
                      .Include(a => a.OptionalStageDetails)
                      .Include(a => a.RentalRequests.OrderByDescending(r => r.CreatedAt))
                      .Include(a => a.SaleRequests.OrderByDescending(r => r.CreatedAt))
                      .Include(a => a.Contracts.OrderByDescending(c => c.CreatedAt))
                      .Include(a => a.AssetValuations.OrderBy(v => v.EvaluationType))
                      .FirstOrDefaultAsync(a => a.Id == id);

        public async Task AddAsync(Asset asset) =>
            await _ctx.Assets.AddAsync(asset);

        public Task UpdateAsync(Asset asset)
        {
            _ctx.Assets.Update(asset);
            return Task.CompletedTask;
        }

        public void Remove(Asset asset) => _ctx.Assets.Remove(asset);

        public async Task SaveChangesAsync() =>
            await _ctx.SaveChangesAsync();

        public async Task<List<Asset>> GetByRolesAsync(IList<string> roles)
        {
            if (roles.Contains("SuperAdmin"))
                return await _ctx.Assets
                                 .Include(a => a.AssetStage)
                                 .Include(a => a.Contracts)
                                 .OrderByDescending(a => a.UpdatedAt ?? a.CreatedAt)
                                 .ToListAsync();

            var stages = new List<int>();
            if (roles.Contains("Legal"))      { stages.Add(1); stages.Add(3); stages.Add(6); stages.Add(8); }
            if (roles.Contains("Marketing"))  { stages.Add(2); stages.Add(3); stages.Add(4); }
            if (roles.Contains("Engineering")) stages.Add(2);
            if (roles.Contains("AdminAffairs")) stages.Add(2);
            if (roles.Contains("Finance"))    { stages.Add(3); stages.Add(7); }
            if (roles.Contains("Board_High"))   stages.Add(5);
            if (roles.Contains("Treasury"))     stages.Add(9);

            stages = stages.Distinct().ToList();

            return await _ctx.Assets
                             .Include(a => a.AssetStage)
                             .Where(a => stages.Contains(a.CurrentStage)
                                      && a.Status != AssetStatus.Rejected)
                             .OrderByDescending(a => a.UpdatedAt ?? a.CreatedAt)
                             .ToListAsync();
        }

        public async Task<int> CountByYearAsync(int year) =>
            await _ctx.Assets.CountAsync(a => a.CreatedAt.Year == year);

        public async Task<Dictionary<int, int>> GetStageCountsAsync() =>
            await _ctx.Assets
                      .GroupBy(a => a.CurrentStage)
                      .ToDictionaryAsync(g => g.Key, g => g.Count());
    }
}
