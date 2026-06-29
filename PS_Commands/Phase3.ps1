# ============================================================
# Phase3.ps1 - User Management + Profile
# ============================================================
$base = "$env:USERPROFILE\Desktop\AssetManagement"
$web  = "$base\AssetManagement.Web"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function wf($path, $txt) {
    $dir = Split-Path $path
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [System.IO.File]::WriteAllText($path, $txt, $utf8)
    Write-Host "  OK: $(Split-Path $path -Leaf)" -ForegroundColor Green
}

Write-Host "==> Phase 3: User Management" -ForegroundColor Cyan

# ── ViewModels ─────────────────────────────────────────────
wf "$base\AssetManagement.Application\ViewModels\UserViewModel.cs" `
'using System.ComponentModel.DataAnnotations;

namespace AssetManagement.Application.ViewModels
{
    public class UserListViewModel
    {
        public string Id       { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? Email   { get; set; }
        public string? Department { get; set; }
        public List<string> Roles { get; set; } = new();
        public bool IsActive  { get; set; } = true;
    }

    public class CreateUserViewModel
    {
        [Required] public string UserName   { get; set; } = string.Empty;
        [Required] public string FullName   { get; set; } = string.Empty;
        [Required][EmailAddress] public string Email { get; set; } = string.Empty;
        public string? Department           { get; set; }
        public string? PhoneNumber          { get; set; }
        [Required][MinLength(4)] public string Password { get; set; } = string.Empty;
        public List<string> SelectedRoles   { get; set; } = new();
        public List<string> AllRoles        { get; set; } = new();
    }

    public class EditUserViewModel
    {
        public string  Id         { get; set; } = string.Empty;
        [Required] public string UserName   { get; set; } = string.Empty;
        [Required] public string FullName   { get; set; } = string.Empty;
        [Required][EmailAddress] public string Email { get; set; } = string.Empty;
        public string? Department  { get; set; }
        public string? PhoneNumber { get; set; }
        public string? NewPassword { get; set; }
        public List<string> SelectedRoles { get; set; } = new();
        public List<string> AllRoles      { get; set; } = new();
    }
}'

# ── UsersController ────────────────────────────────────────
$uc = [System.Collections.Generic.List[string]]::new()
$uc.Add("using AssetManagement.Application.ViewModels;")
$uc.Add("using AssetManagement.Infrastructure.Data;")
$uc.Add("using Microsoft.AspNetCore.Authorization;")
$uc.Add("using Microsoft.AspNetCore.Identity;")
$uc.Add("using Microsoft.AspNetCore.Mvc;")
$uc.Add("using Microsoft.EntityFrameworkCore;")
$uc.Add("")
$uc.Add("namespace AssetManagement.Web.Controllers")
$uc.Add("{")
$uc.Add("    [Authorize(Roles = " + [char]34 + "SuperAdmin" + [char]34 + ")]")
$uc.Add("    public class UsersController : Controller")
$uc.Add("    {")
$uc.Add("        private readonly UserManager<AppIdentityUser> _um;")
$uc.Add("        private readonly RoleManager<IdentityRole>    _rm;")
$uc.Add("")
$uc.Add("        public UsersController(UserManager<AppIdentityUser> um, RoleManager<IdentityRole> rm)")
$uc.Add("        { _um = um; _rm = rm; }")
$uc.Add("")
$uc.Add("        public async Task<IActionResult> Index()")
$uc.Add("        {")
$uc.Add("            var users = await _um.Users.ToListAsync();")
$uc.Add("            var vm = new List<UserListViewModel>();")
$uc.Add("            foreach (var u in users)")
$uc.Add("            {")
$uc.Add("                var roles = await _um.GetRolesAsync(u);")
$uc.Add("                vm.Add(new UserListViewModel")
$uc.Add("                {")
$uc.Add("                    Id=u.Id, UserName=u.UserName??string.Empty,")
$uc.Add("                    FullName=u.FullName, Email=u.Email,")
$uc.Add("                    Department=u.Department, Roles=roles.ToList()")
$uc.Add("                });")
$uc.Add("            }")
$uc.Add("            return View(vm);")
$uc.Add("        }")
$uc.Add("")
$uc.Add("        [HttpGet]")
$uc.Add("        public async Task<IActionResult> Create()")
$uc.Add("        {")
$uc.Add("            var vm = new CreateUserViewModel")
$uc.Add("                { AllRoles = _rm.Roles.Select(r => r.Name!).OrderBy(r=>r).ToList() };")
$uc.Add("            return View(vm);")
$uc.Add("        }")
$uc.Add("")
$uc.Add("        [HttpPost][ValidateAntiForgeryToken]")
$uc.Add("        public async Task<IActionResult> Create(CreateUserViewModel vm)")
$uc.Add("        {")
$uc.Add("            vm.AllRoles = _rm.Roles.Select(r => r.Name!).OrderBy(r=>r).ToList();")
$uc.Add("            if (!ModelState.IsValid) return View(vm);")
$uc.Add("            var user = new AppIdentityUser")
$uc.Add("            {")
$uc.Add("                UserName=vm.UserName, Email=vm.Email,")
$uc.Add("                FullName=vm.FullName, Department=vm.Department,")
$uc.Add("                PhoneNumber=vm.PhoneNumber, EmailConfirmed=true")
$uc.Add("            };")
$uc.Add("            var result = await _um.CreateAsync(user, vm.Password);")
$uc.Add("            if (!result.Succeeded)")
$uc.Add("            {")
$uc.Add("                foreach (var e in result.Errors)")
$uc.Add("                    ModelState.AddModelError(string.Empty, e.Description);")
$uc.Add("                return View(vm);")
$uc.Add("            }")
$uc.Add("            if (vm.SelectedRoles.Any())")
$uc.Add("                await _um.AddToRolesAsync(user, vm.SelectedRoles);")
$uc.Add("            TempData[" + [char]34 + "Success" + [char]34 + "] = " + [char]34 + "User created successfully" + [char]34 + ";")
$uc.Add("            return RedirectToAction(nameof(Index));")
$uc.Add("        }")
$uc.Add("")
$uc.Add("        [HttpGet]")
$uc.Add("        public async Task<IActionResult> Edit(string id)")
$uc.Add("        {")
$uc.Add("            var user = await _um.FindByIdAsync(id);")
$uc.Add("            if (user == null) return NotFound();")
$uc.Add("            var userRoles = await _um.GetRolesAsync(user);")
$uc.Add("            var vm = new EditUserViewModel")
$uc.Add("            {")
$uc.Add("                Id=user.Id, UserName=user.UserName??string.Empty,")
$uc.Add("                FullName=user.FullName, Email=user.Email??string.Empty,")
$uc.Add("                Department=user.Department, PhoneNumber=user.PhoneNumber,")
$uc.Add("                SelectedRoles=userRoles.ToList(),")
$uc.Add("                AllRoles=_rm.Roles.Select(r=>r.Name!).OrderBy(r=>r).ToList()")
$uc.Add("            };")
$uc.Add("            return View(vm);")
$uc.Add("        }")
$uc.Add("")
$uc.Add("        [HttpPost][ValidateAntiForgeryToken]")
$uc.Add("        public async Task<IActionResult> Edit(EditUserViewModel vm)")
$uc.Add("        {")
$uc.Add("            vm.AllRoles = _rm.Roles.Select(r=>r.Name!).OrderBy(r=>r).ToList();")
$uc.Add("            if (!ModelState.IsValid) return View(vm);")
$uc.Add("            var user = await _um.FindByIdAsync(vm.Id);")
$uc.Add("            if (user == null) return NotFound();")
$uc.Add("            user.UserName   = vm.UserName;")
$uc.Add("            user.Email      = vm.Email;")
$uc.Add("            user.FullName   = vm.FullName;")
$uc.Add("            user.Department = vm.Department;")
$uc.Add("            user.PhoneNumber= vm.PhoneNumber;")
$uc.Add("            await _um.UpdateAsync(user);")
$uc.Add("            if (!string.IsNullOrWhiteSpace(vm.NewPassword))")
$uc.Add("            {")
$uc.Add("                var token = await _um.GeneratePasswordResetTokenAsync(user);")
$uc.Add("                await _um.ResetPasswordAsync(user, token, vm.NewPassword);")
$uc.Add("            }")
$uc.Add("            var currentRoles = await _um.GetRolesAsync(user);")
$uc.Add("            await _um.RemoveFromRolesAsync(user, currentRoles);")
$uc.Add("            if (vm.SelectedRoles.Any())")
$uc.Add("                await _um.AddToRolesAsync(user, vm.SelectedRoles);")
$uc.Add("            TempData[" + [char]34 + "Success" + [char]34 + "] = " + [char]34 + "User updated successfully" + [char]34 + ";")
$uc.Add("            return RedirectToAction(nameof(Index));")
$uc.Add("        }")
$uc.Add("")
$uc.Add("        [HttpPost][ValidateAntiForgeryToken]")
$uc.Add("        public async Task<IActionResult> Delete(string id)")
$uc.Add("        {")
$uc.Add("            var user = await _um.FindByIdAsync(id);")
$uc.Add("            if (user != null && user.UserName != " + [char]34 + "admin" + [char]34 + ")")
$uc.Add("                await _um.DeleteAsync(user);")
$uc.Add("            TempData[" + [char]34 + "Success" + [char]34 + "] = " + [char]34 + "User deleted" + [char]34 + ";")
$uc.Add("            return RedirectToAction(nameof(Index));")
$uc.Add("        }")
$uc.Add("    }")
$uc.Add("}")

[System.IO.File]::WriteAllText("$web\Controllers\UsersController.cs",
    [string]::Join([System.Environment]::NewLine, $uc), $utf8)
Write-Host "  OK: UsersController.cs" -ForegroundColor Green

# ── Views/Users ────────────────────────────────────────────
New-Item -ItemType Directory -Force "$web\Views\Users" | Out-Null

wf "$web\Views\Users\Index.cshtml" `
'@model List<AssetManagement.Application.ViewModels.UserListViewModel>
@{
    ViewData["Title"] = "Users Management";
}
<div class="d-flex justify-content-between align-items-center mb-4">
    <h5 class="fw-bold mb-0">
        <i class="bi bi-people me-2 text-primary"></i>Users Management
        <span class="badge bg-secondary ms-2">@Model.Count</span>
    </h5>
    <a asp-action="Create" class="btn btn-primary">
        <i class="bi bi-person-plus me-1"></i>Add User
    </a>
</div>

<div class="card border-0 shadow-sm">
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="table-dark">
                <tr>
                    <th>#</th>
                    <th>Username</th>
                    <th>Full Name</th>
                    <th>Email</th>
                    <th>Department</th>
                    <th>Roles</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @foreach (var (u, i) in Model.Select((u, i) => (u, i + 1)))
                {
                <tr>
                    <td class="text-muted small">@i</td>
                    <td class="fw-semibold">
                        <i class="bi bi-person-circle me-1 text-primary"></i>@u.UserName
                    </td>
                    <td>@u.FullName</td>
                    <td class="text-muted small">@u.Email</td>
                    <td class="text-muted small">@u.Department</td>
                    <td>
                        @foreach (var r in u.Roles)
                        {
                            <span class="badge bg-primary me-1 small">@r</span>
                        }
                    </td>
                    <td>
                        <a asp-action="Edit" asp-route-id="@u.Id"
                           class="btn btn-sm btn-outline-primary me-1">
                            <i class="bi bi-pencil"></i>
                        </a>
                        @if (u.UserName != "admin")
                        {
                        <form asp-action="Delete" method="post" class="d-inline"
                              onsubmit="return confirm(''Are you sure?'')">
                            @Html.AntiForgeryToken()
                            <input type="hidden" name="id" value="@u.Id" />
                            <button type="submit" class="btn btn-sm btn-outline-danger">
                                <i class="bi bi-trash"></i>
                            </button>
                        </form>
                        }
                    </td>
                </tr>
                }
            </tbody>
        </table>
    </div>
</div>'

wf "$web\Views\Users\Create.cshtml" `
'@model AssetManagement.Application.ViewModels.CreateUserViewModel
@{
    ViewData["Title"] = "Add New User";
}
<div class="row justify-content-center">
<div class="col-md-8">
    <div class="card border-0 shadow-sm">
        <div class="card-header bg-primary text-white fw-bold">
            <i class="bi bi-person-plus me-2"></i>Add New User
        </div>
        <div class="card-body">
            <form asp-action="Create" method="post">
                @Html.AntiForgeryToken()
                <div asp-validation-summary="ModelOnly" class="alert alert-danger d-none"></div>

                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Username *</label>
                        <input asp-for="UserName" class="form-control" />
                        <span asp-validation-for="UserName" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Full Name *</label>
                        <input asp-for="FullName" class="form-control" />
                        <span asp-validation-for="FullName" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Email *</label>
                        <input asp-for="Email" type="email" class="form-control" />
                        <span asp-validation-for="Email" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Password *</label>
                        <input asp-for="Password" type="password" class="form-control" />
                        <span asp-validation-for="Password" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Department</label>
                        <input asp-for="Department" class="form-control" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Phone</label>
                        <input asp-for="PhoneNumber" class="form-control" />
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Roles</label>
                        <div class="row g-2">
                            @foreach (var role in Model.AllRoles)
                            {
                            <div class="col-md-3">
                                <div class="form-check">
                                    <input type="checkbox" class="form-check-input"
                                           name="SelectedRoles" value="@role" id="role_@role" />
                                    <label class="form-check-label small" for="role_@role">@role</label>
                                </div>
                            </div>
                            }
                        </div>
                    </div>
                </div>

                <div class="d-flex gap-2 mt-4">
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-check-lg me-1"></i>Save
                    </button>
                    <a asp-action="Index" class="btn btn-outline-secondary">Cancel</a>
                </div>
            </form>
        </div>
    </div>
</div>
</div>'

wf "$web\Views\Users\Edit.cshtml" `
'@model AssetManagement.Application.ViewModels.EditUserViewModel
@{
    ViewData["Title"] = "Edit User";
}
<div class="row justify-content-center">
<div class="col-md-8">
    <div class="card border-0 shadow-sm">
        <div class="card-header bg-warning text-dark fw-bold">
            <i class="bi bi-pencil me-2"></i>Edit User: @Model.UserName
        </div>
        <div class="card-body">
            <form asp-action="Edit" method="post">
                @Html.AntiForgeryToken()
                <input type="hidden" asp-for="Id" />
                <div asp-validation-summary="ModelOnly" class="alert alert-danger"></div>

                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Username *</label>
                        <input asp-for="UserName" class="form-control" />
                        <span asp-validation-for="UserName" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Full Name *</label>
                        <input asp-for="FullName" class="form-control" />
                        <span asp-validation-for="FullName" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Email *</label>
                        <input asp-for="Email" type="email" class="form-control" />
                        <span asp-validation-for="Email" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">New Password</label>
                        <input asp-for="NewPassword" type="password" class="form-control"
                               placeholder="Leave empty to keep current" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Department</label>
                        <input asp-for="Department" class="form-control" />
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Phone</label>
                        <input asp-for="PhoneNumber" class="form-control" />
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Roles</label>
                        <div class="row g-2">
                            @foreach (var role in Model.AllRoles)
                            {
                            <div class="col-md-3">
                                <div class="form-check">
                                    <input type="checkbox" class="form-check-input"
                                           name="SelectedRoles" value="@role"
                                           id="role_@role"
                                           @(Model.SelectedRoles.Contains(role) ? "checked" : "") />
                                    <label class="form-check-label small" for="role_@role">@role</label>
                                </div>
                            </div>
                            }
                        </div>
                    </div>
                </div>

                <div class="d-flex gap-2 mt-4">
                    <button type="submit" class="btn btn-warning">
                        <i class="bi bi-check-lg me-1"></i>Update
                    </button>
                    <a asp-action="Index" class="btn btn-outline-secondary">Cancel</a>
                </div>
            </form>
        </div>
    </div>
</div>
</div>'

# ── تحديث _Layout لإضافة رابط Users ───────────────────────
wf "$web\Views\Shared\_Layout.cshtml" `
'<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@(ViewData["Title"]) - Asset Management</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"/>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap" rel="stylesheet"/>
    <style>
        *{font-family:"Cairo",sans-serif;}
        body{background:#f0f2f5;}
        .topbar{background:#1a56db;}
        .sidebar{background:#1e3a5f;width:240px;min-width:240px;min-height:calc(100vh - 56px);}
        .sidebar a{color:#94a3b8;display:flex;align-items:center;gap:10px;
            padding:10px 16px;border-radius:8px;margin:3px 8px;
            text-decoration:none;font-size:14px;transition:all .2s;}
        .sidebar a:hover{background:#2d5986;color:#fff;}
        .sidebar a.active{background:#1a56db;color:#fff;}
        .sidebar .sec{color:#64748b;font-size:11px;padding:12px 20px 4px;letter-spacing:1px;}
        .main{flex:1;padding:24px;min-width:0;}
    </style>
</head>
<body>
<nav class="navbar topbar sticky-top shadow-sm" style="height:56px;">
    <div class="container-fluid">
        <span class="text-white fw-bold fs-6">
            <i class="bi bi-buildings me-2"></i>Asset Management System
        </span>
        @if (User.Identity?.IsAuthenticated == true)
        {
            <div class="d-flex align-items-center gap-3">
                <span class="text-white small">
                    <i class="bi bi-person-circle me-1"></i>@User.Identity.Name
                </span>
                <form asp-controller="Account" asp-action="Logout" method="post" class="d-inline">
                    @Html.AntiForgeryToken()
                    <button class="btn btn-outline-light btn-sm">
                        <i class="bi bi-box-arrow-left me-1"></i>Logout
                    </button>
                </form>
            </div>
        }
    </div>
</nav>
<div class="d-flex" style="min-height:calc(100vh - 56px);">
    @if (User.Identity?.IsAuthenticated == true)
    {
        <div class="sidebar">
            <nav class="nav flex-column pt-2">
                <div class="sec">MAIN</div>
                <a asp-controller="Dashboard" asp-action="Index"
                   class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Dashboard"?"active":"")">
                    <i class="bi bi-speedometer2"></i> Dashboard
                </a>
                <a asp-controller="Asset" asp-action="Index"
                   class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Asset"?"active":"")">
                    <i class="bi bi-building"></i> Assets
                </a>
                <div class="sec">TOOLS</div>
                <a asp-controller="AssetImport" asp-action="Index"
                   class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="AssetImport"?"active":"")">
                    <i class="bi bi-file-earmark-excel"></i> Import Excel
                </a>
                @if (User.IsInRole("SuperAdmin"))
                {
                <div class="sec">ADMIN</div>
                <a asp-controller="Users" asp-action="Index"
                   class="@(ViewContext.RouteData.Values["controller"]?.ToString()=="Users"?"active":"")">
                    <i class="bi bi-people"></i> Users
                </a>
                }
            </nav>
        </div>
    }
    <div class="main">
        @if (TempData["Success"] != null)
        {
            <div class="alert alert-success alert-dismissible fade show mb-3">
                <i class="bi bi-check-circle me-2"></i>@TempData["Success"]
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        }
        @if (TempData["Error"] != null)
        {
            <div class="alert alert-danger alert-dismissible fade show mb-3">
                <i class="bi bi-exclamation-triangle me-2"></i>@TempData["Error"]
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        }
        @RenderBody()
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
@await RenderSectionAsync("Scripts", required: false)
</body>
</html>'

Write-Host "`n==> Build..." -ForegroundColor Cyan
cd $base
dotnet build

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild OK! Running..." -ForegroundColor Green
    cd "$base\AssetManagement.Web"
    dotnet run
}