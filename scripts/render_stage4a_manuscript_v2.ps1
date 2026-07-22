param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$SkipPdf
)

$ErrorActionPreference = 'Stop'
$quartoCandidates = @(
    (Join-Path $env:ProgramFiles 'RStudio\resources\app\bin\quarto\bin\quarto.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'RStudio\resources\app\bin\quarto\bin\quarto.exe')
)
$quarto = $quartoCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $quarto) {
    $cmd = Get-Command quarto -ErrorAction SilentlyContinue
    if ($cmd) { $quarto = $cmd.Source }
}
if (-not $quarto) { throw 'Quarto was not found.' }

$pandoc = Join-Path (Split-Path $quarto -Parent) 'tools\pandoc.exe'
if (-not (Test-Path -LiteralPath $pandoc)) {
    $cmd = Get-Command pandoc -ErrorAction SilentlyContinue
    if ($cmd) { $pandoc = $cmd.Source }
}
if (-not (Test-Path -LiteralPath $pandoc)) { throw 'Pandoc was not found.' }

$rendered = Join-Path $ProjectRoot 'manuscript\rendered'
New-Item -ItemType Directory -Path $rendered -Force | Out-Null

$browserCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')
)
$browser = $browserCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $browser) { throw 'Microsoft Edge or Google Chrome was not found for deterministic SVG-to-PNG export.' }

Push-Location $ProjectRoot
try {
    $env:RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE'
    & Rscript --no-init-file scripts/build_stage4a_manuscript_package_v2.R .
    if ($LASTEXITCODE -ne 0) { throw 'Aggregate manuscript build failed.' }

    Get-ChildItem -LiteralPath manuscript/figures -Filter *.svg | ForEach-Object {
        $svgText = Get-Content -Raw -LiteralPath $_.FullName
        $widthMatch = [regex]::Match($svgText, '<svg[^>]*width=[''\"](\d+)')
        $heightMatch = [regex]::Match($svgText, '<svg[^>]*height=[''\"](\d+)')
        $width = if ($widthMatch.Success) { [int]$widthMatch.Groups[1].Value } else { 1200 }
        $height = if ($heightMatch.Success) { [int]$heightMatch.Groups[1].Value } else { 800 }
        $png = [System.IO.Path]::ChangeExtension($_.FullName, '.png')
        $uri = [System.Uri]::new($_.FullName).AbsoluteUri
        & $browser --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files `
            --force-device-scale-factor=2 --window-size="$width,$height" --screenshot="$png" $uri | Out-Null
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $png) -or (Get-Item $png).Length -eq 0) {
            throw "SVG-to-PNG export failed: $($_.FullName)"
        }
    }

    $mainStage = Join-Path $rendered '.main'
    $suppStage = Join-Path $rendered '.supp'
    foreach ($stage in @($mainStage, $suppStage)) {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    }
    & $quarto render manuscript/stage4a_manuscript_v2.qmd --output-dir rendered/.main
    if ($LASTEXITCODE -ne 0) { throw 'Main manuscript HTML/DOCX render failed.' }
    Copy-Item -LiteralPath (Join-Path $mainStage 'stage4a_manuscript_v2.html') -Destination $rendered -Force
    Copy-Item -LiteralPath (Join-Path $mainStage 'stage4a_manuscript_v2.docx') -Destination $rendered -Force

    & $quarto render manuscript/stage4a_supplement_v2.qmd --output-dir rendered/.supp
    if ($LASTEXITCODE -ne 0) { throw 'Supplement HTML/DOCX render failed.' }
    Copy-Item -LiteralPath (Join-Path $suppStage 'stage4a_supplement_v2.html') -Destination $rendered -Force
    Copy-Item -LiteralPath (Join-Path $suppStage 'stage4a_supplement_v2.docx') -Destination $rendered -Force
    Remove-Item -LiteralPath $mainStage -Recurse -Force
    Remove-Item -LiteralPath $suppStage -Recurse -Force

    & $pandoc manuscript/stage4a_cover_letter_template_v2.md --standalone --output manuscript/rendered/stage4a_cover_letter_template_v2.docx
    if ($LASTEXITCODE -ne 0) { throw 'Cover-letter DOCX render failed.' }

    if (-not $SkipPdf) {
        $word = $null
        try {
            $word = New-Object -ComObject Word.Application
            $word.Visible = $false
            $word.DisplayAlerts = 0
            $docxFiles = @(
                'stage4a_manuscript_v2.docx',
                'stage4a_supplement_v2.docx',
                'stage4a_cover_letter_template_v2.docx'
            )
            foreach ($name in $docxFiles) {
                $input = Join-Path $rendered $name
                if (-not (Test-Path -LiteralPath $input)) { throw "Missing DOCX: $input" }
                $pdf = [System.IO.Path]::ChangeExtension($input, '.pdf')
                $doc = $word.Documents.Open($input, $false, $true)
                try {
                    # wdExportFormatPDF = 17; wdExportOptimizeForPrint = 0.
                    $doc.ExportAsFixedFormat($pdf, 17, $false, 0)
                }
                finally {
                    $doc.Close($false)
                }
                if (-not (Test-Path -LiteralPath $pdf) -or (Get-Item $pdf).Length -eq 0) {
                    throw "PDF export failed: $pdf"
                }
            }
        }
        finally {
            if ($word) {
                $word.Quit()
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
            }
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
        }
    }
}
finally {
    Pop-Location
}

Write-Host 'Stage 4A manuscript HTML, DOCX, and requested PDF artifacts rendered.'
