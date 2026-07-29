param(
    [ValidateSet('fixture', 'production')]
    [string]$Mode = 'fixture'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$rRunner = Join-Path $PSScriptRoot `
    'run_post_stage4a_stage2_block_slope_diagnostic_v1.R'

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
$projectLibrary = Join-Path $repoRoot `
    'renv\library\windows\R-4.5\x86_64-w64-mingw32'
if (Test-Path -LiteralPath $projectLibrary) {
    $env:R_LIBS_USER = $projectLibrary
}

Push-Location $repoRoot
try {
    & Rscript --no-init-file --no-site-file $rRunner $Mode
    if ($LASTEXITCODE -ne 0) {
        throw "Block-slope runner exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

