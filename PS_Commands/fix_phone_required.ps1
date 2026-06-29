$base = "$env:USERPROFILE\Desktop\AssetManagement"
$enc  = [System.Text.Encoding]::UTF8

# Make phone fields required in ViewModel
$vp = "$base\AssetManagement.Application\ViewModels\RequestViewModel.cs"
$vc = [System.IO.File]::ReadAllText($vp, $enc)
$vc = $vc.Replace(
    "public string? TenantPhone    { get; set; }",
    "[System.ComponentModel.DataAnnotations.Required(ErrorMessage = \"Phone number is required\")]" + [Environment]::NewLine + "        public string? TenantPhone    { get; set; }"
)
$vc = $vc.Replace(
    "public string? BuyerPhone    { get; set; }",
    "[System.ComponentModel.DataAnnotations.Required(ErrorMessage = \"Phone number is required\")]" + [Environment]::NewLine + "        public string? BuyerPhone    { get; set; }"
)
[System.IO.File]::WriteAllText($vp, $vc, $enc)
Write-Host "OK: Phone required attribute added" -ForegroundColor Green

# Add required attribute to CreateRental form
$rp = "$base\AssetManagement.Web\Views\Requests\CreateRental.cshtml"
$rc = [System.IO.File]::ReadAllText($rp, $enc)
$rc = $rc.Replace(
    '<input asp-for="TenantPhone" class="form-control"/>',
    '<input asp-for="TenantPhone" class="form-control" required/>'
)
[System.IO.File]::WriteAllText($rp, $rc, $enc)
Write-Host "OK: CreateRental phone required" -ForegroundColor Green

# Add required attribute to CreateSale form
$sp = "$base\AssetManagement.Web\Views\Requests\CreateSale.cshtml"
$sc = [System.IO.File]::ReadAllText($sp, $enc)
$sc = $sc.Replace(
    '<input asp-for="BuyerPhone" class="form-control"/>',
    '<input asp-for="BuyerPhone" class="form-control" required/>'
)
[System.IO.File]::WriteAllText($sp, $sc, $enc)
Write-Host "OK: CreateSale phone required" -ForegroundColor Green

cd $base
dotnet build 2>&1 | Select-Object -Last 4
if ($LASTEXITCODE -eq 0) { Write-Host "Build OK!" -ForegroundColor Green }