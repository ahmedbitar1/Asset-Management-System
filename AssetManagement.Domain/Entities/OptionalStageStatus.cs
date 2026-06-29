namespace AssetManagement.Domain.Entities
{
    public class OptionalStageStatus
    {
        public int    Id          { get; set; }
        public int    AssetId     { get; set; }
        public Asset  Asset       { get; set; } = null!;

        public string   StageKey      { get; set; } = string.Empty;
        public bool     IsRequired    { get; set; } = false;
        public bool     IsCompleted   { get; set; } = false;
        public DateTime? CompletedAt  { get; set; }
        public string?  CompletedById { get; set; }
    }
}