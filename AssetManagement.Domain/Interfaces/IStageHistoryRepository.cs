using AssetManagement.Domain.Entities;

namespace AssetManagement.Domain.Interfaces
{
    public interface IStageHistoryRepository
    {
        Task AddAsync(StageHistory history);
    }
}