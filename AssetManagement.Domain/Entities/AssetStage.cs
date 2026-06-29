using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    public class AssetStage
    {
        public int    Id          { get; set; }
        public int    AssetId     { get; set; }
        public Asset  Asset       { get; set; } = null!;

        public int         StageNumber { get; set; }
        public string      StageName   { get; set; } = string.Empty;
        public StageStatus Status      { get; set; } = StageStatus.Pending;

        public string?          AssignedToId { get; set; }
        public ApplicationUser? AssignedTo   { get; set; }

        public DateTime? StartedAt       { get; set; }
        public DateTime? CompletedAt     { get; set; }
        public string?   Notes           { get; set; }
        public string?   RejectionReason { get; set; }
    }
}