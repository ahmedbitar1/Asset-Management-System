using ClosedXML.Excel;

var wb = new XLWorkbook();
var ws = wb.Worksheets.Add("Assets");

var headers = new[] {
    "\u0627\u0633\u0645 \u0627\u0644\u0639\u0642\u0627\u0631",
    "\u0627\u0644\u0645\u0648\u0642\u0639",
    "\u0627\u0644\u0645\u062f\u064a\u0646\u0629",
    "\u0627\u0644\u062d\u064a",
    "\u0627\u0644\u0645\u0633\u0627\u062d\u0629",
    "\u0648\u062d\u062f\u0629 \u0627\u0644\u0645\u0633\u0627\u062d\u0629",
    "\u0646\u0648\u0639 \u0627\u0644\u0623\u0635\u0644",
    "\u0631\u0642\u0645 \u0627\u0644\u0635\u0643",
    "\u0631\u0642\u0645 \u0627\u0644\u0642\u0637\u0639\u0629",
    "\u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0642\u0627\u0646\u0648\u0646\u064a\u0629",
    "\u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0634\u0631\u0627\u0621",
    "\u0633\u0639\u0631 \u0627\u0644\u0634\u0631\u0627\u0621",
    "\u0645\u0644\u0627\u062d\u0638\u0627\u062a"
};

for (int i = 0; i < headers.Length; i++) {
    var cell = ws.Cell(1, i + 1);
    cell.Value = headers[i];
    cell.Style.Font.Bold = true;
    cell.Style.Font.FontName = "Cairo";
    cell.Style.Font.FontColor = XLColor.White;
    cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#1a56db");
    cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
    cell.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
    cell.Style.Alignment.WrapText = true;
    cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
}
ws.Row(1).Height = 35;

// sample data
var s1 = new object[] {"\u0639\u0642\u0627\u0631 \u0627\u0644\u0645\u0639\u0627\u062f\u064a", "\u0627\u0644\u0645\u0639\u0627\u062f\u064a", "\u0627\u0644\u0642\u0627\u0647\u0631\u0629", "\u0627\u0644\u0645\u0639\u0627\u062f\u064a \u0627\u0644\u062c\u062f\u064a\u062f\u0629", 300, "\u0645\u00b2", "\u0625\u064a\u062c\u0627\u0631", "", "", "", "2020-01-01", 3000000, ""};
var s2 = new object[] {"\u0623\u0631\u0636 \u0627\u0644\u0634\u064a\u062e \u0632\u0627\u064a\u062f", "\u0627\u0644\u0634\u064a\u062e \u0632\u0627\u064a\u062f", "\u0627\u0644\u062c\u064a\u0632\u0629", "", 1000, "\u0641\u062f\u0627\u0646", "\u0627\u0644\u0627\u062a\u0646\u064a\u0646", "", "", "", "", 8000000, ""};
var s3 = new object[] {"\u0639\u0642\u0627\u0631 \u0627\u0644\u062a\u062c\u0645\u0639 \u0627\u0644\u062e\u0627\u0645\u0633", "\u0627\u0644\u062a\u062c\u0645\u0639 \u0627\u0644\u062e\u0627\u0645\u0633", "\u0627\u0644\u0642\u0627\u0647\u0631\u0629", "\u0627\u0644\u062a\u062c\u0645\u0639", 500, "\u0645\u00b2", "\u0628\u064a\u0639", "12345", "A1", "", "2021-03-15", 5000000, ""};

var samples = new object[][] { s1, s2, s3 };
for (int r = 0; r < samples.Length; r++) {
    for (int c = 0; c < samples[r].Length; c++) {
        var cell = ws.Cell(r + 2, c + 1);
        cell.Value = samples[r][c]?.ToString() ?? "";
        cell.Style.Font.FontName = "Cairo";
        cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
        cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        if ((r + 2) % 2 == 0)
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#EEF4FF");
    }
}

// 50 empty rows
for (int r = samples.Length + 2; r <= samples.Length + 51; r++) {
    for (int c = 1; c <= headers.Length; c++) {
        var cell = ws.Cell(r, c);
        cell.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        if (r % 2 == 0)
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#F8FBFF");
    }
}

int[] widths = {25,20,15,15,10,15,18,18,18,35,15,15,25};
for (int i = 0; i < widths.Length; i++)
    ws.Column(i + 1).Width = widths[i];

// Instructions sheet
var ws2 = wb.Worksheets.Add("\u062a\u0639\u0644\u064a\u0645\u0627\u062a");
var tips = new (string col, string tip)[] {
    ("\u0627\u0633\u0645 \u0627\u0644\u0639\u0642\u0627\u0631",  "\u0645\u0637\u0644\u0648\u0628 - \u0627\u0633\u0645 \u0627\u0644\u0639\u0642\u0627\u0631 \u0628\u0627\u0644\u0643\u0627\u0645\u0644"),
    ("\u0627\u0644\u0645\u0648\u0642\u0639",                    "\u0645\u0637\u0644\u0648\u0628 - \u0627\u0644\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u062a\u0641\u0635\u064a\u0644\u064a"),
    ("\u0627\u0644\u0645\u062f\u064a\u0646\u0629",              "\u0627\u062e\u062a\u064a\u0627\u0631\u064a"),
    ("\u0627\u0644\u062d\u064a",                                "\u0627\u062e\u062a\u064a\u0627\u0631\u064a"),
    ("\u0627\u0644\u0645\u0633\u0627\u062d\u0629",              "\u0623\u0631\u0642\u0627\u0645 \u0641\u0642\u0637 \u0628\u062f\u0648\u0646 \u0648\u062d\u062f\u0629"),
    ("\u0648\u062d\u062f\u0629 \u0627\u0644\u0645\u0633\u0627\u062d\u0629", "\u0645\u00b2 \u0623\u0648 \u0641\u062f\u0627\u0646"),
    ("\u0646\u0648\u0639 \u0627\u0644\u0623\u0635\u0644",       "\u0628\u064a\u0639 \u0623\u0648 \u0625\u064a\u062c\u0627\u0631 \u0623\u0648 \u0627\u0644\u0627\u062a\u0646\u064a\u0646"),
    ("\u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0634\u0631\u0627\u0621", "YYYY-MM-DD \u0645\u062b\u0627\u0644: 2020-01-15"),
    ("\u0633\u0639\u0631 \u0627\u0644\u0634\u0631\u0627\u0621", "\u0623\u0631\u0642\u0627\u0645 \u0641\u0642\u0637 \u0628\u062f\u0648\u0646 \u0641\u0648\u0627\u0635\u0644"),
};

ws2.Cell(1,1).Value = "\u0627\u0644\u062d\u0642\u0644";
ws2.Cell(1,2).Value = "\u062a\u0639\u0644\u064a\u0645\u0627\u062a";
ws2.Cell(1,1).Style.Font.Bold = true;
ws2.Cell(1,2).Style.Font.Bold = true;
ws2.Cell(1,1).Style.Fill.BackgroundColor = XLColor.FromHtml("#1a56db");
ws2.Cell(1,2).Style.Fill.BackgroundColor = XLColor.FromHtml("#1a56db");
ws2.Cell(1,1).Style.Font.FontColor = XLColor.White;
ws2.Cell(1,2).Style.Font.FontColor = XLColor.White;

for (int i = 0; i < tips.Length; i++) {
    ws2.Cell(i+2,1).Value = tips[i].col;
    ws2.Cell(i+2,2).Value = tips[i].tip;
    ws2.Cell(i+2,1).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
    ws2.Cell(i+2,2).Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
    if ((i+2) % 2 == 0) {
        ws2.Cell(i+2,1).Style.Fill.BackgroundColor = XLColor.FromHtml("#EEF4FF");
        ws2.Cell(i+2,2).Style.Fill.BackgroundColor = XLColor.FromHtml("#EEF4FF");
    }
}
ws2.Column(1).Width = 25;
ws2.Column(2).Width = 45;

var path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "AssetImportTemplate.xlsx");
wb.SaveAs(path);
Console.WriteLine("Saved: " + path);