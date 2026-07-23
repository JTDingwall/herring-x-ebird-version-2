param(
    [ValidateSet('fixture', 'production')]
    [string]$Mode = 'fixture'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot 'run_post_stage4a_sog_event_study_v1.R'

if (-not (Get-Command Rscript -ErrorAction SilentlyContinue)) {
    throw 'Rscript is not available on PATH.'
}
if ($Mode -eq 'production' -and
    $env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED -ne
        'through_2025_post_result_refinement_v1') {
    throw @'
Production requires:
$env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED =
  "through_2025_post_result_refinement_v1"
'@
}

$env:RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE'
$projectLibrary = Join-Path $repoRoot 'renv\library\windows\R-4.5\x86_64-w64-mingw32'
if (Test-Path -LiteralPath $projectLibrary) {
    $env:R_LIBS_USER = $projectLibrary
}

Push-Location $repoRoot
try {
    & Rscript --no-init-file $runner $Mode
    if ($LASTEXITCODE -ne 0) {
        throw "Event-study runner exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
