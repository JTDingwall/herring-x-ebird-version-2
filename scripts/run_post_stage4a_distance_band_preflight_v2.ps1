param(
    [ValidateSet('links', 'support')]
    [string]$Mode = 'support'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectLibrary = Join-Path $repoRoot `
    'renv\library\windows\R-4.5\x86_64-w64-mingw32'
if (Test-Path -LiteralPath $projectLibrary) {
    $env:R_LIBS_USER = $projectLibrary
}
$env:RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE'

Push-Location $repoRoot
try {
    if ($Mode -eq 'links') {
        & (Join-Path $PSScriptRoot `
            'build_post_stage4a_distance_26km_links_v2.ps1') `
            -Mode production
    }
    else {
        & Rscript --no-init-file --no-site-file `
            (Join-Path $PSScriptRoot `
                'preflight_post_stage4a_distance_bands_v2.R')
        if ($LASTEXITCODE -ne 0) {
            throw "Distance-band preflight exited with code $LASTEXITCODE."
        }
    }
}
finally {
    Pop-Location
}
