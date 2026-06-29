using AssetManagement.Domain.Enums;

namespace AssetManagement.Domain.Entities
{
    /// <summary>
    /// ÙŠØ­ÙØ¸ Ø§Ù„ØªÙ‚ÙŠÙŠÙ…Ø§Øª Ø§Ù„Ø«Ù„Ø§Ø«Ø© Ø§Ù„Ù…Ø³ØªÙ‚Ù„Ø© Ù„ÙƒÙ„ Ø£ØµÙ„:
    /// Marketing (ØªØ³ÙˆÙŠÙ‚) / Finance (Ù…Ø§Ù„ÙŠØ©) / Expert (Ù…ÙƒØ§ØªØ¨ Ø®Ø¨Ø±Ø§Ø¡)
    /// </summary>
    public class AssetValuation
    {
        public int Id      { get; set; }
        public int AssetId { get; set; }
        public Asset Asset { get; set; } = null!;

        /// <summary>Ù†ÙˆØ¹ Ø§Ù„ØªÙ‚ÙŠÙŠÙ…: Marketing / Finance / Expert</summary>
        public EvaluationType EvaluationType { get; set; }

        /// <summary>Ø§Ù„Ù‚ÙŠÙ…Ø© Ø§Ù„ØªÙ‚Ø¯ÙŠØ±ÙŠØ© Ø¨Ø§Ù„Ø¬Ù†ÙŠÙ‡ Ø§Ù„Ù…ØµØ±ÙŠ</summary>
        public decimal Value { get; set; }

        /// <summary>ØªØ¹Ù„ÙŠÙ‚Ø§Øª Ø§Ø®ØªÙŠØ§Ø±ÙŠØ© Ø¹Ù„Ù‰ Ø§Ù„ØªÙ‚ÙŠÙŠÙ…</summary>
        public string? Comments { get; set; }   // nullable â€” Ù„ÙŠØ³Øª Ø¥Ø¬Ø¨Ø§Ø±ÙŠØ©

        public DateTime EvaluationDate { get; set; } = DateTime.Now;

        /// <summary>Id Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ø§Ù„Ø°ÙŠ Ø£Ø¬Ø±Ù‰ Ø§Ù„ØªÙ‚ÙŠÙŠÙ…</summary>
        public string? UserId { get; set; }
    }
}