param(
  [ValidateSet('production','fixture')][string]$Mode = 'production'
)

$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'Stage3Phase2SupportAudit.cs')

if ($Mode -eq 'fixture') {
  [Stage3Phase2SupportAudit]::RunFixture()
  exit 0
}

if ($env:STAGE3_AUTHORIZED_PHASE -ne 'phase_2') {
  throw 'Set STAGE3_AUTHORIZED_PHASE=phase_2 to acknowledge the registered Phase 2 hard stop'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $repoRoot '.Renviron'
if (Test-Path -LiteralPath $environmentFile) {
  foreach ($line in Get-Content -LiteralPath $environmentFile) {
    if ($line -match '^\s*(HERRING_EBIRD_V2_(EBD|SED|HERRING))\s*=\s*(.+?)\s*$') {
      $name = $matches[1]
      $value = $matches[3].Trim('"').Trim("'")
      [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
  }
}

$ebdPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_EBD')
$sedPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_SED')
$herringPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_HERRING')
if ([string]::IsNullOrWhiteSpace($ebdPath) -or
    [string]::IsNullOrWhiteSpace($sedPath) -or
    [string]::IsNullOrWhiteSpace($herringPath)) {
  throw 'Configured protected metadata input environment variables are required'
}

$protectedDirectory = Join-Path $repoRoot 'data/derived/stage3_phase2_protected'
$outputDirectory = Join-Path $repoRoot 'outputs/stage3_phase2_sampling_support'
[Stage3Phase2SupportAudit]::RunProduction(
  $ebdPath, $sedPath, $herringPath, $repoRoot, $protectedDirectory, $outputDirectory
)
