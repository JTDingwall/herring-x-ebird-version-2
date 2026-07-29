# Project state: MER manuscript, as of 26 July 2026

Compacted record of a long Claude session. Written for an AI agent picking this
up cold. Read `README.md` first if you have not.

---

## 1. What the paper is

**Title.** Coastal bird responses to Pacific herring spawn revealed by two
decades of eBird records in the Strait of Georgia

**Author.** Jacob T. Dingwall, sole author. University of Victoria.

**Target.** Marine Environmental Research (Elsevier). Full-length article.
Abstract cap 250 words, body 5,000 to 10,000, max 50 references, author-year
citations.

**The question.** Do coastal bird observations change around recorded Pacific
herring spawning events, and do different feeding groups respond at different
points in an event.

**The data.** 217,200 complete eBird checklists in the Strait of Georgia,
2005 to 2025, linked to 1,120 recorded DFO herring spawning events forming 58
event blocks.

---

## 2. The analysis, in enough detail to write about it

**The comparison.** For each species, whether the association between a
checklist and a nearby spawning event grew stronger after spawning began
than in the fortnight before, relative to the same change further away.

- **Near zone**: checklist within 5 km of a recorded event point.
- **Reference zone**: 5 to 20 km.
- **Six periods** relative to the event anchor: baseline (−28 to −15 d), early
  pre-spawn (−14 to −8), immediate pre-spawn (−7 to −1), spawn start (0 to 3),
  early egg (4 to 14), late egg (15 to 28).
- **Twelve exposure variables**: six periods crossed with two zones, each
  counting the number of checklist-to-event links.
- **Primary quantity**: `did_active_0_14_day` minus `did_pre_14_day` on the
  model scale, exponentiated. Active is duration-weighted, 4/15 spawn start plus
  11/15 early egg. The two baseline terms cancel exactly, so the baseline period
  acts through the model and not through the comparison.

**Two outcomes, kept apart throughout.**

1. **Checklist reporting.** Binomial mixed model, logit link, `nAGQ = 0`.
   Whether the species appeared on a complete checklist.
2. **Reported number given detection.** Gaussian mixed model on log positive
   counts, REML. How many birds, among records that carried a finite number.

**Structure.** Random intercepts for event block, observer cluster and
generalized location cluster. Adjusted for year as a factor, protocol, log
duration, log of one plus travel distance, observer count. Benjamini-Hochberg
correction across the fixed 49-species family, keyed
`analysis_role__outcome__contrast`.

**Headline results.** Counts rose for 42 of 46 estimable species, 18 surviving
correction. Reporting rose for 28 of 48, 13 surviving. No negative survived in
either outcome.

---

## 3. CRITICAL: what day 0 actually is

Established 26 July 2026 by the distance-band follow-up run, and **not yet
propagated into the manuscript**.

Day 0 is `floor((StartDate + EndDate) / 2)` from the DFO record, or the
available endpoint if only one exists. **It is not an observed biological
onset.** The manuscript currently says "recorded onset" roughly thirty times.

Supporting numbers, from `DISTANCE_BAND_FOLLOWUP_REPORT.md` section 7:

- 1,144 source events in the 0 to 26 km linked frame
- 466 have same-day endpoints; 744 within one day; 904 within two
- endpoint span: median 1 day, 75th percentile 2, 95th percentile 4, max 72
- survey cadence is **not available**, so true onset precision is not
  identifiable

**The fix is one honest definition in Methods, not thirty word changes.** Define
the anchor where periods are defined, then "recorded onset" is defensible
shorthand. This also killed the proposed ±3 day symmetric window test, correctly:
gate result `FAIL_NO_SURVEY_CADENCE_AND_ANCHOR_IS_NOT_OBSERVED_ONSET`.

---

## 4. Manuscript lineage

All manuscript builds live in the Claude session outputs directory, not in this
repository. Copies of the current ones are in `manuscript/` beside this file.
Each version was produced by a Python script using `python-docx`, rebuilding
from the previous version so images, equations, styles and line numbering
survive.

| Version | What changed |
|---|---|
| v12 | Starting point, supplied in the original handoff packet |
| v13 to v18 | Editorial review pass: abstract, title, first person, citation audit, claim trace, four corrections from an independent verification run |
| v19 | Thirteen text fixes from a blind referee report |
| v20 | Binary any-link sensitivity, guild timing test, comparator intervals, prediction baselines, resolved 850/51 placeholder |
| v21 | Corrected guild test after exact covariance; corrected paired outcome comparison |
| v22 | Section 4.4 consolidated from six paragraphs to four |
| v23 | Expansive draft: new Section 3.3 by feeding group, fuller Introduction and Discussion. **Structurally broken**, insertions landed reversed |
| v24 | Full style pass, rebuilt from the clean v22 base rather than v23 |
| v25 | First person removed from the body; limitations sentence removed from the abstract |
| v26 | Scientific name at first mention of all 43 named species |
| v27 | Count timing profile added to 3.4 as Figure 4; ordination null reported |
| v30 | Author's second round: 15 comments, 5 insertions, 6 deletions |
| v31 | The 15 v30 comments applied. Delivered as clean text, which was wrong: his comments sat unanswered and none of the work was visible. Also introduced two text corruptions and destroyed 12 of 15 comment anchors |
| v32 | Rebuilt as tracked changes against v30 with his own edits accepted. v31 corruptions repaired. Distributed hedging cut, 24 places |
| v33 | Ordination removed from 3.4; case study moved into 3.4 with a placeholder Figure 5; 17 headings retitled; italics fixed across tracked-change boundaries |
| **v34** | **Current.** Case-study cross-reference repointed from phantom Figs. S4 to S6 at Figure 5 |

**Supplement is at v34**, with Figure S3 (the NMDS ordination) removed. Tables S1
to S9 and Figures S1 to S2 are unchanged and keep their numbering.

**v30 in the uploads directory carries the author's tracked changes and 15
comments**, made 26 July. Every manuscript from v32 onward is tracked against
v30-with-his-edits-accepted, so rejecting all changes returns exactly that
document. Verify it with `tools/verify_v34.py` after any build.

---

## 5. Verification discipline

This project has been through several independent verification passes and the
discipline should be maintained. Every numeric claim in the manuscript has been
traced to an archived output.

**Automated check that must be re-run after every manuscript build:** extract
every `X.XX (Y.YY–Z.ZZ)` triple from the body and match against
`figures_out/tableS_primary_contrast_49x2.csv` and
`outputs/referee_reads_v1/item2_specificity_comparators.csv`. As of v27, 44 of
44 match exactly.

**Errors caught this way, all real:**

- A claimed "median within 2% of one" pre-trend statement was false; the true
  maximum is 1.021.
- `log` versus `log1p` for travel distance in Methods.
- Delta-method described where the variance is an exact linear contrast.
- Mallard count upper bound written as 1.11 when it is 1.1046.
- Glaucous-winged Gull count lower bound written as 1.14 when it is 1.1346.
- A convergence double-count in v12: one singular fit counted twice.
- A paired McNemar test computed on the wrong contrast, caught by arithmetic
  impossibility (29 positives claimed in a 46-subset of 48 that contains 28).

**Structural checks that have caught real bugs:** paragraph insertion order,
italic runs lost during text replacement, figure and equation paragraphs
overwritten by off-by-one indices, ambiguous genus abbreviations
(*Melanitta americana* and *Mareca americana* both give *M. americana*).

---

## 6. Analyses that exist beyond the primary

| Analysis | Output directory | Status |
|---|---|---|
| Primary event study | `outputs/post_stage4a_sog_event_study_v1/` | Frozen, hash-locked |
| Reproduction with persisted covariance | `outputs/post_stage4a_sog_event_study_v1_1/` | Reproduces 13 and 18 exactly |
| Editorial requested contrasts | `outputs/editorial_requested_analysis_v1/` | Active-minus-pre contrasts, absolute predictions, binary any-link sensitivity |
| Referee reads | `outputs/referee_reads_v1/` | Ten read-only items |
| Referee reads follow-up | `outputs/referee_reads_followup_v1/` | Corrected McNemar and exact-covariance guild test |
| Count-only response profiles | `outputs/count_only_response_profiles_v1/` | Family timing curve, heatmaps, PCA, NMDS. The ordination half is retained as a record but is not reported in the manuscript |
| Distance bands, Bald Eagle | `outputs/post_stage4a_distance_band_sensitivity_v2/` | 13 bands to 26 km |
| Distance bands, Glaucous-winged Gull | `outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/` | 13 bands to 26 km |
| Distance band follow-up | `outputs/post_stage4a_distance_band_followup_v1/` | BH correction, terrestrial controls, tight contrast |

**Key results from the later analyses, all verified:**

- **Guild timing test.** Both outcomes reject equal timing across the seven
  pre-assigned feeding groups. Reported number Q = 117.3 on 6 df, p < 0.001;
  reporting Q = 15.0, p = 0.02. Diving sea ducks peak during early egg; gulls
  and shoreline scavengers at the anchor. Residual heterogeneity 76% and 39%.
- **Family timing curve.** Equal-weight geometric mean count ratios across the
  five periods: 1.00, 1.03, 1.06, 1.11, 1.07. Share of species above one rises
  from 24 of 46 to 39 of 46.
- **Ordination is a null, and is no longer reported.** Species do not form
  discrete response types, and the pre-assigned groups overlapped in both PCA
  and NMDS. The author cut it from the manuscript on 26 July: the surviving
  claim in Section 3.4 now rests on the residual heterogeneity from the guild
  timing test, which says the same thing without a second analysis. Figure S3
  was removed from the supplement.

  **Do not reinstate it, and do not delete the record that it was run.** The
  outputs in `outputs/count_only_response_profiles_v1/` and
  `outputs/response_clustering_v1/`, the report at
  `RESPONSE_CLUSTERING_REPORT.md`, and the registry rows for M22 in
  `metadata/model_registry.csv`, `metadata/model_progression_gate.csv` and
  `metadata/hypothesis_model_multiplicity_registry.csv` all stay as they are.
  They document an analysis that was performed and pre-registered. Removing them
  would misrepresent what was done; a decision not to report a null is not a
  licence to erase it.
- **Distance bands.** Within 2 km both species are flat through both pre-spawn
  windows and rise at the anchor. Tight contrast, days 0 to 3 against days −7 to
  −1: gull reporting 1.31, gull counts 1.40, eagle counts 1.22 all survive BH;
  eagle reporting 1.23 does not.
- **Terrestrial controls.** Neither American Robin nor Chestnut-backed Chickadee
  shows a near-band spike at the anchor. Robin is not flat overall: its reporting
  is elevated at 0 to 2 km during immediate pre-spawn, BH q = 0.039.

---

## 7. Standing constraints

From the original brief. Still in force unless the author says otherwise.

1. Use only findings verifiable in the manuscript or repository output.
2. Do not invent, estimate or back-calculate any number, interval, p-value,
   date, species total, reference or DOI.
3. Do not rerun or redesign the primary analysis as part of writing.
4. **Preserve the fixed 49-species family.** Do not remove taxa after seeing
   results or because sample sizes are low. This was proposed once and rejected
   after showing a top-25 cut would delete 12 of 31 significant results.
5. Do not access, analyse or release protected 2026 to 2028 confirmation
   records.
6. Do not add citations unless necessary and verified.
7. Do not overwrite frozen analytical outputs in
   `outputs/post_stage4a_sog_event_study_v1/`.
8. Missing author information is preserved as
   `[[AUTHOR INPUT REQUIRED: description]]`.
9. Do not set `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED` yourself. The value is
   `through_2025_post_result_refinement_v1` and only the author sets it.

**Author preferences.** No em dashes. Concise and direct. Must not read as AI
writing. No sycophancy. See `WRITING_STYLE.md`, which is now the authority and
whose section 9 is derived from the author's own edits.

---

## 8. Where things stand

**Compliant.** Abstract 250 words. Body 10,562. References 32. Four figures.
Author-year citations. Supplementary material with nine tables and three
figures.

**Outstanding, author only.** Six `[[AUTHOR INPUT REQUIRED]]` placeholders:
repository DOI in two places, funding statement, AI declaration,
acknowledgements, and one on validation refit species.

**Outstanding, production.** Figures must be regenerated as vector PDF or at
full-page width and 500 dpi. This is the one outright compliance failure. Six R
scripts exist in the session outputs under `figures_ggplot2/` and have never
been executed, because R is not available in the Claude sandbox.

**Outstanding, analysis.** Block-aware intervals over the 58 event blocks remain
the only item that could change the counts of 13 and 18. A commission prompt
exists at `prompts/codex_clustering_prompt.md`. Three lines of evidence suggest
the correction will be small: 99.8% of exposed checklists sit in a block
represented in both zones, the contrast is identified within blocks, and the one
model whose block variance was separately estimable put it at zero.

**Deferred by the author.** Using the DFO spawn index as a biomass exposure
rather than only presence, location and timing. The author disagrees with the
current Methods position and wants this tried. Explicitly postponed.
