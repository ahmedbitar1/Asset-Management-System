using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AssetManagement.Web.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        public IActionResult Index() =>
            RedirectToAction("Index", "Dashboard");

        public IActionResult Error() => View();
    }
}