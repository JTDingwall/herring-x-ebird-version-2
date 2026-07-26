param(
    [ValidateSet('fixture', 'production')]
    [string]$Mode = 'fixture'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot `
    'run_post_stage4a_distance_band_sensitivity_v2.R'

if (-not (Get-Command Rscript -ErrorAction SilentlyContinue)) {
    throw 'Rscript is not available on PATH.'
}
if ($Mode -eq 'production' -and
    $env:POST_STAGE4A_DISTANCE_BAND_SENSITIVITY_V2_AUTHORIZED -ne
        'through_2025_bald_eagle_distance_bands_26km_v2') {
    throw @'
Production requires:
$env:POST_STAGE4A_DISTANCE_BAND_SENSITIVITY_V2_AUTHORIZED =
  "through_2025_bald_eagle_distance_bands_26km_v2"
'@
}

$env:RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE'
$projectLibrary = Join-Path $repoRoot `
    'renv\library\windows\R-4.5\x86_64-w64-mingw32'
if (Test-Path -LiteralPath $projectLibrary) {
    $env:R_LIBS_USER = $projectLibrary
}

Push-Location $repoRoot
try {
    & Rscript --no-init-file --no-site-file $runner $Mode
    if ($LASTEXITCODE -ne 0) {
        throw "Distance-band v2 runner exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
