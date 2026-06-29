namespace AssetManagement.Application.ViewModels
{
    public class ImportResultViewModel
    {
        public int TotalRows    { get; set; }
        public int SuccessCount { get; set; }
        public int ErrorCount   { get; set; }
        public List<AssetImportRowViewModel> Rows { get; set; } = new();
    }

    public class AssetImportRowViewModel
    {
        public int     RowNumber    { get; set; }
        public string? AssetName    { get; set; }
        public string? Location     { get; set; }
        public bool    IsSuccess    { get; set; }
        public string? ErrorMessage { get; set; }
        public string? AssetCode    { get; set; }
    }
}