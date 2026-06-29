namespace AssetManagement.Domain.Entities
{
    public class StageHistory
    {
        public int   Id        { get; set; }
        public int   AssetId   { get; set; }
        public Asset Asset     { get; set; } = null!;

        public int     FromStage    { get; set; }
        public int     ToStage      { get; set; }
        public string? Action       { get; set; }
        public string? Notes        { get; set; }

        public string?          PerformedById { get; set; }
        public ApplicationUser? PerformedBy   { get; set; }
        public DateTime         PerformedAt   { get; set; } = DateTime.Now;
    }
}