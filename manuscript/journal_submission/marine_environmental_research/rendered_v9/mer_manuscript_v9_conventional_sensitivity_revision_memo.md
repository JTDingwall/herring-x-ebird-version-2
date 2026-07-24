# Revision memo: manuscript v9 conventional exposure sensitivity

## Scope and branch basis

This additive revision starts from the exact head of PR #13 (`167489b54d506748c17ab8fb77a6c92d5c58be19`), because that head contains the PR #12 verified analytical base and the v9 manuscript. The protected Stage 4A history and the original PR #13 v9 files remain unchanged; the revised clean manuscript is a new file.

## Single new analysis

A prefit comparison used only support and geometry. Complete single-event restriction retained 72,443 checklists and supported conditional positive numeric reported-count models for 19 of 49 species. Deterministic nearest-event assignment retained all 217,200 checklists, full fixed-effect rank, and count-model support for 41 species, so it was frozen as the sole conventional sensitivity before any model was fitted. No other new sensitivity, engine, species family, bootstrap, influence analysis, radius, travel/stationary restriction, observer restriction, placebo, or hierarchical model was run.

## Verified comparison

| Outcome | Primary estimable | Nearest-event estimable | Sign concordance | Primary BH q < 0.05 | Nearest-event BH positive / negative | Sign reversals | Material interpretation changes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Checklist reporting | 48 | 49 | 34/48 (70.8%) | 13 | 7 positive / 2 negative | 14 | 3 |
| Conditional positive numeric reported count | 46 | 41 | 34/41 (82.9%) | 18 | 19 positive / 0 negative | 7 | 1 |

The nearest-event sensitivity identifies 4 material interpretation change(s) under the fixed pre-result comparison rule. 11/13 primary-BH reporting signs and 18/18 primary-BH count signs were preserved; 7 and 17, respectively, remained BH-significant. The main conclusions therefore require the species- and outcome-specific qualifications listed below; observational and noncausal limitations remain.

## Manuscript changes

- Abstract: replaces the incomplete nearest-event statement with the verified estimability and sign-concordance results and remains within the 250-word limit.
- Methods: records the prefit single-event versus nearest-event support comparison, deterministic tie handling, unchanged estimand components, and the prohibition on outcome-informed design choice.
- Results: reports nearest-event estimability, BH counts, sign concordance, and every material change or reversal under the fixed rule.
- Discussion and Conclusion: state how the conventional sensitivity affects robustness without weakening the noncausal, observation-process, or regional-abundance limitations.
- Submission formatting: continuous line numbering and page-number fields are added to the revised clean manuscript.
- Terminology: the revision uses checklist reporting and reported counts; it does not recast them as detection, occupancy, flock size, or abundance.

## Complete status handling

The synchronized Supplement and `component_status.csv` retain all 245 primary, finite-number-versus-X, and nearest-event components. Status, formula, engine, model sample size, grouping levels, convergence flags, singularity, rank deficiency, optimizer code, maximum absolute gradient, random-effect variances, residual variance, and failure reason are reported. Failed components are not displayed as estimates and are not described as biological null results.

The status table explicitly flags Surfbird, Rhinoceros Auklet, Glaucous Gull, Red-throated Loon, Western Gull, Common Goldeneye, Marbled Murrelet, and Western Grebe.

## Material changes and reversals

| Species | Outcome | Primary ratio (95% CI) | Nearest-event ratio (95% CI) | Primary q | Nearest-event q | BH threshold crossed | Classification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Surf Scoter | Checklist reporting | 1.00 (0.93–1.08) | 0.71 (0.59–0.85) | 0.948 | 0.001 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| Harlequin Duck | Checklist reporting | 1.15 (1.05–1.26) | 0.84 (0.66–1.07) | 0.013 | 0.394 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| American Wigeon | Checklist reporting | 1.11 (1.04–1.17) | 0.99 (0.87–1.14) | 0.004 | 0.967 | yes | material_direction_reversal__at_least_one_interval_excludes_zero |
| Barrow's Goldeneye | Conditional positive numeric reported count | 1.10 (1.01–1.19) | 0.95 (0.81–1.12) | 0.052 | 0.615 | no | material_direction_reversal__at_least_one_interval_excludes_zero |

All BH-threshold crossings, uncertain reversals, unsupported components, and same-direction interval differences remain in `interpretation_changes.csv` and the synchronized Supplement.

## Author inputs retained

Visible placeholders remain for the full postal address, telephone number, registration/repository DOI, funding statement, journal-compliant generative-AI disclosure, and additional acknowledgements.

## Deliverables

- Revised clean manuscript: `mer_manuscript_unblinded_v9_revised_clean.docx`.
- Synchronized Supplement: `mer_supplement_v9.docx`.
- Updated highlights: `mer_highlights_v9.docx`.
- Machine-readable results, comparison summary, interpretation changes, component statuses, execution record, and output hashes in `outputs/conventional_exposure_sensitivity_v1/`.

## Verification

- The complete repository `testthat` harness and both targeted conventional-sensitivity/manuscript tests passed.
- The privacy scan passed across 754 text files with no violations.
- Visual QA covered every rendered page: 19 manuscript pages, 34 Supplement pages, and the one-page highlights file.
- The revised manuscript is a valid DOCX with continuous line numbering, page-number fields, retained author placeholders, and a 197-word abstract.

## Interpretation boundary

The sensitivity supports only robustness to one conventional exposure encoding. It does not establish formal detection probability, occupancy, regional abundance, diet, individual movement, or causation. The current analysis remains exploratory and estimand-refining until prospective confirmation using the complete locked release.
