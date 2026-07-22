# Stage 4A publication sensitivity v2 — pre-execution specification

## Purpose and boundary

This specification repairs the released Stage 4A placebo, WCVI 2-km, and dominant-observer diagnostics before they are used in a publication. It was written and committed before any protected production input was read on this branch. The protected execution may use only registered 2005–2025 inputs and may release only aggregate model outputs, diagnostics, hashes, and reports.

M26 v1 is retired from the inferential publication set without replacement. Its released mean visitation count does not estimate an exposure or visitation contrast, and the manuscript does not require a replacement observation-process estimand.

## Matched model family

Every v2 sensitivity is matched to the registered M01 guild hurdle family. Detection uses a binomial-logit model. Positive numeric count uses the registered Gaussian model on log count among finite counts greater than zero. Both use the complete registered fixed-effect set, event-block, observer-cluster, and location-cluster random intercepts, and `mgcv::bam(method = "fREML", discrete = TRUE, nthreads = 1)`. A failed `bam` fit remains a visible failure; a simplified GLM cannot replace it.

All eight frozen guilds, both primary regions where applicable, and both hurdle response states are reported regardless of sign or significance. The 2-km and dominant-observer analyses are WCVI sensitivities. BH adjustment is within each registered sensitivity × region × response family of eight guilds.

## Placebo transformation

M27 v2 and M28 v2 move one complete exposure-bundle row at a time within region-year strata. The bundle contains active/reference state, concurrent-link count, every event-time count, and every distance-ring count. M27 uses a nonzero cyclic shift in protected analysis-event-token order with seed 10007. M28 uses a nonzero cyclic shift in protected location-token then analysis-event-token order with seed 20011. The offset is `1 + seed mod (stratum size - 1)`, so strata of at least two rows have no fixed position.

The transformation does not read a response, does not cross a region or year, does not duplicate a checklist, preserves the bundle distribution within every stratum, and must reproduce the registered concurrent-link invariants after shifting. Tokens used for deterministic ordering never enter a released artifact.

## Sensitivity definitions

The WCVI 2-km sensitivity changes only cohort eligibility: the registered `high_precision_2km` flag must be true. The dominant-observer sensitivity defines the dominant cluster once, before joining any guild response, as the cluster with the most eligible WCVI primary-frame checklists; an internal lexical token tie-break is used. That cluster is excluded for every guild and response, but its token is never released.

## Validation and release

Each fit retains the frozen four-fold event-blocked validation view. Factor levels absent from training are excluded with explicit aggregate counts. Model errors, nonconvergence, rank deficiency, missing coefficients, and insufficient support remain visible. Cells below 20 are suppressed. The execution record must identify this pre-execution commit, code commit, input hashes without protected paths or rows, the maximum year read, the count of 2026+ rows read, model outcomes, and output hashes.

These analyses remain checklist-conditional sensitivity and placebo associations. They do not estimate causal effects, population abundance, biomass, occupancy, or movement. Unmonitored DFO coverage remains unknown rather than negative.
