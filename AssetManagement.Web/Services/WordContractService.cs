using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;

namespace AssetManagement.Web.Services
{
    public class WordContractService
    {
        public byte[] FillTemplate(string templatePath, Dictionary<string, string> data)
        {
            byte[] templateBytes = File.ReadAllBytes(templatePath);

            using var outputMs = new MemoryStream();
            outputMs.Write(templateBytes, 0, templateBytes.Length);

            using (var zip = new ZipArchive(outputMs, ZipArchiveMode.Update, leaveOpen: true))
            {
                var docEntry = zip.GetEntry("word/document.xml");
                if (docEntry == null) return templateBytes;

                string xml;
                using (var reader = new StreamReader(docEntry.Open(), Encoding.UTF8))
                    xml = reader.ReadToEnd();

                // Fix: Word splits placeholders across XML runs
                // Step 1: merge fragmented runs inside {{ }}
                xml = FixSplitPlaceholders(xml);

                // Step 2: replace placeholders
                foreach (var kvp in data)
                    xml = xml.Replace("{{" + kvp.Key + "}}", Escape(kvp.Value ?? ""));

                docEntry.Delete();
                var newEntry = zip.CreateEntry("word/document.xml");
                using var writer = new StreamWriter(newEntry.Open(), new UTF8Encoding(false));
                writer.Write(xml);
            }

            return outputMs.ToArray();
        }

        private static string FixSplitPlaceholders(string xml)
        {
            // Remove XML tags that appear between {{ and }} characters
            // Loop multiple times to handle deeply nested splits
            for (int i = 0; i < 5; i++)
            {
                var prev = xml;
                xml = Regex.Replace(xml,
                    @"(\{\{(?:[^{}]|(?!\}\})<[^>]+>)*)<[^>]+>((?:[^{}]|(?!\}\})<[^>]+>)*\}\})",
                    m => m.Groups[1].Value + m.Groups[2].Value,
                    RegexOptions.Singleline);
                if (xml == prev) break;
            }
            return xml;
        }

        private static string Escape(string s) =>
            s.Replace("&", "&amp;")
             .Replace("<", "&lt;")
             .Replace(">", "&gt;")
             .Replace("\"", "&quot;");
    }
}