[CmdletBinding()]
param(
    [ValidateSet("fixture", "case", "family", "sensitivities")]
    [string]$Mode = "fixture"
)

$ErrorActionPreference = "Stop"
$expectedAuthorization = "through_2025_post_result_refinement_v1"
if ($Mode -ne "fixture") {
    $observedAuthorization =
        [Environment]::GetEnvironmentVariable(
            "POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED",
            "Process"
        )
    if ($observedAuthorization -cne $expectedAuthorization) {
        throw "STAGE3_DOSE_AUTHORIZATION_GATE: exact author-set process value absent"
    }
}

$libraryPath = Resolve-Path (
    "renv/library/windows/R-4.5/x86_64-w64-mingw32"
)
$env:RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE"
$env:R_LIBS_USER = $libraryPath.Path

& Rscript "scripts/run_post_stage4a_stage3_dose_v1.R" $Mode
if ($LASTEXITCODE -ne 0) {
    throw "Stage 3 dose runner failed with exit code $LASTEXITCODE"
}
