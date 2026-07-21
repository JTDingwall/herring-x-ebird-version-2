if (!identical(Sys.getenv("STAGE3_AUTHORIZED_PHASE"), "phase_1")) {
  stop("Set STAGE3_AUTHORIZED_PHASE=phase_1 to acknowledge the registered hard stop", call. = FALSE)
}

runner <- file.path("scripts", "run_stage3_phase1_denominator.ps1")
status <- system2(
  "powershell",
  c("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", runner, "-Mode", "production")
)
if (!identical(status, 0L)) stop("Stage 3 Phase 1 denominator construction failed", call. = FALSE)
