# Post-review remediation: findings and status

Working branch: `claude/post-review-remediation-saw3bl`
Base commit inspected: `3fc1ec2`

This records what was run, what each acceptance check returned, what changed
on disk, and — most importantly — everything that disagreed with the handoff
brief or the manuscript. Disagreements are not resolved here. None of them
were resolved by editing the manuscript.

---

## Session blockers

Three preconditions for the production refit are absent in this environment.
Tasks 1, 2, 3 and 4 are therefore **implemented, unit-tested and ready to
run, but not executed**.

| Precondition | State |
| --- | --- |
| `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED` | **Unset.** Per the brief, the human sets this. It was not set, not written into any script, and not committed. |
| Four protected inputs under `data/derived/` | **Absent.** `.gitignore` covers `data/derived/**`, and the clone carries none of them. |
| Checkpoint cache | **Absent** (`data/derived/post_stage4a_sog_event_study_v1/checkpoints` does not exist). |

R itself was not installed in the container. It was installed locally for
this session so the code could be parsed, unit-tested and exercised
end-to-end on synthetic data. That install is ephemeral and is not part of
the repository.

**Nothing about the authorization gate was weakened.** The gate, the year
gate, the taxon gate and the source-link hash gate are all byte-identical to
their committed forms; this was verified mechanically (see
"Gate preservation" below).

---

## Finding 1 — the frozen manifest does not fully verify, and never could

The brief states that everything in `output_hash_manifest_v1.csv` "is
hash-locked and currently matches". **Six of the seven entries match. One
does not**, and it was already mismatched before any change in this session.

```
MATCH     effect_estimates_v1.csv
MATCH     model_diagnostics_v1.csv
MATCH     model_term_support_v1.csv
MATCH     joint_exposure_support_v1.csv
MATCH     main_species_panel_v1.csv
MATCH     specificity_comparators_v1.csv
MISMATCH  execution_record_v1.yml
```

Cause, confirmed exactly rather than inferred:

```
sha256(file as committed)            = 8b3a6831c117...
sha256(same bytes with CRLF endings) = 1438214102d6...   <-- the manifest value
```

The run wrote the YAML with `yaml::write_yaml`, which uses the platform line
ending, on Windows. Every CSV is written through `.post_stage4a_write_csv_v1`,
which opens a binary connection and forces `eol = "\n"`, so the CSVs survived.
`.gitattributes` (`*.yml text eol=lf`) then normalised the YAML on commit,
after the hash had been recorded. The recorded hash describes bytes that
cannot exist in the repository.

This is benign for the science — the file's *content* is intact and its
provenance is not in question — but a referee who runs the manifest check
will see a failure, and the honest answer is that this entry has never been
verifiable from a checkout.

**Fixed for future runs, not retroactively.** A `.post_stage4a_write_yaml_v1`
helper now writes YAML through a binary connection, matching the CSV writer.
The frozen v1 files were not touched, and their six data hashes still match.

---

## Finding 2 — Task 1's significance acceptance targets cannot be checked before the refit, and one of them looks doubtful

The point-estimate half of the acceptance check **passes completely, right
now, with no refit.** Because the new contrast vector is exactly
`did_active_0_14_day − did_pre_14_day` (verified in R: max elementwise
difference `0`), its point estimate is the released difference and its ratio
is the released ratio quotient:

| Species | Outcome | Derived | Brief's value |
| --- | --- | --- | --- |
| Surf Scoter | reported number | 1.303834 | 1.3038 |
| Surf Scoter | reporting | 1.003393 | 1.0034 |
| Harlequin Duck | reporting | 1.150277 | 1.1503 |

This holds for all 49 species and both outcomes, and is now a permanent
regression test against the frozen release.

The **significance** half cannot be derived. The new contrast's standard
error needs `Cov(active, pre)`, which is exactly the quantity that was
discarded. Bounding it by Cauchy–Schwarz over the feasible correlation
range gives, after BH adjustment within the new 49-species family:

| Outcome | ρ = +1 | ρ = 0 | ρ = −1 |
| --- | --- | --- | --- |
| reporting | 28 pos / 18 neg | 7 pos / 0 neg | 0 pos / 0 neg |
| reported number | 42 pos / 3 neg | 12 pos / 0 neg | 9 pos / 0 neg |

The brief's targets (13 reporting positives, 18 reported-number positives,
no significant negatives) sit inside these brackets, so nothing is
contradicted — but nothing is confirmed either. **The refit is genuinely
required.** This is the strongest possible argument for Task 3.

**One target deserves scrutiny.** "No significant negatives in either
outcome" does not hold for the *released* primary contrast: six reporting
species are adjusted-significant negatives on `did_active_0_14_day`.

| Species | Released active ratio | Released q | Derived new-contrast ratio |
| --- | --- | --- | --- |
| Ring-billed Gull | 0.7897 | 0.0016 | 0.9678 |
| Rhinoceros Auklet | 0.7088 | 0.0245 | 0.7510 |
| Western Grebe | 0.7407 | 0.0232 | 0.7679 |
| Black-bellied Plover | 0.8387 | 0.0232 | 0.9427 |
| Common Raven | 0.9392 | 0.0260 | 0.9426 |
| Common Loon | 0.9028 | 0.0217 | 0.9414 |

Rhinoceros Auklet (0.751) and Western Grebe (0.768) retain large negative
point estimates under the new contrast. Whether they clear BH depends
entirely on the covariance. Twenty of 48 reporting species have negative
point estimates on the new contrast. **If the refit returns significant
negatives in reporting, that is a real result, not a bug** — it should not
be treated as a failed acceptance check.

---

## Finding 3 — the baseline genuinely carries zero weight (flagged for the author, not acted on)

Confirmed in R: the new contrast's weights on `es_near_baseline` and
`es_reference_baseline` are exactly `0`, and the full weight vector sums to
`0`. The primary contrast is therefore precisely

> (near − reference) during days 0–14, minus (near − reference) during days
> −14 to −1

with the days −28 to −15 baseline appearing nowhere in the contrast vector.
The baseline period still matters for *estimation*, because those links are
modelled as their own exposure category rather than folded into zero
exposure, but it is not subtracted in the comparison.

The manuscript describes the primary comparison as made "after allowing for
the spatial difference already present during days −28 to −15". That is
defensible, but a sharp referee will read it as though the baseline is
subtracted in the contrast, and it is not. **This is flagged for the author.
The manuscript was not edited.**

---

## Finding 4 — `did_pre_7_day` and `did_immediate_pre` are the same test released twice

`did_pre_7_day` is defined as `did("immediate_pre")` — identical weights.
Across all 100 released components, the estimate, standard error and
q-value are identical in every case (100 identical, 0 differing).

They are keyed into two separate BH families, so neither inflates the
other's adjustment, and no released number is wrong. But the release
presents 14 contrasts of which two are the same test under different names.
Left as-is (changing it would alter released semantics); flagged.

---

## Finding 5 — two contrasts are now flagged `primary_estimand = TRUE`

The brief specifies `primary_estimand = TRUE` for the new contrast, and
`did_active_0_14_day` already carries that flag. Both are now `TRUE`.
`did_active_0_14_day` was deliberately **not** demoted, because that would
change the released meaning of a column in the frozen file and make any
refit disagree with the release on a field unrelated to the new work.
Downstream code keys the main panel on contrast *names*, not on this flag,
so nothing breaks. The author should decide which contrast the flag ought to
denote.

---

## Finding 6 — `figures_ggplot2/` does not exist in this repository

Task 5 could not be started. The brief describes `figures_ggplot2/` with a
README, `00_theme_mer.R`, `01_map_study_area.R`, `03_family_forest.R`,
`04_period_profiles.R` and `05_supp_pretrend_and_tables.R`. **None of these
paths exist in the working tree, in any commit, on any branch.** The only
comparable asset is `scripts/build_mer_figures_ggplot2_v2.R`, which builds
the ten Stage 4A journal figures — a different deliverable from the
post-Stage 4A event study.

Consequences:

- The `04` console check (Surf Scoter reported number 0.96 / 1.05 / 1.33 /
  1.13; White-winged Scoter reporting 0.84 / 0.91 / 0.91 / 0.92) could not
  be run.
- The schema for `active_minus_pre_contrasts_v1.csv` was specified as
  "documented in `figures_ggplot2/00_theme_mer.R`", which is unavailable.
  The file is therefore written with **exactly the schema of
  `effect_estimates_v1.csv`** (same columns, same order, filtered to the new
  contrast), which is the safest available choice and needs confirming.
- The pre-trend half of `05` was reimplemented from scratch (Task 6 below)
  rather than fixed, since there was nothing to fix.

The map-suppression rule in `01` was not altered, relaxed or re-specified.

---

## Task-by-task status

### Task 1 — archive the active-minus-pre contrast · implemented, not run

`active_minus_pre_14_day` added to `post_stage4a_contrast_definitions_v1`,
with the required zero-baseline assertion promoted to a hard gate
(`POST_STAGE4A_EVENT_STUDY_CONTRAST_WEIGHT_GATE`) that fires whenever the
definitions are built, not merely before a run.

Verified in R:

- baseline weights exactly `0`; vector sums to `0`
- vector identical to `did_active_0_14_day − did_pre_14_day` (max diff `0`)
- duration weights 4/15, 11/15, −0.5, −0.5 as specified
- **multiplicity confirmed in output, not assumed**: the new contrast keys
  into `core_species__detection__active_minus_pre_14_day`, its own
  49-species BH family, and each family adjusts over its own tests only
- on synthetic data the fitted new-contrast SE lies inside the
  Cauchy–Schwarz bracket, and the estimate identity holds to `5.6e-17`

Output goes to `active_minus_pre_contrasts_v1.csv` and is registered in the
run's manifest. A gate stops the run if the contrast yields no rows.

### Task 2 — Laplace reporting sensitivity · implemented, not run

New module `R/post_stage4a_sog_event_study_laplace_sensitivity_v1.R` and
runner `scripts/run_post_stage4a_laplace_sensitivity_v1.R`. Writes to
`outputs/post_stage4a_sog_event_study_laplace_v1/`. The primary path is
untouched.

The technical constraint in the brief was checked and is correct: with three
crossed random intercepts, lme4 offers no adaptive quadrature above Laplace.
`nAGQ` is now a parameter of the fitting function defaulting to `0L`, and
`nAGQ > 1` is refused by an explicit gate. **The sensitivity differs from the
primary in exactly one argument** — same formula, same optimiser, same
control, same contrast set.

Scope defaults to **all 49 core species**, not the 13. This is deliberate and
matters: BH adjustment over 13 species is not comparable with the primary's
49-species families, so a reduced scope would make the "q < 0.05 preserved"
comparison meaningless. `adjusted_significant` scope remains available and
sets a `q_families_comparable = FALSE` column when used.

Emits a paired table (primary ratio and interval, Laplace ratio and interval,
both q-values, direction preserved, significance preserved, log-ratio shift),
a headline-only comparison for the two primary contrasts, and an
`overturned` set. If any headline result flips direction or crosses q = 0.05,
the runner prints `POST_STAGE4A_LAPLACE_SENSITIVITY_ALERT` naming the species
and records it in the execution record — it cannot be buried.

**Runtime warning.** On synthetic data at 3,000 rows and a 3.3 % reporting
rate, `nAGQ = 1` took **12.3 s against 1.4 s** for `nAGQ = 0` — roughly 9×.
Production models carry 217,200 rows. Budget accordingly, and consider
`POST_STAGE4A_SOG_EVENT_STUDY_WORKERS`.

### Task 3 — persist fixed effects and covariance · implemented, not run

Per-component `fixef` and `vcov` are persisted to
`outputs/post_stage4a_sog_event_study_model_summaries_v1/`, one RDS per
component, alongside taxon, outcome, role, status and the gradient result.
Failed components write a status-only record so the archive is complete.

The checkpoint cache was a trap here: a cache hit returns before any fit
exists. The cache is now honoured **only if the corresponding model summary
is also present**, so a cache populated by an older run cannot leave the
archive with holes. Verified: deleting a summary forces a refit and
regenerates it.

**Acceptance check, on synthetic data, both outcomes:** recomputing all 15
contrasts from the persisted `fixef` and `vcov` reproduced the effect table
with `max |estimate difference| = 0` and `max |SE difference| = 0` — exact,
not merely close. The same code path runs on real data. Persisted matrices
were 37 × 37.

These are aggregate summaries, strictly less disclosive than the effect
estimates already released. `.gitignore` now allowlists the directory so the
artefacts *can* be archived; committing them remains a deliberate act.

### Task 4 — verify the convergence claim · implemented, not run; the concern is confirmed

**The concern in the brief is correct.** `calc.derivs = FALSE` is passed to
both `glmerControl` and `lmerControl`, and `.post_stage4a_model_messages_v1`
inspects only `optinfo$conv$opt` and lme4 messages. The gradient-based
convergence check never ran. `converged = TRUE` for all 96 fitted components
reflects a check that was disabled, exactly as suspected.

A gradient check is now computed per component and reported as
`max_abs_gradient`, `gradient_check_status` and `devfun_reference_deviation`
in the diagnostics. It rebuilds the deviance function explicitly (never via
`update()`, which would break under `parLapply`), selects the parameterisation
deterministically from the fit, validates it against the optimised criterion
before trusting it, and degrades to `NA` with a reason rather than failing a
run. It is off-switchable via `POST_STAGE4A_EVENT_STUDY_GRADIENT_CHECK=0`.

Two things worth recording, both found by testing rather than reasoning:

- **`stats::deviance()` is the wrong reference for a glmer fit.** It returns
  the sum of squared deviance residuals, not the optimised criterion. Using
  it marked every binomial component as mismatched (relative deviation
  6.0e-4). `-2 * logLik(fit)` is correct for both engines and gives
  deviation `0`. Anyone writing this check independently will hit the same
  trap.
- **Gradient magnitudes are not comparable across `nAGQ` settings.** At
  `nAGQ = 0` and for `lmer`, the objective is profiled and takes `theta`
  alone; at `nAGQ = 1` it takes `c(theta, beta)`. Synthetic fits gave
  `max|grad|` 7.6e-5 (nAGQ = 0) versus 0.33 (nAGQ = 1) on the same data. Do
  not apply one threshold across both.

**On manuscript §3.1** ("Every other fit converged without qualification"):
the statement is true as recorded, and no evidence was found that any fit is
actually poorly converged — but no evidence was found that they are well
converged either, because the check was off. Whether §3.1 needs softening
cannot be settled until `max_abs_gradient` comes back from the refit. If the
values are small, §3.1 stands and is now defensible against a referee reading
the code. If any are large, that is a finding for the author. **This is the
one task whose answer is genuinely unknown until the refit runs.**

### Task 5 — figure and supplement scripts · cannot be started

See Finding 6. Nothing to run. No figure code was invented to fill the gap,
beyond the pre-trend summary that Task 6 required.

### Task 6 — pre-trend · COMPLETE

The only task fully executable here: `did_early_pre` and `did_immediate_pre`
already exist for every species and both outcomes, so no refitting was
needed. `scripts/build_post_stage4a_pretrend_summary_v1.R` verifies the
release against its recorded hash, then summarises it.

Core species, frozen v1 release:

| Outcome | Window | Days | n | Median ratio | IQR | q < 0.05 |
| --- | --- | --- | --- | --- | --- | --- |
| reporting | `did_early_pre` | −14 to −8 | 48 | 0.9875 | 0.9441–1.0288 | 0 |
| reporting | `did_immediate_pre` | −7 to −1 | 48 | 0.9896 | 0.9295–1.0556 | 0 |
| reporting | `did_pre_14_day` | −14 to −1 | 48 | 0.9869 | 0.9571–1.0215 | 0 |
| reported number | `did_early_pre` | −14 to −8 | 46 | 1.0085 | 0.9614–1.0343 | 0 |
| reported number | `did_immediate_pre` | −7 to −1 | 46 | 1.0211 | 0.9794–1.0558 | 2 (+2/−0) |
| reported number | `did_pre_14_day` | −14 to −1 | 46 | 1.0121 | 0.9798–1.0413 | 1 (+1/−0) |

Species clearing q < 0.05 before spawn onset:

| Outcome | Window | Species | Ratio | 95 % CI | q |
| --- | --- | --- | --- | --- | --- |
| reported number | `did_immediate_pre` | Great Blue Heron | 1.0660 | 1.0289–1.1045 | 0.0094 |
| reported number | `did_immediate_pre` | Iceland Gull | 1.2529 | 1.1069–1.4181 | 0.0094 |
| reported number | `did_pre_14_day` | Iceland Gull | 1.1957 | 1.0757–1.3291 | 0.0426 |

No species in either reporting window clears q < 0.05, and there are no
significant negatives anywhere. Medians sit within about 2 % of 1.0 in all
six cells.

**No interpretive paragraph is offered.** Whether a drifting pre-trend is
fatal, a caveat or noise is the author's scientific judgement.

---

## Gate preservation

Every `POST_STAGE4A_*` gate string in the committed file is present in the
modified file; the only differences are four **added** gates
(`CONTRAST_WEIGHT_GATE`, `CONTRAST_ARCHIVE_GATE`, `FROZEN_OUTPUT_GATE`,
`NAGQ_GATE`). The taxon gate (49 + 2), the year gate (2026+), the SoG scope
gate (217,200), the cardinality gates (239,934 / 1,169,612 / 5,834) and the
source-link hash literal all appear the same number of times as before.

The input-preparation block was moved verbatim into
`post_stage4a_prepare_event_study_inputs_v1()` so the sensitivity module runs
against the identical gates rather than a copy that can drift. No gate
constant was edited.

A new `POST_STAGE4A_EVENT_STUDY_FROZEN_OUTPUT_GATE` refuses to write to
`outputs/post_stage4a_sog_event_study_v1`, and the runner's default output
directory moved to `outputs/post_stage4a_sog_event_study_v1_1`. Under the
brief's boundary 3 the frozen release must not be overwritten, and the old
default would have overwritten it on the very next authorized run.

Tests: 13 `test_that` blocks pass, including five new ones. Both fixture
modes pass. The privacy scan passes across 760 files with zero violations.
The six frozen data files still hash-match.

---

## To run when authorized

```bash
export POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED=through_2025_post_result_refinement_v1
# the four protected inputs must be present and hash-matching

Rscript scripts/run_post_stage4a_sog_event_study_v1.R fixture       # cheap self-test
Rscript scripts/run_post_stage4a_sog_event_study_v1.R production    # tasks 1, 3, 4
Rscript scripts/run_post_stage4a_laplace_sensitivity_v1.R production all_core  # task 2
```

Both production runners refuse to start until their code is committed, so
commit first. Because `code_signature` includes the execution commit, every
checkpoint is invalidated and all 100 components refit — which is the point:
after this run, `fixef` and `vcov` are on disk and no future contrast needs a
rerun.

Report back afterwards: the two significance counts and whether any
significant negatives appear (Finding 2), the `max_abs_gradient` distribution
(Task 4), and whether any headline gull result moved under Laplace (Task 2).
