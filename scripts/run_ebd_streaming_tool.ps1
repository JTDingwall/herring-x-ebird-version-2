param(
  [Parameter(Mandatory = $true)][ValidateSet('membership','focal')][string]$Mode,
  [string]$EbdEnv = 'HERRING_EBIRD_V2_EBD',
  [string]$SedEnv = 'HERRING_EBIRD_V2_SED',
  [string]$MissingOutput,
  [string]$StatsOutput,
  [string]$Patterns,
  [string]$Output
)

$ebdPath = [Environment]::GetEnvironmentVariable($EbdEnv)
if ([string]::IsNullOrWhiteSpace($ebdPath)) { throw 'Configured protected EBD environment variable is unavailable' }
Add-Type -Path (Join-Path $PSScriptRoot 'EbdStreamingTools.cs')

if ($Mode -eq 'membership') {
  $sedPath = [Environment]::GetEnvironmentVariable($SedEnv)
  if ([string]::IsNullOrWhiteSpace($sedPath)) { throw 'Configured protected SED environment variable is unavailable' }
  [EbdStreamingTools]::AuditMembership($ebdPath, $sedPath, $MissingOutput, $StatsOutput)
} else {
  [EbdStreamingTools]::ExtractFocalPre2026($ebdPath, $Patterns, $Output)
}
