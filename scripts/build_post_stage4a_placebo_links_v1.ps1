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

# Additive protected rebuild: preserve the frozen 20 km spatial rule and widen
# only the midpoint-relative temporal candidate window enough to evaluate all
# four amended fake-anchor offsets after conversion to the Stage 1 start anchor.
$source = Get-Content -LiteralPath $sourcePath -Raw
$source = $source.Replace(
    'public static class Stage3Phase2SupportAudit',
    'public static class PostStage4aPlaceboLinkBuilder'
)
$source = $source.Replace(
    'if (day < -90 || day > 120) continue;',
    'if (day < -270 || day > 240) continue;'
)
$source = $source.Replace(
    'link.EventDay < -90 || link.EventDay > 120 ||',
    'link.EventDay < -270 || link.EventDay > 240 ||'
)
if ($source -match 'public static class Stage3Phase2SupportAudit' -or
    $source -match 'if \(day < -90 \|\| day > 120\) continue;' -or
    $source -match
        'link\.EventDay < -90 \|\| link\.EventDay > 120 \|\|') {
    throw 'The placebo linkage source transformation was incomplete.'
}

Add-Type -TypeDefinition $source -Language CSharp
[PostStage4aPlaceboLinkBuilder]::RunFixture()

if ($Mode -eq 'fixture') {
    Write-Output 'POST_STAGE4A_PLACEBO_LINK_FIXTURE=PASS'
    exit 0
}

$authorizationPath = Join-Path $repoRoot `
    'metadata/post_stage4a_staged_refit_authorization_v1.yml'
$authorizationText = Get-Content -LiteralPath $authorizationPath -Raw
$match = [regex]::Match(
    $authorizationText,
    '(?m)^\s+value:\s*([^\r\n#]+?)\s*$'
)
if (-not $match.Success) {
    throw 'Unable to resolve the human acknowledgement from its record.'
}
$expectedAcknowledgement = $match.Groups[1].Value.Trim('"').Trim("'")
if ($env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED -ne
    $expectedAcknowledgement) {
    throw 'The exact author-set staged-refit acknowledgement is required.'
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
    'data/derived/post_stage4a_staged_refit_amendment_v1'
$linkDirectory = Join-Path $protectedRoot 'placebo_link_builder'
$auditDirectory = Join-Path $protectedRoot 'placebo_link_builder_audit'
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

[PostStage4aPlaceboLinkBuilder]::RunProduction(
    $ebdPath,
    $sedPath,
    $herringPath,
    $repoRoot,
    $linkDirectory,
    $auditDirectory
)

$placeboLinks = Join-Path $linkDirectory `
    'metadata_source_point_links.tsv.gz'
if (-not (Test-Path -LiteralPath $placeboLinks)) {
    throw 'The protected placebo link cache was not created.'
}

Write-Output 'POST_STAGE4A_PLACEBO_LINK_BUILD=PASS'
