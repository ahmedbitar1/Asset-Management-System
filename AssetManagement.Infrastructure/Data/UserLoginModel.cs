using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AssetManagement.Infrastructure.Data
{
    [Table("user_Login")]
    public class UserLogin
    {
        [Key]
        public int serial { get; set; }
        public string User_Name     { get; set; } = string.Empty;
        public string Password_Encr { get; set; } = string.Empty;
    }

    [Table("Admins")]
    public class AdminUser
    {
        [Key]
        public int Id { get; set; }
        public string User_Name { get; set; } = string.Empty;
    }
}