$base = "$env:USERPROFILE\Desktop\AssetManagement"
$enc  = [System.Text.Encoding]::UTF8

# Fix Word template placeholders
function Fix-DocxPlaceholders($docxPath, [hashtable]$replacements) {
    $tmpDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
    [System.IO.Directory]::CreateDirectory($tmpDir) | Out-Null
    # Extract docx (it is a ZIP)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($docxPath, $tmpDir)
    # Fix word/document.xml
    $xmlPath = Join-Path $tmpDir "word\document.xml"
    if (Test-Path $xmlPath) {
        $xml = [System.IO.File]::ReadAllText($xmlPath, [System.Text.Encoding]::UTF8)
        foreach ($key in $replacements.Keys) {
            $xml = $xml.Replace($key, $replacements[$key])
        }
        [System.IO.File]::WriteAllText($xmlPath, $xml, [System.Text.Encoding]::UTF8)
    }
    # Repack as docx
    $bakPath = $docxPath + ".bak"
    if (Test-Path $bakPath) { Remove-Item $bakPath -Force }
    Copy-Item $docxPath $bakPath
    Remove-Item $docxPath -Force
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tmpDir, $docxPath)
    Remove-Item $tmpDir -Recurse -Force
}

# rent.docx
$rentPath = "$base\AssetManagement.Web\wwwroot\templates\rent.docx"
if (Test-Path $rentPath) {
    $o1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("MDAwMDA="))
    $n1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("e3tBTk5VQUxfSU5DUkVBU0V9fQ=="))
    $o2 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("MDAwMDAwMDAwMDAw"))
    $n2 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("e3tHUkFDRV9QRVJJT0R9fQ=="))
    $o3 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("MDAwMDAwMDA="))
    $n3 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("e3tTVEFSVF9EQVRFfX0="))
    Fix-DocxPlaceholders $rentPath @{$o1=$n1; $o2=$n2; $o3=$n3}
    Write-Host "OK: rent.docx fixed" -ForegroundColor Green
} else { Write-Host "WARN: rent.docx not found" -ForegroundColor Yellow }

$commPath = "$base\AssetManagement.Web\wwwroot\templates\rent_commercial.docx"
if (Test-Path $commPath) {
    $o1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("MDAwMDA="))
    $n1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("e3tBTk5VQUxfSU5DUkVBU0V9fQ=="))
    $o3 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("MDAwMDAwMDA="))
    $n3 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("e3tTVEFSVF9EQVRFfX0="))
    Fix-DocxPlaceholders $commPath @{$o1=$n1; $o3=$n3}
    Write-Host "OK: rent_commercial.docx fixed" -ForegroundColor Green
} else { Write-Host "WARN: rent_commercial.docx not found" -ForegroundColor Yellow }

# Fix ContractsController
$cp = "$base\AssetManagement.Web\Controllers\ContractsController.cs"
$cc = [System.IO.File]::ReadAllText($cp, $enc)
$oldCtrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("CiAgICAgICAgcHVibGljIGFzeW5jIFRhc2s8SUFjdGlvblJlc3VsdD4gRG93bmxvYWRXb3JkKGludCBjb250cmFjdElkKQogICAgICAgIHsKICAgICAgICAgICAgdmFyIGFsbCAgID0gYXdhaXQgX3JlcG8uR2V0QWxsQXN5bmMoKTsKICAgICAgICAgICAgdmFyIGFzc2V0ID0gYWxsLkZpcnN0T3JEZWZhdWx0KGEgPT4gYS5Db250cmFjdHMuQW55KGMgPT4gYy5JZCA9PSBjb250cmFjdElkKSk7CiAgICAgICAgICAgIGlmIChhc3NldCA9PSBudWxsKSByZXR1cm4gTm90Rm91bmQoKTsKICAgICAgICAgICAgdmFyIGNvbnRyYWN0ID0gYXNzZXQuQ29udHJhY3RzLkZpcnN0KGMgPT4gYy5JZCA9PSBjb250cmFjdElkKTs="))
$newCtrl = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("CiAgICAgICAgcHVibGljIGFzeW5jIFRhc2s8SUFjdGlvblJlc3VsdD4gRG93bmxvYWRXb3JkKGludCBjb250cmFjdElkKQogICAgICAgIHsKICAgICAgICAgICAgdmFyIGFsbCAgICA9IGF3YWl0IF9yZXBvLkdldEFsbEFzeW5jKCk7CiAgICAgICAgICAgIHZhciB0bXAgICAgPSBhbGwuRmlyc3RPckRlZmF1bHQoYSA9PiBhLkNvbnRyYWN0cy5BbnkoYyA9PiBjLklkID09IGNvbnRyYWN0SWQpKTsKICAgICAgICAgICAgaWYgKHRtcCA9PSBudWxsKSByZXR1cm4gTm90Rm91bmQoKTsKICAgICAgICAgICAgLy8gR2V0QnlJZEFzeW5jIGxvYWRzIFJlbnRhbFJlcXVlc3RzIHdpdGggZnVsbCBkYXRhCiAgICAgICAgICAgIHZhciBhc3NldCAgPSBhd2FpdCBfcmVwby5HZXRCeUlkQXN5bmModG1wLklkKSA/PyB0bXA7CiAgICAgICAgICAgIHZhciBjb250cmFjdCA9IGFzc2V0LkNvbnRyYWN0cy5GaXJzdChjID0+IGMuSWQgPT0gY29udHJhY3RJZCk7"))
if ($cc.Contains($oldCtrl)) {
    $cc = $cc.Replace($oldCtrl, $newCtrl)
    [System.IO.File]::WriteAllText($cp, $cc, $enc)
    Write-Host "OK: DownloadWord fixed - loads RentalRequests" -ForegroundColor Green
} else {
    Write-Host "INFO: DownloadWord already updated" -ForegroundColor Yellow
}

# Fix SecurityDeposit to not fallback to Amount
$cc = [System.IO.File]::ReadAllText($cp, $enc)
$oldSec = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgc3RyaW5nIHNlY3VyaXR5RGVwb3NpdCA9IGxhc3RSZW50YWw/LlNlY3VyaXR5RGVwb3NpdC5IYXNWYWx1ZSA9PSB0cnVlCiAgICAgICAgICAgICAgICA/IGxhc3RSZW50YWwuU2VjdXJpdHlEZXBvc2l0LlZhbHVlLlRvU3RyaW5nKCJOMCIpCiAgICAgICAgICAgICAgICA6IChjb250cmFjdC5Db250cmFjdFR5cGUgPT0gQ29udHJhY3RUeXBlLlNhbGUKICAgICAgICAgICAgICAgICAgICA/ICgobG9uZykoY29udHJhY3QuQW1vdW50ICogMC4wNW0pKS5Ub1N0cmluZygiTjAiKQogICAgICAgICAgICAgICAgICAgIDogY29udHJhY3QuQW1vdW50LlRvU3RyaW5nKCJOMCIpKTs="))
$newSec = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("ICAgICAgICAgICAgLy8gU2VjdXJpdHlEZXBvc2l0IE1VU1QgY29tZSBmcm9tIHJlbnRhbCByZXF1ZXN0LCBOT1QgZnJvbSBjb250cmFjdCBhbW91bnQKICAgICAgICAgICAgc3RyaW5nIHNlY3VyaXR5RGVwb3NpdCA9ICIiOwogICAgICAgICAgICBpZiAobGFzdFJlbnRhbD8uU2VjdXJpdHlEZXBvc2l0Lkhhc1ZhbHVlID09IHRydWUpCiAgICAgICAgICAgICAgICBzZWN1cml0eURlcG9zaXQgPSBsYXN0UmVudGFsLlNlY3VyaXR5RGVwb3NpdC5WYWx1ZS5Ub1N0cmluZygiTjAiKTsKICAgICAgICAgICAgZWxzZSBpZiAoY29udHJhY3QuQ29udHJhY3RUeXBlID09IENvbnRyYWN0VHlwZS5TYWxlKQogICAgICAgICAgICAgICAgc2VjdXJpdHlEZXBvc2l0ID0gIiI7CiAgICAgICAgICAgIC8vIEZvciByZW50IHdpdGggbm8gU2VjdXJpdHlEZXBvc2l0IGVudGVyZWQsIGxlYXZlIGJsYW5r"))
if ($cc.Contains($oldSec)) {
    $cc = $cc.Replace($oldSec, $newSec)
    [System.IO.File]::WriteAllText($cp, $cc, $enc)
    Write-Host "OK: SecurityDeposit fix applied" -ForegroundColor Green
} else {
    Write-Host "INFO: SecurityDeposit already fixed" -ForegroundColor Yellow
}

cd $base
dotnet build 2>&1 | Select-Object -Last 4
if ($LASTEXITCODE -eq 0) { Write-Host "All done! Test DownloadWord now." -ForegroundColor Green }