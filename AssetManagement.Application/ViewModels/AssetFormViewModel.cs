using System.ComponentModel.DataAnnotations;

namespace AssetManagement.Application.ViewModels
{
    /// <summary>
    /// يُستعمل لإنشاء أو تعديل أصل يدوياً بنفس الأعمدة الموجودة في كشف الإكسل
    /// </summary>
    public class AssetFormViewModel
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "City is required")]
        public string City { get; set; } = string.Empty;

        [Required(ErrorMessage = "District is required")]
        public string District { get; set; } = string.Empty;

        [Required(ErrorMessage = "Asset name is required")]
        public string AssetName { get; set; } = string.Empty;

        public string? AssetDescription { get; set; }
        public string? PropertyType     { get; set; }
        public decimal? LandArea        { get; set; }
        public decimal? BuildingArea    { get; set; }
        public string? DeedType         { get; set; }
        public string? OwnerCompany     { get; set; }
        public string? OccupancyStatus  { get; set; }
        public string? Notes            { get; set; }
        public string? PreviousOffers   { get; set; }

        // للعرض فقط عند التعديل
        public string? AssetCode { get; set; }
    }
}
