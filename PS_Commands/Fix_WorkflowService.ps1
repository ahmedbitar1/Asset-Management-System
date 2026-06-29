# Fix_WorkflowService.ps1
# شغّله من أي مكان:
# powershell -ExecutionPolicy Bypass -File C:\Users\ahmed.essamm\Desktop\Fix_WorkflowService.ps1

$base  = "$env:USERPROFILE\Desktop\AssetManagement"
$app   = "$base\AssetManagement.Application"
$utf8  = New-Object System.Text.UTF8Encoding($false)

$content = @'
using AssetManagement.Application.Interfaces;
using AssetManagement.Domain.Entities;
using AssetManagement.Domain.Enums;
using AssetManagement.Domain.Interfaces;

namespace AssetManagement.Application.Services
{
    public class WorkflowService : IWorkflowService
    {
        private readonly IAssetRepository _repo;
        private readonly IStageHistoryRepository _historyRepo;

        public WorkflowService(IAssetRepository repo, IStageHistoryRepository historyRepo)
        {
            _repo        = repo;
            _historyRepo = historyRepo;
        }

        public async Task<(bool Success, string Message)> AdvanceStageAsync(
            int assetId, string userId, string? notes = null)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "الأصل غير موجود");

            int from = asset.CurrentStage;

            if (from == 2)
            {
                var required = asset.OptionalStageStatuses
                    .Where(o => o.IsRequired && !o.IsCompleted).ToList();
                if (required.Any())
                    return (false, "يوجد مراحل اختيارية إلزامية لم تكتمل بعد");
            }

            int to = GetNextStage(asset);
            asset.CurrentStage = to;
            asset.UpdatedAt    = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.StageNumber  = to;
                asset.AssetStage.StageName    = StageDefinition.GetName(to);
                asset.AssetStage.Status       = StageStatus.InProgress;
                asset.AssetStage.StartedAt    = DateTime.Now;
                asset.AssetStage.CompletedAt  = null;
                asset.AssetStage.AssignedToId = userId;
            }

            if (to > 11)
            {
                asset.Status = AssetStatus.Active;
                if (asset.AssetStage != null)
                {
                    asset.AssetStage.Status      = StageStatus.Completed;
                    asset.AssetStage.CompletedAt = DateTime.Now;
                }
            }

            await _repo.UpdateAsync(asset);
            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = to,
                Action        = "Approved",
                Notes         = notes,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });

            await _repo.SaveChangesAsync();
            return (true, $"تم الانتقال إلى {StageDefinition.GetName(to)}");
        }

        public async Task<(bool Success, string Message)> RejectStageAsync(
            int assetId, string userId, string reason)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "الأصل غير موجود");

            int from = asset.CurrentStage;
            asset.Status    = AssetStatus.Rejected;
            asset.UpdatedAt = DateTime.Now;

            if (asset.AssetStage != null)
            {
                asset.AssetStage.Status          = StageStatus.Rejected;
                asset.AssetStage.CompletedAt     = DateTime.Now;
                asset.AssetStage.RejectionReason = reason;
            }

            await _repo.UpdateAsync(asset);
            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = from,
                Action        = "Rejected",
                Notes         = reason,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });

            await _repo.SaveChangesAsync();
            return (true, "تم رفض الأصل");
        }

        public async Task<(bool Success, string Message)> CompleteOptionalStageAsync(
            int assetId, string stageKey, string userId)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "الأصل غير موجود");

            var opt = asset.OptionalStageStatuses
                .FirstOrDefault(o => o.StageKey == stageKey);

            if (opt == null)
            {
                asset.OptionalStageStatuses.Add(new OptionalStageStatus
                {
                    AssetId       = assetId,
                    StageKey      = stageKey,
                    IsRequired    = false,
                    IsCompleted   = true,
                    CompletedAt   = DateTime.Now,
                    CompletedById = userId
                });
            }
            else
            {
                opt.IsCompleted   = true;
                opt.CompletedAt   = DateTime.Now;
                opt.CompletedById = userId;
            }

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();

            string name = stageKey switch
            {
                "2a" => "التسويق",
                "2b" => "الهندسة",
                "2c" => "الشؤون الإدارية",
                _    => stageKey
            };

            return (true, $"تم إكمال مرحلة {name}");
        }

        public async Task<List<Asset>> GetAssetsByRoleAsync(string userId, IList<string> roles)
        {
            return await _repo.GetByRolesAsync(roles);
        }

        public async Task<Asset?> GetAssetDetailAsync(int assetId)
        {
            return await _repo.GetByIdAsync(assetId);
        }

        private static int GetNextStage(Asset asset)
        {
            if (asset.CurrentStage == 1) return 2;
            if (asset.CurrentStage == 2) return 3;
            return asset.CurrentStage + 1;
        }
    }
}
'@

[System.IO.File]::WriteAllText("$app\Services\WorkflowService.cs", $content, $utf8)
Write-Host "WorkflowService.cs fixed!" -ForegroundColor Green

# تحقق إن مفيش userRoles تاني
$check = [System.IO.File]::ReadAllText("$app\Services\WorkflowService.cs", $utf8)
$bad   = ($check -split "`n") | Select-String "userRoles"
if ($bad) {
    Write-Host "ERROR: Still has userRoles!" -ForegroundColor Red
} else {
    Write-Host "Clean - no userRoles found." -ForegroundColor Green
}

Write-Host "`nNow run:" -ForegroundColor Yellow
Write-Host "  cd $base" -ForegroundColor White
Write-Host "  dotnet build" -ForegroundColor White
