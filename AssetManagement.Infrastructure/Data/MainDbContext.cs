using Microsoft.EntityFrameworkCore;

namespace AssetManagement.Infrastructure.Data
{
    public class MainDbContext : DbContext
    {
        public MainDbContext(DbContextOptions<MainDbContext> options)
            : base(options) { }

        public DbSet<UserLogin>  UserLogin { get; set; }
        public DbSet<AdminUser>  Admins    { get; set; }
    }
}