# Full claim trace: mer_manuscript_v15.docx

Traced 24 July 2026 against `JTDingwall/herring-x-ebird-version-2` at commit
`1186d8eaaa29fba3a97da85c7a38298190592f05`, the three embedded figure images, and
the publisher record for every reference.

Scope: 131 numeric sentences, 32 references, 3 figures, 0 tables.

## Verdict

No claim in the manuscript contradicts anything I could check. Every internal
arithmetic identity holds, every cross-section repeat agrees, every reference is
cited and every citation resolves.

Three findings need action, none of them a wrong number: one internal
inconsistency introduced during editing, one class of quantity that cannot be
checked against the archive at all, and repository shorthand sitting inside a
placeholder.

## Evidence tiers

| Tier | Meaning | Count |
|---|---|---|
| A | Recomputed by me from the frozen release, exact match | 11 quantities |
| B | Read directly from a repository artefact at the pinned commit | 24 quantities |
| C | Internally consistent and arithmetically sound, source not reachable | 19 quantities |
| D | From the remediation run, not independently checked here | 4 statements |
| E | Literature claim, checked against the cited source | 9 claims |

---

## 1. Tier A: recomputed from the frozen release

The primary estimand is `did_active_0_14_day` minus `did_pre_14_day` on the link
scale. Recomputing from `main_species_panel_v1.csv` reproduces the manuscript
exactly for every species I hold rows for.

| Species | Outcome | Recomputed | Manuscript | Match |
|---|---|---|---|---|
| Surf Scoter | count | 1.3038 | 1.30 (§3.2) | exact |
| Surf Scoter | reporting | 1.0034 | 1.00 (§3.6) | exact |
| Harlequin Duck | reporting | 1.1503 | 1.15 (§3.6) | exact |
| Harlequin Duck | count | 1.2027 | positive, §3.2 | consistent |
| White-winged Scoter | count | 1.1714 | positive, §3.2 | consistent |
| White-winged Scoter | reporting | 1.0817 | not significant, open point Fig 2 | consistent |
| Common Merganser | reporting | 1.1633 | positive, §3.2 and §3.3 | consistent |
| Common Merganser | count | 1.1109 | positive, §3.2 and §3.3 | consistent |
| Glaucous-winged Gull | reporting | 1.1374 | positive, §3.2 | consistent |
| Glaucous-winged Gull | count | 1.1694 | positive, §3.2 | consistent |
| Mallard | count | 1.0722 | positive, §3.5 | consistent |

## 2. Tier B: read from repository artefacts

From `model_diagnostics_v1.csv` (all 100 rows):

- 96 of 100 components fitted; 4 failed. Exact.
- Glaucous Gull 185 quantified reports, both models failed. Exact.
- Surfbird 1,063 and Rhinoceros Auklet 1,816, count models failed. Exact.
- Western Gull 712, singular fit, retained. Exact.
- `converged` is TRUE for all 96 fitted components, which is what §3.1's
  optimizer-status wording now says.

From `R/post_stage4a_sog_event_study_v1.R`:

- Six period definitions and their day ranges. Exact.
- Duration weights 4/15 and 11/15. Exact.
- Twelve exposure terms, six periods by two zones. Exact.
- Near <5 km, reference 5–20 km. Exact.
- Suppression threshold 20. Exact.
- BH families keyed `role__outcome__contrast`. Exact.
- 49 core species and 2 comparators, gate-enforced. Exact.
- `nAGQ = 0L` for reporting, REML `lmer` for counts. Exact.
- Wald intervals, `estimate ± 1.959963984540054 · SE`. Exact.
- 217,200 SoG checklists, gate-enforced. Exact.
- `calc.derivs = FALSE`, which is why §3.1 says optimizer status rather than
  full convergence.

From `OPEN_QUESTIONS.md`, `CHANGES.md`, `REPO_MAP.md`:

- Northern Shoveler core-family q = 0.0115. Exact.
- American Herring Gull 0.9% and Iceland Gull 2.2% prevalence. Exact.
- 12% of near-zone checklists >2.5 km, 3% >4 km. Exact.
- 5,163 checklists spanning baseline and active, 5.5% of exposed. Exact.
- VIF 1.22 to 1.26. Exact.
- eBird/Clements v2025 and the three gull split/lump events. Exact.

From `canonical_species_registry.csv`: all 18 binomials, and the guild
assignments underlying the dabbling-duck and comparator framing.

## 3. Tier C: internally sound, source not reachable at this commit

These are consistent with everything else and arithmetically correct, but the
artefact that would confirm them is not in the release I can read.

Family totals: 28 up and 20 down of 48 reporting; 42 up and 4 down of 46 count;
13 and 18 significant. **Partially corroborated:** I counted exactly 13 filled
points in Figure 2's reporting panel and exactly 18 in the count panel, with no
filled point below one in either. The figure and the text agree.

Frame counts: 1,120 events, 58 event blocks, 29,248 observer clusters, 22,980
location clusters, smallest cell 2,992, 850 events and 51 blocks in both zones.

Sensitivity: 72,443 single-event checklists, 19 of 49 count models; nearest-event
41 species, 34 of 41 (82.9%), 34 of 48 (70.8%), 18 preserved with 17 significant,
11 of 13 preserved with 7 significant; the four material changes.

Finite-versus-X: 41 estimable, 18 positive, 23 negative, none significant, 30
singular.

Standardized predictions: Glaucous-winged Gull 2.00 pp (1.10–2.91), Short-billed
Gull 3.34 birds (2.59–4.09), Surf Scoter 10.94 birds (7.43–14.46).

Six quoted ratios with intervals: Bonaparte's 1.48 (1.22–1.79), American Herring
1.39 (1.23–1.57), California 1.32 (1.21–1.43), Long-tailed Duck 1.43 (1.29–1.60),
Surf Scoter 1.30 (1.21–1.40), Short-billed Gull 1.30 (1.23–1.37).

**Why they cannot be checked.** The frozen release holds period-versus-baseline
contrasts only. There is no active-minus-pre-onset row, so intervals, p-values
and q-values for the primary estimand depend on a covariance matrix that is not
archived. Point estimates are recoverable, as Tier A shows. Intervals are not.
This is review issue 1 and it remains open.

## 4. Tier D: from the remediation run, not checked here

The four §3.6 pre-trend statements: no reporting contrast surviving adjustment in
either pre-onset window; medians within 2% of one in every window and outcome;
Great Blue Heron 1.07 and Iceland Gull 1.25, both q = 0.009, days −7 to −1.

Re-running `figures_ggplot2/05_supp_pretrend_and_tables.R` confirms all four in
about a minute. These are the only numbers in the manuscript that have not passed
through a check in this session.

## 5. Tier E: literature claims against cited sources

| Claim | Source | Status |
|---|---|---|
| Five species took roughly a third of one season's spawn deposition, most of it gulls | Bishop and Green 2001 | Checked. 31% of estimated deposition; Glaucous-winged 26% plus Mew 3% is most of it. |
| Glaucous-winged Gull alone about a quarter | Bishop and Green 2001 | Checked. 26%. |
| Harlequin Ducks aggregate at spawning sites in the Strait of Georgia | Rodway et al. 2003 | Title and subject match. |
| Scoters change movement and foraging during spawning | Lewis et al. 2007; Lok et al. 2008 | Titles and subjects match. |
| Surf Scoters may track successive spawning areas | Lok et al. 2012 | "Silver wave hypothesis" paper. Matches. |
| Complete checklists and semi-structured survey design | B. L. Sullivan et al. 2009; Kelling et al. 2019 | Standard, correctly attributed. |
| Parallel-trends assumption in ecology and policy evaluation | Larsen et al. 2019; Wing et al. 2018 | Verified against publisher record. |
| Gull taxonomy v2025 | Clements et al. 2025 | Correct source for taxonomy decisions. |
| Eagles take spawning herring, scavenge, and gather where predators concentrate prey | Willson and Womble 2006 | Review of vertebrate exploitation of spawning herring. Appropriate. |

One claim is deliberately uncited: dabbling ducks taking stranded and drifting
eggs, carried as `(J. T. Dingwall, personal observation)` in §3.5 and in the first
person in §4.2. Bishop and Green covers gulls, sea ducks and shorebirds but not
dabblers, so there is no literature to cite. The manuscript says so.

## 6. Figures

**Figure 1**, study design schematic. No data claims. Caption matches content.
Every box and arrow corresponds to a Methods statement.

**Figure 2**, complete-family forest plot. Content verified against the family
totals: 13 filled reporting points, 18 filled count points, none filled below
one, Glaucous Gull absent from both panels as a non-estimable component. Caption
correctly states the estimand, the q threshold, the family, and the fact that
non-estimable components have no point. It also now cross-references Figure 3's
different reference point.

**Figure 3**, period profiles for eight species. I verified every plotted point
against the frozen `did_*` ratios for the five species I hold rows for. All match
to two decimal places: Surf Scoter count 0.96 / 1.05 / 1.33 / 1.13; Surf Scoter
reporting 0.99 / 1.02 / 0.98 / 1.03; White-winged Scoter count 1.12 / 1.11 /
1.39 / 1.03; White-winged Scoter reporting 0.84 / 0.91 / 0.91 / 0.92; Harlequin
count 1.02 / 1.14 / 1.25 / 1.10; Harlequin reporting 0.95 / 1.09 / 1.09 / 1.15;
Common Merganser reporting 1.02 / 1.25 / 1.17 / 1.11; Glaucous-winged Gull count
1.04 / 1.27 / 1.20 / 1.07. Caption matches content, including the baseline
reference and the pointer to Figure 2 for the formal test.

**Tables:** none. Consistent throughout; no table is referenced anywhere in the
text.

## 7. Citations and references

- 32 references, every one carrying a DOI or a stable publisher or agency URL.
- Zero uncited references.
- Zero in-text citations lacking a reference entry.
- Author–year style applied consistently; alphabetical list.
- Lok 2008 correctly precedes Lok 2012.

## 8. Findings requiring action

**8.1 Internal inconsistency, introduced during editing.** §2.1 now says the
records "came from the eBird Basic Dataset released in May 2026". Data
availability still says "EBD_relMay-2026". Same release, two names. Pick one and
use it in both places. The release-code form is the more citable.

**8.2 Repository shorthand inside the §2.1 placeholder.** The placeholder text
contains "Stage 4A", "analysis_status" and
"post_result_ecologically_motivated_refinement". That is correct for a note to
yourself and wrong for a manuscript, and the original brief specifically excluded
repository shorthand. It disappears when you resolve the placeholder, but do not
let it reach a reviewer.

**8.3 The primary contrast still cannot be verified against the archive.** Nineteen
Tier C quantities, including all six quoted ratios and all three standardized
predictions, sit on outputs that are not in the frozen release. Their point
estimates reproduce and Figure 2 corroborates the family totals, so I have no
reason to doubt them. But a referee who opens the repository cannot confirm a
single interval in the abstract. This is unchanged from the original review and it
is the one substantive gap.

## 9. What I could not check, stated plainly

- Confidence intervals, p-values and q-values for the primary estimand. Not
  archived.
- The standardized absolute-scale predictions. Not archived.
- The nearest-event sensitivity output. Not archived.
- The finite-versus-X family. Not archived.
- Frame counts beyond the 217,200 gate: event, block, observer and location
  cluster totals.
- Whether the two validation refits, Laplace and zero-truncated negative
  binomial, were run and on which species. The manuscript carries a placeholder.
- The four pre-trend statements, which come from the remediation run.
