namespace AssetManagement.Domain.Entities
{
    public static class StageDefinition
    {
        public static readonly Dictionary<int, string> Names = new()
        {
            { 1,  "1 - \u0631\u0641\u0639 \u0627\u0644\u0623\u0635\u0648\u0644" },
            { 2,  "2 - \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629" },
            { 3,  "3 - \u0627\u0644\u062a\u0642\u064a\u064a\u0645" },
            { 4,  "4 - \u0637\u0644\u0628 \u0627\u0644\u0628\u064a\u0639 / \u0627\u0644\u0625\u064a\u062c\u0627\u0631" },
            { 5,  "5 - \u0627\u0644\u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0646\u0647\u0627\u0626\u064a" },
            { 6,  "6 - \u0627\u0644\u0642\u0627\u0646\u0648\u0646\u064a\u0629 / \u0627\u0644\u0639\u0642\u062f" },
            { 7,  "7 - \u0627\u0644\u0645\u0627\u0644\u064a\u0629 (\u0645\u0631\u0627\u062c\u0639\u0629 \u0627\u0644\u0639\u0642\u062f)" },
            { 8,  "8 - \u0631\u0641\u0639 \u0627\u0644\u0639\u0642\u062f \u0627\u0644\u0645\u0648\u0642\u0651\u0639" },
            { 9,  "9 - \u0627\u0644\u062e\u0632\u0646\u0629" },
            { 10, "10 - \u0645\u0643\u062a\u0645\u0644" },
        };

        // \u0627\u0644\u0623\u062f\u0648\u0627\u0631 \u0627\u0644\u062c\u062f\u064a\u062f\u0629:
        // 1 \u0631\u0641\u0639 \u0623\u0635\u0648\u0644   : Legal (\u0628\u062f\u0644 DataEntry)
        // 3 \u062a\u0642\u064a\u064a\u0645        : Marketing + Finance + Legal (\u0643\u0644 \u0645\u0646\u0647\u0645 \u064a\u062f\u062e\u0644 \u062a\u0642\u064a\u064a\u0645\u0647)
        // 4 \u0637\u0644\u0628 \u0628\u064a\u0639/\u0625\u064a\u062c\u0627\u0631: Marketing (\u0628\u062f\u0644 Sales)
        // 8 \u0631\u0641\u0639 \u0645\u0648\u0642\u0651\u0639   : Legal (\u0628\u062f\u0644 Marketing)
        public static readonly Dictionary<int, string[]> StageRoles = new()
        {
            { 1,  new[] { "Legal",       "SuperAdmin" } },
            { 2,  new[] { "Marketing",   "Engineering", "AdminAffairs", "SuperAdmin" } },
            { 3,  new[] { "Marketing",   "Finance", "Legal", "SuperAdmin" } },
            { 4,  new[] { "Marketing",   "SuperAdmin" } },
            { 5,  new[] { "Board_High",  "SuperAdmin" } },
            { 6,  new[] { "Legal",       "SuperAdmin" } },
            { 7,  new[] { "Finance",     "SuperAdmin" } },
            { 8,  new[] { "Legal",       "SuperAdmin" } },
            { 9,  new[] { "Treasury",    "SuperAdmin" } },
        };

        public static string GetName(int stage) =>
            Names.TryGetValue(stage, out var n) ? n : stage.ToString();

        public static bool IsLastStage(int stage) => stage >= 10;
    }
}
