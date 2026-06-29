using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AssetManagement.Domain.Entities
{
    public class OptionalStageDetail
    {
        [Key]
        public int Id { get; set; }
        public int AssetId    { get; set; }
        public string StageKey { get; set; } = string.Empty; // 2a=Marketing, 2b=Engineering, 2c=AdminAffairs
        public string? Notes   { get; set; }
        public string? Details { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        [ForeignKey(nameof(AssetId))]
        public Asset Asset { get; set; } = null!;
    }
}