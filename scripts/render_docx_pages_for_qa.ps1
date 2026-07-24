param(
  [Parameter(Mandatory = $true)]
  [string]$DocxPath,
  [Parameter(Mandatory = $true)]
  [string]$OutputDir
)

$ErrorActionPreference = "Stop"
$docx = (Resolve-Path -LiteralPath $DocxPath).Path
$output = [System.IO.Path]::GetFullPath($OutputDir)
New-Item -ItemType Directory -Path $output -Force | Out-Null

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$powerPoint = New-Object -ComObject PowerPoint.Application

try {
  $document = $word.Documents.Open($docx, $false, $true)
  $pages = $document.ComputeStatistics(2)
  $presentation = $powerPoint.Presentations.Add()
  $presentation.PageSetup.SlideWidth = $document.PageSetup.PageWidth
  $presentation.PageSetup.SlideHeight = $document.PageSetup.PageHeight

  for ($page = 1; $page -le $pages; $page++) {
    $range = $document.GoTo(1, 1, $page)
    if ($page -lt $pages) {
      $next = $document.GoTo(1, 1, $page + 1)
      $range.End = $next.Start - 1
    } else {
      $range.End = $document.Content.End
    }
    $range.CopyAsPicture()
    Start-Sleep -Milliseconds 150

    $slide = $presentation.Slides.Add(1, 12)
    $pasted = $slide.Shapes.PasteSpecial(2)
    $shape = $pasted.Item(1)
    $shape.LockAspectRatio = -1
    $maxWidth = $presentation.PageSetup.SlideWidth - 8
    $maxHeight = $presentation.PageSetup.SlideHeight - 8
    if (($shape.Width / $shape.Height) -gt ($maxWidth / $maxHeight)) {
      $shape.Width = $maxWidth
    } else {
      $shape.Height = $maxHeight
    }
    $shape.Left = (
      $presentation.PageSetup.SlideWidth - $shape.Width
    ) / 2
    $shape.Top = (
      $presentation.PageSetup.SlideHeight - $shape.Height
    ) / 2

    $pagePath = Join-Path $output ("page-{0:D3}.png" -f $page)
    $slide.Export($pagePath, "PNG", 1224, 1584)
    $slide.Delete()
  }
  $presentation.Slides.Add(1, 12) | Out-Null
  $presentation.Saved = -1
  try {
    $presentation.Close()
  } catch {
    Write-Output "PAGE_PRESENTATION_CLOSE_WARNING=temporary_close_failed"
  }

  $pageImages = @(
    Get-ChildItem -LiteralPath $output -Filter "page-*.png" |
      Sort-Object Name
  )
  $contact = $powerPoint.Presentations.Add()
  $contact.PageSetup.SlideWidth = 960
  $contact.PageSetup.SlideHeight = 720
  $columns = 4
  $rows = 4
  $perSheet = $columns * $rows
  $cellWidth = $contact.PageSetup.SlideWidth / $columns
  $cellHeight = $contact.PageSetup.SlideHeight / $rows
  $sheets = [Math]::Ceiling($pageImages.Count / $perSheet)

  for ($sheetIndex = 0; $sheetIndex -lt $sheets; $sheetIndex++) {
    $slide = $contact.Slides.Add(1, 12)
    for ($slot = 0; $slot -lt $perSheet; $slot++) {
      $imageIndex = $sheetIndex * $perSheet + $slot
      if ($imageIndex -ge $pageImages.Count) {
        break
      }
      $column = $slot % $columns
      $row = [Math]::Floor($slot / $columns)
      $left = $column * $cellWidth + 4
      $top = $row * $cellHeight + 4
      $image = $slide.Shapes.AddPicture(
        $pageImages[$imageIndex].FullName,
        0,
        -1,
        $left,
        $top,
        -1,
        -1
      )
      $image.LockAspectRatio = -1
      $image.Height = $cellHeight - 20
      if ($image.Width -gt ($cellWidth - 8)) {
        $image.Width = $cellWidth - 8
      }
      $image.Left = $left + (($cellWidth - 8 - $image.Width) / 2)
      $label = $slide.Shapes.AddTextbox(
        1,
        $column * $cellWidth + 4,
        ($row + 1) * $cellHeight - 16,
        $cellWidth - 8,
        12
      )
      $label.TextFrame.TextRange.Text = (
        "Page {0}" -f ($imageIndex + 1)
      )
      $label.TextFrame.TextRange.Font.Size = 8
      $label.TextFrame.TextRange.ParagraphFormat.Alignment = 2
    }
    $contactPath = Join-Path $output (
      "contact-sheet-{0:D2}.png" -f ($sheetIndex + 1)
    )
    $slide.Export($contactPath, "PNG", 1920, 1440)
    $slide.Delete()
  }
  $contact.Slides.Add(1, 12) | Out-Null
  $contact.Saved = -1
  try {
    $contact.Close()
  } catch {
    Write-Output "CONTACT_PRESENTATION_CLOSE_WARNING=temporary_close_failed"
  }
  $document.Close(0)

  Write-Output "DOCX_PAGE_RENDER=PASS"
  Write-Output "PAGES=$pages"
  Write-Output "CONTACT_SHEETS=$sheets"
} finally {
  try { $word.Quit() } catch {}
  try { $powerPoint.Quit() } catch {}
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) |
    Out-Null
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($powerPoint) |
    Out-Null
}
