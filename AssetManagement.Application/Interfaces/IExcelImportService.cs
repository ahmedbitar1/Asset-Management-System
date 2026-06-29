using AssetManagement.Application.ViewModels;

namespace AssetManagement.Application.Interfaces
{
    public interface IExcelImportService
    {
        Task<ImportResultViewModel> ImportAsync(Stream fileStream, string userId);
    }
}