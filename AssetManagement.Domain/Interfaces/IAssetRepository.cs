using AssetManagement.Domain.Entities;

namespace AssetManagement.Domain.Interfaces
{
    public interface IAssetRepository
    {
        Task<IEnumerable<Asset>> GetAllAsync();
        Task<Asset?> GetByIdAsync(int id);
        Task AddAsync(Asset asset);
        Task UpdateAsync(Asset asset);
        Task SaveChangesAsync();
        void Remove(Asset asset);
        Task<List<Asset>> GetByRolesAsync(IList<string> roles);
        Task<int>  CountByYearAsync(int year);
        Task<Dictionary<int, int>> GetStageCountsAsync();
    }
}