param([ValidateSet('production','fixture')][string]$Mode = 'fixture')

$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'Stage4AProtectedBuilder.cs')
if ($Mode -eq 'fixture') {
  [Stage4AProtectedBuilder]::RunFixture()
  exit 0
}
if ($env:STAGE4A_AUTHORIZED_RESPONSE_ACCESS -ne 'through_2025_after_lock_ci') {
  throw 'Production requires the post-lock Stage 4A response-access acknowledgement'
}
$repoRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $repoRoot '.Renviron'
if (Test-Path -LiteralPath $environmentFile) {
  foreach ($line in Get-Content -LiteralPath $environmentFile) {
    if ($line -match '^\s*(HERRING_EBIRD_V2_SED)\s*=\s*(.+?)\s*$') {
      [Environment]::SetEnvironmentVariable($matches[1], $matches[2].Trim('"').Trim("'"), 'Process')
    }
  }
}
$sedPath = [Environment]::GetEnvironmentVariable('HERRING_EBIRD_V2_SED')
if ([string]::IsNullOrWhiteSpace($sedPath)) { throw 'Configured protected SED metadata input is required' }
$protectedDirectory = Join-Path $repoRoot 'data/derived/stage4a_protected'
[Stage4AProtectedBuilder]::RunProduction($sedPath, $repoRoot, $protectedDirectory)
