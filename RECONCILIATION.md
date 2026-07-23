# RECONCILIATION — D12 numeric sweep

Every number checked below was verified programmatically against the frozen
authoritative outputs. Sources:

- `outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv` (per-contrast
  estimates, ratios, CIs, q-values) — hash-matched to `output_hash_manifest_v1.csv`.
- `.../model_diagnostics_v1.csv` (fit statuses).
- `.../joint_exposure_support_v1.csv` (global period-by-zone support).
- `.../model_term_support_v1.csv` (per-species joint-cell support).
- `.../execution_record_v1.yml` (frame size, status counts).

Result: **0 mismatches across all items checked.** Manuscript = v7 source
`mer_manuscript_unblinded_v7.qmd`.

## Structural counts

| Manuscript location | Manuscript value | Source | Source value | Match |
|---|---|---|---|---|
| Abstract, §2.1, §3.1 | 217,200 eligible complete checklists | execution_record | 217200 | yes |
| §3.1 | 100 species-response fits | model_diagnostics rows | 100 | yes |
| §3.1 | 1,400 contrast rows | effect_estimates rows | 1400 (1372 core + 28 comparator) | yes |
| §3.1 | 95 normal / 1 singular / 3 support / 1 numerical | model_diagnostics status | 95 / 1 / 3 / 1 | yes |
| §3.1 | detection estimable 48 of 49 | core active finite-q detection | 48 | yes |
| §3.1 | count estimable 46 of 49 | core active finite-q count | 46 | yes |
| §3.1 | global support 2,992 (near, spawn start) | joint_exposure_support min | 2992 near spawn_start | yes |
| §3.1 | global support 28,655 (reference, late egg) | joint_exposure_support max | 28655 reference late_egg | yes |
| §3.1 | minimum panel joint-cell support 259 | model_term_support (panel) | 259 | yes |

## §3.4 period-by-period BH-significant tallies (positive / negative)

| Period | Manuscript (det ; count) | Source (det ; count) | Match |
|---|---|---|---|
| Pre-spawn -14 to -1 d | 0 pos ; 1 pos | 0/0 ; 1/0 | yes |
| Spawn start 0-3 d | 10 pos 4 neg ; 13 pos | 10/4 ; 13/0 | yes |
| Early egg 4-14 d | 12 pos 2 neg ; 21 pos 1 neg | 12/2 ; 21/1 | yes |
| Late egg 15-28 d | 10 pos 2 neg ; 13 pos | 10/2 ; 13/0 | yes |
| Active 0-14 d (§3.2) | 13 pos 6 neg ; 19 pos 1 neg | 13/6 ; 19/1 | yes |

## Table 1 — eleven-species active interactions

All 22 values (11 species x detection + flock size, estimate and 95% CI) matched
`effect_estimates` `did_active_0_14_day` rows to two decimals. 0 mismatches.

## Abstract and §3.3 headline family values

| Manuscript location | Value | Source (active 0-14 d) | Match |
|---|---|---|---|
| Abstract, §3.3 | American Herring Gull detection 1.49 (1.29-1.71) | 1.49 (1.29-1.71) | yes |
| Abstract, §3.3 | Iceland Gull detection 1.43 (1.30-1.57) | 1.43 (1.30-1.57) | yes |
| Abstract, §3.3 | Long-tailed Duck count 1.49 (1.33-1.67) | 1.49 (1.33-1.67) | yes |
| Abstract, §3.3 | Ring-billed Gull detection 0.79 / count 0.83 | 0.79 (0.69-0.90) / 0.83 (0.74-0.94) | yes |
| Abstract, §3.3, §4.1 | Northern Pintail detection 1.29 (1.18-1.42) | 1.29 (1.18-1.42) | yes |
| §3.3 | Common Goldeneye 1.22, Greater Scaup 1.18, Double-crested Cormorant 1.13, Barrow's Goldeneye 1.11, American Wigeon 1.11, Bufflehead 1.10, Red-breasted Merganser 1.10 | all matched | yes |
| §3.3 negatives | Rhinoceros Auklet 0.71, Western Grebe 0.74, Black-bellied Plover 0.84, Common Loon 0.90 | all matched | yes |

## §3.4/§3.5/§3.6 inline quotes

27 inline ratio quotes across timing (§3.4), the five candidate species (§3.5),
and the two comparators (§3.6) matched their `effect_estimates` rows to two
decimals. 0 mismatches. Includes Bald Eagle spawn-start detection 1.21 and count
1.18; Common Merganser detection 1.25 / 1.17 / 1.11; scoter and Harlequin count
timing; Mallard count 1.09 / 1.12 / 1.15; Hooded Merganser baseline 1.11;
American Crow baseline 1.06 / 1.06 and late-egg 0.94; Common Raven active 0.94
and baseline count 0.98; Gadwall baseline 0.88 and active 1.03; Northern Shoveler
active 1.24, early egg 1.25, late egg 1.27.

## One reporting-standard flag (not a numeric error)

Northern Shoveler's active-detection q is reported as 0.0056, correctly computed
inside its 2-species comparator BH family. If pooled with the four core dabbling
ducks under the manuscript's "four of five" framing, the comparable core-family
q is 0.0115 (D8). The number 0.0056 is correct for the family it was computed in;
the issue is which family the prose implies. Routed to `OPEN_QUESTIONS.md` and
Phase 3 item 14.
