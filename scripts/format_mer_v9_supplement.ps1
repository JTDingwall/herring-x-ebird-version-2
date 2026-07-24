param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$docx = Join-Path $ProjectRoot (
  "manuscript\journal_submission\marine_environmental_research\" +
  "rendered_v9\mer_supplement_v9.docx"
)
$qaDir = Join-Path $ProjectRoot (
  "manuscript\journal_submission\marine_environmental_research\" +
  "rendered_v9_qa"
)
$pdf = Join-Path $qaDir "mer_supplement_v9.pdf"
New-Item -ItemType Directory -Path $qaDir -Force | Out-Null

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
  $document = $word.Documents.Open($docx, $false, $false)
  foreach ($section in $document.Sections) {
    $section.PageSetup.TopMargin = 43.2
    $section.PageSetup.BottomMargin = 43.2
    $section.PageSetup.LeftMargin = 43.2
    $section.PageSetup.RightMargin = 43.2
    $section.PageSetup.DifferentFirstPageHeaderFooter = $false
    $footer = $section.Footers.Item(1)
    $footer.Range.Text = ""
    $footer.Range.ParagraphFormat.Alignment = 1
    $footer.Range.Fields.Add($footer.Range, 33) | Out-Null
  }

  foreach ($table in $document.Tables) {
    $table.AutoFitBehavior(2)
    $table.Range.Font.Name = "Times New Roman"
    $table.Range.Font.Size = 7.5
    $table.Range.ParagraphFormat.SpaceAfter = 0
    $table.Range.ParagraphFormat.LineSpacingRule = 0
    $table.Rows.AllowBreakAcrossPages = 0
    if ($table.Rows.Count -ge 1) {
      $table.Rows.Item(1).HeadingFormat = -1
      $table.Rows.Item(1).Range.Font.Bold = -1
    }
  }

  $document.Save()
  $document.ExportAsFixedFormat($pdf, 17)
  Write-Output "SUPPLEMENT_FORMAT=PASS"
  Write-Output ("TABLES=" + $document.Tables.Count)
  Write-Output ("PAGES=" + $document.ComputeStatistics(2))
  Write-Output "PDF=$pdf"
  $document.Close(0)
} finally {
  $word.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
