
$path = "C:\Users\ahmed.essamm\Desktop\AssetManagement\AssetManagement.Web\Views\Asset\FullDetails.cshtml"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# Fix ActionAr - add missing actions
$old = 'string ActionAr(string? action) => action switch {
        "Approved"      => "موافقة",
        "Rejected"      => "رفض",
        "Imported"      => "استيراد",
        "AutoAdvanced"  => "تلقائي",
        "RentalRequest" => "طلب إيجار",
        "SaleRequest"   => "طلب بيع",
        "Valued"        => "تقييم",
        "Collected"     => "تحصيل",
        _               => action ?? ""
    };'

$new = 'string ActionAr(string? action) => action switch {
        "Approved"               => "موافقة",
        "Rejected"               => "رفض",
        "Imported"               => "استيراد",
        "AutoAdvanced"           => "تلقائي",
        "RentalRequest"          => "طلب إيجار",
        "SaleRequest"            => "طلب بيع",
        "Valued"                 => "تقييم",
        "Collected"              => "تحصيل",
        "ContractCreated"        => "إنشاء عقد",
        "ContractApproved"       => "اعتماد عقد",
        "SignedContractUploaded" => "رفع عقد موقّع",
        "FinanceRejected"        => "رفض مالي",
        "Advanced"               => "تقدم",
        _                        => action ?? ""
    };'

$content = $content.Replace($old, $new)

# Fix NoteAr - add Cash note fix
$oldNote = 'string NoteAr(string? note) => note switch {
        "Imported from Excel"                => "تم الاستيراد من ملف Excel",
        "Auto-advanced to optional stages"   => "انتقال تلقائي إلى المراحل الاختيارية",
        "Auto-advanced"                      => "انتقال تلقائي",
        _                                    => note ?? ""
    };'

$newNote = 'string NoteAr(string? note) {
        if (note == null) return "";
        note = note
            .Replace("Cash \u2014 ", "نقداً — ")
            .Replace("Cash - ", "نقداً - ")
            .Replace("Cash", "نقداً")
            .Replace("Check", "شيك")
            .Replace("Transfer", "تحويل")
            .Replace("\u00e2\u20ac\u201c", "—")
            .Replace("Receipt:", "إيصال:")
            .Replace("Imported from Excel", "تم الاستيراد من ملف Excel")
            .Replace("Auto-advanced to optional stages", "انتقال تلقائي إلى المراحل الاختيارية")
            .Replace("Auto-advanced", "انتقال تلقائي");
        return note;
    }'

$content = $content.Replace($oldNote, $newNote)

$bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
[System.IO.File]::WriteAllBytes($path, $bytes)
Write-Host "OK: FullDetails.cshtml patched" -ForegroundColor Green
