param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$SkipPdf
)

$ErrorActionPreference = 'Stop'
$journalRoot = Join-Path $ProjectRoot 'manuscript\journal_submission\marine_environmental_research'
$sourceDir = Join-Path $journalRoot 'source'
$renderedDir = Join-Path $journalRoot 'rendered'
$figureDir = Join-Path $journalRoot 'figures'
New-Item -ItemType Directory -Force -Path $renderedDir,$figureDir | Out-Null

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
if (-not (Test-Path -LiteralPath $pandoc)) { throw 'Pandoc was not found.' }

$browserCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe')
)
$browser = $browserCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $browser) { throw 'A Chromium browser was not found for high-resolution artwork export.' }

function Copy-WithRetry([string]$Source, [string]$Destination) {
    for ($attempt = 1; $attempt -le 20; $attempt++) {
        try {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force -ErrorAction Stop
            return
        }
        catch {
            if ($attempt -eq 20) { throw }
            Start-Sleep -Milliseconds 500
        }
    }
}

$figureMap = [ordered]@{
    'figure1_workflow_v2.svg' = 'Figure_1.png'
    'figure2_primary_guild_v2.svg' = 'Figure_2.png'
    'figure3_event_time_v2.svg' = 'Figure_3.png'
    'figure4_focal_specificity_v2.svg' = 'Figure_4.png'
    'figure4_wcvi_robustness_v2.svg' = 'Figure_5.png'
    'figureS1_priority_species_v2.svg' = 'Figure_S1.png'
    'figureS2_pooling_row_disposition_v2.svg' = 'Figure_S2.png'
    'figureS3_pooling_tau_v2.svg' = 'Figure_S3.png'
    'figureS4_model_diagnostics_v2.svg' = 'Figure_S4.png'
    'figure5_placebo_v2.svg' = 'Figure_S5.png'
}

foreach ($existing in Get-ChildItem -LiteralPath $figureDir -File) {
    Remove-Item -LiteralPath $existing.FullName -Force
}
foreach ($entry in $figureMap.GetEnumerator()) {
    $svg = if ($entry.Key -eq 'figure1_workflow_v2.svg') {
        Join-Path $journalRoot 'source_artwork\Figure_1.svg'
    } elseif ($entry.Key -eq 'figure4_focal_specificity_v2.svg') {
        Join-Path $journalRoot 'source_artwork\Figure_4.svg'
    } else {
        Join-Path $ProjectRoot ('manuscript\figures\' + $entry.Key)
    }
    $svgText = Get-Content -Raw -LiteralPath $svg
    $widthMatch = [regex]::Match($svgText, '<svg[^>]*width=[''\"](\d+)')
    $heightMatch = [regex]::Match($svgText, '<svg[^>]*height=[''\"](\d+)')
    $width = if ($widthMatch.Success) { [int]$widthMatch.Groups[1].Value } else { 1200 }
    $height = if ($heightMatch.Success) { [int]$heightMatch.Groups[1].Value } else { 800 }
    $png = Join-Path $figureDir $entry.Value
    $uri = [System.Uri]::new($svg).AbsoluteUri
    & $browser --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files `
        --force-device-scale-factor=4 --window-size="$width,$height" --screenshot="$png" $uri | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $png) -or (Get-Item $png).Length -eq 0) {
        throw "High-resolution export failed: $svg"
    }
}

function Add-ReviewFormatting([string]$Path, [bool]$Blinded) {
    $doc = $script:word.Documents.Open($Path, $false, $false)
    try {
        foreach ($section in $doc.Sections) {
            $section.PageSetup.LineNumbering.Active = $true
            $section.PageSetup.LineNumbering.StartingNumber = 1
            $section.PageSetup.LineNumbering.CountBy = 1
            $section.PageSetup.LineNumbering.RestartMode = 0
            $footer = $section.Footers.Item(1)
            $footer.Range.Text = 'Page '
            $footer.Range.ParagraphFormat.Alignment = 1
            $range = $footer.Range
            $range.Collapse(0)
            $null = $footer.Range.Fields.Add($range, -1, 'PAGE')
        }
        try { $doc.BuiltInDocumentProperties.Item('Author').Value = $(if ($Blinded) { 'Anonymous' } else { 'Jacob T. Dingwall' }) } catch {}
        try { $doc.BuiltInDocumentProperties.Item('Last Author').Value = $(if ($Blinded) { 'Anonymous' } else { 'Jacob T. Dingwall' }) } catch {}
        try { $doc.BuiltInDocumentProperties.Item('Company').Value = $(if ($Blinded) { '' } else { 'University of Victoria' }) } catch {}
        $doc.Save()
    }
    finally { $doc.Close($false) }
}

function Export-Pdf([string]$Path) {
    $pdf = [System.IO.Path]::ChangeExtension($Path, '.pdf')
    $doc = $script:word.Documents.Open($Path, $false, $true)
    try { $doc.ExportAsFixedFormat($pdf, 17, $false, 0) }
    finally { $doc.Close($false) }
    if (-not (Test-Path -LiteralPath $pdf) -or (Get-Item $pdf).Length -eq 0) { throw "PDF export failed: $pdf" }
}

Push-Location $ProjectRoot
try {
    $env:RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE'
    $qmds = @(
        'mer_manuscript_unblinded_v2.qmd',
        'mer_manuscript_blinded_companion_v2.qmd',
        'mer_supplement_v2.qmd',
        'mer_supplement_blinded_companion_v2.qmd'
    )
    foreach ($qmd in $qmds) {
        $stageName = '.' + [System.IO.Path]::GetFileNameWithoutExtension($qmd)
        $stage = Join-Path $renderedDir $stageName
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
        $sourceRel = 'manuscript/journal_submission/marine_environmental_research/source/' + $qmd
        & $quarto render $sourceRel --output-dir ("../rendered/" + $stageName)
        if ($LASTEXITCODE -ne 0) { throw "Quarto render failed: $qmd" }
        $stem = [System.IO.Path]::GetFileNameWithoutExtension($qmd)
        Copy-WithRetry (Join-Path $stage ($stem + '.docx')) $renderedDir
        Copy-WithRetry (Join-Path $stage ($stem + '.html')) $renderedDir
        Remove-Item -LiteralPath $stage -Recurse -Force
    }

    $markdownDocs = [ordered]@{
        'mer_title_page_v2.md' = 'mer_title_page_v2.docx'
        'mer_abstract_v2.md' = 'mer_abstract_v2.docx'
        'mer_highlights_v2.md' = 'mer_highlights_v2.docx'
        'mer_cover_letter_v2.md' = 'mer_cover_letter_v2.docx'
        'mer_author_declarations_v2.md' = 'mer_author_declarations_v2.docx'
        'mer_reviewer_expertise_v2.md' = 'mer_reviewer_expertise_v2.docx'
        'mer_response_to_reviewers_template_v2.md' = 'mer_response_to_reviewers_template_v2.docx'
        'mer_reporting_checklist_v2.md' = 'mer_reporting_checklist_v2.docx'
        'mer_title_options_v2.md' = 'mer_title_options_v2.docx'
    }
    foreach ($entry in $markdownDocs.GetEnumerator()) {
        & $pandoc (Join-Path $sourceDir $entry.Key) --from gfm --standalone --output (Join-Path $renderedDir $entry.Value)
        if ($LASTEXITCODE -ne 0) { throw "Pandoc render failed: $($entry.Key)" }
    }
    Copy-Item -LiteralPath (Join-Path $sourceDir 'mer_highlights_v2.md') -Destination (Join-Path $renderedDir 'mer_highlights_v2.txt') -Force

    $word = $null
    try {
        $word = New-Object -ComObject Word.Application
        $word.Visible = $false
        $word.DisplayAlerts = 0
        $script:word = $word
        Add-ReviewFormatting (Join-Path $renderedDir 'mer_manuscript_unblinded_v2.docx') $false
        Add-ReviewFormatting (Join-Path $renderedDir 'mer_manuscript_blinded_companion_v2.docx') $true
        Add-ReviewFormatting (Join-Path $renderedDir 'mer_supplement_v2.docx') $false
        Add-ReviewFormatting (Join-Path $renderedDir 'mer_supplement_blinded_companion_v2.docx') $true
        if (-not $SkipPdf) {
            Get-ChildItem -LiteralPath $renderedDir -Filter *.docx | ForEach-Object { Export-Pdf $_.FullName }
        }
    }
    finally {
        if ($word) {
            $word.Quit()
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
        }
        Remove-Variable -Scope Script -Name word -ErrorAction SilentlyContinue
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
    }
}
finally { Pop-Location }

Write-Host 'Marine Environmental Research submission files rendered.'
