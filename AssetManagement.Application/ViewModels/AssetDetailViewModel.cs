using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;

namespace AssetManagement.Application.ViewModels
{
    public class AssetDetailViewModel
    {
        public Asset Asset { get; set; } = null!;
        public List<StageHistoryItem>  History        { get; set; } = new();
        public List<OptionalStageInfo> OptionalStages { get; set; } = new();
        public List<ValuationItem>     Valuations     { get; set; } = new();
        public bool CanAdvance     { get; set; }
        public bool CanReject      { get; set; }
        public bool IsStage2       { get; set; }
        public bool IsStage3       { get; set; }
        public bool IsStage4       { get; set; }
        public bool AllOptionalDone{ get; set; }
    }

    public class StageHistoryItem
    {
        public int     FromStage    { get; set; }
        public int     ToStage      { get; set; }
        public string? Action       { get; set; }
        public string? Notes        { get; set; }
        public string? PerformedBy  { get; set; }
        public DateTime PerformedAt { get; set; }

        private static readonly Dictionary<int, string> Names = new()
        {
            { 0,  "البداية" },
            { 1,  "رفع الأصول" },
            { 2,  "المراحل الاختيارية" },
            { 3,  "التقييم" },
            { 4,  "طلب البيع / الإيجار" },
            { 5,  "الاعتماد النهائي" },
            { 6,  "القانونية / العقد" },
            { 7,  "المالية (مراجعة العقد)" },
            { 8,  "التسويق (رفع موقع)" },
            { 9,  "الخزنة" },
            { 10, "مكتمل" },
        };

        public string FromName => Names.TryGetValue(FromStage, out var n) ? n : FromStage.ToString();
        public string ToName   => Names.TryGetValue(ToStage,   out var n) ? n : ToStage.ToString();
    }

    public class OptionalStageInfo
    {
        public string StageKey    { get; set; } = string.Empty;
        public string StageName   { get; set; } = string.Empty;
        public bool   IsRequired  { get; set; }
        public bool   IsCompleted { get; set; }
        public string RoleNeeded  { get; set; } = string.Empty;
    }

    public class ValuationItem
    {
        public int            Id             { get; set; }
        public EvaluationType EvaluationType { get; set; }
        public decimal        Value          { get; set; }
        public string?        Comments       { get; set; }
        public DateTime       EvaluationDate { get; set; }
        public string?        UserId         { get; set; }

        public string TypeLabel => EvaluationType switch
        {
            EvaluationType.Marketing => "تقييم التسويق",
            EvaluationType.Finance   => "تقييم المالية",
            EvaluationType.Expert    => "تقييم مكاتب الخبراء",
            _                        => EvaluationType.ToString()
        };

        public string TypeColor => EvaluationType switch
        {
            EvaluationType.Marketing => "warning",
            EvaluationType.Finance   => "info",
            EvaluationType.Expert    => "success",
            _                        => "secondary"
        };
    }
}
