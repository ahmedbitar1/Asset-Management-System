$p = "$env:USERPROFILE\Desktop\AssetManagement\AssetManagement.Web\Controllers\AssetController.cs"
$enc = [System.Text.Encoding]::UTF8
$c = [System.IO.File]::ReadAllText($p, $enc)
$old = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgZm9yZWFjaCAodmFyIHRhYmxlIGluIHRhYmxlc1RvUmVzZWVkKQogICAgICAgICAgICB7CiAgICAgICAgICAgICAgICB0cnkKICAgICAgICAgICAgICAgIHsKICAgICAgICAgICAgICAgICAgICBhd2FpdCBfY3R4LkRhdGFiYXNlLkV4ZWN1dGVTcWxSYXdBc3luYygKICAgICAgICAgICAgICAgICAgICAgICAgJCJEQkNDIENIRUNLSURFTlQgKCd7dGFibGV9JywgUkVTRUVELCAwKSIpOwogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgY2F0Y2ggeyAvKiBcdTA2MmFcdTA2MmNcdTA2MjdcdTA2NDdcdTA2NDQgXHUwNjIzXHUwNjRhIFx1MDYyY1x1MDYyZlx1MDY0OFx1MDY0NCBcdTA2M2FcdTA2NGFcdTA2MzEgXHUwNjQ1XHUwNjQ4XHUwNjJjXHUwNjQ4XHUwNjJmICovIH0KICAgICAgICAgICAgfQ=="))
$new = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgdmFyIHJlc2VlZEVycm9ycyA9IG5ldyBMaXN0PHN0cmluZz4oKTsKICAgICAgICAgICAgZm9yZWFjaCAodmFyIHRhYmxlIGluIHRhYmxlc1RvUmVzZWVkKQogICAgICAgICAgICB7CiAgICAgICAgICAgICAgICB0cnkKICAgICAgICAgICAgICAgIHsKICAgICAgICAgICAgICAgICAgICBhd2FpdCBfY3R4LkRhdGFiYXNlLkV4ZWN1dGVTcWxSYXdBc3luYygKICAgICAgICAgICAgICAgICAgICAgICAgJCJEQkNDIENIRUNLSURFTlQgKCd7dGFibGV9JywgUkVTRUVELCAwKSIpOwogICAgICAgICAgICAgICAgfQogICAgICAgICAgICAgICAgY2F0Y2ggKEV4Y2VwdGlvbiBleCkKICAgICAgICAgICAgICAgIHsKICAgICAgICAgICAgICAgICAgICByZXNlZWRFcnJvcnMuQWRkKCQie3RhYmxlfToge2V4Lk1lc3NhZ2V9Iik7CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaWYgKHJlc2VlZEVycm9ycy5BbnkoKSkKICAgICAgICAgICAgewogICAgICAgICAgICAgICAgVGVtcERhdGFbIkVycm9yIl0gPSAiXHUwNjJhXHUwNjQ1IFx1MDYyN1x1MDY0NFx1MDYyZFx1MDYzMFx1MDY0MSBcdTA2NDRcdTA2NDNcdTA2NDYgXHUwNjQxXHUwNjM0XHUwNjQ0IFx1MDYyN1x1MDY0NFx1MDYyYVx1MDYzNVx1MDY0MVx1MDY0YVx1MDYzMTogIiArIHN0cmluZy5Kb2luKCIgfCAiLCByZXNlZWRFcnJvcnMpOwogICAgICAgICAgICAgICAgcmV0dXJuIFJlZGlyZWN0VG9BY3Rpb24obmFtZW9mKEluZGV4KSk7CiAgICAgICAgICAgIH0="))
if ($c.Contains($old)) {
    $c = $c.Replace($old, $new)
    [System.IO.File]::WriteAllText($p, $c, $enc)
    Write-Host "OK: Error reporting added to DeleteAll reseed" -ForegroundColor Green
} else {
    Write-Host "WARN: pattern not found - showing current DeleteAll section:" -ForegroundColor Red
    $idx = $c.IndexOf("tablesToReseed")
    if ($idx -ge 0) { Write-Host $c.Substring($idx, [Math]::Min(800, $c.Length - $idx)) }
    else { Write-Host "tablesToReseed not found at all - DeleteAll wasn't updated last time!" -ForegroundColor Red }
}
cd "$env:USERPROFILE\Desktop\AssetManagement"
dotnet build 2>&1 | Select-Object -Last 4
if ($LASTEXITCODE -eq 0) { Write-Host "Build OK!" -ForegroundColor Green }