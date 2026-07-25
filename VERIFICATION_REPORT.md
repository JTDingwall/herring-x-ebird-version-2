# Verification report — MER manuscript v16

Scope: the ~17 quantities an earlier editorial review could not verify, plus
re-checks of the 12 it did verify. Reference commit `1186d8ea`
("Complete nearest-event robustness sensitivity and v9 revision").

Nothing in the manuscript was edited. Nothing in
`outputs/post_stage4a_sog_event_study_v1/` was modified — all six hash-locked
files still match `output_hash_manifest_v1.csv`, with the documented benign
CRLF mismatch on `execution_record_v1.yml`.

**Headline: Task 1 succeeded.** Both files the review believed missing exist,
at the reference commit, and they close Tasks 3, 4 and 5 without any refit.
Two substantive disagreements remain, plus one number with no traceable source.

---

## 1. Disagreements

### 1.1 The "within 2% of one" pre-trend claim is false as written

§3.6: *"No checklist-reporting contrast in either window survived adjustment,
and the median contrast across species lay within 2% of one in every window and
outcome."*

The first clause is correct. The second is not. Recomputed directly from
`outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv`:

| Outcome | Window | n estimable | Median ratio | Deviation from 1 | Within 2%? |
|---|---|---|---|---|---|
| reporting | −14 to −8 | 48 | 0.987482 | 1.252% | yes |
| reporting | −7 to −1 | 48 | 0.989646 | 1.035% | yes |
| reported number | −14 to −8 | 46 | 1.008492 | 0.849% | yes |
| **reported number** | **−7 to −1** | **46** | **1.021071** | **2.107%** | **no** |

The reported-number median in the days −7 to −1 window is 2.107% above one, not
within 2%. The margin is small but the statement is quantitative and universal
("in every window and outcome"), so as written it is wrong.

The finding does not depend on a median convention. With n = 46 the median is
the mean of the two central order statistics, and *both* exceed 1.02
individually (1.020562 and 1.021580), so any interpolation rule between them
still lands above 2%.

For completeness, the combined −14 to −1 window (not one of the two the
sentence refers to) gives 1.012147, within 2%.

The author's options are to widen the bound (2.2% is safe), to restrict the
claim to the reporting outcome, or to state the reported-number figure
explicitly. This is the author's call; nothing was changed.

### 1.2 §2.4 misdescribes the travel-distance covariate

§2.4: *"Models adjusted for checklist year as a factor, protocol, the natural
logarithms of checklist duration and travel distance, and the number of
observers."*

Everything holds except travel distance. From `R/stage4a_production.R:50-51`,
which the event study calls at `R/post_stage4a_sog_event_study_v1.R:880`:

```r
events$log_duration        <- log(events$duration_minutes)      # natural log
events$log_effort_distance <- log1p(events$effort_distance_km)  # log(1 + km)
```

Travel distance enters as **log(1 + distance in km)**, not the natural
logarithm of travel distance. This is not a nitpick: stationary checklists have
distance 0, where `log(0)` is undefined, so `log1p` is doing real work. It is
also consistent with the standardization profile recorded in
`absolute_predictions.csv` (`..._0km_...`), which requires `log1p(0) = 0`.

Suggested correction, not applied: *"…the natural logarithm of checklist
duration, log(1 + travel distance in km), and the number of observers."*

### 1.3 Two premises in the task description are incorrect

Reported because they change where the author should point reviewers.

**(a) The two files are at the reference commit.** The task states
`active_minus_pre_contrasts.csv` and `absolute_predictions.csv` are "not at the
reference commit". Both are present at `1186d8ea`, under
`outputs/editorial_requested_analysis_v1/`, and are byte-identical to the
copies in the working tree. The review appears to have searched only
`outputs/post_stage4a_sog_event_study_v1/`.

**(b) The reference commit is not on `main`.** `1186d8ea` is the tip of the
unmerged branch `origin/agent/conventional-exposure-sensitivity-v9`. It is
*not* an ancestor of `main`; the two diverge from `f597b82` (6 commits on the
branch, 5 on main). The practical consequence is significant:
`outputs/conventional_exposure_sensitivity_v1/` — the entire nearest-event
sensitivity behind §3.6 — **exists only on that branch and is absent from
`main`**. If the author archives `main`, the §3.6 sensitivity output ships
missing. This should be merged or explicitly archived before submission.

---

## 2. Now verified

### Task 1 — the missing artefacts (found)

| File | Path | Status |
|---|---|---|
| `active_minus_pre_contrasts.csv` | `outputs/editorial_requested_analysis_v1/` | present at `1186d8ea` and at HEAD, identical |
| `absolute_predictions.csv` | `outputs/editorial_requested_analysis_v1/` | present at `1186d8ea` and at HEAD, identical |

`active_minus_pre_contrasts.csv` carries 196 rows (49 species × 2 outcomes × 2
comparisons), with `full_covariance_used = TRUE` on every row — i.e. the exact
linear-contrast variance, the thing Task 3 said needed `vcov(fit)`. No refit was
required.

### Task 2 — primary contrast point estimates

Written to `verification/primary_contrast_point_estimates.csv` (98 rows: 49
core species × 2 outcomes), computed as
`exp(estimate[did_active_0_14_day] − estimate[did_pre_14_day])` from
`effect_estimates_v1.csv`. Structure confirmed: 1,372 core rows = 686 per
outcome = 49 species × 14 contrasts.

**All twelve review values reproduce**; largest absolute deviation 4.5e-05,
none beyond the 1e-4 threshold.

| Species | Outcome | Expected | Computed |
|---|---|---|---|
| Surf Scoter | count | 1.3038 | 1.303834 |
| Surf Scoter | reporting | 1.0034 | 1.003393 |
| White-winged Scoter | count | 1.1714 | 1.171425 |
| White-winged Scoter | reporting | 1.0817 | 1.081714 |
| Harlequin Duck | count | 1.2027 | 1.202722 |
| Harlequin Duck | reporting | 1.1503 | 1.150277 |
| Common Merganser | count | 1.1109 | 1.110919 |
| Common Merganser | reporting | 1.1633 | 1.163319 |
| Glaucous-winged Gull | count | 1.1694 | 1.169415 |
| Glaucous-winged Gull | reporting | 1.1374 | 1.137355 |
| Mallard | count | 1.0722 | 1.072191 |
| Short-billed Gull | count | 1.2998 | 1.299756 |

**The four the review could not reach — all confirm the manuscript:**

| Species | Outcome | Manuscript | Computed |
|---|---|---|---|
| Bonaparte's Gull | reporting | 1.48 | 1.480904 |
| American Herring Gull | reporting | 1.39 | 1.390628 |
| California Gull | reporting | 1.32 | 1.315386 |
| Long-tailed Duck | count | 1.43 | 1.432137 |

Estimable components, from archived `did_active_0_14_day` q-values only:
**48 reporting** (1 `failed_numerical_fit_no_fallback`) and **46 count**
(3 `failed_insufficient_support`). Both as claimed.

### Task 3 — intervals, q-values and family tallies

From `active_minus_pre_contrasts.csv`, `comparison == active_minus_pre14`.

All six quoted results reproduce exactly at the manuscript's precision:

| Species | Outcome | Manuscript | Computed | q |
|---|---|---|---|---|
| Bonaparte's Gull | reporting | 1.48 (1.22–1.79) | 1.4809 (1.2241–1.7916) | 3.21e-04 |
| American Herring Gull | reporting | 1.39 (1.23–1.57) | 1.3906 (1.2335–1.5678) | 8.51e-07 |
| California Gull | reporting | 1.32 (1.21–1.43) | 1.3154 (1.2119–1.4278) | 1.35e-09 |
| Long-tailed Duck | count | 1.43 (1.29–1.60) | 1.4321 (1.2855–1.5954) | 4.06e-10 |
| Surf Scoter | count | 1.30 (1.21–1.40) | 1.3038 (1.2139–1.4005) | 2.32e-12 |
| Short-billed Gull | count | 1.30 (1.23–1.37) | 1.2998 (1.2290–1.3746) | 1.02e-18 |

Family tallies, all as claimed:

| Outcome | Estimable | Up | Down | q < 0.05 | Significant negative |
|---|---|---|---|---|---|
| reporting | 48 | 28 | 20 | 13 | 0 |
| count | 46 | 42 | 4 | 18 | 0 |

**Independent corroboration.** The editorial run and the frozen post-Stage-4A
release are two separate fits. Their `active_minus_pre14` ratios agree to
**max absolute difference 5.6e-08** across all 94 comparable components. The
manuscript's primary estimand is therefore reproducible from two independent
artefacts. Written to
`verification/primary_contrast_intervals_crosscheck.csv`.

### Task 4 — the two "orphaned" analyses are not orphaned

Both were produced by `R/editorial_requested_analysis_v1.R`, driven by
`scripts/run_editorial_requested_analysis_v1.R`. Runnable in principle: it
requires `EDITORIAL_PROTECTED_ROOT`, optional `EDITORIAL_R_LIBRARY`, and the
authorization acknowledgement checked at `R/editorial_requested_analysis_v1.R:989`.
It could not be executed here (see §5).

**Standardized predictions (§3.4)** — `absolute_predictions.csv`, quantity
`active_minus_pre14`, configuration `observed_covariate_standardization`:

| Species | Outcome | Manuscript | Computed |
|---|---|---|---|
| Glaucous-winged Gull | reporting | 2.00 pp (1.10–2.91) | 2.0003 (1.0956–2.9050) |
| Short-billed Gull | count | 3.34 birds (2.59–4.09) | 3.3429 (2.5917–4.0940) |
| Surf Scoter | count | 10.94 birds (7.43–14.46) | 10.9435 (7.4302–14.4568) |

Worth flagging for the author: the file also contains a
`standardized_one_additional_link` configuration whose values differ
substantially (Surf Scoter 15.89 rather than 10.94). The manuscript quotes the
observed-covariate figures; §3.4 should make the standardization explicit so
the two are not confused. The generating code confirms this — the numbers are
emitted by an `sprintf` over the observed-covariate objects at
`R/editorial_reporting_v1.R:702-707`.

**Finite-versus-X family (§3.6)** — `finite_vs_x_results.csv`,
`comparison == active_minus_pre14`. All five figures reproduce exactly:

| Quantity | Manuscript | Computed |
|---|---|---|
| estimable | 41 | 41 |
| positive | 18 | 18 |
| negative | 23 | 23 |
| surviving adjustment | none | 0 (min q = 0.545) |
| singular fits | 30 | 30 |

### Task 5 — nearest-event sensitivity

Found at `outputs/conventional_exposure_sensitivity_v1/`, added by the
reference commit itself, on the unmerged branch (see §1.3). "Conventional
exposure" is the nearest-event design: `design_selection.csv` records candidate
`nearest_event` as `selected = TRUE`, and `sensitivity_execution_record.yml`
lists `sensitivity_ids: [nearest_event]`.

From `comparison_summary.csv`, every §3.6 figure reproduces:

| Claim | Value |
|---|---|
| all checklists retained | `retained_checklists` 217,200, `retained_fraction` 1 |
| estimable count models | 41 |
| count sign concordance | 34 / 41 = 82.93% |
| reporting sign concordance | 34 / 48 = 70.83% |
| count BH directions preserved | 18 / 18, 17 still significant |
| reporting BH directions preserved | 11 / 13, 7 still significant |
| material changes | 3 reporting + 1 count = 4 |

The four material changes, from `interpretation_changes.csv`:

| Species | Outcome | Manuscript | Computed |
|---|---|---|---|
| Surf Scoter | reporting | 1.00 → 0.71 | 1.0034 → 0.7085 |
| Harlequin Duck | reporting | 1.15 → 0.84 | 1.1503 → 0.8411 |
| American Wigeon | reporting | 1.11 → 0.99 | 1.1056 → 0.9937 |
| Barrow's Goldeneye | count | 1.10 → 0.95 | 1.0996 → 0.9500 |

### Task 6 — frame counts

Five of six verified from `outputs/editorial_requested_analysis_v1/verified_dataset_totals.csv`:

| Quantity | Claimed | Found |
|---|---|---|
| source events | 1,120 | 1,120 |
| event blocks | 58 | 58 |
| observer clusters | 29,248 | 29,248 |
| generalized location clusters | 22,980 | 22,980 |
| eligible checklists | 217,200 | 217,200 |

Independently corroborated by the per-model columns in
`sensitivity_comparisons.csv` (`model_event_blocks` 58, `model_observer_clusters`
29,248, `model_generalized_locations` 22,980), and internally consistent:
`event_block_influence_support.csv` sums to 58 blocks and 217,200 checklists.

Baseline/active overlap verified from `diagnostics/D4_baseline_active_cooccupancy.csv`:
**5,163** checklists occupy both a baseline and an active cell via different
events, out of 93,342 with modeled exposure = **5.53%**, consistent with the
manuscript's 5.5% of exposed checklists.

The sixth (850 source events / 51 event blocks in both zones) is a provenance
gap — see §4.

Also re-confirmed in passing: the smallest period-by-zone cell is 2,992
(near, spawn start), and it is genuinely the minimum of all twelve cells in
`joint_exposure_support_v1.csv`.

### Task 8 — the two Methods sentences

**Sentence 1 — partially correct.** `post_stage4a_formula_v1`
(`R/post_stage4a_sog_event_study_v1.R:180-191`) has fixed effects: exposure
terms, `factor(checklist_year)`, `protocol`, `log_duration`,
`log_effort_distance`, `observer_count`. So "checklist year as a factor",
"protocol", "the number of observers" and the natural log of duration are all
accurate. Travel distance is not — see §1.2.

"Count models were fitted by restricted maximum likelihood" is **accurate**:
the count branch is `lme4::lmer(formula, data = d, REML = TRUE, ...)`
(line 561-563; detection uses `glmer` with a binomial family).

**Sentence 2 — accurate, and the review's reasoning is correct.** At the
reference commit, lines 433-434 and 453-502:

```r
beta       <- lme4::fixef(fit)
covariance <- as.matrix(stats::vcov(fit))
...
estimate  <- sum(vector * beta)
variance  <- drop(t(vector) %*% covariance %*% vector)
conf_low  <- estimate - 1.959963984540054 * standard_error
ratio_conf_low <- exp(conf_low)
```

`t(c) %*% V %*% c` against the complete `vcov(fit)` is the **exact** variance of
the linear contrast, not a delta-method approximation — the review's claim
holds, and the earlier wording was indeed wrong. The interval is Wald on the
link scale (the multiplier is `qnorm(0.975)` to 16 digits) and then
exponentiated. The trailing clause "inherit that approximation" refers back to
nAGQ = 0 in the preceding sentence, which is coherent.

### Task 7 — the four pre-trend statements

The supplied script could not be run (see §3), but all four statements were
verified **independently** from the frozen release, which is what the task
wanted — they no longer rest on a single earlier run.

| Statement | Verdict |
|---|---|
| No checklist-reporting contrast survives adjustment in either pre-onset window | **confirmed** (0 survivors in both windows) |
| Median contrast within 2% of one in every window and outcome | **contradicted** — see §1.1 |
| Two reported-number contrasts survive days −7 to −1: Great Blue Heron 1.07, Iceland Gull 1.25 | **confirmed** (1.066016, 1.252903) |
| Both carry q = 0.009 | **confirmed** (both 0.009436) |

The BH implementation used was validated against the release: recomputing
q-values from p-values within each of the 42 multiplicity families reproduces
the archived q-values to **max deviation 2.9e-15**.

These agree with the existing
`outputs/post_stage4a_sog_event_study_pretrend_v1/` outputs, which were derived
from the same frozen release by a different route.

---

## 3. Still unverified

| Item | Category | Why |
|---|---|---|
| 850 source events / 51 event blocks in both zones | **no computed source** | Hard-coded literal; protected frame absent. See §4. |
| `figures_ggplot2/05_supp_pretrend_and_tables.R` console output | **artefact missing** | The script was never supplied — only the `.docx` was uploaded, and no `figures_ggplot2/` directory exists in the working tree or anywhere in git history. R is also not installed here. Its four claims were verified independently instead (§2, Task 7), so nothing is left materially unchecked. |
| Laplace (nAGQ = 1) reporting sensitivity | **not run** | Optional, and conditional on Task 3 refitting. Task 3 needed no refit. Also blocked twice over: `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED` is unset, and R is absent. |
| Persisted `fixef`/`vcov` in `outputs/post_stage4a_sog_event_study_v1_1/` | **not run** | Explicitly conditional in Task 3 on the file not being found. It was found, so no refit and no persistence step. The code for it already exists (commit `c720812`) but has never been executed. |

Nothing in the manuscript's quantitative claims is left unverified except the
850/51 pair.

---

## 4. Provenance gaps

**One number in the manuscript has no traceable source: 850 source events and
51 event blocks contributing to both zones** (§2.3).

It appears in exactly two places, both narrative:

- `R/editorial_reporting_v1.R:717` — a static string literal
- `docs/editorial_requested_analysis_handoff.md:25` — the rendered output of that literal

No CSV, YAML, or diagnostic in the repository contains it, on any branch. It is
not computed. This is visible in the source: the surrounding sentences in the
same function are built with `sprintf` from fitted objects, while the 850/51
sentence is plain text baked into the string.

It cannot be recomputed here — `data/raw`, `data/interim` and `data/derived`
contain only `.gitkeep` and a README, so the protected frame is not present.

The related figures *are* traceable: `period_zone_support.csv` gives
`source_events` per period-by-zone cell (654 baseline-near, 948
baseline-reference, and so on), and 58 blocks / 1,120 events are in
`verified_dataset_totals.csv`. It is only the both-zones intersection that has
no artefact. Recomputing it needs the link table on the machine that holds the
protected frame.

Given the sentence's history — v8 carried an explicit
`[[ANALYSIS REQUIRED: report the number of source events and event blocks with
adequate near and reference support…]]` placeholder at exactly this point —
the author should confirm the number was actually computed and not estimated
before submitting.

**Unresolved placeholders still in v16.** Seven `[[AUTHOR INPUT REQUIRED: …]]`
markers remain in the manuscript body, including the funding statement,
repository DOI (twice), the AI-tool declaration, and the names of the two
validation-refit species in §2.4. One is directly answered by this report:

> *"confirm that the archived release includes the active-minus-pre-onset
> contrast estimates, standard errors, confidence intervals and q-values for all
> 49 species and both outcomes, the standardized absolute-scale predictions, and
> the nearest-event sensitivity output"*

All three exist, but **not** in `outputs/post_stage4a_sog_event_study_v1/`:

- contrasts with SEs, CIs and q-values → `outputs/editorial_requested_analysis_v1/active_minus_pre_contrasts.csv`
- standardized predictions → `outputs/editorial_requested_analysis_v1/absolute_predictions.csv`
- nearest-event sensitivity → `outputs/conventional_exposure_sensitivity_v1/` (**unmerged branch only**)

The archive statement needs to name all three directories, and the third needs
to reach `main` first.

---

## 5. What I ran, wrote, and did not do

**Environment.** R is **not installed** in this container (no `Rscript`, no
`/usr/lib/R`), so no R code was executed and no model was fitted. All
verification was done by recomputing from released CSVs in Python
(pandas 3.0.5), which is sufficient because every quantity checked is
arithmetic over archived estimates. `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED`
is unset; per the boundaries I did not set it, did not write it into any
script, and did not commit it.

**Ran:**
- Filesystem, all-branch, reflog and dangling-object searches for the two
  artefacts (`git rev-list --all --objects`, `git fsck --dangling`, `find /`)
- Recomputation of the primary contrast for 49 species × 2 outcomes
- Cross-check of the editorial contrasts against the frozen release
- Independent BH recomputation, validated to 2.9e-15 against archived q-values
- Median and tally recomputation for the pre-trend windows
- SHA-256 verification of the frozen release against its manifest
- Source reading of `post_stage4a_formula_v1`, the `lmer`/`glmer` calls, the
  contrast block at the reference commit, and `.stage4a_prepare_events`

**Wrote** (only inside `verification/`, untracked, nothing staged):
- `verification/primary_contrast_point_estimates.csv` — 98 rows, as specified
- `verification/primary_contrast_intervals_crosscheck.csv` — the same 98
  components with intervals, q-values, and the release-vs-editorial difference
- `VERIFICATION_REPORT.md` — this file

**Deliberately did not:**
- Edit the manuscript, or soften any finding
- Modify, regenerate or overwrite anything in
  `outputs/post_stage4a_sog_event_study_v1/` (re-verified by hash afterwards)
- Add or remove taxa; touch the 2026–2028 holdout
- Set or commit the authorization variable
- Run the test suite (it mutates published Stage 4A artefacts on non-UTF-8
  machines)
- `git add -A`, or stage anything outside `verification/`
- Create `outputs/post_stage4a_sog_event_study_v1_1/` — conditional on a refit
  that Task 1 made unnecessary

**One caveat on scope.** Everything above verifies that the manuscript's
numbers match the archived artefacts, and that two independent fits agree with
each other. It does not re-fit any model, so it cannot detect an error shared
by both runs — for example a mis-specified contrast vector that was applied
consistently. Closing that would require the gated refit and the protected
frame.
