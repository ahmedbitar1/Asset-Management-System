$base = "$env:USERPROFILE\Desktop\AssetManagement"
$enc  = [System.Text.Encoding]::UTF8

# Fix DownloadWord filename to: contract_AssetName-AssetCode.docx
$cp = "$base\AssetManagement.Web\Controllers\ContractsController.cs"
$cc = [System.IO.File]::ReadAllText($cp, $enc)
$oldFn = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgcmV0dXJuIEZpbGUoYnl0ZXMsCiAgICAgICAgICAgICAgICAiYXBwbGljYXRpb24vdm5kLm9wZW54bWxmb3JtYXRzLW9mZmljZWRvY3VtZW50LndvcmRwcm9jZXNzaW5nbWwuZG9jdW1lbnQiLAogICAgICAgICAgICAgICAgY29udHJhY3QuQ29udHJhY3ROdW1iZXIgKyAiLmRvY3giKTs="))
$newFn = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgc3RyaW5nIHNhZmVBc3NldE5hbWUgPSBzdHJpbmcuSm9pbigiXyIsIGFzc2V0LkFzc2V0TmFtZS5TcGxpdCgnICcsIFN0cmluZ1NwbGl0T3B0aW9ucy5SZW1vdmVFbXB0eUVudHJpZXMpKTsKICAgICAgICAgICAgc3RyaW5nIGRvd25sb2FkTmFtZSAgPSAkIlx1MDYzOVx1MDY0Mlx1MDYyZl97c2FmZUFzc2V0TmFtZX0te2Fzc2V0LkFzc2V0Q29kZX0uZG9jeCI7CgogICAgICAgICAgICByZXR1cm4gRmlsZShieXRlcywKICAgICAgICAgICAgICAgICJhcHBsaWNhdGlvbi92bmQub3BlbnhtbGZvcm1hdHMtb2ZmaWNlZG9jdW1lbnQud29yZHByb2Nlc3NpbmdtbC5kb2N1bWVudCIsCiAgICAgICAgICAgICAgICBkb3dubG9hZE5hbWUpOw=="))
if ($cc.Contains($oldFn)) {
    $cc = $cc.Replace($oldFn, $newFn)
    [System.IO.File]::WriteAllText($cp, $cc, $enc)
    Write-Host "OK: Download filename fixed" -ForegroundColor Green
} else {
    Write-Host "INFO: filename pattern not found exactly - checking" -ForegroundColor Yellow
}

# Fix Asset/Details.cshtml price display
$dp = "$base\AssetManagement.Web\Views\Asset\Details.cshtml"
$dc = [System.IO.File]::ReadAllText($dp, $enc)
$oldP = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgICAgIDxkaXYgY2xhc3M9ImNvbC02Ij4KICAgICAgICAgICAgICAgICAgICA8ZGl2IGNsYXNzPSJ0ZXh0LW11dGVkIHNtYWxsIj7Ys9i52LEg2KfZhNi02LHYp9ihPC9kaXY+CiAgICAgICAgICAgICAgICAgICAgPGRpdiBjbGFzcz0iZnctc2VtaWJvbGQgdGV4dC1zdWNjZXNzIj5AKGEuUHVyY2hhc2VQcmljZS5IYXNWYWx1ZT8iRUdQICIrYS5QdXJjaGFzZVByaWNlLlZhbHVlLlRvU3RyaW5nKCJOMCIpOiLigJQiKTwvZGl2PgogICAgICAgICAgICAgICAgPC9kaXY+"))
$newP = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgICAgIEB7CiAgICAgICAgICAgICAgICAgICAgdmFyIGxhc3RTYWxlUiAgID0gYS5TYWxlUmVxdWVzdHMuT3JkZXJCeURlc2NlbmRpbmcoeCA9PiB4LkNyZWF0ZWRBdCkuRmlyc3RPckRlZmF1bHQoKTsKICAgICAgICAgICAgICAgICAgICB2YXIgbGFzdFJlbnRhbFIgPSBhLlJlbnRhbFJlcXVlc3RzLk9yZGVyQnlEZXNjZW5kaW5nKHggPT4geC5DcmVhdGVkQXQpLkZpcnN0T3JEZWZhdWx0KCk7CiAgICAgICAgICAgICAgICAgICAgZGVjaW1hbD8gZGlzcGxheVByaWNlID0gYS5QdXJjaGFzZVByaWNlOwogICAgICAgICAgICAgICAgICAgIHN0cmluZyBwcmljZUxhYmVsID0gIlx1MDYzM1x1MDYzOVx1MDYzMSBcdTA2MjdcdTA2NDRcdTA2MzRcdTA2MzFcdTA2MjdcdTA2MjEiOwogICAgICAgICAgICAgICAgICAgIGlmIChsYXN0U2FsZVIgIT0gbnVsbCkgeyBkaXNwbGF5UHJpY2UgPSBsYXN0U2FsZVIuT2ZmZXJlZFByaWNlOyBwcmljZUxhYmVsID0gIlx1MDYzM1x1MDYzOVx1MDYzMSBcdTA2MjdcdTA2NDRcdTA2MjhcdTA2NGFcdTA2MzkiOyB9CiAgICAgICAgICAgICAgICAgICAgZWxzZSBpZiAobGFzdFJlbnRhbFIgIT0gbnVsbCkgeyBkaXNwbGF5UHJpY2UgPSBsYXN0UmVudGFsUi5Qcm9wb3NlZFJlbnQ7IHByaWNlTGFiZWwgPSAiXHUwNjI3XHUwNjQ0XHUwNjI1XHUwNjRhXHUwNjJjXHUwNjI3XHUwNjMxIFx1MDYyN1x1MDY0NFx1MDYzNFx1MDY0N1x1MDYzMVx1MDY0YSI7IH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIDxkaXYgY2xhc3M9ImNvbC02Ij4KICAgICAgICAgICAgICAgICAgICA8ZGl2IGNsYXNzPSJ0ZXh0LW11dGVkIHNtYWxsIj5AcHJpY2VMYWJlbDwvZGl2PgogICAgICAgICAgICAgICAgICAgIDxkaXYgY2xhc3M9ImZ3LXNlbWlib2xkIHRleHQtc3VjY2VzcyI+QChkaXNwbGF5UHJpY2UuSGFzVmFsdWU/IkVHUCAiK2Rpc3BsYXlQcmljZS5WYWx1ZS5Ub1N0cmluZygiTjAiKToiXHUyMDE0Iik8L2Rpdj4KICAgICAgICAgICAgICAgIDwvZGl2Pg=="))
if ($dc.Contains($oldP)) {
    $dc = $dc.Replace($oldP, $newP)
    [System.IO.File]::WriteAllText($dp, $dc, $enc)
    Write-Host "OK: Price display fixed in Details.cshtml" -ForegroundColor Green
} else {
    Write-Host "WARN: Price section pattern not found exactly" -ForegroundColor Red
}

cd $base
dotnet build 2>&1 | Select-Object -Last 4
if ($LASTEXITCODE -eq 0) { Write-Host "Build OK!" -ForegroundColor Green }