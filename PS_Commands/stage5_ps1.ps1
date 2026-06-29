$base = "$env:USERPROFILE\Desktop\AssetManagement"
$web  = "$base\AssetManagement.Web"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host "=== Stage 5: Views ===" -ForegroundColor Cyan

# ── مجلدات جديدة ──────────────────────────────────────────────────
New-Item -ItemType Directory -Force "$web\Views\Finance"         | Out-Null
New-Item -ItemType Directory -Force "$web\Views\MarketingUpload" | Out-Null
New-Item -ItemType Directory -Force "$web\Views\Requests"        | Out-Null

# ══ 1. Asset/Details.cshtml — Workflow الجديد ═════════════════════
[System.IO.File]::WriteAllText("$web\Views\Asset\Details.cshtml", @'
@model AssetManagement.Application.ViewModels.AssetDetailViewModel
@{
    ViewData["Title"] = "تفاصيل الأصل";
    var a = Model.Asset;
    var roles = (IList<string>)(ViewBag.Roles ?? new List<string>());
    bool isSuperAdmin   = roles.Contains("SuperAdmin");
    bool isMarketing    = roles.Contains("Marketing")    || isSuperAdmin;
    bool isEngineering  = roles.Contains("Engineering")  || isSuperAdmin;
    bool isAdminAffairs = roles.Contains("AdminAffairs") || isSuperAdmin;
    bool isValuator     = roles.Contains("Valuator")     || isSuperAdmin;
    bool isSales        = roles.Contains("Sales")        || isSuperAdmin;
    bool isLegal        = roles.Contains("Legal")        || isSuperAdmin;
    bool isFinance      = roles.Contains("Finance")      || isSuperAdmin;
    bool isTreasury     = roles.Contains("Treasury")     || isSuperAdmin;
    string stageName    = AssetManagement.Application.ViewModels.AssetCardViewModel.StageNames
        .GetValueOrDefault(a.CurrentStage, a.CurrentStage.ToString());
}

<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
    <div>
        <h5 class="fw-bold mb-1">@a.AssetName</h5>
        <code class="text-primary">@a.AssetCode</code>
        @if (!string.IsNullOrEmpty(a.PropertyType))
        {<span class="badge bg-secondary ms-2">@a.PropertyType</span>}
    </div>
    <div class="d-flex gap-2 align-items-center flex-wrap">
        <span class="badge bg-warning text-dark px-3 py-2">@stageName</span>
        <span class="badge px-3 py-2
            @(a.Status==AssetStatus.Rejected?"bg-danger":
              a.Status==AssetStatus.Active?"bg-success":
              a.Status==AssetStatus.Sold?"bg-primary":
              a.Status==AssetStatus.Rented?"bg-info":"bg-secondary")">
            @a.Status
        </span>
        @if (isMarketing)
        {
        <a asp-controller="Images" asp-action="Index" asp-route-assetId="@a.Id"
           class="btn btn-sm btn-outline-info">
            <i class="bi bi-images me-1"></i>الصور
        </a>
        }
        @if (isSuperAdmin)
        {
        <button type="button" class="btn btn-sm btn-danger"
                onclick="confirmDelete(@a.Id,'@a.AssetName.Replace("'","\\'")' )">
            <i class="bi bi-trash me-1"></i>حذف
        </button>
        <form id="deleteForm_@a.Id" asp-action="Delete" asp-route-id="@a.Id"
              method="post" class="d-none">@Html.AntiForgeryToken()</form>
        }
        <a asp-action="Index" class="btn btn-sm btn-outline-secondary">
            <i class="bi bi-arrow-right me-1"></i>رجوع
        </a>
    </div>
</div>

<!-- Delete Modal -->
<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
            <div class="modal-body text-center px-4 py-4">
                <i class="bi bi-trash3-fill text-danger fs-1 mb-3 d-block"></i>
                <h5 class="fw-bold mb-2">حذف الأصل؟</h5>
                <p class="text-muted">أنت على وشك حذف <strong id="deleteAssetName" class="text-danger"></strong></p>
            </div>
            <div class="modal-footer border-0 justify-content-center gap-3 pb-4">
                <button type="button" class="btn btn-light px-4 rounded-pill" data-bs-dismiss="modal">إلغاء</button>
                <button type="button" id="confirmDeleteBtn" class="btn btn-danger px-4 rounded-pill">نعم، احذف</button>
            </div>
        </div>
    </div>
</div>

<div class="row g-3">
<div class="col-md-7">

    <!-- بيانات العقار -->
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-light fw-bold">
            <i class="bi bi-info-circle me-2 text-primary"></i>بيانات العقار
        </div>
        <div class="card-body">
            <div class="row g-3">
                <div class="col-6"><div class="text-muted small">الاسم</div><div class="fw-semibold">@a.AssetName</div></div>
                <div class="col-6"><div class="text-muted small">الكود</div><code class="text-primary">@a.AssetCode</code></div>
                @if (!string.IsNullOrEmpty(a.PropertyType))
                {<div class="col-6"><div class="text-muted small">نوع العقار</div><div>@a.PropertyType</div></div>}
                @if (!string.IsNullOrEmpty(a.OwnerCompany))
                {<div class="col-6"><div class="text-muted small">الشركة المالكة</div><div>@a.OwnerCompany</div></div>}
                <div class="col-6"><div class="text-muted small">الموقع</div><div>@a.City @a.District @a.Location</div></div>
                @if (!string.IsNullOrEmpty(a.OccupancyStatus))
                {<div class="col-6"><div class="text-muted small">الموقف</div>
                    <span class="badge @(a.OccupancyStatus=="مستغل"?"bg-success":a.OccupancyStatus=="مؤجر"?"bg-info":"bg-secondary")">@a.OccupancyStatus</span></div>}
                <div class="col-6">
                    <div class="text-muted small">المساحة</div>
                    @if (a.LandArea.HasValue || a.BuildingArea.HasValue)
                    {
                        if (a.LandArea.HasValue)
                        {<div class="small">أرض: @a.LandArea.Value.ToString("N0") م²</div>}
                        if (a.BuildingArea.HasValue)
                        {<div class="small">مباني: @a.BuildingArea.Value.ToString("N0") م²</div>}
                    }
                    else if (a.Area.HasValue)
                    {<div>@a.Area.Value.ToString("N0") @a.AreaUnit</div>}
                    else
                    {<div>—</div>}
                </div>
                <div class="col-6">
                    <div class="text-muted small">نوع التصرف</div>
                    <span class="badge @(a.AssetType==AssetType.Sale?"bg-success":a.AssetType==AssetType.Rent?"bg-info":"bg-warning text-dark")">
                        @(a.AssetType==AssetType.Sale?"بيع":a.AssetType==AssetType.Rent?"إيجار":"بيع وإيجار")
                    </span>
                </div>
                <div class="col-6">
                    <div class="text-muted small">سعر الشراء</div>
                    <div class="fw-semibold text-success">@(a.PurchasePrice.HasValue?"EGP "+a.PurchasePrice.Value.ToString("N0"):"—")</div>
                </div>
                @if (!string.IsNullOrEmpty(a.DeedNumber) || !string.IsNullOrEmpty(a.DeedType))
                {
                <div class="col-12 col-md-6">
                    <div class="text-muted small">سند الملكية</div>
                    <div>@a.DeedType @(string.IsNullOrEmpty(a.DeedNumber)?"":" — "+a.DeedNumber)</div>
                </div>
                }
                @if (!string.IsNullOrEmpty(a.Notes))
                {<div class="col-12"><div class="text-muted small">ملاحظات</div>
                    <div class="p-2 bg-light rounded small">@a.Notes</div></div>}
                @if (!string.IsNullOrEmpty(a.PreviousOffers))
                {<div class="col-12"><div class="text-muted small">العروض السابقة</div>
                    <div class="p-2 bg-light rounded small text-muted">@a.PreviousOffers</div></div>}
            </div>
        </div>
    </div>

    <!-- التقييمات الثلاثة -->
    @if (Model.Valuations.Any())
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-warning bg-opacity-10 fw-bold">
            <i class="bi bi-bar-chart me-2 text-warning"></i>التقييمات
        </div>
        <div class="card-body p-2">
            <div class="row g-2">
                @foreach (var v in Model.Valuations)
                {
                <div class="col-md-4">
                    <div class="border rounded p-3 text-center">
                        <div class="text-muted small mb-1">@v.TypeLabel</div>
                        <div class="fw-bold fs-5 text-@v.TypeColor">@v.Value.ToString("N0")</div>
                        <div class="text-muted" style="font-size:11px;">EGP</div>
                        @if (!string.IsNullOrEmpty(v.Comments))
                        {<div class="text-muted" style="font-size:11px;" title="@v.Comments">@v.Comments</div>}
                    </div>
                </div>
                }
            </div>
        </div>
    </div>
    }

    <!-- طلبات الإيجار -->
    @if (a.RentalRequests.Any())
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-info bg-opacity-10 fw-bold d-flex justify-content-between">
            <span><i class="bi bi-house-door me-2"></i>طلبات الإيجار (@a.RentalRequests.Count)</span>
            @if (a.CurrentStage == 4 && (isSales || isMarketing))
            {
            <a asp-controller="Requests" asp-action="PrintRequest" asp-route-assetId="@a.Id"
               class="btn btn-sm btn-outline-secondary" target="_blank">
                <i class="bi bi-printer me-1"></i>طباعة
            </a>
            }
        </div>
        <div class="table-responsive">
            <table class="table table-sm mb-0">
                <thead class="table-light"><tr><th>المستأجر</th><th>الإيجار/شهر</th><th>المدة</th><th>التأمين</th><th>الزيادة</th><th>البداية</th></tr></thead>
                <tbody>
                    @foreach (var r in a.RentalRequests.OrderByDescending(x => x.CreatedAt))
                    {
                    <tr>
                        <td class="fw-semibold">@r.TenantName</td>
                        <td class="text-success">@r.ProposedRent.ToString("N0")</td>
                        <td>@(r.ContractDurationYears.HasValue?r.ContractDurationYears+"سنة":r.RentDurationMonths+"شهر")</td>
                        <td>@(r.SecurityDeposit.HasValue?r.SecurityDeposit.Value.ToString("N0"):"—")</td>
                        <td>@(r.AnnualIncrease.HasValue?r.AnnualIncrease.Value+"%":"—")</td>
                        <td class="text-muted small">@r.StartDate?.ToString("yyyy/MM/dd")</td>
                    </tr>
                    }
                </tbody>
            </table>
        </div>
    </div>
    }

    <!-- طلبات البيع -->
    @if (a.SaleRequests.Any())
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-success bg-opacity-10 fw-bold">
            <i class="bi bi-cash-coin me-2"></i>طلبات البيع (@a.SaleRequests.Count)
        </div>
        <div class="table-responsive">
            <table class="table table-sm mb-0">
                <thead class="table-light"><tr><th>المشتري</th><th>السعر</th><th>الدفع</th><th>التاريخ</th></tr></thead>
                <tbody>
                    @foreach (var r in a.SaleRequests.OrderByDescending(x => x.CreatedAt))
                    {
                    <tr>
                        <td class="fw-semibold">@r.BuyerName</td>
                        <td class="text-success">@r.OfferedPrice.ToString("N0")</td>
                        <td>@r.PaymentMethod</td>
                        <td class="text-muted small">@r.CreatedAt.ToString("yyyy/MM/dd")</td>
                    </tr>
                    }
                </tbody>
            </table>
        </div>
    </div>
    }

    <!-- العقود -->
    @if (a.Contracts.Any())
    {
    <div class="card border-0 shadow-sm">
        <div class="card-header bg-primary bg-opacity-10 fw-bold">
            <i class="bi bi-file-earmark-text me-2"></i>العقود (@a.Contracts.Count)
        </div>
        <div class="table-responsive">
            <table class="table table-sm mb-0">
                <thead class="table-light"><tr><th>الرقم</th><th>النوع</th><th>الطرف</th><th>المبلغ</th><th></th></tr></thead>
                <tbody>
                    @foreach (var c in a.Contracts.OrderByDescending(x => x.CreatedAt))
                    {
                    <tr>
                        <td><code class="small">@c.ContractNumber</code></td>
                        <td><span class="badge @(c.ContractType==ContractType.Rent?"bg-info":"bg-success")">@c.ContractType</span></td>
                        <td>@c.PartyName</td>
                        <td class="fw-semibold">@c.Amount.ToString("N0")</td>
                        <td>
                            <a asp-controller="Contracts" asp-action="DownloadWord" asp-route-contractId="@c.Id"
                               class="btn btn-sm btn-success"><i class="bi bi-file-word"></i></a>
                        </td>
                    </tr>
                    }
                </tbody>
            </table>
        </div>
    </div>
    }

</div>
<div class="col-md-5">

    <!-- الأقسام الاختيارية — دائماً متاحة -->
    @if (isMarketing || isEngineering || isAdminAffairs)
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-light fw-bold">
            <i class="bi bi-diagram-3 me-2 text-info"></i>الأقسام الاختيارية
            <span class="badge bg-info float-end small">متاح دائماً</span>
        </div>
        <div class="card-body p-2">
            @if (isMarketing)
            {
            <a asp-controller="OptionalStages" asp-action="Marketing" asp-route-assetId="@a.Id"
               class="btn btn-sm btn-outline-warning w-100 mb-2 text-start">
                <i class="bi bi-megaphone me-2"></i>التسويق
                @if (a.OptionalStageStatuses.Any(o=>o.StageKey=="2a"&&o.IsCompleted))
                {<span class="badge bg-success float-end">مكتمل</span>}
                else {<span class="badge bg-secondary float-end">معلق</span>}
            </a>
            }
            @if (isEngineering)
            {
            <a asp-controller="OptionalStages" asp-action="Engineering" asp-route-assetId="@a.Id"
               class="btn btn-sm btn-outline-primary w-100 mb-2 text-start">
                <i class="bi bi-rulers me-2"></i>الهندسة
                @if (a.OptionalStageStatuses.Any(o=>o.StageKey=="2b"&&o.IsCompleted))
                {<span class="badge bg-success float-end">مكتمل</span>}
                else {<span class="badge bg-secondary float-end">معلق</span>}
            </a>
            }
            @if (isAdminAffairs)
            {
            <a asp-controller="OptionalStages" asp-action="AdminAffairs" asp-route-assetId="@a.Id"
               class="btn btn-sm btn-outline-success w-100 mb-2 text-start">
                <i class="bi bi-lightning-charge me-2"></i>الشؤون الإدارية
                @if (a.OptionalStageStatuses.Any(o=>o.StageKey=="2c"&&o.IsCompleted))
                {<span class="badge bg-success float-end">مكتمل</span>}
                else {<span class="badge bg-secondary float-end">معلق</span>}
            </a>
            }
        </div>
    </div>
    }

    <!-- مرحلة 3: التقييم -->
    @if (Model.IsStage3 && isValuator)
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-warning bg-opacity-10 fw-bold">
            <i class="bi bi-bar-chart me-2 text-warning"></i>مرحلة التقييم
        </div>
        <div class="card-body">
            <p class="text-muted small mb-3">أدخل التقييمات الثلاثة وحدد نوع التصرف</p>
            <a asp-controller="Valuation" asp-action="Evaluate" asp-route-assetId="@a.Id"
               class="btn btn-warning w-100 fw-bold">
                <i class="bi bi-calculator me-2"></i>
                @(Model.Valuations.Any() ? "تعديل التقييمات" : "بدء التقييم")
            </a>
        </div>
    </div>
    }

    <!-- مرحلة 4: طلب البيع/الإيجار -->
    @if (Model.IsStage4 && (isSales || isMarketing))
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-success bg-opacity-10 fw-bold">
            <i class="bi bi-plus-circle me-2"></i>طلب البيع / الإيجار
        </div>
        <div class="card-body">
            <div class="d-flex gap-2 flex-wrap">
                @if (a.AssetType == AssetType.Rent || a.AssetType == AssetType.Both)
                {
                <a asp-controller="Requests" asp-action="CreateRental" asp-route-assetId="@a.Id"
                   class="btn btn-info text-white flex-grow-1">
                    <i class="bi bi-house-door me-1"></i>طلب إيجار
                </a>
                }
                @if (a.AssetType == AssetType.Sale || a.AssetType == AssetType.Both)
                {
                <a asp-controller="Requests" asp-action="CreateSale" asp-route-assetId="@a.Id"
                   class="btn btn-success flex-grow-1">
                    <i class="bi bi-cash-coin me-1"></i>طلب بيع
                </a>
                }
            </div>
        </div>
    </div>
    }

    <!-- مرحلة 6: إنشاء العقد -->
    @if (a.CurrentStage == 6 && isLegal && !a.Contracts.Any())
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-primary bg-opacity-10 fw-bold">
            <i class="bi bi-file-earmark-text me-2"></i>إنشاء العقد
        </div>
        <div class="card-body">
            <a asp-controller="Contracts" asp-action="Create" asp-route-assetId="@a.Id"
               class="btn btn-primary w-100 fw-bold">
                <i class="bi bi-file-earmark-plus me-2"></i>إنشاء العقد
            </a>
        </div>
    </div>
    }

    <!-- مرحلة 7: المالية تراجع العقد -->
    @if (a.CurrentStage == 7 && isFinance)
    {
    <div class="card border-0 shadow-sm mb-3" style="border:2px solid #0dcaf0 !important;">
        <div class="card-header fw-bold text-white bg-info">
            <i class="bi bi-eye-fill me-2"></i>مراجعة العقد — المالية
        </div>
        <div class="card-body">
            <p class="text-muted small mb-3">راجع بنود العقد ثم اعتمده أو ارفضه</p>
            <a asp-controller="Finance" asp-action="ReviewContract" asp-route-assetId="@a.Id"
               class="btn btn-info text-white w-100 fw-bold">
                <i class="bi bi-eye me-2"></i>مراجعة واعتماد العقد
            </a>
        </div>
    </div>
    }

    <!-- مرحلة 8: التسويق يرفع العقد الموقّع -->
    @if (a.CurrentStage == 8 && isMarketing)
    {
    <div class="card border-0 shadow-sm mb-3" style="border:2px solid #ffc107 !important;">
        <div class="card-header fw-bold text-dark bg-warning">
            <i class="bi bi-upload me-2"></i>رفع العقد الموقّع — التسويق
        </div>
        <div class="card-body">
            <p class="text-muted small mb-3">ارفع نسخة العقد بعد التوقيع (PDF أو Word)</p>
            <a asp-controller="MarketingUpload" asp-action="UploadSigned" asp-route-assetId="@a.Id"
               class="btn btn-warning w-100 fw-bold">
                <i class="bi bi-cloud-upload me-2"></i>رفع العقد الموقّع
            </a>
        </div>
    </div>
    }

    <!-- مرحلة 9: الخزنة -->
    @if (a.CurrentStage == 9 && isTreasury)
    {
    <div class="card border-0 shadow-sm mb-3" style="border:2px solid #1e3a5f !important;">
        <div class="card-header fw-bold text-white" style="background:#1e3a5f;">
            <i class="bi bi-bank me-2"></i>تحصيل الخزنة
        </div>
        <div class="card-body">
            <p class="text-muted small mb-3">الخطوة الأخيرة – تسجيل استلام الدفعة</p>
            <a asp-controller="Treasury" asp-action="Collect" asp-route-assetId="@a.Id"
               class="btn w-100 fw-bold text-white" style="background:#1e3a5f;">
                <i class="bi bi-check-circle me-2"></i>تسجيل التحصيل
            </a>
        </div>
    </div>
    }

    <!-- زرار العقد المتاح دائماً -->
    @if (a.Contracts.Any())
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-primary bg-opacity-10 fw-bold">
            <i class="bi bi-file-earmark-word me-2"></i>@a.Contracts.First().ContractNumber
        </div>
        <div class="card-body">
            <a asp-controller="Contracts" asp-action="DownloadWord"
               asp-route-contractId="@a.Contracts.OrderByDescending(c=>c.CreatedAt).First().Id"
               class="btn btn-success w-100 fw-bold">
                <i class="bi bi-download me-2"></i>تحميل العقد Word
            </a>
        </div>
    </div>
    }

    <!-- Workflow Action: Advance/Reject -->
    @if (Model.CanAdvance || Model.CanReject)
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-primary bg-opacity-10 fw-bold">
            <i class="bi bi-gear me-2"></i>إجراء سير العمل
        </div>
        <div class="card-body">
            @if (Model.CanAdvance)
            {
            <form asp-action="Advance" asp-controller="Asset" method="post" class="mb-3">
                @Html.AntiForgeryToken()
                <input type="hidden" name="id" value="@a.Id"/>
                <textarea name="notes" class="form-control form-control-sm mb-2" rows="2"
                          placeholder="ملاحظات (اختياري)"></textarea>
                <button type="submit" class="btn btn-success w-100 fw-semibold">
                    <i class="bi bi-arrow-right-circle me-2"></i>
                    التقدم إلى: @AssetManagement.Application.ViewModels.AssetCardViewModel.StageNames.GetValueOrDefault(a.CurrentStage + 1, "مكتمل")
                </button>
            </form>
            }
            @if (Model.CanReject)
            {
            <form asp-action="Reject" asp-controller="Asset" method="post">
                @Html.AntiForgeryToken()
                <input type="hidden" name="id" value="@a.Id"/>
                <textarea name="reason" class="form-control form-control-sm border-danger mb-2"
                          rows="2" placeholder="سبب الرفض..." required></textarea>
                <button type="submit" class="btn btn-danger w-100">
                    <i class="bi bi-x-circle me-2"></i>رفض
                </button>
            </form>
            }
        </div>
    </div>
    }

    <!-- مكتمل -->
    @if (StageDefinition.IsLastStage(a.CurrentStage))
    {
    <div class="card border-0 shadow-sm mb-3 bg-success text-white">
        <div class="card-body text-center py-4">
            <i class="bi bi-check-circle-fill fs-1"></i>
            <h5 class="mt-2 mb-1">اكتمل سير العمل!</h5>
            <p class="mb-0 opacity-75">@a.Status</p>
        </div>
    </div>
    }

    <!-- سجل المراحل -->
    <div class="card border-0 shadow-sm">
        <div class="card-header bg-light fw-bold">
            <i class="bi bi-clock-history me-2"></i>سجل المراحل
        </div>
        <div class="card-body p-2" style="max-height:350px;overflow-y:auto;">
            @if (!Model.History.Any())
            {<p class="text-center text-muted small py-3">لا يوجد سجل بعد</p>}
            @foreach (var h in Model.History)
            {
            <div class="d-flex gap-2 mb-3 border-bottom pb-2">
                <div class="mt-1">
                    <i class="bi @(h.Action=="Rejected"?"bi-x-circle-fill text-danger":
                                   h.Action is "Imported" or "AutoAdvanced"?"bi-box-arrow-in-down text-secondary":
                                   "bi-check-circle-fill text-success") fs-6"></i>
                </div>
                <div class="flex-grow-1">
                    <div class="fw-semibold small">@h.FromName &#8594; @h.ToName</div>
                    @if (!string.IsNullOrEmpty(h.Notes))
                    {<div class="text-muted" style="font-size:12px;">@h.Notes</div>}
                    <div class="text-muted" style="font-size:11px;">@h.PerformedAt.ToString("yyyy/MM/dd HH:mm")</div>
                </div>
                <span class="badge @(h.Action=="Rejected"?"bg-danger":
                                    h.Action is "Imported" or "AutoAdvanced"?"bg-secondary":"bg-success") small">
                    @h.Action
                </span>
            </div>
            }
        </div>
    </div>

</div>
</div>

@section Scripts {
<script>
var deleteFormId = null;
function confirmDelete(id, name) {
    deleteFormId = id;
    document.getElementById('deleteAssetName').textContent = name;
    new bootstrap.Modal(document.getElementById('deleteModal')).show();
}
document.getElementById('confirmDeleteBtn').addEventListener('click', function() {
    if (deleteFormId) document.getElementById('deleteForm_' + deleteFormId).submit();
});
</script>
}
'@, $utf8)
Write-Host "OK: Asset/Details.cshtml" -ForegroundColor Green

# ══ 2. Valuation/Evaluate.cshtml — 3 تقييمات + نوع التصرف ═════════
[System.IO.File]::WriteAllText("$web\Views\Valuation\Evaluate.cshtml", @'
@model AssetManagement.Application.ViewModels.ValuationViewModel
@{
    ViewData["Title"] = "مرحلة التقييم";
    var asset = (AssetManagement.Domain.Entities.Asset)ViewBag.Asset;
}

<div class="d-flex justify-content-between align-items-center mb-3">
    <div>
        <h5 class="fw-bold mb-1">
            <i class="bi bi-bar-chart me-2 text-warning"></i>مرحلة التقييم
        </h5>
        <span class="text-muted small">@asset.AssetName — <code>@asset.AssetCode</code></span>
    </div>
    <a asp-controller="Asset" asp-action="Details" asp-route-id="@asset.Id"
       class="btn btn-outline-secondary btn-sm">
        <i class="bi bi-arrow-right me-1"></i>رجوع
    </a>
</div>

<form asp-action="Evaluate" method="post" id="valForm">
    @Html.AntiForgeryToken()
    <input type="hidden" asp-for="AssetId"/>

    <div class="row g-3 mb-4">

        <!-- تقييم التسويق -->
        <div class="col-md-4">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-header fw-bold bg-warning bg-opacity-10">
                    <i class="bi bi-megaphone me-2 text-warning"></i>تقييم التسويق
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label class="form-label fw-semibold small">القيمة التقديرية (EGP) *</label>
                        <div class="input-group">
                            <span class="input-group-text">EGP</span>
                            <input asp-for="MarketingValue" type="number" class="form-control"
                                   step="1" min="1" placeholder="0"/>
                        </div>
                        <span asp-validation-for="MarketingValue" class="text-danger small"></span>
                    </div>
                    <div>
                        <label class="form-label small">تعليق (اختياري)</label>
                        <textarea asp-for="MarketingComments" class="form-control form-control-sm" rows="2"
                                  placeholder="ملاحظات تقييم التسويق..."></textarea>
                    </div>
                </div>
            </div>
        </div>

        <!-- تقييم المالية -->
        <div class="col-md-4">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-header fw-bold bg-info bg-opacity-10">
                    <i class="bi bi-bank me-2 text-info"></i>تقييم المالية
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label class="form-label fw-semibold small">القيمة التقديرية (EGP) *</label>
                        <div class="input-group">
                            <span class="input-group-text">EGP</span>
                            <input asp-for="FinanceValue" type="number" class="form-control"
                                   step="1" min="1" placeholder="0"/>
                        </div>
                        <span asp-validation-for="FinanceValue" class="text-danger small"></span>
                    </div>
                    <div>
                        <label class="form-label small">تعليق (اختياري)</label>
                        <textarea asp-for="FinanceComments" class="form-control form-control-sm" rows="2"
                                  placeholder="ملاحظات تقييم المالية..."></textarea>
                    </div>
                </div>
            </div>
        </div>

        <!-- تقييم مكاتب الخبراء -->
        <div class="col-md-4">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-header fw-bold bg-success bg-opacity-10">
                    <i class="bi bi-person-badge me-2 text-success"></i>تقييم مكاتب الخبراء
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label class="form-label fw-semibold small">القيمة التقديرية (EGP) *</label>
                        <div class="input-group">
                            <span class="input-group-text">EGP</span>
                            <input asp-for="ExpertValue" type="number" class="form-control"
                                   step="1" min="1" placeholder="0"/>
                        </div>
                        <span asp-validation-for="ExpertValue" class="text-danger small"></span>
                    </div>
                    <div>
                        <label class="form-label small">تعليق (اختياري)</label>
                        <textarea asp-for="ExpertComments" class="form-control form-control-sm" rows="2"
                                  placeholder="ملاحظات مكاتب الخبراء..."></textarea>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- نوع التصرف -->
    <div class="card border-0 shadow-sm mb-4">
        <div class="card-header fw-bold bg-primary bg-opacity-10">
            <i class="bi bi-tag me-2 text-primary"></i>نوع التصرف في العقار
        </div>
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-4">
                    <div class="form-check form-check-inline me-4">
                        <input class="form-check-input" type="radio" asp-for="DispositionType"
                               value="@AssetManagement.Domain.Enums.AssetType.Sale" id="typeSale"/>
                        <label class="form-check-label fw-semibold" for="typeSale">
                            <span class="badge bg-success me-1">بيع</span> Sale
                        </label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-check-inline me-4">
                        <input class="form-check-input" type="radio" asp-for="DispositionType"
                               value="@AssetManagement.Domain.Enums.AssetType.Rent" id="typeRent"/>
                        <label class="form-check-label fw-semibold" for="typeRent">
                            <span class="badge bg-info me-1">إيجار</span> Rent
                        </label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-check-inline">
                        <input class="form-check-input" type="radio" asp-for="DispositionType"
                               value="@AssetManagement.Domain.Enums.AssetType.Both" id="typeBoth"/>
                        <label class="form-check-label fw-semibold" for="typeBoth">
                            <span class="badge bg-warning text-dark me-1">بيع وإيجار</span> Both
                        </label>
                    </div>
                </div>
            </div>
            <div class="form-text mt-2">
                <i class="bi bi-info-circle me-1"></i>
                لو اخترت "بيع وإيجار" — ستظهر خيارات البيع والإيجار معاً في المرحلة التالية
            </div>
        </div>
    </div>

    <div class="d-flex gap-2">
        <button type="submit" id="submitBtn" class="btn btn-warning fw-bold flex-grow-1">
            <i class="bi bi-check-circle me-2"></i>حفظ التقييمات والانتقال لمرحلة الطلب
        </button>
        <a asp-controller="Asset" asp-action="Details" asp-route-id="@Model.AssetId"
           class="btn btn-outline-secondary">إلغاء</a>
    </div>
</form>

@section Scripts {
<script>
document.getElementById('valForm').addEventListener('submit', function() {
    var btn = document.getElementById('submitBtn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>جار الحفظ...';
});
</script>
}
'@, $utf8)
Write-Host "OK: Valuation/Evaluate.cshtml" -ForegroundColor Green

# ══ 3. Requests/CreateRental.cshtml — 4 حقول جديدة ════════════════
[System.IO.File]::WriteAllText("$web\Views\Requests\CreateRental.cshtml", @'
@model AssetManagement.Application.ViewModels.RentalRequestViewModel
@{
    ViewData["Title"] = "طلب إيجار";
    var asset = ViewBag.Asset as AssetManagement.Domain.Entities.Asset;
    var vals  = ViewBag.Valuations as ICollection<AssetManagement.Domain.Entities.AssetValuation> ?? new List<AssetManagement.Domain.Entities.AssetValuation>();
}

<div class="row justify-content-center">
<div class="col-md-9">

    <!-- بطاقة التقييمات للمرجعية -->
    @if (vals.Any())
    {
    <div class="card border-0 shadow-sm mb-3 border-start border-4 border-warning">
        <div class="card-body py-2">
            <div class="d-flex gap-3 align-items-center flex-wrap">
                <span class="fw-semibold small text-muted">التقييمات:</span>
                @foreach (var v in vals)
                {
                    string lbl = v.EvaluationType.ToString() switch {
                        "Marketing" => "تسويق",
                        "Finance"   => "مالية",
                        "Expert"    => "خبراء",
                        _ => v.EvaluationType.ToString()
                    };
                <span class="badge bg-light text-dark border fw-semibold">
                    @lbl: @v.Value.ToString("N0") EGP
                </span>
                }
                <a asp-controller="Requests" asp-action="PrintRequest"
                   asp-route-assetId="@Model.AssetId" target="_blank"
                   class="btn btn-sm btn-outline-secondary ms-auto">
                    <i class="bi bi-printer me-1"></i>طباعة
                </a>
            </div>
        </div>
    </div>
    }

    <div class="card border-0 shadow-sm">
        <div class="card-header bg-info text-white fw-bold">
            <i class="bi bi-house-door me-2"></i>طلب إيجار — @Model.AssetName
            <code class="ms-2 small text-white opacity-75">@Model.AssetCode</code>
            @if (!string.IsNullOrEmpty(Model.AssetPropertyType))
            {<span class="badge bg-light text-dark ms-2">@Model.AssetPropertyType</span>}
        </div>
        <div class="card-body">
            <form asp-action="CreateRental" method="post">
                @Html.AntiForgeryToken()
                <input type="hidden" asp-for="AssetId"/>
                <input type="hidden" asp-for="AssetName"/>
                <input type="hidden" asp-for="AssetCode"/>
                <input type="hidden" asp-for="AssetPropertyType"/>

                <!-- بيانات المستأجر -->
                <h6 class="fw-bold text-muted mb-3 border-bottom pb-2">بيانات المستأجر</h6>
                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">اسم المستأجر *</label>
                        <input asp-for="TenantName" class="form-control"/>
                        <span asp-validation-for="TenantName" class="text-danger small"></span>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">رقم الهوية</label>
                        <input asp-for="TenantIdNumber" class="form-control"/>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">الهاتف</label>
                        <input asp-for="TenantPhone" class="form-control"/>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">البريد الإلكتروني</label>
                        <input asp-for="TenantEmail" type="email" class="form-control"/>
                    </div>
                </div>

                <!-- تفاصيل العقد -->
                <h6 class="fw-bold text-muted mb-3 border-bottom pb-2">تفاصيل العقد</h6>
                <div class="row g-3 mb-4">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">الإيجار الشهري (EGP) *</label>
                        <div class="input-group">
                            <input asp-for="ProposedRent" type="number" class="form-control" min="1"/>
                            <span class="input-group-text">EGP</span>
                        </div>
                        <span asp-validation-for="ProposedRent" class="text-danger small"></span>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">مدة العقد (سنوات) *</label>
                        <input asp-for="ContractDurationYears" type="number" class="form-control" min="1" max="99"/>
                        <span asp-validation-for="ContractDurationYears" class="text-danger small"></span>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">تاريخ البداية</label>
                        <input asp-for="StartDate" type="date" class="form-control"/>
                    </div>
                </div>

                <!-- الحقول الجديدة -->
                <h6 class="fw-bold text-muted mb-3 border-bottom pb-2">
                    <i class="bi bi-plus-circle text-info me-2"></i>بنود العقد الإضافية
                </h6>
                <div class="row g-3 mb-4">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            التأمين (EGP)
                            <i class="bi bi-info-circle text-muted ms-1"
                               title="مبلغ التأمين المدفوع مقدماً"></i>
                        </label>
                        <div class="input-group">
                            <input asp-for="SecurityDeposit" type="number" class="form-control" min="0"/>
                            <span class="input-group-text">EGP</span>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            الزيادة السنوية (%)
                            <i class="bi bi-info-circle text-muted ms-1"
                               title="نسبة الزيادة السنوية على الإيجار"></i>
                        </label>
                        <div class="input-group">
                            <input asp-for="AnnualIncrease" type="number" class="form-control"
                                   min="0" max="100" step="0.5"/>
                            <span class="input-group-text">%</span>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">
                            فترة السماح (أشهر)
                            <i class="bi bi-info-circle text-muted ms-1"
                               title="فترة الإعفاء من الإيجار في بداية العقد"></i>
                        </label>
                        <div class="input-group">
                            <input asp-for="GracePeriod" type="number" class="form-control" min="0" max="24"/>
                            <span class="input-group-text">شهر</span>
                        </div>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">ملاحظات</label>
                        <textarea asp-for="Notes" class="form-control" rows="2"
                                  placeholder="أي ملاحظات إضافية على الطلب..."></textarea>
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-info text-white fw-bold flex-grow-1">
                        <i class="bi bi-check-lg me-2"></i>إرسال طلب الإيجار
                    </button>
                    <a asp-controller="Asset" asp-action="Details"
                       asp-route-id="@Model.AssetId" class="btn btn-outline-secondary">إلغاء</a>
                </div>
            </form>
        </div>
    </div>
</div>
</div>
'@, $utf8)
Write-Host "OK: Requests/CreateRental.cshtml" -ForegroundColor Green

# ══ 4. Requests/PrintRequest.cshtml (NEW) ════════════════════════
[System.IO.File]::WriteAllText("$web\Views\Requests\PrintRequest.cshtml", @'
@{
    ViewData["Title"] = "طباعة الطلب";
    var asset  = (AssetManagement.Domain.Entities.Asset)ViewBag.Asset;
    var vals   = (ICollection<AssetManagement.Domain.Entities.AssetValuation>)(ViewBag.Valuations ?? new List<AssetManagement.Domain.Entities.AssetValuation>());
    var rental = ViewBag.Rental as AssetManagement.Domain.Entities.RentalRequest;
    var sale   = ViewBag.Sale   as AssetManagement.Domain.Entities.SaleRequest;
    Layout = null;
}
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="utf-8"/>
    <title>طباعة الطلب — @asset.AssetCode</title>
    <style>
        * { font-family: "Arial", sans-serif; font-size: 13px; }
        body { margin: 20px; color: #333; }
        h2 { text-align: center; font-size: 18px; border-bottom: 2px solid #333; padding-bottom: 8px; }
        .section { margin-bottom: 16px; }
        .section-title { font-weight: bold; background: #f0f0f0; padding: 6px 10px;
                          border-right: 4px solid #1a56db; margin-bottom: 8px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 10px; }
        td, th { border: 1px solid #ddd; padding: 6px 10px; }
        th { background: #f5f5f5; font-weight: bold; text-align: right; }
        .val-box { display: inline-block; text-align: center; border: 1px solid #ddd;
                   padding: 8px 20px; margin: 4px; border-radius: 6px; min-width: 130px; }
        .val-label { font-size: 11px; color: #666; }
        .val-amount { font-size: 16px; font-weight: bold; color: #1a56db; }
        .no-print { display: none; }
        @@media print { .no-print { display: none !important; } }
    </style>
</head>
<body>
<div class="no-print" style="display:block; margin-bottom:16px; text-align:center;">
    <button onclick="window.print()" style="padding:8px 24px;background:#1a56db;color:white;border:none;border-radius:6px;cursor:pointer;font-size:14px;">
        طباعة
    </button>
    <button onclick="window.close()" style="padding:8px 24px;margin-right:8px;cursor:pointer;font-size:14px;">
        إغلاق
    </button>
</div>

<h2>نموذج طلب @(rental!=null?"إيجار":"بيع") — @DateTime.Now.ToString("yyyy/MM/dd")</h2>

<!-- بيانات العقار -->
<div class="section">
    <div class="section-title">بيانات العقار</div>
    <table>
        <tr><th>اسم العقار</th><td>@asset.AssetName</td><th>الكود</th><td>@asset.AssetCode</td></tr>
        <tr><th>نوع العقار</th><td>@asset.PropertyType</td><th>المدينة / الحي</th><td>@asset.City @asset.District</td></tr>
        <tr><th>مساحة الأرض</th><td>@(asset.LandArea.HasValue?asset.LandArea.Value.ToString("N0")+" م²":"—")</td>
            <th>مساحة المباني</th><td>@(asset.BuildingArea.HasValue?asset.BuildingArea.Value.ToString("N0")+" م²":"—")</td></tr>
        <tr><th>الشركة المالكة</th><td>@asset.OwnerCompany</td><th>الموقف</th><td>@asset.OccupancyStatus</td></tr>
    </table>
</div>

<!-- التقييمات -->
@if (vals.Any())
{
<div class="section">
    <div class="section-title">التقييمات</div>
    <div style="text-align:center; padding:10px;">
        @foreach (var v in vals)
        {
            string lbl = v.EvaluationType.ToString() switch {
                "Marketing" => "تقييم التسويق",
                "Finance"   => "تقييم المالية",
                "Expert"    => "تقييم مكاتب الخبراء",
                _ => v.EvaluationType.ToString()
            };
        <div class="val-box">
            <div class="val-label">@lbl</div>
            <div class="val-amount">@v.Value.ToString("N0") EGP</div>
            @if (!string.IsNullOrEmpty(v.Comments))
            {<div class="val-label">@v.Comments</div>}
        </div>
        }
    </div>
</div>
}

<!-- بيانات الطلب -->
@if (rental != null)
{
<div class="section">
    <div class="section-title">بيانات طلب الإيجار</div>
    <table>
        <tr><th>اسم المستأجر</th><td>@rental.TenantName</td><th>رقم الهوية</th><td>@rental.TenantIdNumber</td></tr>
        <tr><th>الهاتف</th><td>@rental.TenantPhone</td><th>البريد</th><td>@rental.TenantEmail</td></tr>
        <tr><th>الإيجار الشهري</th><td class="fw-bold">@rental.ProposedRent.ToString("N0") EGP</td>
            <th>مدة العقد</th><td>@(rental.ContractDurationYears.HasValue?rental.ContractDurationYears+"سنة":rental.RentDurationMonths+"شهر")</td></tr>
        <tr><th>التأمين</th><td>@(rental.SecurityDeposit.HasValue?rental.SecurityDeposit.Value.ToString("N0")+" EGP":"—")</td>
            <th>الزيادة السنوية</th><td>@(rental.AnnualIncrease.HasValue?rental.AnnualIncrease.Value+"%":"—")</td></tr>
        <tr><th>فترة السماح</th><td>@(rental.GracePeriod.HasValue?rental.GracePeriod.Value+" شهر":"—")</td>
            <th>تاريخ البداية</th><td>@rental.StartDate?.ToString("yyyy/MM/dd")</td></tr>
        <tr><th colspan="4">ملاحظات: @rental.Notes</th></tr>
    </table>
</div>
}

@if (sale != null)
{
<div class="section">
    <div class="section-title">بيانات طلب البيع</div>
    <table>
        <tr><th>اسم المشتري</th><td>@sale.BuyerName</td><th>رقم الهوية</th><td>@sale.BuyerIdNumber</td></tr>
        <tr><th>الهاتف</th><td>@sale.BuyerPhone</td><th>البريد</th><td>@sale.BuyerEmail</td></tr>
        <tr><th>السعر المعروض</th><td class="fw-bold" colspan="3">@sale.OfferedPrice.ToString("N0") EGP — @sale.PaymentMethod</td></tr>
    </table>
</div>
}

<div style="margin-top:40px; text-align:center; color:#999; font-size:11px;">
    نظام إدارة الأصول — تاريخ الطباعة: @DateTime.Now.ToString("yyyy/MM/dd HH:mm")
</div>
</body>
</html>
'@, $utf8)
Write-Host "OK: Requests/PrintRequest.cshtml (NEW)" -ForegroundColor Green

# ══ 5. Finance/ReviewContract.cshtml (NEW) ════════════════════════
[System.IO.File]::WriteAllText("$web\Views\Finance\ReviewContract.cshtml", @'
@{
    ViewData["Title"] = "مراجعة العقد";
    var asset    = (AssetManagement.Domain.Entities.Asset)ViewBag.Asset;
    var contract = (AssetManagement.Domain.Entities.Contract)ViewBag.Contract;
    var vals     = (ICollection<AssetManagement.Domain.Entities.AssetValuation>)(ViewBag.Valuations ?? new List<AssetManagement.Domain.Entities.AssetValuation>());
    bool isSale  = contract.ContractType == AssetManagement.Domain.Enums.ContractType.Sale;
    var rental   = asset.RentalRequests.OrderByDescending(r=>r.CreatedAt).FirstOrDefault();
}

<div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="fw-bold mb-0">
        <i class="bi bi-eye me-2 text-info"></i>مراجعة العقد — المالية
    </h5>
    <a asp-controller="Asset" asp-action="Details" asp-route-id="@asset.Id"
       class="btn btn-outline-secondary btn-sm">
        <i class="bi bi-arrow-right me-1"></i>رجوع
    </a>
</div>

<div class="row g-3">
<div class="col-md-8">

    <!-- بيانات العقد -->
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-primary text-white fw-bold">
            <i class="bi bi-file-earmark-text me-2"></i>@contract.ContractNumber
        </div>
        <div class="card-body">
            <div class="row g-3">
                <div class="col-6"><div class="text-muted small">الطرف</div><div class="fw-bold">@contract.PartyName</div></div>
                <div class="col-6"><div class="text-muted small">رقم الهوية</div><div>@contract.PartyIdNumber</div></div>
                <div class="col-6"><div class="text-muted small">الهاتف</div><div>@contract.PartyPhone</div></div>
                <div class="col-6">
                    <div class="text-muted small">المبلغ</div>
                    <div class="fw-bold text-success fs-5">@contract.Amount.ToString("N0") EGP</div>
                </div>
                @if (!isSale)
                {
                <div class="col-6"><div class="text-muted small">تاريخ البداية</div><div>@contract.StartDate?.ToString("yyyy/MM/dd")</div></div>
                <div class="col-6"><div class="text-muted small">تاريخ الانتهاء</div><div>@contract.EndDate?.ToString("yyyy/MM/dd")</div></div>
                @if (rental != null)
                {
                <div class="col-4"><div class="text-muted small">التأمين</div>
                    <div class="fw-semibold">@(rental.SecurityDeposit.HasValue?rental.SecurityDeposit.Value.ToString("N0")+" EGP":"—")</div></div>
                <div class="col-4"><div class="text-muted small">الزيادة السنوية</div>
                    <div class="fw-semibold">@(rental.AnnualIncrease.HasValue?rental.AnnualIncrease.Value+"%":"—")</div></div>
                <div class="col-4"><div class="text-muted small">فترة السماح</div>
                    <div class="fw-semibold">@(rental.GracePeriod.HasValue?rental.GracePeriod.Value+" شهر":"—")</div></div>
                }
                }
                <div class="col-6"><div class="text-muted small">العقار</div><div>@asset.AssetName — @asset.City</div></div>
                <div class="col-6"><div class="text-muted small">نوع العقد</div>
                    <span class="badge @(isSale?"bg-success":"bg-info")">@(isSale?"بيع":"إيجار")</span>
                </div>
            </div>
        </div>
    </div>

    <!-- التقييمات للمرجعية -->
    @if (vals.Any())
    {
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header bg-warning bg-opacity-10 fw-bold">
            <i class="bi bi-bar-chart me-2 text-warning"></i>التقييمات (للمرجعية)
        </div>
        <div class="card-body">
            <div class="row g-2">
                @foreach (var v in vals)
                {
                    string lbl = v.EvaluationType.ToString() switch {
                        "Marketing" => "تقييم التسويق",
                        "Finance"   => "تقييم المالية",
                        "Expert"    => "تقييم مكاتب الخبراء",
                        _ => v.EvaluationType.ToString()
                    };
                <div class="col-md-4">
                    <div class="border rounded p-3 text-center">
                        <div class="text-muted small">@lbl</div>
                        <div class="fw-bold fs-5">@v.Value.ToString("N0")</div>
                        <div class="text-muted small">EGP</div>
                    </div>
                </div>
                }
            </div>
        </div>
    </div>
    }

</div>
<div class="col-md-4">

    <!-- اعتماد العقد -->
    <div class="card border-0 shadow-sm mb-3 border-success border-2">
        <div class="card-header bg-success text-white fw-bold">
            <i class="bi bi-check-circle me-2"></i>اعتماد العقد
        </div>
        <div class="card-body">
            <p class="text-muted small">بعد المراجعة — اعتمد العقد لإرساله للتسويق</p>
            <form asp-controller="Finance" asp-action="ApproveContract" method="post">
                @Html.AntiForgeryToken()
                <input type="hidden" name="assetId" value="@asset.Id"/>
                <textarea name="notes" class="form-control form-control-sm mb-3" rows="2"
                          placeholder="ملاحظات الاعتماد (اختياري)"></textarea>
                <button type="submit" class="btn btn-success w-100 fw-bold">
                    <i class="bi bi-check-lg me-2"></i>اعتماد العقد
                </button>
            </form>
        </div>
    </div>

    <!-- رفض العقد -->
    <div class="card border-0 shadow-sm border-danger border-2">
        <div class="card-header bg-danger text-white fw-bold">
            <i class="bi bi-x-circle me-2"></i>رفض العقد
        </div>
        <div class="card-body">
            <form asp-controller="Finance" asp-action="RejectContract" method="post">
                @Html.AntiForgeryToken()
                <input type="hidden" name="assetId" value="@asset.Id"/>
                <textarea name="reason" class="form-control form-control-sm border-danger mb-3" rows="2"
                          placeholder="سبب الرفض (مطلوب)..." required></textarea>
                <button type="submit" class="btn btn-danger w-100">
                    <i class="bi bi-x-lg me-2"></i>رفض العقد
                </button>
            </form>
        </div>
    </div>

    <!-- تحميل Word -->
    <div class="card border-0 shadow-sm mt-3">
        <div class="card-body">
            <a asp-controller="Contracts" asp-action="DownloadWord" asp-route-contractId="@contract.Id"
               class="btn btn-outline-success w-100">
                <i class="bi bi-file-earmark-word me-2"></i>تحميل العقد Word
            </a>
        </div>
    </div>

</div>
</div>
'@, $utf8)
Write-Host "OK: Finance/ReviewContract.cshtml (NEW)" -ForegroundColor Green

# ══ 6. MarketingUpload/UploadSigned.cshtml (NEW) ══════════════════
[System.IO.File]::WriteAllText("$web\Views\MarketingUpload\UploadSigned.cshtml", @'
@{
    ViewData["Title"] = "رفع العقد الموقّع";
    var asset    = (AssetManagement.Domain.Entities.Asset)ViewBag.Asset;
    var contract = ViewBag.Contract as AssetManagement.Domain.Entities.Contract;
    var files    = ViewBag.Files as List<AssetManagement.Domain.Entities.ContractFile> ?? new();
}

<div class="row justify-content-center">
<div class="col-md-8">

    <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-bold mb-0">
            <i class="bi bi-cloud-upload me-2 text-warning"></i>رفع العقد الموقّع
        </h5>
        <a asp-controller="Asset" asp-action="Details" asp-route-id="@asset.Id"
           class="btn btn-outline-secondary btn-sm">
            <i class="bi bi-arrow-right me-1"></i>رجوع
        </a>
    </div>

    @if (contract != null)
    {
    <div class="alert alert-info border-0 mb-3">
        <strong>@contract.ContractNumber</strong> — @contract.PartyName —
        <span class="fw-bold">@contract.Amount.ToString("N0") EGP</span>
    </div>
    }

    <!-- رفع الملف -->
    <div class="card border-0 shadow-sm mb-3">
        <div class="card-header fw-bold bg-warning text-dark">
            <i class="bi bi-upload me-2"></i>رفع نسخة موقّعة
        </div>
        <div class="card-body">
            <form asp-action="UploadSigned" method="post" enctype="multipart/form-data">
                @Html.AntiForgeryToken()
                <input type="hidden" name="assetId" value="@asset.Id"/>
                <div class="mb-3">
                    <label class="form-label fw-semibold">اختر الملف *</label>
                    <input type="file" name="file" class="form-control"
                           accept=".pdf,.doc,.docx" required/>
                    <div class="form-text">
                        <i class="bi bi-info-circle me-1"></i>
                        يُقبل: PDF، Word (.doc، .docx) — الحجم الأقصى 10MB
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">ملاحظات (اختياري)</label>
                    <textarea name="notes" class="form-control" rows="2"
                              placeholder="ملاحظات على الملف المرفوع..."></textarea>
                </div>
                <button type="submit" class="btn btn-warning fw-bold w-100">
                    <i class="bi bi-cloud-upload me-2"></i>رفع العقد الموقّع والانتقال للخزنة
                </button>
            </form>
        </div>
    </div>

    <!-- الملفات المرفوعة مسبقاً -->
    @if (files.Any())
    {
    <div class="card border-0 shadow-sm">
        <div class="card-header bg-light fw-bold">
            <i class="bi bi-paperclip me-2"></i>الملفات المرفوعة (@files.Count)
        </div>
        <div class="list-group list-group-flush">
            @foreach (var f in files)
            {
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <div>
                    <i class="bi @(f.FileType=="PDF"?"bi-file-earmark-pdf text-danger":"bi-file-earmark-word text-primary") me-2 fs-5"></i>
                    <span class="fw-semibold">@f.FileName</span>
                    <span class="text-muted small ms-2">
                        @(f.FileSize/1024)KB — @f.UploadedAt.ToString("yyyy/MM/dd HH:mm")
                    </span>
                </div>
                <a href="@f.FilePath" class="btn btn-sm btn-outline-secondary" target="_blank">
                    <i class="bi bi-eye me-1"></i>عرض
                </a>
            </div>
            }
        </div>
    </div>
    }

</div>
</div>
'@, $utf8)
Write-Host "OK: MarketingUpload/UploadSigned.cshtml (NEW)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Stage 5 Complete ===" -ForegroundColor Cyan
Write-Host "Files modified/created:"
Write-Host "  [M] Views/Asset/Details.cshtml"
Write-Host "  [M] Views/Valuation/Evaluate.cshtml"
Write-Host "  [M] Views/Requests/CreateRental.cshtml"
Write-Host "  [N] Views/Requests/PrintRequest.cshtml"
Write-Host "  [N] Views/Finance/ReviewContract.cshtml"
Write-Host "  [N] Views/MarketingUpload/UploadSigned.cshtml"
Write-Host ""

cd $base
dotnet build 2>&1 | Select-Object -Last 6

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build OK!" -ForegroundColor Green
    Write-Host "Run: cd AssetManagement.Web && dotnet run" -ForegroundColor Yellow
} else {
    Write-Host "Build FAILED" -ForegroundColor Red
}
