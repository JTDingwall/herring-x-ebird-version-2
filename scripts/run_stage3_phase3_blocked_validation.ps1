param(
  [ValidateSet('production','fixture')][string]$Mode = 'production'
)

$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'Stage3Phase3BlockedValidation.cs')

if ($Mode -eq 'fixture') {
  [Stage3Phase3BlockedValidation]::RunFixture()
  exit 0
}

if ($env:STAGE3_AUTHORIZED_PHASE -ne 'phase_3') {
  throw 'Set STAGE3_AUTHORIZED_PHASE=phase_3 to acknowledge the registered Phase 3 hard stop'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $repoRoot '.Renviron'
if (Test-Path -LiteralPath $environmentFile) {
  foreach ($line in Get-Content -LiteralPath $environmentFile) {
    if ($line -match '^\s*(HERRING_EBIRD_V2_SED)\s*=\s*(.+?)\s*$') {
      [Environment]::SetEnvironmentVariable(
        $matches[1], $matches[2].Trim('"').Trim("'"), 'Process'
      )
    }
  }
}

$sedPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_SED')
if ([string]::IsNullOrWhiteSpace($sedPath)) {
  throw 'Configured protected SED metadata environment variable is required'
}

$protectedDirectory = Join-Path $repoRoot 'data/derived/stage3_phase3_protected'
$outputDirectory = Join-Path $repoRoot 'outputs/stage3_phase3_validation'
[Stage3Phase3BlockedValidation]::RunProduction(
  $sedPath, $repoRoot, $protectedDirectory, $outputDirectory
)
