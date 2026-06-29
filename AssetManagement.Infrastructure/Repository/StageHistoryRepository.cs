using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;

namespace AssetManagement.Infrastructure.Repository
{
    public class StageHistoryRepository : IStageHistoryRepository
    {
        private readonly ApplicationDbContext _ctx;
        public StageHistoryRepository(ApplicationDbContext ctx) => _ctx = ctx;
        public async Task AddAsync(StageHistory history) =>
            await _ctx.StageHistories.AddAsync(history);
    }
}