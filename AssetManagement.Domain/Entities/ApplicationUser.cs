using Microsoft.AspNetCore.Identity;

namespace AssetManagement.Domain.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public string FullName    { get; set; } = string.Empty;
        public string? Department { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public bool IsActive      { get; set; } = true;
    }
}