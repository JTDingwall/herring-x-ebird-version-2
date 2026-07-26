# Follow-up: two items from REFEREE_READS_REPORT.md

Short task. Both items are corrections to work already done, not new analysis.
Same clone, same boundaries: do not modify
`outputs/post_stage4a_sog_event_study_v1/`, do not change the 49-species family,
do not read the 2026-2028 holdout, do not edit the manuscript.

Write `REFEREE_READS_FOLLOWUP.md`.

---

## Item A: the paired outcome-asymmetry test is on the wrong contrast

Item 8 of `REFEREE_READS_REPORT.md` reports a paired 2x2 table over 46 species
and an exact McNemar p = 0.00634765625, sourced from
`outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv`.

That table cannot be describing the primary estimand. Its marginals are 29 of 46
positive for checklist reporting and 39 of 46 positive for reported number. The
manuscript reports 28 positive out of all 48 estimable reporting species and 42
positive out of 46 estimable count species, both for the
`did_active_0_14_day` minus `did_pre_14_day` contrast. A 46-species subset of
those 48 cannot contain 29 positives when the full 48 contain 28.

The most likely cause is that `effect_estimates_v1.csv` carries period-versus-
baseline contrasts only, so the join picked up `did_active_0_14_day` rather than
the primary active-minus-pre-onset contrast. That contrast is in
`outputs/editorial_requested_analysis_v1/active_minus_pre_contrasts.csv`, and now
also in `outputs/post_stage4a_sog_event_study_v1_1/active_minus_pre_contrasts_v1.csv`.

Recompute the paired analysis from the primary contrast and report:

1. Which contrast the original item 8 actually used. Confirm or correct the
   diagnosis above rather than assuming it.
2. The corrected paired 2x2 table over the species with both models estimable:
   positive in both, count only, reporting only, negative in both.
3. The exact two-sided McNemar p-value on the discordant pairs.
4. The two marginal proportions from the corrected table, and whether they
   reconcile with the manuscript's 28 of 48 and 42 of 46. If they do not
   reconcile, say so plainly and do not adjust either side to make them agree.

If the reconciliation fails, that is the most important sentence in the report
and it goes first. The manuscript's headline counts depend on those two figures.

## Item B: redo the guild timing test with the archived covariance

Item 10 computed each species' timing contrast as `did_spawn_start` minus
`did_early_egg` and took its variance as the sum of the two archived squared
standard errors, with the covariance set to zero. The report labels this
correctly as an approximation.

Part 2 has since persisted fixed effects and covariance matrices for 96 fitted
components to `outputs/post_stage4a_sog_event_study_v1_1/` and
`outputs/post_stage4a_sog_event_study_model_summaries_v1/`. The exact variance
of the timing contrast is therefore now available without refitting anything.

Recompute the same meta-regression using the exact linear-contrast variance
against the persisted covariance matrix, and report:

1. The per-species timing contrasts with exact standard errors, replacing
   `item10_species_timing_contrasts.csv`.
2. The inverse-variance weighted guild means with 95% intervals, both outcomes,
   replacing `item10_guild_means.csv`.
3. The omnibus guild tests and residual heterogeneity, replacing
   `item10_meta_regression_tests.csv`.
4. Side by side with the approximate values, so the effect of the approximation
   is visible.
5. The sign of the covariance between `did_spawn_start` and `did_early_egg`,
   averaged across components. The manuscript currently states that the shared
   baseline terms imply a positive covariance and that the approximate test is
   therefore conservative. Confirm or correct that claim; it is asserted in
   Section 3.3 and must be right.

Everything else about the test stays fixed. Same guild assignments from
`metadata/canonical_species_registry.csv`, taken without alteration. Same species
retained, all 48 and all 46, none dropped. Same contrast definition.

The manuscript currently reports Q = 76.8 on 6 df with p < 0.001 for reported
number and Q = 11.0 on 6 df with p = 0.09 for checklist reporting, and states
that roe-feeding diving sea ducks peak during early egg availability while
shoreline scavengers peak at spawn start. If the exact variance changes any of
those conclusions, including the direction of any guild mean or which guild
intervals exclude zero, say so at the top of the report.

## What not to do

Do not rerun the response models. Both items are recomputations from archived
output. If either turns out to need a fit, stop and say so rather than fitting
one.
