# Fix_Final.ps1
# powershell -ExecutionPolicy Bypass -File C:\Users\ahmed.essamm\Desktop\Fix_Final.ps1

$base = "$env:USERPROFILE\Desktop\AssetManagement"
$utf8 = New-Object System.Text.UTF8Encoding($false)

# ============================================================
# FIX 1: ContractsController - AppIdentityUser → ApplicationUser
# ============================================================
$ccPath = "$base\AssetManagement.Web\Controllers\ContractsController.cs"
if (Test-Path $ccPath) {
    $cc = [System.IO.File]::ReadAllText($ccPath, $utf8)
    $cc = $cc.Replace("AppIdentityUser", "ApplicationUser")
    [System.IO.File]::WriteAllText($ccPath, $cc, $utf8)
    Write-Host "Fixed: ContractsController" -ForegroundColor Green
} else {
    Write-Host "MISSING: ContractsController" -ForegroundColor Red
}

# ============================================================
# FIX 2: أي controller فيه AppIdentityUser
# ============================================================
$controllers = Get-ChildItem "$base\AssetManagement.Web\Controllers\*.cs"
foreach ($f in $controllers) {
    $content = [System.IO.File]::ReadAllText($f.FullName, $utf8)
    if ($content -match "AppIdentityUser") {
        $content = $content.Replace("AppIdentityUser", "ApplicationUser")
        [System.IO.File]::WriteAllText($f.FullName, $content, $utf8)
        Write-Host "Fixed AppIdentityUser in: $($f.Name)" -ForegroundColor Yellow
    }
}

# ============================================================
# FIX 3: Build
# ============================================================
Write-Host "`nBuilding..." -ForegroundColor Cyan
Set-Location $base
$result = & dotnet build 2>&1
$result | Write-Host

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild succeeded!" -ForegroundColor Green
    Write-Host "Now run migrations:" -ForegroundColor Yellow
    Write-Host "  cd $base\AssetManagement.Infrastructure" -ForegroundColor White
    Write-Host "  dotnet ef migrations add InitialCreate --startup-project ..\AssetManagement.Web --context ApplicationDbContext" -ForegroundColor White
    Write-Host "  dotnet ef database update --startup-project ..\AssetManagement.Web --context ApplicationDbContext" -ForegroundColor White
} else {
    Write-Host "`nBuild FAILED - check errors above" -ForegroundColor Red
}
