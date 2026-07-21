# Stage 4A human-review decision packet

Status: decision aid only; no decision is made here. This packet was prepared after the
Stage 4A results were known and uses tracked privacy-safe aggregates only.

## Decisions requested

1. **Historical record.** Should PR #2 be merged as the immutable record of the
   authorized Stage 4A v1 run, accompanied by the post-result audit? Its original specs,
   locks, execution record, hashes, and outputs have not been changed.
2. **Partial-pooling repair.** Should a new aggregate-only repair specify model- and
   unit-class-specific pooling families and exclude duplicate M11/M12 component evidence?
   The existing `partial_pool_*` columns are unusable. Individual estimates and
   model-specific BH columns remain intact.
3. **Protected diagnostic repair.** Are the M27/M28 placebos, WCVI 2-km view, and
   dominant-observer holdout important enough to authorize a new versioned protected run
   using the locked matched families? The original diagnostic tables must remain frozen.
4. **Claim level.** Does the non-null SoG specificity panel downgrade claims to broad
   checklist-reporting associations, or does it preclude only species-specific or causal
   attribution? The panel was not guaranteed biologically inert.
5. **Stage 4B.** Which, if any, post-result option has an outcome-independent scientific
   rationale and acceptable selection risk? Do not activate the 32 deferred models as a
   catalogue.

## Result-family disposition proposed for review

| Family | Current review status | Reason |
|---|---|---|
| Individual M01/M02/M05/M08/M11/M12/M29 estimates and uncertainty | Descriptive/exploratory with stated region and support limits | Core fitting path is reconstructible; associations are conditional on submitted checklists and recorded-event exposure. |
| Within-family BH q-values | Descriptive multiplicity summary | Model-specific BH implementation is distinct from defective pooling. |
| `partial_pool_*` columns | **Unusable** | Every computed pooling family mixes model IDs or unit classes and may duplicate component evidence. |
| M27/M28 placebo rows | **Unusable as locked falsification evidence pending repair** | Construction and model family do not conform. |
| WCVI 2-km and dominant-observer sign summaries | Exploratory sensitivity only pending repair | Simplified GLMs do not match the primary family. |
| M26 | Unusable for preferential-visitation inference | No exposure/visitation coefficient. |
| M32/M40 | Descriptive process signal | Non-null simplified diagnostics show observation structure but do not identify or correct selection. |
| CC/NA | Descriptive only | Frozen role and limited geometry/support. |

## Facts that should constrain the decision

- 441/460 underlying checkpoints completed; all 19 failure/support rows and 28
  rank-deficiency warnings remain visible.
- SoG specificity is 2/2 at BH q < 0.05; WCVI is 0/2.
- WCVI dominant-observer share is 35.6%, effective replication 7.4, and the two reported
  robustness comparisons each agree for 6/8 guilds, subject to the fit defect.
- ztNB2 versus lognormal disagreement is visible and must not be selectively suppressed.
- No protected record was reopened for this audit and no 2026+ response was accessed.

## Required authorization boundary

An aggregate-only pooling repair can be defined without protected data, but its family
definition is a scientific choice requiring approval. Any rerun of placebos, 2-km, or
observer-holdout models requires explicit protected-data authorization, a new spec and
lock, a new execution record, a new output directory, and a separate report. M31 and all
2026-2028 responses remain inaccessible until the complete prospective release.
