param(
  [ValidateSet('production','fixture')][string]$Mode = 'production'
)

$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'Stage3Phase1Denominator.cs')

if ($Mode -eq 'fixture') {
  [Stage3Phase1Denominator]::RunFixture()
  exit 0
}

$ebdPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_EBD')
$sedPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_SED')
if ([string]::IsNullOrWhiteSpace($ebdPath) -or [string]::IsNullOrWhiteSpace($sedPath)) {
  throw 'Configured protected EBD and SED environment variables are required'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$protectedDirectory = Join-Path $repoRoot 'data/derived/stage3_phase1_protected'
$aggregateDirectory = Join-Path $repoRoot 'outputs/stage3_phase1'
[Stage3Phase1Denominator]::RunProduction(
  $ebdPath, $sedPath, $repoRoot, $protectedDirectory, $aggregateDirectory
)
