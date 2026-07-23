# Strait of Georgia event-study implementation audit (v6)

## Implemented

- Versioned the user's 2026-07-22 authorization as a post-results,
  ecologically motivated refinement.
- Preserved every historical Stage 4A output, checkpoint, specification, and
  interpretation as immutable.
- Replaced the 28-day pre-spawn category for the new analysis with:
  - baseline: -28 to -15 days;
  - early pre-spawn: -14 to -8 days;
  - immediate pre-spawn: -7 to -1 days.
- Kept spawn start (0-3 days), early egg availability (4-14 days), and late egg
  availability (15-28 days) separate.
- Defined a primary active interval for days 0-14 as a duration-weighted linear
  contrast of spawn-start and early-egg coefficients.
- Implemented a near/reference difference-in-differences relative to the
  -28 to -15 day baseline.
- Preserved one checklist as one model row and all concurrent herring-event links
  as additive exposure counts.
- Added a hard gate that rejects construction from separate time and distance
  margins; true joint period-by-zone counts are rebuilt from the frozen link
  table.
- Retained detection and positive numeric flock size as separate responses.
- Fit all 49 frozen named species; promoted Bald Eagle, Hooded Merganser,
  Mallard, American Crow, and Common Raven into the 11-species main ecological
  panel.
- Reclassified Gadwall and Northern Shoveler as supplementary specificity
  comparators and aligned them to the new detection estimand.
- Added deterministic table and figure builders for manuscript integration after
  complete execution.

## Executed and verified

The fixture workflow and full repository R tests passed. Production was executed
with the exact acknowledgement
`through_2025_post_result_refinement_v1` using committed analysis code
`6bfef2c5b828ca392255d5b3365a2f84b8a2f9f2`.

The frozen source-link hash, historical cardinalities, joint concurrent-link
pairing, protected-input hashes, and 2025 response cutoff passed. The released
family contains only privacy-safe aggregates. Protected checkpoints and
record-level derivatives were not opened for interpretation or tracked.

## Manuscript consequence

The complete output family received a scientific decision of **pass with
qualifications**. The v6 Strait of Georgia-only manuscript was therefore revised
using the new interaction results. Historical registered M05/M08 results remain
unchanged and are labelled as historical Stage 4A evidence in the supplement.
No historical coefficient was recycled as a new event-study result.

## Validation summary

- All 100 components were attempted: 49 core species x 2 responses, plus 2
  detection-only specificity comparators.
- All 22 main-panel components completed without convergence, rank-deficiency,
  or singularity problems.
- Three supplementary count components failed support, Glaucous Gull detection
  failed numerically without fallback, and Western Gull count was singular.
- Gadwall was null for the primary active interaction; Northern Shoveler was
  positive and is disclosed as evidence of residual confounding.
- Exponentiation, confidence intervals, BH multiplicity adjustment, hashes,
  privacy, and frozen-output preservation passed independent audit.
- Manuscript assets were generated from the complete aggregate family.
