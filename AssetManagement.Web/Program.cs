using AssetManagement.Domain.Entities;
using AssetManagement.Application.Interfaces;
using AssetManagement.Application.Services;
using AssetManagement.Domain.Interfaces;
using AssetManagement.Infrastructure.Data;
using AssetManagement.Infrastructure.Repository;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options => {
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 4;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireLowercase = false;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

builder.Services.ConfigureApplicationCookie(o => {
    o.LoginPath = "/Account/Login";
    o.AccessDeniedPath = "/Account/AccessDenied";
});

builder.Services.AddScoped<IAssetRepository, AssetRepository>();
builder.Services.AddScoped<IStageHistoryRepository, StageHistoryRepository>();
builder.Services.AddScoped<IExcelImportService, ExcelImportService>();
builder.Services.AddScoped<AssetManagement.Application.Interfaces.IWorkflowService, WorkflowService>();
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(o => { o.IdleTimeout = TimeSpan.FromMinutes(30); o.Cookie.HttpOnly = true; });
builder.Services.AddControllersWithViews();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var um = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
    var rm = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

    // الأدوار الجديدة فقط
    string[] roles = {
        "SuperAdmin", "Legal", "Marketing", "Engineering",
        "AdminAffairs", "Finance", "Board_High", "Treasury"
    };
    foreach (var r in roles)
        if (!await rm.RoleExistsAsync(r))
            await rm.CreateAsync(new IdentityRole(r));

    // Admin
    var admin = await um.FindByNameAsync("admin");
    if (admin == null)
    {
        admin = new ApplicationUser {
            UserName="admin", Email="admin@system.com",
            FullName="System Admin", EmailConfirmed=true
        };
        await um.CreateAsync(admin, "1234");
        await um.AddToRoleAsync(admin, "SuperAdmin");
    }
    else
    {
        var t = await um.GeneratePasswordResetTokenAsync(admin);
        await um.ResetPasswordAsync(admin, t, "1234");
        admin.FullName = "System Admin";
        await um.UpdateAsync(admin);
    }

    // يوزرز الاختبار - الأدوار الجديدة فقط
    var testUsers = new (string U, string F, string R)[]
    {
        ("legal1",       "Legal User",         "Legal"),
        ("finance1",     "Finance User",       "Finance"),
        ("marketing1",   "Marketing User",     "Marketing"),
        ("board_high1",  "Board High User",    "Board_High"),
        ("treasury1",    "Treasury User",      "Treasury"),
        ("engineering1", "Engineering User",   "Engineering"),
        ("adminaffairs1","Admin Affairs User", "AdminAffairs"),
    };
    foreach (var (u, f, r) in testUsers)
    {
        var existing = await um.FindByNameAsync(u);
        if (existing == null)
        {
            var nu = new ApplicationUser { UserName=u, Email=u+"@test.com", FullName=f, EmailConfirmed=true };
            var cr = await um.CreateAsync(nu, "Test@1234");
            if (cr.Succeeded) await um.AddToRoleAsync(nu, r);
            Console.WriteLine(cr.Succeeded ? "Created: "+u : "Failed: "+u);
        }
        else
        {
            // تأكد إن الدور صح
            var currentRoles = await um.GetRolesAsync(existing);
            if (!currentRoles.Contains(r))
            {
                await um.RemoveFromRolesAsync(existing, currentRoles);
                await um.AddToRoleAsync(existing, r);
            }
            Console.WriteLine("OK: "+u);
        }
    }
    Console.WriteLine("Roles and users ready!");
}

app.UseStaticFiles();
app.UseSession();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllerRoute("default", "{controller=Dashboard}/{action=Index}/{id?}");
app.Run();
