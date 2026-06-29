namespace AssetManagement.Domain.Entities
{
    public class AssetCategory
    {
        public int     Id          { get; set; }
        public string  Name        { get; set; } = string.Empty;
        public string? Description { get; set; }
        public ICollection<Asset> Assets { get; set; } = new List<Asset>();
    }
}