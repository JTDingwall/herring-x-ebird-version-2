param(
    [ValidateSet('fixture', 'production')]
    [string]$Mode = 'fixture',
    [int]$Workers = 0,
    [double]$KenwardRogerBudgetGb = 12
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$rRunner = Join-Path $PSScriptRoot 'run_post_stage4a_blockaware_v1.R'

if (-not (Get-Command Rscript -ErrorAction SilentlyContinue)) {
    throw 'Rscript is not available on PATH.'
}
if ($Mode -eq 'production') {
    $expected = 'through_2025_post_result_refinement_v1'
    $actual = [Environment]::GetEnvironmentVariable(
        'POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED',
        'Process'
    )
    if ($actual -cne $expected) {
        throw @'
Production requires the exact author-set current-shell acknowledgement.
This runner does not set it.
'@
    }
}

$env:RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE'

# The frozen renv library stays read-only. pbkrtest and lmerTest live only in
# the separate versioned analysis library, which is prepended to the search
# path by the R runner.
$analysisLibrary = Join-Path $repoRoot `
    '.analysis-library\blockaware_v1\R-4.5\x86_64-w64-mingw32'
if (-not (Test-Path -LiteralPath $analysisLibrary)) {
    throw @"
The versioned analysis library is missing:
  $analysisLibrary
Create it and install pbkrtest and lmerTest into that path only.
"@
}
$projectLibrary = Join-Path $repoRoot `
    'renv\library\windows\R-4.5\x86_64-w64-mingw32'
if (Test-Path -LiteralPath $projectLibrary) {
    $env:R_LIBS_USER = "$analysisLibrary;$projectLibrary"
} else {
    $env:R_LIBS_USER = $analysisLibrary
}

if ($Workers -gt 0) {
    $env:POST_STAGE4A_BLOCKAWARE_WORKERS = "$Workers"
}
$env:POST_STAGE4A_BLOCKAWARE_KR_BUDGET_GB = "$KenwardRogerBudgetGb"

Push-Location $repoRoot
try {
    & Rscript --no-init-file --no-site-file $rRunner $Mode
    if ($LASTEXITCODE -ne 0) {
        throw "Block-aware runner exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
