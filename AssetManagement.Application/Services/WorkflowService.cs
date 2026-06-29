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

        // ── Advance ──────────────────────────────────────────────
        public async Task<(bool Success, string Message)> AdvanceStageAsync(
            int assetId, string userId, string? notes = null)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");

            if (StageDefinition.IsLastStage(asset.CurrentStage))
                return (false, "\u0627\u0643\u062a\u0645\u0644 \u0633\u064a\u0631 \u0627\u0644\u0639\u0645\u0644 \u0628\u0627\u0644\u0641\u0639\u0644");

            int from = asset.CurrentStage;

            if (from == 2)
            {
                var pending = asset.OptionalStageStatuses
                    .Where(o => o.IsRequired && !o.IsCompleted).ToList();
                if (pending.Any())
                    return (false, "\u0644\u0645 \u064a\u062a\u0645 \u0627\u0633\u062a\u0643\u0645\u0627\u0644 \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629 \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629 \u0628\u0639\u062f");
            }
            if (from == 3)
            {
                if (!asset.AssetValuations.Any())
                    return (false, "\u064a\u062c\u0628 \u0625\u062f\u062e\u0627\u0644 \u062a\u0642\u064a\u064a\u0645 \u0648\u0627\u062d\u062f \u0639\u0644\u0649 \u0627\u0644\u0627\u0642\u0644 \u0642\u0628\u0644 \u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629");
            }

            int to = from + 1;
            asset.CurrentStage = to;
            asset.UpdatedAt    = DateTime.Now;

            UpdateAssetStage(asset, to, userId);

            if (StageDefinition.IsLastStage(to))
                SetFinalStatus(asset);

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

            return (true, "\u062a\u0645 \u0627\u0644\u0627\u0646\u062a\u0642\u0627\u0644 \u0625\u0644\u0649: " + StageDefinition.GetName(to));
        }

        // ── Reject ───────────────────────────────────────────────
        // عند رفض الطلب في مرحلة 5 (الاعتماد النهائي) يرجع الأصل فوراً لمرحلة 4
        // ليسمح بعمل طلب جديد (بيع/إيجار) بدلاً من التوقف النهائي
        public async Task<(bool Success, string Message)> RejectStageAsync(
            int assetId, string userId, string reason)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");

            int from = asset.CurrentStage;
            asset.UpdatedAt = DateTime.Now;

            int toStage;
            string action;

            if (from == 5)
            {
                // رفض الاعتماد — الرجوع لمرحلة 4 لعمل طلب جديد
                toStage      = 4;
                action       = "Rejected";
                asset.Status = AssetStatus.Pending;
                UpdateAssetStage(asset, 4, userId);
            }
            else
            {
                // السلوك القديم: رفض نهائي بدون رجوع
                toStage      = from;
                action       = "Rejected";
                asset.Status = AssetStatus.Rejected;
                if (asset.AssetStage != null)
                {
                    asset.AssetStage.Status          = StageStatus.Rejected;
                    asset.AssetStage.RejectionReason = reason;
                    asset.AssetStage.CompletedAt     = DateTime.Now;
                }
            }

            await _repo.UpdateAsync(asset);
            await _historyRepo.AddAsync(new StageHistory
            {
                AssetId       = assetId,
                FromStage     = from,
                ToStage       = toStage,
                Action        = action,
                Notes         = reason,
                PerformedById = userId,
                PerformedAt   = DateTime.Now
            });
            await _repo.SaveChangesAsync();

            string msg = from == 5
                ? "\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0637\u0644\u0628 \u0648\u0639\u0627\u062f \u0627\u0644\u0623\u0635\u0644 \u0644\u0645\u0631\u062d\u0644\u0629 4 \u0644\u0639\u0645\u0644 \u0637\u0644\u0628 \u062c\u062f\u064a\u062f"
                : "\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0623\u0635\u0644 \u0628\u0646\u062c\u0627\u062d";
            return (true, msg);
        }

        // ── Complete Optional Stage ────────────────────────────────
        public async Task<(bool Success, string Message)> CompleteOptionalStageAsync(
            int assetId, string userId, string stageKey)
        {
            var asset = await _repo.GetByIdAsync(assetId);
            if (asset == null) return (false, "Asset not found");

            var opt = asset.OptionalStageStatuses.FirstOrDefault(o => o.StageKey == stageKey);
            if (opt == null) return (false, "Optional stage not found");

            opt.IsCompleted   = true;
            opt.CompletedAt   = DateTime.Now;
            opt.CompletedById = userId;

            await _repo.UpdateAsync(asset);
            await _repo.SaveChangesAsync();

            return (true, "\u062a\u0645 \u0625\u0643\u0645\u0627\u0644 \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629: " + stageKey);
        }

        // ── Get Assets By Role ──────────────────────────────────────
        public async Task<List<Asset>> GetAssetsByRoleAsync(string userId, IList<string> roles)
        {
            var all = await _repo.GetAllAsync();
            if (roles.Contains("SuperAdmin"))
                return all.OrderByDescending(a => a.CreatedAt).ToList();

            return all.Where(a =>
            {
                if (a.Status == AssetStatus.Rejected) return false;
                if (!StageDefinition.StageRoles.TryGetValue(a.CurrentStage, out var sr)) return false;
                return sr.Any(r => roles.Contains(r));
            }).OrderByDescending(a => a.CreatedAt).ToList();
        }

        public async Task<Asset?> GetAssetDetailAsync(int id) =>
            await _repo.GetByIdAsync(id);

        // ── Private Helpers ──────────────────────────────────────────
        private static void UpdateAssetStage(Asset asset, int toStage, string userId)
        {
            if (asset.AssetStage == null) return;
            asset.AssetStage.StageNumber      = toStage;
            asset.AssetStage.StageName        = StageDefinition.GetName(toStage);
            asset.AssetStage.Status           = StageDefinition.IsLastStage(toStage)
                                                 ? StageStatus.Completed
                                                 : StageStatus.InProgress;
            asset.AssetStage.StartedAt        = DateTime.Now;
            asset.AssetStage.CompletedAt      = StageDefinition.IsLastStage(toStage)
                                                 ? DateTime.Now
                                                 : null;
            asset.AssetStage.AssignedToId     = userId;
            asset.AssetStage.RejectionReason  = null;
        }

        private static void SetFinalStatus(Asset asset)
        {
            var lastContract = asset.Contracts
                .OrderByDescending(c => c.CreatedAt)
                .FirstOrDefault();

            asset.Status = lastContract?.ContractType switch
            {
                ContractType.Sale => AssetStatus.Sold,
                ContractType.Rent => AssetStatus.Rented,
                _                 => AssetStatus.Active
            };
        }
    }
}
