param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$DocumentName = ''
)

$ErrorActionPreference = 'Stop'
$rendered = Join-Path $ProjectRoot 'manuscript\journal_submission\marine_environmental_research\rendered'
$output = Join-Path $ProjectRoot 'manuscript\journal_submission\marine_environmental_research\audits\page_renders'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$documents = Get-ChildItem -LiteralPath $rendered -Filter '*.docx' | Where-Object { -not $DocumentName -or $_.Name -eq $DocumentName } | Sort-Object Name
if ($documents.Count -eq 0) { throw "No DOCX matched '$DocumentName'." }
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$powerPoint = New-Object -ComObject PowerPoint.Application
try {
    foreach ($file in $documents) {
        $docOutput = Join-Path $output $file.BaseName
        New-Item -ItemType Directory -Force -Path $docOutput | Out-Null
        $doc = $word.Documents.Open($file.FullName, $false, $true)
        $deck = $powerPoint.Presentations.Add()
        try {
            $pageCount = $doc.ComputeStatistics(2)
            $deck.PageSetup.SlideWidth = $doc.Sections.Item(1).PageSetup.PageWidth
            $deck.PageSetup.SlideHeight = $doc.Sections.Item(1).PageSetup.PageHeight
            for ($page = 1; $page -le $pageCount; $page++) {
                $pageStart = $doc.GoTo(1, 1, $page)
                $pageStart.Select()
                $range = $doc.Bookmarks.Item('\Page').Range
                $range.CopyAsPicture()
                Start-Sleep -Milliseconds 250
                $slide = $deck.Slides.Add($deck.Slides.Count + 1, 12)
                $shapes = $slide.Shapes.PasteSpecial(2)
                if ($shapes.Count -lt 1) { throw "Clipboard rendering failed for $($file.Name), page $page." }
                $shape = $shapes.Item(1)
                try {
                    $path = Join-Path $docOutput ('page-{0:D3}.png' -f $page)
                    $shape.LockAspectRatio = -1
                    $shape.Left = 0
                    $shape.Top = 0
                    if ($shape.Width -gt $deck.PageSetup.SlideWidth) { $shape.Width = $deck.PageSetup.SlideWidth }
                    if ($shape.Height -gt $deck.PageSetup.SlideHeight) { $shape.Height = $deck.PageSetup.SlideHeight }
                    $slide.Export((Resolve-Path $docOutput).Path + '\' + ('page-{0:D3}.png' -f $page), 'PNG', 1275, 1650)
                }
                finally { [Runtime.InteropServices.Marshal]::ReleaseComObject($shape) | Out-Null }
            }
        }
        finally {
            try { $deck.Close() } catch { Write-Warning "Deck close warning for $($file.Name): $($_.Exception.Message)" }
            try { $doc.Close($false) } catch { Write-Warning "Document close warning for $($file.Name): $($_.Exception.Message)" }
            if ($deck) { [Runtime.InteropServices.Marshal]::ReleaseComObject($deck) | Out-Null }
            if ($doc) { [Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null }
        }
    }
}
finally {
    try { $word.Quit() } catch { Write-Warning "Word quit warning: $($_.Exception.Message)" }
    try { $powerPoint.Quit() } catch { Write-Warning "PowerPoint quit warning: $($_.Exception.Message)" }
    [Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    [Runtime.InteropServices.Marshal]::ReleaseComObject($powerPoint) | Out-Null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Host "Rendered $($documents.Count) DOCX files to page images."
