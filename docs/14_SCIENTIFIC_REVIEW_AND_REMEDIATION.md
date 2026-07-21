# Scientific review and remediation register

Independent top-tier review of the Version 2 design, with a prioritized list of what must
be revisited before any response model is fit (Phase 4) and before any confirmatory claim is
made. Severities: **S1** blocks confirmatory claims; **S2** must be fixed before Phase 4
model fitting; **S3** engineering-integrity fixes (several are silent-corruption risks).

This register is the authoritative "go back and fix" list. It is advisory design guidance,
not a response result, and computes nothing from bird outcomes.

## Framing correction: no assumed response direction

The design must not assume that most species respond to herring spawn. There is direct
field evidence for only about five of the fifty-eight taxa; the remainder rest on
family-level dietary plausibility, and no prior study in any system has used eBird
occurrence to detect a herring-spawn effect. A broad, inclusive **candidate** list is
appropriate and is retained. A presumed **positive direction** is not, for three reasons:

1. It voids the falsification panel. A negative control only carries information if the
   analyst has not already decided the answer is "yes" everywhere.
2. It contradicts the standing rule that all prespecified models are reported regardless of
   sign. One cannot report regardless of sign while assuming the sign.
3. Spawn aggregations increase flock size and mixed-flock misidentification for confusable
   taxa, so a "most respond" prior will read differential detection error as biological
   signal.

Operational consequence: `expected_direction` in the registries is a **prespecified
hypothesis label used for placebo/consistency checks, never a prior belief or an inclusion
criterion**. "Most species respond" is a testable prediction to be evaluated against a
strengthened control panel, not a design assumption.

## Remediation register

| ID | Sev | Finding | Required fix | Gate |
|----|-----|---------|--------------|------|
| R1 | S1 | Confirmatory validity is self-administered: single-author approvals, blind extraction in C# tools CI never runs on real data, prospective "lock" is a static source-line-order check, and the independence claim is self-attestation. | Externally pre-register the frozen models, estimands, and numeric support thresholds (OSF or Registered Report). Place 2026+ and any external-region response data under an independent custodian who is not the analyst. | Before any confirmatory claim |
| R2 | S1 | Exposure (DFO-recorded spawn) and sampling (eBird effort) share one human-effort process, and birders are drawn to visible spawn. Outcome-blinding does not blind the effort–exposure correlation. Site selection is endogenous to the spawn, so even E01 is contaminated; the visitation model cannot be turned into weights. | Treat shared-effort/observer-attraction as a named first-class identification threat. Report the visitation/allocation diagnostic alongside **every** biological estimand. Cap all claims at "recorded-event vs no-recorded-active-event, conditional on observed eBird sampling." Foreground same-observer and same-location designs as primary, not sensitivity. | Before Phase 4 |
| R3 | S1 | Exposure is presence-only; "no recorded active event" is not "no spawn," and DFO survey effort plausibly co-varies with eBird effort, biasing the counterfactual. | Obtain or reconstruct a DFO survey-effort surface. Treat unmonitored shoreline as missing, not control. Re-derive comparison sets, or explicitly bound the residual bias. | Before Phase 4 |
| R4 | S1 | Entire confirmatory burden rests on a 3-year holdout with no power analysis; real primary support is only Strait of Georgia (2005+) and WCVI (2015+). | Run a metadata-only prospective power / minimum-detectable-effect analysis per guild×region for 2026–2028. Pre-declare which cells are adequately powered for confirmation; the rest remain permanently exploratory and must be framed as such. | Before Phase 4 |
| R5 | S1 | "Assume most species respond" would bias interpretation and void the controls; falsification panel is only two dabbling ducks ecologically adjacent to a guild that is hypothesized to respond, with no rule for a non-null panel. | Adopt the framing correction above. Enlarge and diversify the negative-control panel beyond `surface_vegetation_roe` neighbors. Prespecify the decision rule triggered if the falsification panel shows an effect. | Before Phase 4 |
| R6 | S2 | Only the source point is a registered geometry; alongshore length/width are provenance-only. H2 (distance decay) and H5 (extent) are exactly the geometry-dependent hypotheses. Source-point snap distances reach ~400+ km medians in some regions. | Register a "nearest-point-on-spawn-line" geometry as a primary sensitivity for H2/H5 wherever shoreline coverage permits; state explicitly that H2/H5 are not identified from point geometry alone. | Before Phase 4 |
| R7 | S2 | Egg-availability kernels run to 42 days but the nearest placebo date shift is ±14 days — inside the response window, so the closest "null" is contaminated. | Require placebo shifts to exceed the maximum registered kernel (>=56 days). Relabel the ±14-day shift as a spillover probe, not a negative control. | Before Phase 4 |
| R8 | S2 | The event-complex definition (1 km/3 d vs 2 km/7 d vs 5 km/14 d) is unresolved yet is the clustering unit for all uncertainty; the Phase-3 event-block union-find has no anti-chaining cap (the shape already patched in Stage 2). | Fix the primary event-complex rule before any clustered SE/bootstrap. Port the Stage-2 anti-chaining cap into the Phase-3 event-block construction and audit the block-size distribution for a few dominating blocks. | Before Phase 4 |
| R9 | S2 | The relative spawn index sums whichever of Surface/Macrocystis/Understory were observed with no normalization, so it is not comparable across records with different component coverage — yet it is the H5 dose. | Model component availability explicitly, or restrict dose-response to component- and method-matched subsets. Do not compare raw component sums across differing coverage. | Before Phase 4 |
| R10 | S2 | Multiplicity is controlled within species families but the operative bar for "strongly supported" is narrative ("agreement across >=2 families," "biologically meaningful magnitude") with no numeric threshold; cross-family multiplicity is unaddressed. | Prespecify numeric agreement and magnitude thresholds for the six-level evidence ladder before the holdout. Define cross-family, not only within-species, multiplicity handling. | Before Phase 4 |
| R11 | S2 | Detectability differs sharply by guild and `ambiguity_affected` records fold into binary detection; spawn increases flock size and misID, so misclassification is plausibly correlated with the exposure. | Add species-specific detection treatment for confusable/hard-to-detect guilds (alcids; scoter/scaup/gull ambiguity). Do not fold `ambiguity_affected` into detection for those taxa. Assess differential misclassification correlated with exposure. | Before Phase 4 |
| R12 | S2 | Traveling checklists up to 5 km are assigned to rings as fine as 0–0.5 km — a 10x spatial-support mismatch. | Restrict fine inner-ring (0–0.5, 0.5–1 km) inference to stationary or short-travel subsets; document the limit. | Before Phase 4 |
| R13 | S3 | The checklist↔herring-event spatial join is the only join with no cardinality assertion, and it passes integer row positions rather than stable ids — a silent-misjoin risk on the most important join. | Add an explicit cardinality assertion and join on stable ids (`sampling_event_identifier`, `event_id`), not row order. | Engineering pass |
| R14 | S3 | Zero-fill eligibility defaults to TRUE for all checklists if the column is absent — a renamed column would silently fabricate structural zeros. | Make missing `zero_fill_eligible` a hard failure, not a fail-open default. | Engineering pass |
| R15 | S3 | `event_id` natural key has no uniqueness assertion; duplicate/re-surveyed keys silently collapse into one event, corrupting the uncertainty unit. | Assert uniqueness of `event_id` in `derive_herring_event_fields`. | Engineering pass |
| R16 | S3 | 20 km candidate radius with kernel scales up to 10 km leaves ~0.135 weight at the cutoff (exp(-20/10)) — truncation bias for the largest scale. | Set the candidate radius to at least ~5x the maximum kernel scale, or document and bound the truncation. | Engineering pass |
| R17 | S3 | The `egg_thickness` parameter in `classify_herring_quality` is actually fed `relative_spawn_index`, obscuring the "high" quality tier. | Rename the parameter and clarify the tier definition. | Engineering pass |
| R18 | S3 | Single-guild membership is enforced in code but H6 concerns within-guild functional heterogeneity, and several taxa are genuinely multi-modal. | Implement the registered multi-guild membership rule, or explicitly scope H6 to single-guild taxa. | Engineering pass |
| R19 | S3 | Guild richness and guild-count-lower can disagree for the same checklist (an `X` adds to richness but 0 to the lower bound). | Document this divergence in modeler guidance so it is not misread. | Engineering pass |

## What does not need to change

Distinct outcome states, `X`/missing never coerced to zero, event-level clustering, full
reporting of all prespecified models regardless of sign, hierarchical partial pooling over
naive 45-way testing, the design against the Version 1 rank-one correlation defect,
marginalizing random effects for held-out prediction, and hard-fail leakage guards in
blocked validation are all sound and are retained.

## Provenance

Derived from the 2026 independent design review. No bird-response value was accessed. All
items are design/inference and code-integrity concerns visible from metadata, documentation,
and source code only.
