# Stage 3 Phase 2 metadata-only sampling-support audit

Status: passed implementation, cardinality, fixture, privacy and reproducibility gates; pending human sampling-support review. Phase 3 has not started.

## Scope and denominator

The audit reused the approved factorized Phase 1 event denominator and independent-event crosswalk. It did not expand the 83,159,588 logical event-by-taxon cells and did not read either sparse bird table. Linkage used immutable herring source points, event dates and region metadata only. Shoreline fields and geometry were not selected.

The registered primary frame reproduced all 1,433,786 approved independent events exactly. The high-spatial-precision frame retained 1,158,032 events, and the registered broad frame retained 1,579,856 events.

## Effort trade-offs

| Frame | All eligible events | Retention | Source-point-linked events | Recommendation |
|---|---:|---:|---:|---|
| Candidate primary, travel at most 5 km | 1,433,786 | 90.8% of broad | 239,934 | retain as primary |
| High precision, travel at most 2 km | 1,158,032 | 80.8% of primary | 193,720 | retain as targeted sensitivity |
| Registered broad | 1,579,856 | reference | 261,494 | retain as targeted sensitivity; do not broaden the default |

The broad frame adds 146,070 events beyond the primary frame. Of these, 72,214 are traveling checklists longer than 5 km. It does not cause any region-period cell to newly pass the frozen sustained-support rule. The primary frame therefore removes a modest share of checklists while preserving the same supported region-period conclusions and a clearer effort-based spatial-validity standard.

The 2 km frame removes 19.2% of the primary events and retains 193,720 source-point-linked events. It supports the same sustained region-period combinations as the primary frame, so it is useful as a focused spatial-precision sensitivity but is unnecessarily restrictive as the principal frame.

## Region and period recommendations

| Region | Earliest supported primary start | Recommendation |
|---|---:|---|
| SoG | 2005 | retain as primary |
| WCVI | 2015 | retain as primary from 2015; earlier windows descriptive/hierarchical only |
| CC | none | descriptive/hierarchical only |
| NA (registered region code) | none | descriptive/hierarchical only |
| PRD | none | descriptive/hierarchical only |
| HG | none | descriptive/hierarchical only |
| A27 | none | descriptive/hierarchical only |
| A2W | none | unsupported |

The complete 1988–2025 window does not pass the sustained-year rule for any region. This does not support discarding all pre-2015 data globally: SoG passes continuously from 2005, while WCVI needs a 2015 start. Region-specific periods or hierarchical treatment preserve more representation than one coastwide late-start restriction.

## Answers to the registered questions

1. The 5 km primary restriction is justified. It retains 90.8% of the broad event population, preserves every region-period support conclusion, and excludes lower-standardization effort, including 72,214 broad-only traveling events longer than 5 km.
2. The 2 km frame is useful as a targeted sensitivity, not the principal dataset. It retains 80.8% of primary events and the same supported region-period combinations, but its additional event loss has no demonstrated metadata-support benefit.
3. The broad frame mainly adds lower-precision or less-standardized checklists. It restores zero region-period sustained-support cells.
4. SoG supports primary analysis from 2005; WCVI supports primary analysis from 2015. CC, NA, PRD, HG and A27 require descriptive or hierarchical treatment under the frozen rule. A2W is unsupported.
5. Credible contemporaneous active/reference metadata support exists in SoG and WCVI within their supported primary periods. CC and NA also have active/reference overlap, but their sustained year support limits them to hierarchical or descriptive comparisons. The remaining regions do not support a primary redistribution comparison.
6. A 2 km principal restriction and a single coastwide 2015 start would reduce representation without a demonstrated scientific benefit. The 5 km primary plus targeted 2 km sensitivity and region-specific start years is the least restrictive configuration supported by the response-blind audit.

All recommendations are based only on checklist effort, time, region, repeated-sampling concentration and immutable source-point linkage. No bird detections, counts, response directions, exposure contrasts, ecological covariates, models, comments, shoreline fields or 2026-and-later records were used.
