using AssetManagement.Domain.Entities;

namespace AssetManagement.Application.Interfaces
{
    public interface IWorkflowService
    {
        Task<(bool Success, string Message)> AdvanceStageAsync(int assetId, string userId, string? notes = null);
        Task<(bool Success, string Message)> RejectStageAsync(int assetId, string userId, string reason);
        Task<(bool Success, string Message)> CompleteOptionalStageAsync(int assetId, string stageKey, string userId);
        Task<List<Asset>> GetAssetsByRoleAsync(string userId, IList<string> roles);
        Task<Asset?> GetAssetDetailAsync(int assetId);
    }
}