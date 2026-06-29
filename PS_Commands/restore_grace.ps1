$p = "$env:USERPROFILE\Desktop\AssetManagement\AssetManagement.Web\Controllers\ContractsController.cs"
$c = [System.IO.File]::ReadAllText($p)
$old = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("Ilx1MDYzNFx1MDY0N1x1MDYzMSAiICsgbGFzdFJlbnRhbC5HcmFjZVBlcmlvZC5WYWx1ZS5Ub1N0cmluZygp"))
$new = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("bGFzdFJlbnRhbC5HcmFjZVBlcmlvZC5WYWx1ZS5Ub1N0cmluZygiTjAiKSArICIgXHUwNjM0XHUwNjQ3XHUwNjMxIg=="))
if ($c.Contains($old)) {
    $c = $c.Replace($old, $new)
    [System.IO.File]::WriteAllText($p, $c, [System.Text.Encoding]::UTF8)
    Write-Host "Restored!" -ForegroundColor Green
} else {
    Write-Host "Not found - already OK" -ForegroundColor Yellow
}
dotnet build 2>&1 | Select-Object -Last 3