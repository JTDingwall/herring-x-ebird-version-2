param(
    [ValidateSet('fixture', 'production')]
    [string]$Mode = 'fixture'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot `
    'run_post_stage4a_staged_refit_amendment_v1.R'

if (-not (Get-Command Rscript -ErrorAction SilentlyContinue)) {
    throw 'Rscript is not available on PATH.'
}
if ($Mode -eq 'production' -and
    [string]::IsNullOrWhiteSpace(
        $env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED
    )) {
    throw @'
Production requires the author-set current-shell acknowledgement. The R
runner verifies its exact value against the committed authorization record.
This runner will not set the variable.
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
        throw "Amended staged-refit runner exited with code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
