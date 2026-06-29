using AssetManagement.Domain.Entities;
using AssetManagement.Application.ViewModels;
using AssetManagement.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AssetManagement.Web.Controllers
{
    [Authorize(Roles = "SuperAdmin")]
    public class UsersController : Controller
    {
        private readonly UserManager<ApplicationUser> _um;
        private readonly RoleManager<IdentityRole>    _rm;

        public UsersController(UserManager<ApplicationUser> um, RoleManager<IdentityRole> rm)
        { _um = um; _rm = rm; }

        public async Task<IActionResult> Index()
        {
            var users = await _um.Users.ToListAsync();
            var vm = new List<UserListViewModel>();
            foreach (var u in users)
            {
                var roles = await _um.GetRolesAsync(u);
                vm.Add(new UserListViewModel
                {
                    Id=u.Id, UserName=u.UserName??string.Empty,
                    FullName=u.FullName, Email=u.Email,
                    Department=u.Department, Roles=roles.ToList()
                });
            }
            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> Create()
        {
            var vm = new CreateUserViewModel
                { AllRoles = _rm.Roles.Select(r => r.Name!).OrderBy(r=>r).ToList() };
            return View(vm);
        }

        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(CreateUserViewModel vm)
        {
            vm.AllRoles = _rm.Roles.Select(r => r.Name!).OrderBy(r=>r).ToList();
            if (!ModelState.IsValid) return View(vm);
            var user = new ApplicationUser
            {
                UserName=vm.UserName, Email=vm.Email,
                FullName=vm.FullName, Department=vm.Department,
                PhoneNumber=vm.PhoneNumber, EmailConfirmed=true
            };
            var result = await _um.CreateAsync(user, vm.Password);
            if (!result.Succeeded)
            {
                foreach (var e in result.Errors)
                    ModelState.AddModelError(string.Empty, e.Description);
                return View(vm);
            }
            if (vm.SelectedRoles.Any())
                await _um.AddToRolesAsync(user, vm.SelectedRoles);
            TempData["Success"] = "تم إنشاء المستخدم بنجاح";
            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> Edit(string id)
        {
            var user = await _um.FindByIdAsync(id);
            if (user == null) return NotFound();
            var userRoles = await _um.GetRolesAsync(user);
            var vm = new EditUserViewModel
            {
                Id=user.Id, UserName=user.UserName??string.Empty,
                FullName=user.FullName, Email=user.Email??string.Empty,
                Department=user.Department, PhoneNumber=user.PhoneNumber,
                SelectedRoles=userRoles.ToList(),
                AllRoles=_rm.Roles.Select(r=>r.Name!).OrderBy(r=>r).ToList()
            };
            return View(vm);
        }

        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(EditUserViewModel vm)
        {
            vm.AllRoles = _rm.Roles.Select(r=>r.Name!).OrderBy(r=>r).ToList();
            if (!ModelState.IsValid) return View(vm);
            var user = await _um.FindByIdAsync(vm.Id);
            if (user == null) return NotFound();
            user.UserName   = vm.UserName;
            user.Email      = vm.Email;
            user.FullName   = vm.FullName;
            user.Department = vm.Department;
            user.PhoneNumber= vm.PhoneNumber;
            await _um.UpdateAsync(user);
            if (!string.IsNullOrWhiteSpace(vm.NewPassword))
            {
                var token = await _um.GeneratePasswordResetTokenAsync(user);
                await _um.ResetPasswordAsync(user, token, vm.NewPassword);
            }
            var currentRoles = await _um.GetRolesAsync(user);
            await _um.RemoveFromRolesAsync(user, currentRoles);
            if (vm.SelectedRoles.Any())
                await _um.AddToRolesAsync(user, vm.SelectedRoles);
            TempData["Success"] = "تم تحديث المستخدم بنجاح";
            return RedirectToAction(nameof(Index));
        }

        [HttpPost][ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(string id)
        {
            var user = await _um.FindByIdAsync(id);
            if (user != null && user.UserName != "admin")
                await _um.DeleteAsync(user);
            TempData["Success"] = "تم حذف المستخدم";
            return RedirectToAction(nameof(Index));
        }
    }
}