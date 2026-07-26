param(
    [ValidateSet('fixture', 'production')]
    [string]$Mode = 'fixture'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $PSScriptRoot 'Stage3Phase2SupportAudit.cs'

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw 'The archived Stage 3 Phase 2 linkage implementation is unavailable.'
}

# Compile an additive copy of the archived linkage implementation. Only the
# class name and maximum source-point distance are changed. The historical
# source file and its 20 km cache remain untouched.
$source = Get-Content -LiteralPath $sourcePath -Raw
$source = $source.Replace(
    'public static class Stage3Phase2SupportAudit',
    'public static class PostStage4aDistance26LinkBuilder'
)
$source = $source.Replace(
    'if (distance > 20.0) continue;',
    'if (distance > 26.0) continue;'
)
$source = $source.Replace(
    'link.DistanceKm < 0 || link.DistanceKm > 20.0001)',
    'link.DistanceKm < 0 || link.DistanceKm > 26.0001)'
)

if ($source -match 'public static class Stage3Phase2SupportAudit' -or
    $source -match 'if \(distance > 20\.0\) continue;' -or
    $source -match 'link\.DistanceKm > 20\.0001') {
    throw 'The linkage source transformation was incomplete.'
}

Add-Type -TypeDefinition $source -Language CSharp
[PostStage4aDistance26LinkBuilder]::RunFixture()

if ($Mode -eq 'fixture') {
    Write-Output 'POST_STAGE4A_DISTANCE_26KM_LINK_FIXTURE=PASS'
    exit 0
}

if ($env:POST_STAGE4A_DISTANCE_26KM_LINKS_AUTHORIZED -ne
    'through_2025_metadata_links_26km_v2') {
    throw @'
Production requires:
$env:POST_STAGE4A_DISTANCE_26KM_LINKS_AUTHORIZED =
  "through_2025_metadata_links_26km_v2"
'@
}

$environmentFile = Join-Path $repoRoot '.Renviron'
if (Test-Path -LiteralPath $environmentFile) {
    foreach ($line in Get-Content -LiteralPath $environmentFile) {
        if ($line -match
            '^\s*(HERRING_EBIRD_V2_(EBD|SED|HERRING))\s*=\s*(.+?)\s*$') {
            $name = $matches[1]
            $value = $matches[3].Trim('"').Trim("'")
            [Environment]::SetEnvironmentVariable($name, $value, 'Process')
        }
    }
}

$ebdPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_EBD')
$sedPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_SED')
$herringPath =
    [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_HERRING')
if ([string]::IsNullOrWhiteSpace($ebdPath) -or
    [string]::IsNullOrWhiteSpace($sedPath) -or
    [string]::IsNullOrWhiteSpace($herringPath)) {
    throw 'Configured protected metadata inputs are required.'
}

$protectedRoot = Join-Path $repoRoot `
    'data/derived/post_stage4a_distance_band_sensitivity_v2_protected'
$linkDirectory = Join-Path $protectedRoot 'link_builder'
$auditDirectory = Join-Path $protectedRoot 'link_builder_audit'
New-Item -ItemType Directory -Force -Path $linkDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $auditDirectory | Out-Null

$existingMembership = Join-Path $repoRoot `
    'data/derived/stage3_phase2_protected/ebd_event_membership_date_gate.tsv.gz'
$reusedMembership = Join-Path $linkDirectory `
    'ebd_event_membership_date_gate.tsv.gz'
if (-not (Test-Path -LiteralPath $existingMembership)) {
    throw 'The archived EBD membership/date cache is unavailable.'
}
if (-not (Test-Path -LiteralPath $reusedMembership)) {
    Copy-Item -LiteralPath $existingMembership -Destination $reusedMembership
}

[PostStage4aDistance26LinkBuilder]::RunProduction(
    $ebdPath,
    $sedPath,
    $herringPath,
    $repoRoot,
    $linkDirectory,
    $auditDirectory
)

$extendedLinks = Join-Path $linkDirectory `
    'metadata_source_point_links.tsv.gz'
if (-not (Test-Path -LiteralPath $extendedLinks)) {
    throw 'The extended protected link cache was not created.'
}

Write-Output 'POST_STAGE4A_DISTANCE_26KM_LINK_BUILD=PASS'
