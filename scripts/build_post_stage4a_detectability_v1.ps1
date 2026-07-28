param(
    [ValidateSet('fixture', 'production')]
    [string]$Mode = 'fixture'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$builder = Join-Path $PSScriptRoot 'PostStage4ADetectabilityBuilder.cs'
Add-Type -Path $builder

if ($Mode -eq 'fixture') {
    [PostStage4ADetectabilityBuilder]::RunFixture()
    exit 0
}

$expected = 'through_2025_post_result_refinement_v1'
$acknowledgement = [Environment]::GetEnvironmentVariable(
    'POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED',
    'Process'
)
if ($acknowledgement -cne $expected) {
    throw @'
Production requires the exact author-set current-shell acknowledgement.
This builder does not set the acknowledgement.
'@
}

$sedPath = [Environment]::GetEnvironmentVariable(
    'HERRING_EBIRD_V2_SED',
    'Process'
)
$environmentFile = Join-Path $repoRoot '.Renviron'
if ([string]::IsNullOrWhiteSpace($sedPath) -and
    (Test-Path -LiteralPath $environmentFile)) {
    foreach ($line in Get-Content -LiteralPath $environmentFile) {
        if ($line -match
            '^\s*(HERRING_EBIRD_V2_SED)\s*=\s*(.+?)\s*$') {
            $sedPath = $matches[2].Trim('"').Trim("'")
        }
    }
}
if ([string]::IsNullOrWhiteSpace($sedPath) -or
    -not (Test-Path -LiteralPath $sedPath)) {
    throw 'Configured protected SED metadata input is unavailable.'
}

$protectedDirectory = Join-Path $repoRoot `
    'data/derived/post_stage4a_staged_refit_stage2_v1'
[PostStage4ADetectabilityBuilder]::RunProduction(
    $sedPath,
    $repoRoot,
    $protectedDirectory
)
