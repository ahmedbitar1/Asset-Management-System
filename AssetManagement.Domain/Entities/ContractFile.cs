namespace AssetManagement.Domain.Entities
{
    /// <summary>
    /// Ù…Ù„ÙØ§Øª Ø§Ù„Ø¹Ù‚Ø¯ Ø§Ù„Ù…Ø±ÙÙˆØ¹Ø© (PDF / Word) Ù…Ù† Ù‚ÙØ¨Ù„ Ø§Ù„ØªØ³ÙˆÙŠÙ‚ Ø¨Ø¹Ø¯ Ø§Ù„ØªÙˆÙ‚ÙŠØ¹
    /// </summary>
    public class ContractFile
    {
        public int Id         { get; set; }
        public int ContractId { get; set; }
        public Contract Contract { get; set; } = null!;

        public int AssetId { get; set; }
        public Asset Asset { get; set; } = null!;

        /// <summary>Ø§Ø³Ù… Ø§Ù„Ù…Ù„Ù Ø§Ù„Ø£ØµÙ„ÙŠ</summary>
        public string FileName { get; set; } = string.Empty;

        /// <summary>Ø§Ù„Ù…Ø³Ø§Ø± Ø§Ù„Ù†Ø³Ø¨ÙŠ Ø¯Ø§Ø®Ù„ wwwroot</summary>
        public string FilePath { get; set; } = string.Empty;

        /// <summary>Ù†ÙˆØ¹ Ø§Ù„Ù…Ù„Ù: PDF Ø£Ùˆ Word</summary>
        public string FileType { get; set; } = string.Empty;

        /// <summary>Ø­Ø¬Ù… Ø§Ù„Ù…Ù„Ù Ø¨Ø§Ù„Ø¨Ø§ÙŠØª</summary>
        public long FileSize { get; set; }

        /// <summary>MIME type Ù…Ø«Ù„ application/pdf Ø£Ùˆ application/vnd.openxmlformats...</summary>
        public string ContentType { get; set; } = string.Empty;

        public string?   UploadedById { get; set; }
        public DateTime  UploadedAt   { get; set; } = DateTime.Now;
    }
}