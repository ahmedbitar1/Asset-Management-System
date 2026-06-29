namespace AssetManagement.Domain.Enums
{
    public enum AssetType     { Sale, Rent, Both }
    public enum AssetStatus   { Active, Sold, Rented, Rejected, Pending }
    public enum StageStatus   { Pending, InProgress, Completed, Rejected, Skipped }
    public enum RequestStatus { Pending, UnderReview, Approved, Rejected }
    public enum ContractType  { Sale, Rent }
    public enum ContractStatus { Draft, Signed, Active, Expired, Terminated }

    // Ù†ÙˆØ¹ Ø§Ù„ØªÙ‚ÙŠÙŠÙ… â€” ÙŠÙØ³ØªØ®Ø¯Ù… ÙÙŠ Ø¬Ø¯ÙˆÙ„ AssetValuations
    public enum EvaluationType { Marketing, Finance, Expert }
}