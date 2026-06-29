$ctrl = "$env:USERPROFILE\Desktop\AssetManagement\AssetManagement.Web\Controllers"
$enc  = [System.Text.Encoding]::UTF8
Write-Host "Fixing Arabic TempData messages..." -ForegroundColor Cyan

# AssetController.cs
$path = "$ctrl\AssetController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ Ø­Ø°Ù Ø§ÙØ£ØµÙ Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0623\u0635\u0644 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم حذف الأصل بنجاح", "\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0623\u0635\u0644 \u0628\u0646\u062c\u0627\u062d")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: AssetController.cs" -ForegroundColor Green
}

# ValuationController.cs
$path = "$ctrl\ValuationController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ÙØ°Ø§ Ø§ÙØ£ØµÙ ÙÙØ³ ÙÙ ÙØ±Ø­ÙØ© Ø§ÙØªÙÙÙÙ Ø­Ø§ÙÙØ§Ù", "\u0647\u0630\u0627 \u0627\u0644\u0623\u0635\u0644 \u0644\u064a\u0633 \u0641\u064a \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0642\u064a\u064a\u0645 \u062d\u0627\u0644\u064a\u0627\u064b")
    $c = $c.Replace("هذا الأصل ليس في مرحلة التقييم حالياً", "\u0647\u0630\u0627 \u0627\u0644\u0623\u0635\u0644 \u0644\u064a\u0633 \u0641\u064a \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0642\u064a\u064a\u0645 \u062d\u0627\u0644\u064a\u0627\u064b")
    $c = $c.Replace("ØªÙ Ø­ÙØ¸ Ø§ÙØªÙÙÙÙØ§Øª ÙØ§ÙØªÙÙ Ø§ÙØ£ØµÙ Ø¥ÙÙ ÙØ±Ø­ÙØ© Ø§ÙØ·ÙØ¨", "\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u062a\u0642\u064a\u064a\u0645\u0627\u062a \u0648\u0627\u0646\u062a\u0642\u0644 \u0627\u0644\u0623\u0635\u0644 \u0625\u0644\u0649 \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0637\u0644\u0628")
    $c = $c.Replace("تم حفظ التقييمات وانتقل الأصل إلى مرحلة الطلب", "\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u062a\u0642\u064a\u064a\u0645\u0627\u062a \u0648\u0627\u0646\u062a\u0642\u0644 \u0627\u0644\u0623\u0635\u0644 \u0625\u0644\u0649 \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0637\u0644\u0628")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: ValuationController.cs" -ForegroundColor Green
}

# RequestsController.cs
$path = "$ctrl\RequestsController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ ØªÙØ¯ÙÙ Ø·ÙØ¨ Ø§ÙØ¥ÙØ¬Ø§Ø± Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u062a\u0642\u062f\u064a\u0645 \u0637\u0644\u0628 \u0627\u0644\u0625\u064a\u062c\u0627\u0631 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم تقديم طلب الإيجار بنجاح", "\u062a\u0645 \u062a\u0642\u062f\u064a\u0645 \u0637\u0644\u0628 \u0627\u0644\u0625\u064a\u062c\u0627\u0631 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("ØªÙ ØªÙØ¯ÙÙ Ø·ÙØ¨ Ø§ÙØ¨ÙØ¹ Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u062a\u0642\u062f\u064a\u0645 \u0637\u0644\u0628 \u0627\u0644\u0628\u064a\u0639 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم تقديم طلب البيع بنجاح", "\u062a\u0645 \u062a\u0642\u062f\u064a\u0645 \u0637\u0644\u0628 \u0627\u0644\u0628\u064a\u0639 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("Ø®Ø·Ø£ ÙÙ Ø§ÙØªØ­ÙÙ: ", "\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062a\u062d\u0642\u0642: ")
    $c = $c.Replace("خطأ في التحقق: ", "\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062a\u062d\u0642\u0642: ")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: RequestsController.cs" -ForegroundColor Green
}

# ContractsController.cs
$path = "$ctrl\ContractsController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ Ø¥ÙØ´Ø§Ø¡ Ø§ÙØ¹ÙØ¯", "\u062a\u0645 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0639\u0642\u062f")
    $c = $c.Replace("تم إنشاء العقد", "\u062a\u0645 \u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u0639\u0642\u062f")
    $c = $c.Replace("ÙØ§ ÙÙØ¬Ø¯ Ø¹ÙØ¯", "\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0642\u062f")
    $c = $c.Replace("لا يوجد عقد", "\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0642\u062f")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: ContractsController.cs" -ForegroundColor Green
}

# FinanceController.cs
$path = "$ctrl\FinanceController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ Ø§Ø¹ØªÙØ§Ø¯ Ø§ÙØ¹ÙØ¯ ÙØ¥Ø±Ø³Ø§ÙÙ ÙÙØªØ³ÙÙÙ ÙØ±ÙØ¹ Ø§ÙÙØ³Ø®Ø© Ø§ÙÙÙÙØ¹Ø©", "\u062a\u0645 \u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0639\u0642\u062f \u0648\u0625\u0631\u0633\u0627\u0644\u0647 \u0644\u0644\u062a\u0633\u0648\u064a\u0642 \u0644\u0631\u0641\u0639 \u0627\u0644\u0646\u0633\u062e\u0629 \u0627\u0644\u0645\u0648\u0642\u0639\u0629")
    $c = $c.Replace("تم اعتماد العقد وإرساله للتسويق لرفع النسخة الموقعة", "\u062a\u0645 \u0627\u0639\u062a\u0645\u0627\u062f \u0627\u0644\u0639\u0642\u062f \u0648\u0625\u0631\u0633\u0627\u0644\u0647 \u0644\u0644\u062a\u0633\u0648\u064a\u0642 \u0644\u0631\u0641\u0639 \u0627\u0644\u0646\u0633\u062e\u0629 \u0627\u0644\u0645\u0648\u0642\u0639\u0629")
    $c = $c.Replace("ØªÙ Ø±ÙØ¶ Ø§ÙØ¹ÙØ¯: ", "\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0639\u0642\u062f: ")
    $c = $c.Replace("تم رفض العقد: ", "\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0639\u0642\u062f: ")
    $c = $c.Replace("ØªÙØª Ø§ÙÙÙØ§ÙÙØ© ÙØ§ÙØ§ÙØªÙØ§Ù ÙÙÙØ±Ø­ÙØ© Ø§ÙØªØ§ÙÙØ©", "\u062a\u0645\u062a \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629 \u0648\u0627\u0644\u0627\u0646\u062a\u0642\u0627\u0644 \u0644\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0627\u0644\u064a\u0629")
    $c = $c.Replace("تمت الموافقة والانتقال للمرحلة التالية", "\u062a\u0645\u062a \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629 \u0648\u0627\u0644\u0627\u0646\u062a\u0642\u0627\u0644 \u0644\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0627\u0644\u064a\u0629")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: FinanceController.cs" -ForegroundColor Green
}

# MarketingUploadController.cs
$path = "$ctrl\MarketingUploadController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ÙØ±Ø¬Ù Ø§Ø®ØªÙØ§Ø± ÙÙÙ PDF Ø£Ù Word", "\u064a\u0631\u062c\u0649 \u0627\u062e\u062a\u064a\u0627\u0631 \u0645\u0644\u0641 PDF \u0623\u0648 Word")
    $c = $c.Replace("يرجى اختيار ملف PDF أو Word", "\u064a\u0631\u062c\u0649 \u0627\u062e\u062a\u064a\u0627\u0631 \u0645\u0644\u0641 PDF \u0623\u0648 Word")
    $c = $c.Replace("ÙØ§ ÙÙØ¬Ø¯ Ø¹ÙØ¯ ÙØ±ØªØ¨Ø·", "\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0642\u062f \u0645\u0631\u062a\u0628\u0637")
    $c = $c.Replace("لا يوجد عقد مرتبط", "\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0642\u062f \u0645\u0631\u062a\u0628\u0637")
    $c = $c.Replace("ÙÙØ¹ Ø§ÙÙÙÙ ØºÙØ± ÙØ³ÙÙØ­. ÙÙØ¨Ù PDF Ù Word ÙÙØ·", "\u0646\u0648\u0639 \u0627\u0644\u0645\u0644\u0641 \u063a\u064a\u0631 \u0645\u0633\u0645\u0648\u062d. \u064a\u0642\u0628\u0644 PDF \u0648 Word \u0641\u0642\u0637")
    $c = $c.Replace("نوع الملف غير مسموح. يقبل PDF و Word فقط", "\u0646\u0648\u0639 \u0627\u0644\u0645\u0644\u0641 \u063a\u064a\u0631 \u0645\u0633\u0645\u0648\u062d. \u064a\u0642\u0628\u0644 PDF \u0648 Word \u0641\u0642\u0637")
    $c = $c.Replace("ØªÙ Ø±ÙØ¹ Ø§ÙØ¹ÙØ¯ Ø§ÙÙÙÙØ¹ Ø¨ÙØ¬Ø§Ø­ ÙØ¥Ø±Ø³Ø§ÙÙ ÙÙØ®Ø²ÙØ©", "\u062a\u0645 \u0631\u0641\u0639 \u0627\u0644\u0639\u0642\u062f \u0627\u0644\u0645\u0648\u0642\u0639 \u0628\u0646\u062c\u0627\u062d \u0648\u0625\u0631\u0633\u0627\u0644\u0647 \u0644\u0644\u062e\u0632\u0646\u0629")
    $c = $c.Replace("تم رفع العقد الموقع بنجاح وإرساله للخزنة", "\u062a\u0645 \u0631\u0641\u0639 \u0627\u0644\u0639\u0642\u062f \u0627\u0644\u0645\u0648\u0642\u0639 \u0628\u0646\u062c\u0627\u062d \u0648\u0625\u0631\u0633\u0627\u0644\u0647 \u0644\u0644\u062e\u0632\u0646\u0629")
    $c = $c.Replace("ÙØ§ ÙÙØ¬Ø¯ Ø¹ÙØ¯ ÙØ±ØªØ¨Ø· Ø¨ÙØ°Ø§ Ø§ÙØ£ØµÙ", "\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0642\u062f \u0645\u0631\u062a\u0628\u0637 \u0628\u0647\u0630\u0627 \u0627\u0644\u0623\u0635\u0644")
    $c = $c.Replace("لا يوجد عقد مرتبط بهذا الأصل", "\u0644\u0627 \u064a\u0648\u062c\u062f \u0639\u0642\u062f \u0645\u0631\u062a\u0628\u0637 \u0628\u0647\u0630\u0627 \u0627\u0644\u0623\u0635\u0644")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: MarketingUploadController.cs" -ForegroundColor Green
}

# TreasuryController.cs
$path = "$ctrl\TreasuryController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ ØªØ³Ø¬ÙÙ Ø§ÙØªØ­ØµÙÙ ÙØ§ÙØªÙÙ Ø³ÙØ± Ø§ÙØ¹ÙÙ ÙÙØ£ØµÙ", "\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062a\u062d\u0635\u064a\u0644 \u0648\u0627\u0643\u062a\u0645\u0644 \u0633\u064a\u0631 \u0627\u0644\u0639\u0645\u0644 \u0644\u0644\u0623\u0635\u0644")
    $c = $c.Replace("تم تسجيل التحصيل واكتمل سير العمل للأصل", "\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062a\u062d\u0635\u064a\u0644 \u0648\u0627\u0643\u062a\u0645\u0644 \u0633\u064a\u0631 \u0627\u0644\u0639\u0645\u0644 \u0644\u0644\u0623\u0635\u0644")
    $c = $c.Replace("Ø®Ø·Ø£ ÙÙ Ø§ÙØªØ­ÙÙ: ", "\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062a\u062d\u0642\u0642: ")
    $c = $c.Replace("خطأ في التحقق: ", "\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062a\u062d\u0642\u0642: ")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: TreasuryController.cs" -ForegroundColor Green
}

# OptionalStagesController.cs
$path = "$ctrl\OptionalStagesController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ Ø¥ÙÙØ§Ù ÙØ±Ø­ÙØ© Ø§ÙØªØ³ÙÙÙ", "\u062a\u0645 \u0625\u0643\u0645\u0627\u0644 \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0633\u0648\u064a\u0642")
    $c = $c.Replace("تم إكمال مرحلة التسويق", "\u062a\u0645 \u0625\u0643\u0645\u0627\u0644 \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u062a\u0633\u0648\u064a\u0642")
    $c = $c.Replace("ØªÙ Ø¥ÙÙØ§Ù Ø§ÙÙØ±Ø­ÙØ© Ø§ÙÙÙØ¯Ø³ÙØ©", "\u062a\u0645 \u0625\u0643\u0645\u0627\u0644 \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0647\u0646\u062f\u0633\u064a\u0629")
    $c = $c.Replace("تم إكمال المرحلة الهندسية", "\u062a\u0645 \u0625\u0643\u0645\u0627\u0644 \u0627\u0644\u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0647\u0646\u062f\u0633\u064a\u0629")
    $c = $c.Replace("ØªÙ Ø¥ÙÙØ§Ù ÙØ±Ø­ÙØ© Ø§ÙØ´Ø¤ÙÙ Ø§ÙØ¥Ø¯Ø§Ø±ÙØ©", "\u062a\u0645 \u0625\u0643\u0645\u0627\u0644 \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0634\u0624\u0648\u0646 \u0627\u0644\u0625\u062f\u0627\u0631\u064a\u0629")
    $c = $c.Replace("تم إكمال مرحلة الشؤون الإدارية", "\u062a\u0645 \u0625\u0643\u0645\u0627\u0644 \u0645\u0631\u062d\u0644\u0629 \u0627\u0644\u0634\u0624\u0648\u0646 \u0627\u0644\u0625\u062f\u0627\u0631\u064a\u0629")
    $c = $c.Replace("ØªÙ Ø­ÙØ¸ Ø§ÙØ¨ÙØ§ÙØ§Øª Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم حفظ البيانات بنجاح", "\u062a\u0645 \u062d\u0641\u0638 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a \u0628\u0646\u062c\u0627\u062d")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: OptionalStagesController.cs" -ForegroundColor Green
}

# UsersController.cs
$path = "$ctrl\UsersController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ Ø¥Ø¶Ø§ÙØ© Ø§ÙÙØ³ØªØ®Ø¯Ù Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم إضافة المستخدم بنجاح", "\u062a\u0645 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("ØªÙ ØªØ¹Ø¯ÙÙ Ø§ÙÙØ³ØªØ®Ø¯Ù Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم تعديل المستخدم بنجاح", "\u062a\u0645 \u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("ØªÙ Ø­Ø°Ù Ø§ÙÙØ³ØªØ®Ø¯Ù Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم حذف المستخدم بنجاح", "\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("Ø§Ø³Ù Ø§ÙÙØ³ØªØ®Ø¯Ù ÙÙØ¬ÙØ¯ ÙØ³Ø¨ÙØ§Ù", "\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0645\u0648\u062c\u0648\u062f \u0645\u0633\u0628\u0642\u0627\u064b")
    $c = $c.Replace("اسم المستخدم موجود مسبقاً", "\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0645\u0648\u062c\u0648\u062f \u0645\u0633\u0628\u0642\u0627\u064b")
    $c = $c.Replace("Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«ÙØ§Ø¡ Ø§ÙØ¥Ø¶Ø§ÙØ©", "\u062d\u062f\u062b \u062e\u0637\u0623 \u0623\u062b\u0646\u0627\u0621 \u0627\u0644\u0625\u0636\u0627\u0641\u0629")
    $c = $c.Replace("حدث خطأ أثناء الإضافة", "\u062d\u062f\u062b \u062e\u0637\u0623 \u0623\u062b\u0646\u0627\u0621 \u0627\u0644\u0625\u0636\u0627\u0641\u0629")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: UsersController.cs" -ForegroundColor Green
}

# ImagesController.cs
$path = "$ctrl\ImagesController.cs"
if (Test-Path $path) {
    $c = [System.IO.File]::ReadAllText($path, $enc)
    $c = $c.Replace("ØªÙ Ø±ÙØ¹ Ø§ÙØµÙØ± Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u0631\u0641\u0639 \u0627\u0644\u0635\u0648\u0631 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم رفع الصور بنجاح", "\u062a\u0645 \u0631\u0641\u0639 \u0627\u0644\u0635\u0648\u0631 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("ØªÙ Ø­Ø°Ù Ø§ÙØµÙØ±Ø© Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0635\u0648\u0631\u0629 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم حذف الصورة بنجاح", "\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0635\u0648\u0631\u0629 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«ÙØ§Ø¡ Ø±ÙØ¹ Ø§ÙØµÙØ±", "\u062d\u062f\u062b \u062e\u0637\u0623 \u0623\u062b\u0646\u0627\u0621 \u0631\u0641\u0639 \u0627\u0644\u0635\u0648\u0631")
    $c = $c.Replace("حدث خطأ أثناء رفع الصور", "\u062d\u062f\u062b \u062e\u0637\u0623 \u0623\u062b\u0646\u0627\u0621 \u0631\u0641\u0639 \u0627\u0644\u0635\u0648\u0631")
    $c = $c.Replace("ÙØ±Ø¬Ù Ø§Ø®ØªÙØ§Ø± ØµÙØ± ØµØ§ÙØ­Ø©", "\u064a\u0631\u062c\u0649 \u0627\u062e\u062a\u064a\u0627\u0631 \u0635\u0648\u0631 \u0635\u0627\u0644\u062d\u0629")
    $c = $c.Replace("يرجى اختيار صور صالحة", "\u064a\u0631\u062c\u0649 \u0627\u062e\u062a\u064a\u0627\u0631 \u0635\u0648\u0631 \u0635\u0627\u0644\u062d\u0629")
    [System.IO.File]::WriteAllText($path, $c, $enc)
    Write-Host "  OK: ImagesController.cs" -ForegroundColor Green
}

# Fix WorkflowService return messages too
$svc = "$env:USERPROFILE\Desktop\AssetManagement\AssetManagement.Application\Services\WorkflowService.cs"
if (Test-Path $svc) {
    $c = [System.IO.File]::ReadAllText($svc, $enc)
    $c = $c.Replace("ÙÙ ÙØªÙ Ø§Ø³ØªÙÙØ§Ù Ø§ÙÙØ±Ø§Ø­Ù Ø§ÙØ§Ø®ØªÙØ§Ø±ÙØ© Ø§ÙÙØ·ÙÙØ¨Ø©", "\u0644\u0645 \u064a\u062a\u0645 \u0627\u0633\u062a\u0643\u0645\u0627\u0644 \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629 \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629")
    $c = $c.Replace("لم يتم استكمال المراحل الاختيارية المطلوبة", "\u0644\u0645 \u064a\u062a\u0645 \u0627\u0633\u062a\u0643\u0645\u0627\u0644 \u0627\u0644\u0645\u0631\u0627\u062d\u0644 \u0627\u0644\u0627\u062e\u062a\u064a\u0627\u0631\u064a\u0629 \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629")
    $c = $c.Replace("ÙØ¬Ø¨ Ø¥Ø¯Ø®Ø§Ù ØªÙÙÙÙ ÙØ§Ø­Ø¯ Ø¹ÙÙ Ø§ÙØ£ÙÙ ÙØ¨Ù Ø§ÙÙØªØ§Ø¨Ø¹Ø©", "\u064a\u062c\u0628 \u0625\u062f\u062e\u0627\u0644 \u062a\u0642\u064a\u064a\u0645 \u0648\u0627\u062d\u062f \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644 \u0642\u0628\u0644 \u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629")
    $c = $c.Replace("يجب إدخال تقييم واحد على الأقل قبل المتابعة", "\u064a\u062c\u0628 \u0625\u062f\u062e\u0627\u0644 \u062a\u0642\u064a\u064a\u0645 \u0648\u0627\u062d\u062f \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644 \u0642\u0628\u0644 \u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629")
    $c = $c.Replace("ØªÙ Ø±ÙØ¶ Ø§ÙØ£ØµÙ Ø¨ÙØ¬Ø§Ø­", "\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0623\u0635\u0644 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("تم رفض الأصل بنجاح", "\u062a\u0645 \u0631\u0641\u0636 \u0627\u0644\u0623\u0635\u0644 \u0628\u0646\u062c\u0627\u062d")
    $c = $c.Replace("Workflow already completed", "Workflow already completed")
    $c = $c.Replace("ØªÙ Ø§ÙØ§ÙØªÙØ§Ù Ø¥ÙÙ: ", "\u062a\u0645 \u0627\u0644\u0627\u0646\u062a\u0642\u0627\u0644 \u0625\u0644\u0649: ")
    $c = $c.Replace("تم الانتقال إلى: ", "\u062a\u0645 \u0627\u0644\u0627\u0646\u062a\u0642\u0627\u0644 \u0625\u0644\u0649: ")
    [System.IO.File]::WriteAllText($svc, $c, $enc)
    Write-Host "  OK: WorkflowService.cs" -ForegroundColor Green
}

cd "$env:USERPROFILE\Desktop\AssetManagement"
dotnet build 2>&1 | Select-Object -Last 4
if ($LASTEXITCODE -eq 0) {
    Write-Host "DONE! All TempData messages fixed in Arabic." -ForegroundColor Green
    dotnet run --project AssetManagement.Web
}