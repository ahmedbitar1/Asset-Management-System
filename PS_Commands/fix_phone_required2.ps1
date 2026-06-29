$base = "$env:USERPROFILE\Desktop\AssetManagement"
$enc  = [System.Text.Encoding]::UTF8

# Make phone fields required in ViewModel
$vp = "$base\AssetManagement.Application\ViewModels\RequestViewModel.cs"
$vc = [System.IO.File]::ReadAllText($vp, $enc)
$o1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("cHVibGljIHN0cmluZz8gVGVuYW50UGhvbmUgICAgeyBnZXQ7IHNldDsgfQ=="))
$n1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("W1N5c3RlbS5Db21wb25lbnRNb2RlbC5EYXRhQW5ub3RhdGlvbnMuUmVxdWlyZWQoRXJyb3JNZXNzYWdlID0gIlBob25lIG51bWJlciBpcyByZXF1aXJlZCIpXQogICAgICAgIHB1YmxpYyBzdHJpbmc/IFRlbmFudFBob25lICAgIHsgZ2V0OyBzZXQ7IH0="))
$o2 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("cHVibGljIHN0cmluZz8gQnV5ZXJQaG9uZSAgICB7IGdldDsgc2V0OyB9"))
$n2 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("W1N5c3RlbS5Db21wb25lbnRNb2RlbC5EYXRhQW5ub3RhdGlvbnMuUmVxdWlyZWQoRXJyb3JNZXNzYWdlID0gIlBob25lIG51bWJlciBpcyByZXF1aXJlZCIpXQogICAgICAgIHB1YmxpYyBzdHJpbmc/IEJ1eWVyUGhvbmUgICAgeyBnZXQ7IHNldDsgfQ=="))
$vc = $vc.Replace($o1, $n1)
$vc = $vc.Replace($o2, $n2)
[System.IO.File]::WriteAllText($vp, $vc, $enc)
Write-Host "OK: Phone required attribute added" -ForegroundColor Green

# Add required to CreateRental
$rp = "$base\AssetManagement.Web\Views\Requests\CreateRental.cshtml"
$rc = [System.IO.File]::ReadAllText($rp, $enc)
$o3 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("PGlucHV0IGFzcC1mb3I9IlRlbmFudFBob25lIiBjbGFzcz0iZm9ybS1jb250cm9sIi8+"))
$n3 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("PGlucHV0IGFzcC1mb3I9IlRlbmFudFBob25lIiBjbGFzcz0iZm9ybS1jb250cm9sIiByZXF1aXJlZC8+"))
$rc = $rc.Replace($o3, $n3)
[System.IO.File]::WriteAllText($rp, $rc, $enc)
Write-Host "OK: CreateRental phone required" -ForegroundColor Green

# Add required to CreateSale
$sp = "$base\AssetManagement.Web\Views\Requests\CreateSale.cshtml"
$sc = [System.IO.File]::ReadAllText($sp, $enc)
$o4 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("PGlucHV0IGFzcC1mb3I9IkJ1eWVyUGhvbmUiIGNsYXNzPSJmb3JtLWNvbnRyb2wiLz4="))
$n4 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("PGlucHV0IGFzcC1mb3I9IkJ1eWVyUGhvbmUiIGNsYXNzPSJmb3JtLWNvbnRyb2wiIHJlcXVpcmVkLz4="))
$sc = $sc.Replace($o4, $n4)
[System.IO.File]::WriteAllText($sp, $sc, $enc)
Write-Host "OK: CreateSale phone required" -ForegroundColor Green

cd $base
dotnet build 2>&1 | Select-Object -Last 4
if ($LASTEXITCODE -eq 0) { Write-Host "Build OK!" -ForegroundColor Green }