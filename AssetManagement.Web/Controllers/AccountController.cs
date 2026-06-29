using AssetManagement.Domain.Entities;
using AssetManagement.Infrastructure.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    public class AccountController : Controller
    {
        private readonly UserManager<ApplicationUser>   _um;
        private readonly SignInManager<ApplicationUser> _sm;

        public AccountController(
            UserManager<ApplicationUser>   um,
            SignInManager<ApplicationUser> sm)
        {
            _um = um; _sm = sm;
        }

        [HttpGet]
        public IActionResult Login() => View();

        [HttpPost]
        public async Task<IActionResult> Login(string username, string password)
        {
            var byEmail = await _um.FindByEmailAsync(username);
            if (byEmail != null)
            {
                var r = await _sm.PasswordSignInAsync(byEmail, password, false, false);
                if (r.Succeeded) return RedirectToAction("Index", "Dashboard");
            }
            var byName = await _um.FindByNameAsync(username);
            if (byName != null)
            {
                var r = await _sm.PasswordSignInAsync(byName, password, false, false);
                if (r.Succeeded) return RedirectToAction("Index", "Dashboard");
            }
            ViewBag.Error = "Invalid username or password";
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            await _sm.SignOutAsync();
            return RedirectToAction("Login");
        }

        public IActionResult AccessDenied() => View();
    }
}