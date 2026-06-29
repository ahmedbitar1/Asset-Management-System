# ================================================================
#  fix-all-issues.ps1  -  شغّل من مجلد AssetManagement.Web
# ================================================================

$root = Split-Path -Parent (Get-Location)
$enc  = [System.Text.Encoding]::UTF8

# ================================================================
# FIX 1 + FIX 5: WorkflowService.cs
#   Fix 1: منع التجاوز بعد stage 11
#   Fix 5: تصليح Arabic encoding في رسائل الـ return
# ================================================================
$wfPath = "$root\AssetManagement.Application\Services\WorkflowService.cs"
$wf = [System.IO.File]::ReadAllText($wfPath, $enc)

if ($wf -match "Workflow already completed") {
    Write-Host "[SKIP] WorkflowService - Fix 1+5 already applied" -ForegroundColor Yellow
} else {
    # --- Fix 1: replace the broken if(to>10) block with proper guard at top ---
    $wf = $wf -replace '(?s)(            int to = GetNextStage\(asset\);.*?)(            await _repo\.UpdateAsync\(asset\);)', {
        param($m)
        @'
            // FIX 1: guard before any mutation
            if (asset.CurrentStage >= 11)
                return (false, "Workflow already completed. No further actions allowed.");

            int to = GetNextStage(asset);
            asset.CurrentStage = to;
            asset.UpdatedAt    = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = to;
                asset.AssetStage.StageName    = StageDefinition.GetName(to);
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.CompletedAt  = null;
                asset.AssetStage.AssignedToId = userId;
                asset.AssetStage.Status = (to >= 11) ? StageStatus.Completed : StageStatus.InProgress;
            }

            await _repo.UpdateAsync(asset);
'@
    }

    # --- Fix 5: replace garbled Arabic return messages with clean English ---
    # "الأصل غير موجود" (Asset not found)
    $wf = $wf -replace 'return \(false, "\xd8\xa7\xd9\x84\xd8\xa3\xd8\xb5\xd9\x84 \xd8\xba\xd9\x8a\xd8\xb1 \xd9\x85\xd9\x88\xd8\xac\xd9\x88\xd8\xaf"\)', 'return (false, "Asset not found")'
    # fallback: any garbled string matching multi-byte pattern for "not found"
    $wf = $wf -replace 'return \(false, "([^\x00-\x7F]{2,}[^"]*)"\)', 'return (false, "Asset not found")'
    # "تم الانتقال إلى ..."
    $wf = $wf -replace 'return \(true, \$"([^\x00-\x7F]{2,}[^"]*)\{StageDefinition\.GetName\(to\)\}"\)', 'return (true, $"Advanced to: {StageDefinition.GetName(to)}")'
    # "تم رفض الأصل"
    $wf = $wf -replace 'return \(true, "([^\x00-\x7F]{2,}[^"]*)"\)', 'return (true, "Action completed successfully")'
    # "تم إكمال مرحلة ..."
    $wf = $wf -replace 'return \(true, \$"([^\x00-\x7F]{2,}[^"]*)\{name\}"\)', 'return (true, $"Stage completed: {name}")'

    [System.IO.File]::WriteAllText($wfPath, $wf, $enc)
    Write-Host "[OK]   WorkflowService - Fix 1+5 applied" -ForegroundColor Green
}

# ================================================================
# FIX 2: AssetController.cs - CanAdvance stops at stage 11
# ================================================================
$acPath = "$root\AssetManagement.Web\Controllers\AssetController.cs"
$ac = [System.IO.File]::ReadAllText($acPath, $enc)

if ($ac -match "CurrentStage < 11") {
    Write-Host "[SKIP] AssetController - Fix 2 already applied" -ForegroundColor Yellow
} else {
    $ac = $ac.Replace(
        'CanAdvance = canAct && asset.Status != AssetManagement.Domain.Enums.AssetStatus.Rejected,',
        'CanAdvance = canAct && asset.Status != AssetManagement.Domain.Enums.AssetStatus.Rejected && asset.CurrentStage < 11,'
    )
    [System.IO.File]::WriteAllText($acPath, $ac, $enc)
    Write-Host "[OK]   AssetController - Fix 2 applied" -ForegroundColor Green
}

# ================================================================
# FIX 3: Details.cshtml
#   3a: شيل شرط الأدوار من جدول الـ Contracts
#   3b: شيل شرط الأدوار من كارت العقد الكبير
#   3c: صلّح رابط Download
# ================================================================
$detPath = "$root\AssetManagement.Web\Views\Asset\Details.cshtml"
$det = [System.IO.File]::ReadAllText($detPath, $enc)
$changed = $false

if ($det -match [regex]::Escape('isLegal || isMarketing || isAdminAffairs || isSuperAdmin')) {
    # replace ALL occurrences of the role guard on contracts
    $det = $det -replace [regex]::Escape('@if (a.Contracts.Any() && (isLegal || isMarketing || isAdminAffairs || isSuperAdmin))'), '@if (a.Contracts.Any())'
    $changed = $true
    Write-Host "[OK]   Details.cshtml - Fix 3a+3b: role guard removed" -ForegroundColor Green
} else {
    Write-Host "[SKIP] Details.cshtml - Fix 3a+3b already applied" -ForegroundColor Yellow
}

if ($det -match [regex]::Escape('asp-action="Download"')) {
    $det = $det.Replace(
        'asp-controller="Contracts" asp-action="Download" asp-route-assetId="@a.Id"',
        'asp-controller="Contracts" asp-action="DownloadWord" asp-route-contractId="@a.Contracts.OrderByDescending(c=>c.CreatedAt).First().Id"'
    )
    $changed = $true
    Write-Host "[OK]   Details.cshtml - Fix 3c: DownloadWord route fixed" -ForegroundColor Green
} else {
    Write-Host "[SKIP] Details.cshtml - Fix 3c already applied" -ForegroundColor Yellow
}

if ($changed) {
    [System.IO.File]::WriteAllText($detPath, $det, $enc)
}

# ================================================================
# FIX 4: TreasuryController.cs - Amount shows 0
#   المشكلة: contract?.Amount ?? 0 بيرجع 0 لو مفيش contract محمّل
#   الحل: fallback على CurrentValue ثم PurchasePrice
# ================================================================
$tPath = "$root\AssetManagement.Web\Controllers\TreasuryController.cs"
$tc = [System.IO.File]::ReadAllText($tPath, $enc)

if ($tc -match "FIX 4") {
    Write-Host "[SKIP] TreasuryController - Fix 4 already applied" -ForegroundColor Yellow
} else {
    $tc = $tc -replace 'Amount\s*=\s*contract\?\.Amount \?\? 0,', 'Amount = contract != null && contract.Amount > 0 ? contract.Amount : (asset.CurrentValue ?? asset.PurchasePrice ?? 0), // FIX 4'
    [System.IO.File]::WriteAllText($tPath, $tc, $enc)
    Write-Host "[OK]   TreasuryController - Fix 4: Amount fallback applied" -ForegroundColor Green
}

# ================================================================
Write-Host ""
Write-Host "All done. Run: dotnet build" -ForegroundColor Cyan
