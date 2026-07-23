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

## Not executed in this environment

The protected event metadata, source-point links, sparse bird states, and
ambiguity masks are not present here, and `Rscript` is unavailable. No protected
row was opened and no biological estimate was produced.

The analysis runner therefore remains deliberately gated on:

1. committed code and specification;
2. passing R fixtures and repository tests;
3. the exact production acknowledgement;
4. the frozen source-link hash;
5. historical event and sparse-state cardinalities;
6. exclusion of every record after 2025.

## Manuscript consequence

The v5 manuscript is not silently updated with invented or recycled timing
results. Its registered M05/M08 results remain historical evidence. The v6
source gate requires the complete new output family and human scientific review
before the abstract, Results, Discussion, tables, or figures are revised.

## Remaining validation

- Run the fixture and full R test suite in the repository's R environment.
- Commit the implementation before production access.
- Execute the complete 100-component family:
  49 core species x 2 responses, plus 2 detection-only specificity comparators.
- Review insufficient-support failures, convergence, rank deficiency, and
  singular fits before interpreting coefficients.
- Confirm all 11 main species have complete primary and timing contrasts.
- Review Gadwall and Northern Shoveler only as specificity evidence.
- Build v6 assets, revise the ecology narrative, render the DOCX/PDF, and inspect
  every page.
