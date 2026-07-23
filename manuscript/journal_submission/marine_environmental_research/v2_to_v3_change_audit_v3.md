# V2-to-v3 change audit

This audit classifies every zero-context text-diff hunk across paired v2 and v3 source documents, every versioned v3-only package file, and v2-only support documents preserved without a v3 replacement. Rendered files are recorded as derivatives and were not independently edited.

## Scope and result

- Paired source artifacts: 9
- Classified source diff hunks or no-change records: 413
- Preserved v2-only support documents: 5
- Classified v3-only package files: 86
- Frozen coefficients, standard errors, intervals, p-values, q-values, sample sizes, fit states, and diagnostics changed: **0**
- The complete line-level classification is `audits/v2_to_v3_change_audit_v3.csv`.

## Classification counts

| Classification | Records |
|---|---:|
| anonymization and versioning | 18 |
| author metadata and declarations | 13 |
| descriptive foundation | 47 |
| ecological narrative and interpretation | 39 |
| editorial restructure and plain language | 47 |
| estimand engine or window correction | 47 |
| future or companion analysis boundary | 26 |
| journal front matter | 4 |
| no content change | 1 |
| preserved v2 support artifact | 5 |
| privacy safe spatial addition | 35 |
| rendered submission derivative | 16 |
| reproducible generation and validation | 5 |
| scientific question and evidence hierarchy | 27 |
| supplementary completeness and provenance | 70 |
| validation and provenance | 11 |
| versioned package derivative | 7 |

## Artifact-level diff accounting

| Artifact | Hunks | Added lines | Deleted lines |
|---|---:|---:|---:|
| main manuscript, unblinded | 102 | 189 | 109 |
| main manuscript, blinded | 110 | 192 | 116 |
| supplement, unblinded | 50 | 77 | 63 |
| supplement, blinded | 50 | 78 | 63 |
| abstract | 1 | 1 | 2 |
| title page | 5 | 13 | 10 |
| cover letter | 7 | 10 | 15 |
| highlights | 1 | 5 | 1 |
| bibliography | 0 | 0 | 0 |

## Interpretation

The v3 changes add a privacy-safe descriptive foundation and broad-region maps, correct the primary baseline and engine wording, reorganize the paper around P1â€“P4 and species-level evidence, expand the ecological discussion, and move completeness/provenance detail to the supplement. Existing adjusted results are only re-expressed on interpretable ratio scales or reorganized; no response model was refit.

Items unavailable from public aggregates remain explicitly unavailable. They were not approximated and would require separate protected-data authorization.
