namespace AssetManagement.Application.Helpers
{
    /// <summary>
    /// يترجم القيم الإنجليزية المخزنة في DB إلى عربي وقت العرض فقط - بدون تغيير أي بيانات
    /// </summary>
    public static class OptionalStageTranslator
    {
        // نوع المبنى (Engineering)
        private static readonly Dictionary<string, string> BuildingType = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Residential"]  = "سكني",
            ["Commercial"]   = "تجاري",
            ["Industrial"]   = "صناعي",
            ["Mixed Use"]    = "متعدد الاستخدامات",
            ["Land"]         = "أرض / قطعة",
        };

        // حالة المرافق (AdminAffairs - كهرباء و مياه و غاز)
        private static readonly Dictionary<string, string> UtilityStatus = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Connected - Active"]       = "متصل - نشط",
            ["Connected - Inactive"]     = "متصل - غير نشط",
            ["Not Connected"]            = "غير متصل",
            ["Needs Upgrade"]            = "يحتاج ترقية",
            ["Well/Private"]             = "بئر / خاص",
            ["Natural Gas - Connected"]  = "غاز طبيعي - متصل",
            ["Cylinder Gas"]             = "أسطوانة غاز",
            ["Not Required"]             = "غير مطلوب",
        };

        // الحالة العامة لأي قيمة (Details عام)
        private static readonly Dictionary<string, string> GeneralStatus = new(StringComparer.OrdinalIgnoreCase)
        {
            ["Yes"]          = "نعم",
            ["No"]           = "لا",
            ["Done"]         = "مكتمل",
            ["Pending"]      = "معلق",
            ["Completed"]    = "مكتمل",
            ["In Progress"]  = "جاري",
        };

        /// <summary>ترجمة نوع المبنى</summary>
        public static string TranslateBuildingType(string? value)
            => Translate(value, BuildingType);

        /// <summary>ترجمة حالة المرفق (كهرباء / مياه / غاز)</summary>
        public static string TranslateUtility(string? value)
            => Translate(value, UtilityStatus);

        /// <summary>ترجمة عامة - يبحث في كل القواميس</summary>
        public static string TranslateAny(string? value)
        {
            if (string.IsNullOrWhiteSpace(value)) return "-";
            return Translate(value, BuildingType)
                ?? Translate(value, UtilityStatus)
                ?? Translate(value, GeneralStatus)
                ?? value;
        }

        /// <summary>
        /// يعالج Details نص تفصيلي كامل (مثل: "buildingType: Commercial | area: 250 m2")
        /// ويترجم القيم الإنجليزية فيه إلى عربي
        /// </summary>
        public static string TranslateDetailsJson(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return "-";
            // شائع: "key: value | key2: value2"
            var parts = raw.Split('|', StringSplitOptions.RemoveEmptyEntries);
            var result = new System.Text.StringBuilder();
            foreach (var part in parts)
            {
                var kv = part.Split(':', 2);
                if (kv.Length == 2)
                {
                    var key = kv[0].Trim();
                    var val = kv[1].Trim();
                    var arKey = TranslateKey(key);
                    var arVal = TranslateAny(val);
                    result.AppendLine($"<div><span class=\"text-muted small\">{arKey}:</span> <strong>{arVal}</strong></div>");
                }
                else
                {
                    result.AppendLine($"<div>{part.Trim()}</div>");
                }
            }
            return result.ToString();
        }

        private static string TranslateKey(string key) => key switch
        {
            "buildingType"  => "نوع المبنى",
            "area"          => "المساحة",
            "structure"     => "تفاصيل الهيكل",
            "electricity"   => "الكهرباء",
            "water"         => "المياه",
            "gas"           => "الغاز",
            "other"         => "خدمات أخرى",
            "notes"         => "ملاحظات",
            "adText"        => "نص الإعلان",
            _               => key
        };

        private static string? Translate(string? value, Dictionary<string, string> dict)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            return dict.TryGetValue(value.Trim(), out var ar) ? ar : null;
        }
    }
}
