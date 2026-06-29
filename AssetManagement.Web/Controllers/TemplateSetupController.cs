using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    // Controller مؤقت لتحضير الـ templates - شغّله مرة واحدة فقط
    [AllowAnonymous: Microsoft.AspNetCore.Authorization.AllowAnonymous]
    public class TemplateSetupController : Controller
    {
        private readonly IWebHostEnvironment _env;
        public TemplateSetupController(IWebHostEnvironment env) { _env = env; }

        public IActionResult Prepare()
        {
            var tplDir = Path.Combine(_env.WebRootPath, "templates");
            var results = new List<string>();

            var configs = new[]
            {
                new { src = "sell.docx",          dst = "sell_tpl.docx",           replacements = GetSellReplacements() },
                new { src = "rent.docx",           dst = "rent_tpl.docx",           replacements = GetRentReplacements() },
                new { src = "rent_commercal.docx", dst = "rent_commercial_tpl.docx",replacements = GetCommReplacements() },
            };

            foreach (var cfg in configs)
            {
                var srcPath = Path.Combine(tplDir, cfg.src);
                var dstPath = Path.Combine(tplDir, cfg.dst);
                if (!System.IO.File.Exists(srcPath)) { results.Add($"MISSING: {cfg.src}"); continue; }

                System.IO.File.Copy(srcPath, dstPath, overwrite: true);
                PrepareTemplate(dstPath, cfg.replacements);
                results.Add($"OK: {cfg.dst}");
            }

            return Content(string.Join("\n", results) + "\n\nDone! You can now use DownloadWord.");
        }

        private static void PrepareTemplate(string path, Dictionary<string, string> replacements)
        {
            using var doc = WordprocessingDocument.Open(path, isEditable: true);
            var body = doc.MainDocumentPart!.Document.Body!;

            foreach (var para in body.Descendants<Paragraph>())
            {
                // دمج كل الـ runs في paragraph واحد عشان نقدر نستبدل النص
                var fullText = string.Concat(para.Descendants<Text>().Select(t => t.Text));
                if (string.IsNullOrWhiteSpace(fullText)) continue;

                var newText = fullText;
                foreach (var kvp in replacements)
                    newText = newText.Replace(kvp.Key, kvp.Value);

                if (newText == fullText) continue;

                // امسح كل الـ runs القديمة وأضف run واحد بالنص الجديد
                var runs = para.Elements<Run>().ToList();
                var firstRun = runs.FirstOrDefault();
                var rPr = firstRun?.RunProperties?.CloneNode(true) as RunProperties;

                foreach (var r in runs) r.Remove();

                var newRun = new Run();
                if (rPr != null) newRun.Append(rPr);
                newRun.Append(new Text(newText) { Space = DocumentFormat.OpenXml.SpaceProcessingModeValues.Preserve });
                para.Append(newRun);
            }

            // نفس الشيء للجداول
            foreach (var cell in body.Descendants<TableCell>())
            {
                foreach (var para in cell.Descendants<Paragraph>())
                {
                    var fullText = string.Concat(para.Descendants<Text>().Select(t => t.Text));
                    if (string.IsNullOrWhiteSpace(fullText)) continue;
                    var newText = fullText;
                    foreach (var kvp in replacements)
                        newText = newText.Replace(kvp.Key, kvp.Value);
                    if (newText == fullText) continue;
                    var runs = para.Elements<Run>().ToList();
                    var firstRun = runs.FirstOrDefault();
                    var rPr = firstRun?.RunProperties?.CloneNode(true) as RunProperties;
                    foreach (var r in runs) r.Remove();
                    var newRun = new Run();
                    if (rPr != null) newRun.Append(rPr);
                    newRun.Append(new Text(newText) { Space = DocumentFormat.OpenXml.SpaceProcessingModeValues.Preserve });
                    para.Append(newRun);
                }
            }

            doc.MainDocumentPart.Document.Save();
        }

        private static Dictionary<string, string> GetSellReplacements() => new()
        {
            ["البائع      :     "] = "البائع: شركة بيت الخبرة للاستثمار الاقتصادي (تكنو إنفستمنت)",
            ["المشتري :    "] = "المشتري: {{PARTY_NAME}}",
            ["الوحدة  المبيعه : "] = "الوحدة: {{ASSET_NAME}} - {{ASSET_LOCATION}} - {{ASSET_CITY}}",
            ["الثمن الإجمالى   :"] = "الثمن الإجمالي: {{AMOUNT}} جنيه مصري",
            ["إنه في يوم             الموافق  "] = "إنه في يوم {{CONTRACT_DATE}}",
            ["( طرف ثان مشترى )"] = "{{PARTY_NAME}} - هوية: {{PARTY_ID}} - هاتف: {{PARTY_PHONE}}",
            ["00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"] = "{{ASSET_NAME}} - {{ASSET_LOCATION}} - {{ASSET_CITY}} - {{ASSET_AREA}}",
            ["تم هذا البيع نظير ثمن إجمالي موضوع هذا العقد بمبلغ 000000000000000000000000جنيهاً مصرياً (000000000000000):-"] = "تم هذا البيع بثمن {{AMOUNT}} جنيه مصري ({{AMOUNT_TEXT}}).",
            ["يمتلك الطرف الأول ما هو 00000000000000000000000000000000والمحددة بالحدود الآتية : -"] = "يمتلك الطرف الأول الوحدة {{ASSET_NAME}} - صك: {{DEED_NUMBER}} - قطعة: {{PLOT_NUMBER}}",
            ["الحـــد البـــــحـــرى : 00000000000000"] = "رقم العقد: {{CONTRACT_NUMBER}}",
            ["الحـــد الـــــشرقى : 0000000000000000"] = "رقم القطعة: {{PLOT_NUMBER}}",
            ["الحد الغربى :  :0000000000000000."] = "هاتف: {{PARTY_PHONE}}",
            ["الحد القبلى :  :000000000000000000"] = "رقم الهوية: {{PARTY_ID}}",
        };

        private static Dictionary<string, string> GetRentReplacements() => new()
        {
            ["إسم المستأجر :"] = "إسم المستأجر: {{PARTY_NAME}}",
            ["  الوحدة رقم : "] = "الوحدة: {{ASSET_NAME}} - {{ASSET_LOCATION}}",
            ["إيجار الشهري للوحدة :"] = "إيجار شهري: {{AMOUNT}} جنيه",
            ["التأمين :"] = "التأمين: {{SECURITY_DEPOSIT}} جنيه",
            ["طرف ثاني مستأجر"] = "{{PARTY_NAME}} - هوية: {{PARTY_ID}} - هاتف: {{PARTY_PHONE}}",
            ["مدة هذا العقد هى 000000000000000000000000000000000000 غير قابله للتجديد"] = "مدة العقد من {{START_DATE}} حتى {{END_DATE}}",
            ["إتفق الطرفان على أن تكون القيمة الإيجارية الشهرية للوحدة  المؤجره موضوع هذا العقد هى مبلغ وقــدره  000000ج  0000000000شهرياً  شاملة  الضريبة العقارية ."] = "القيمة الإيجارية الشهرية {{AMOUNT}} جنيه ({{AMOUNT_TEXT}}) شاملة الضريبة.",
            [" حدد مبلغ التأمين بمبلغ 000000000000000000 ) وقدره,"] = "مبلغ التأمين: {{SECURITY_DEPOSIT}} جنيه",
        };

        private static Dictionary<string, string> GetCommReplacements() => new()
        {
            ["المستأجر :"] = "المستأجر: {{PARTY_NAME}}",
            ["الوحدة المستأجرة: المحل رقم  "] = "الوحدة التجارية: {{ASSET_NAME}} - {{ASSET_LOCATION}}",
            ["الإيجار الشهري للوحدة : "] = "إيجار شهري: {{AMOUNT}} جنيه",
            ["التامين :"] = "التأمين: {{SECURITY_DEPOSIT}} جنيه",
            ["طرف ثان مستاجر"] = "{{PARTY_NAME}} - هوية: {{PARTY_ID}} - هاتف: {{PARTY_PHONE}}",
            ["مدة هذا العقد هى  00000000000000000000 غير قابله للتجديد"] = "مدة العقد من {{START_DATE}} حتى {{END_DATE}}",
            ["إتفق الطرفان على أن تكون القيمة الإيجارية الشهرية للمحل المؤجر موضوع هذا العقد هى مبلغ وقــدره 000000000000000000000000"] = "القيمة الإيجارية الشهرية {{AMOUNT}} جنيه ({{AMOUNT_TEXT}}).",
        };
    }
}