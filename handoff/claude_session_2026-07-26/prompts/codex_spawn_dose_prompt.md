# Spawn dose-response: do larger recorded spawns draw a larger bird response?

For GPT-5.6 (sol High) in VS Code, working in
`herring-x-ebird-version-2`.

Read this whole file before writing code. Sections 1 to 4 are the design and are
not negotiable. Section 5 is the confound work and is the part most likely to
decide whether the result survives review. Section 9 tells you what to do when
something does not fit.

---

## 1. The question

The manuscript currently reports that birds were recorded differently near
recorded herring spawning events. It says nothing about event size, and Section
2.2 states explicitly that the index value never enters the models.

The author wants that changed. The question is whether the response scales with
the recorded size of the spawn.

**This is a strictly stronger claim than the paper currently makes.** "Birds
changed around events" survives a lot of alternative explanations. "Birds
changed in proportion to how much spawn was recorded" survives fewer, but it
also fails more easily, and a null here is a publishable and useful result. Do
not tune the analysis toward a positive finding.

---

## 2. Authorization gate

**Do not run anything until `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED` is set.**

Its value is `through_2025_post_result_refinement_v1`. Only the author sets it.
If it is unset, stop and say so. Do not set it yourself, do not work around it,
and do not fit "just a quick check" first.

Additional standing constraints, unchanged from previous commissions:

- Do not access, analyse or summarise protected 2026 to 2028 confirmation records.
- Do not overwrite anything in `outputs/post_stage4a_sog_event_study_v1/`.
- Do not modify the existing 49-species family. It is fixed. Species that fail
  to fit are reported as failures, not dropped.
- Do not invent, estimate or back-calculate any number.

---

## 3. Pre-registration, before you fit anything

This analysis is post-result and ecologically motivated. The repository already
records that status for the parent study. Be equally explicit here.

Write `metadata/post_stage4a_spawn_dose_spec_v1.yml` **before running any
model**, containing:

```yaml
analysis_status: post_result_ecologically_motivated_refinement
motivation: author request, 27 July 2026; comment 105 on manuscript v30
created_after_stage4a_results_available: true
primary_dose: log_relative_spawn_index_t
scope: fixed 49-species family, both outcomes
primary_contrast: dose_did_active_minus_pre
multiplicity: benjamini_hochberg within the 49-species family, per outcome
negative_controls: [American Robin, Chestnut-backed Chickadee]
falsification: <the criteria you write in section 8, stated before fitting>
```

Then commit it. The point is that the falsification criteria exist in git
history before the results do.

---

## 4. Design

### 4.1 What the dose is

`relative_spawn_index_t` in `metadata/data_dictionary_v2.csv`, described there as
"Sum of observed components; not absolute biomass". It is built from `Surface`,
`Macrocystis` and `Understory` per Grinnell et al. 2023.

Use `log(relative_spawn_index_t)`. The distribution is heavily right-skewed and
the biological expectation is diminishing returns, not linearity.

**Records with no component observed cannot be scored.** The component pattern
audit shows 1,444 of 31,167 source rows with all three components absent. Drop
them from the dose analysis and report exactly how many links and events that
removes. Do not treat them as zero.

### 4.2 How the dose enters the model

The existing model carries twelve exposure terms: six periods by two zones, each
holding the count of eligible checklist-to-event links. Keep all twelve. Add
twelve more.

For checklist *i*, period *p*, zone *z*:

```
n[i,p,z] = number of eligible links            (existing, unchanged)
s[i,p,z] = sum over those links of (log index - mean log index)
```

Centre the log index on its grand mean across all eligible links so that the
`n` coefficients keep their current interpretation at average dose. Report the
centring constant.

The dose estimand is then formed exactly as the existing one is, but on the `s`
terms:

```
dose_did_active_minus_pre = contrast(s, active 0-14 day) - contrast(s, pre 14 day)
```

duration-weighted 4/15 and 11/15 as before, exponentiated. It reads as: the
multiplicative change in the near-versus-reference active-minus-pre response per
one-unit increase in log recorded spawn index.

Because the twelve `n` terms are retained, the model with dose nests the current
model. **Report the likelihood ratio test.** That single number is the honest
headline: does adding dose improve the fit at all?

### 4.3 Everything else stays as it is

Same six periods, same 5 km and 5 to 20 km zones, same random intercepts for
event block, observer cluster and generalized location cluster, same covariates
(year as factor, protocol, log duration, log distance travelled, observer
count), same `nAGQ = 0` for the binomial fits, same Gaussian fits on log
positive counts, same Wald intervals from the full fixed-effect covariance
matrix.

Do not take the opportunity to improve unrelated parts of the model. If the
dose result differs from the current result for reasons other than dose, nobody
will be able to tell.

---

## 5. The three confounds that decide this

Work these properly. They are the reason the author's own Methods section
currently refuses to use the index.

### 5.1 Survey method, the measurement confound

**This is first-order and easy to miss.** The index is a *sum of observed
components*. Which components exist depends on how the spawn was surveyed:

| Component | Non-missing rows |
|---|---|
| Surface | 23,279 |
| Understory | 6,318 |
| Macrocystis | 1,497 |

A surface-only survey and a dive survey at the identical true spawn produce
different index values. `Method` has four levels. Unhandled, "larger index"
partly means "more thoroughly surveyed", and a dose response could be an
artefact of survey intensity.

Required:

1. Carry `Method` as a link-level covariate in the primary model.
2. Run a sensitivity restricted to **surface-observed records only**, the
   largest consistent component set. If the dose coefficient survives that
   restriction, the measurement confound is largely answered.
3. Report the association between `Method` and log index directly, so a reader
   can see its size rather than take your word for it.

### 5.2 Site recurrence, the confound that will sink this if ignored

Large spawns recur at the same places. If those places are also good bird
habitat, a dose response is a site effect wearing a dose costume. A location
random intercept does not fix this: it absorbs differences in level, and the
dose effect is estimated on a slope.

**Decompose the dose within and between locations** (Mundlak):

```
log_index_between = mean of log index over all events at that location
log_index_within  = log index - log_index_between
```

Enter both. The **within** term is the identifying variation: the same location
in a big year versus a small year. It cannot be explained by that location being
good habitat.

Treat `log_index_within` as the primary dose result and say so in the
pre-registration. If within and between disagree, that is the most informative
thing this analysis can produce and it must be reported prominently, not
buried.

### 5.3 Extent versus intensity

A larger index may mean a longer stretch of shoreline rather than denser spawn.
`Length` and `Width` are nearly complete (30,856 and 30,405 non-missing).

The author chose the index as the dose, not extent, so extent is **not** the
exposure. But it must be accounted for:

1. Report the correlation between `log(relative_spawn_index_t)` and
   `log(Length * Width)`.
2. Run a sensitivity with `log(Length)` as a covariate alongside the dose. If
   the dose effect vanishes once shoreline length is held constant, the finding
   is about how far a spawn stretches, not how much fish it holds, and the
   manuscript must say that.

---

## 6. Negative controls

American Robin (*Turdus migratorius*) and Chestnut-backed Chickadee (*Poecile
rufescens*). Neither has any plausible route to a herring spawn.

**Fit these to the same dose specification.** They are more informative here
than in the parent analysis. A dose response in a terrestrial songbird cannot be
ecological; it would mean the index is proxying for something about observers,
sites or seasons. If either control shows a dose response surviving correction,
the primary result is not interpretable and you should say so in the first
paragraph of the report.

Note the existing complication so you are not surprised: American Robin is not
perfectly flat in the distance-band work. Its reporting is elevated at 0 to 2 km
during immediate pre-spawn (BH q = 0.039). Pre-spawn elevation is not the same
as a dose response and does not by itself invalidate anything.

---

## 7. Secondary analyses

### 7.1 The figure the author wants

Glaucous-winged Gull (*Larus glaucescens*) and Bald Eagle (*Haliaeetus
leucocephalus*), the two species already carried as a case study in Section 3.4.

Split events into **within-year terciles of the index** so the strong year trend
in stock size does not drive the split. Re-fit the existing twelve-term model
separately within each tercile and plot the three active-minus-pre estimates
with intervals, for both outcomes.

A monotone rise across terciles is the visual claim. Non-monotonicity is worth
seeing and worth reporting.

### 7.2 Guild-level dose

The seven feeding groups are fixed in the species registry. Regress the
species-level dose estimates on group, weighted by precision, using the exact
covariance as in the corrected guild timing test. Roe-feeding divers and
shoreline scavengers are the groups with a prior expectation of dose sensitivity.

Use the exact covariance. An earlier version of the guild timing test set the
covariances to zero and produced p = 0.089 where the correct answer was p =
0.020. Do not repeat that.

---

## 8. Falsification criteria, to be written down before fitting

State these in the spec file. Suggested, adjust if you have a better argument:

- **Supported**: the within-location dose contrast is positive and survives BH
  for a meaningful number of species; it holds under the surface-only
  restriction; neither negative control shows a dose response; the tercile
  figure is monotone for at least one of the two case species.
- **Not supported**: the likelihood ratio test against the current model is not
  significant, or the dose effect is carried entirely by the between-location
  term, or it disappears when `log(Length)` is held constant.
- **Uninterpretable**: a negative control shows a dose response surviving
  correction, or the dose effect reverses between the full and surface-only
  fits.

A null is a real answer. The manuscript's current position, that the index is
relative and was therefore not used as an exposure, is defensible and can simply
stand.

---

## 9. Runtime, and what to do when it breaks

The parent analysis was expensive: no single species fit completed within an
hour on four parallel workers under Laplace, which is why `nAGQ = 0` is used.
You are adding twelve fixed-effect terms across 49 species and two outcomes,
plus terciles and sensitivities.

Stage it:

1. The two case species and the two negative controls first. Four species, both
   outcomes. If the machinery is wrong you will find out in minutes rather than
   days.
2. Then the full 49.
3. Then terciles and sensitivities.

Expect singular fits and convergence failures. The parent analysis had a
singular fit in Western Gull counts and 30 singular fits in the count-state
exploratory set. Report every one. Do not drop a species because it failed to
converge, and do not quietly switch optimiser or tolerance to make a fit
succeed without recording that you did.

**If something does not fit the design described here, stop and write down why
rather than adapting the design silently.** The previous commission in this
project produced a wrong answer by computing item 8 on the wrong contrast, and
it was caught only because the resulting table was arithmetically impossible
(29 reporting positives claimed in a 46-species subset of 48 that contains 28).
An explicit "this cannot be done as specified, here is what I would need" is
worth more than a plausible number.

---

## 10. Deliverables

Everything under `outputs/post_stage4a_spawn_dose_v1/`.

| File | Contents |
|---|---|
| `dose_estimates_49x2.csv` | Per species and outcome: dose contrast, SE, Wald interval, p, BH q, n links, n events, fit status, singular flag |
| `dose_within_between.csv` | The decomposition from 5.2, both terms per species |
| `dose_lrt.csv` | Likelihood ratio test of dose model against current model, per species and outcome |
| `dose_method_sensitivity.csv` | Surface-only refit, alongside the primary for comparison |
| `dose_extent_sensitivity.csv` | Refit with `log(Length)` held constant |
| `dose_negative_controls.csv` | Robin and Chickadee, full detail |
| `dose_terciles_case_species.csv` | The tercile estimates behind the figure |
| `dose_guild_meta.csv` | Guild regression with exact covariance |
| `figures/` | Tercile dose-response panel; species-level dose forest |
| `execution_record_v1.yml` | Seeds, versions, timings, every failure and every deviation |

Plus `SPAWN_DOSE_REPORT.md` at the repository root, structured:

1. **Verdict in the first three sentences.** Supported, not supported, or
   uninterpretable, against the section 8 criteria. Do not build to it.
2. The likelihood ratio result.
3. Within versus between decomposition, and what it implies.
4. The two confound sensitivities, method and extent.
5. Negative controls.
6. Species-level table and the guild result.
7. Everything that failed.
8. What you would tell the author not to claim.

Give the report to the author before anything is written into the manuscript.
The manuscript text is being handled separately and Section 2.2 will need
rewriting only if the result supports it.
