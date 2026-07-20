param(
  [ValidateSet('production','fixture','extract')][string]$Mode = 'production',
  [string]$AnalysisTaxonId,
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'Stage3Phase1Denominator.cs')

if ($Mode -eq 'fixture') {
  [Stage3Phase1Denominator]::RunFixture()
  exit 0
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$protectedDirectory = Join-Path $repoRoot 'data/derived/stage3_phase1_repair_protected'
if ($Mode -eq 'extract') {
  if ([string]::IsNullOrWhiteSpace($AnalysisTaxonId) -or [string]::IsNullOrWhiteSpace($OutputPath)) {
    throw 'Factorized extraction requires AnalysisTaxonId and OutputPath'
  }
  [Stage3Phase1Denominator]::ExtractSpeciesFromFactorized(
    $repoRoot, $protectedDirectory, $AnalysisTaxonId, $OutputPath
  )
  exit 0
}

$ebdPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_EBD')
$sedPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_SED')
if ([string]::IsNullOrWhiteSpace($ebdPath) -or [string]::IsNullOrWhiteSpace($sedPath)) {
  throw 'Configured protected EBD and SED environment variables are required'
}

$aggregateDirectory = Join-Path $repoRoot 'outputs/stage3_phase1_repair'
[Stage3Phase1Denominator]::RunProduction(
  $ebdPath, $sedPath, $repoRoot, $protectedDirectory, $aggregateDirectory
)
