$base = "$env:USERPROFILE\Desktop\AssetManagement"
$enc  = [System.Text.Encoding]::UTF8

$mp = "$base\AssetManagement.Web\Controllers\MarketingUploadController.cs"
$mc = [System.IO.File]::ReadAllText($mp, $enc)
$mc = $mc.Replace('[Authorize(Roles = "Marketing,SuperAdmin")]', '[Authorize(Roles = "Legal,SuperAdmin")]')
[System.IO.File]::WriteAllText($mp, $mc, $enc)
Write-Host "OK: MarketingUploadController role changed to Legal" -ForegroundColor Green

$dp = "$base\AssetManagement.Web\Views\Asset\Details.cshtml"
$dc = [System.IO.File]::ReadAllText($dp, $enc)
$o8=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("QGlmIChhLkN1cnJlbnRTdGFnZSA9PSA4ICYmIGlzTWFya2V0aW5nKQ=="))
$n8=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("QGlmIChhLkN1cnJlbnRTdGFnZSA9PSA4ICYmIGlzTGVnYWwp"))
$dc = $dc.Replace($o8,$n8)
[System.IO.File]::WriteAllText($dp,$dc,$enc)
Write-Host "OK: Details.cshtml stage 8 card changed to Legal" -ForegroundColor Green

$up = "$base\AssetManagement.Web\Views\Users\Index.cshtml"
if (Test-Path $up) {
    $uc = [System.IO.File]::ReadAllText($up, $enc)
    $toRemove = @("Board_Low","DataEntry","Sales","Valuator")
    foreach ($r in $toRemove) {
        $uc = [System.Text.RegularExpressions.Regex]::Replace($uc,
            "\s*<option value=\"" + $r + "\">" + $r + "</option>", "")
    }
    [System.IO.File]::WriteAllText($up, $uc, $enc)
    Write-Host "OK: Users roles dropdown cleaned" -ForegroundColor Green
} else { Write-Host "WARN: Users/Index not found" -ForegroundColor Red }

cd $base
dotnet build 2>&1 | Select-Object -Last 4
if ($LASTEXITCODE -eq 0) { Write-Host "Build OK!" -ForegroundColor Green }