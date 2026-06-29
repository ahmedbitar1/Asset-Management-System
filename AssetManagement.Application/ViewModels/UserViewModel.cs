using System.ComponentModel.DataAnnotations;

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
}