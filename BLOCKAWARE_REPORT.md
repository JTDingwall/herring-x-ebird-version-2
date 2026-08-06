# Block-aware intervals for the primary contrast

Execution version `post_stage4a_blockaware_v1`. Branch
`codex/blockaware-random-slope-v1`, cut from main-checkout HEAD `7483386`.
Outputs in `outputs/post_stage4a_blockaware_v1/`, hashed in
`output_hash_manifest_v1.csv`.

---

## 1. New tallies

**The count tally falls from 19 to 15. The positive reporting tally holds at 13,
but a third negative-direction species appears, so the reporting family goes
from 15 Benjamini-Hochberg survivors to 16.**

| Outcome | Stage 2 fixed-49 | Block-aware fixed-49 | Change |
|---|---|---|---|
| Count, positive direction | 19 | **15** | −4 |
| Reporting, positive direction | 13 | **13** | 0 |
| Reporting, negative direction | 2 | **3** | +1 |

Both tallies are Benjamini-Hochberg within the fixed 49-species family, per
outcome, with non-estimable models carrying p = 1. The family did not change: no
species was added or removed from it.

The three negative-direction reporting results are reported separately from the
thirteen positive ones, as required: **Bufflehead** (ratio 0.922, q = 0.0253),
**Common Raven** (0.941, q = 0.0498) and now **Black Oystercatcher** (0.838,
q = 0.0212). Black Oystercatcher is new: at Stage 2 its reporting estimate was
−0.0467, and under the random slope it is −0.1773, a 279% move away from zero.
Common Raven's q of 0.0498 sits just inside the threshold and would not survive
a marginally different family.

Substituting the uniform Satterthwaite family, or the uniform Wald family, for
the primary column changes neither tally (15 count, 13 positive reporting in all
three). The tally is not an artefact of mixing interval methods.

---

## 2. Which species moved, and what moved them

Nine species changed Benjamini-Hochberg status. Mechanism is assigned by
counterfactual Benjamini-Hochberg over the same fixed 49-species family:
`widening_only` substitutes the Stage 2 point estimate against the block-aware
standard error and denominator df; `point_movement_only` substitutes the
block-aware point estimate against the Stage 2 standard error. Whichever
counterfactual loses the species is the mechanism.

### Count, four species left, none entered

| Species | Stage 2 | Block-aware | Shift | Width ratio | Mechanism |
|---|---|---|---|---|---|
| Iceland Gull | 0.2120 | 0.1100 | −48% | 1.375 | point estimate movement |
| Mallard | 0.0602 | 0.0398 | −34% | 1.821 | interval widening |
| Canada Goose | 0.0634 | 0.0394 | −38% | 1.546 | both |
| Common Loon | 0.0530 | 0.0198 | −63% | 1.436 | both |

Every count loss involves the point estimate falling, and in three of the four
the interval also widened enough to matter on its own. This is the reweighting
the random slope was expected to produce: the precision-weighted average no
longer leans on the blocks that dominated it.

### Reporting, four left and five entered

Left: **Bald Eagle** (point movement), **Harlequin Duck** (point movement),
**Northern Pintail** (widening), **Iceland Gull** (neither alone sufficient —
only the two together remove it).

Entered: **Glaucous Gull**, **Black Scoter**, **Long-tailed Duck**,
**White-winged Scoter**, **Black Oystercatcher**. All five entered on point
estimates that moved *away* from zero by 159% to 279% while their intervals
widened by 34% to 56%. The movement outran the widening.

Bald Eagle leaving the reporting family is worth the author's attention: its
width ratio is 1.006, essentially unchanged, and its estimate fell only 13%,
from 0.0625 to 0.0544. It was marginal at Stage 2 and a small move was enough.

---

## 3. Interval widths against Stage 2

| Outcome | Median | Quartiles | Range | Wider than Stage 2 |
|---|---|---|---|---|
| Reporting | 1.179 | 1.036 / 1.266 | 1.000 to 1.893 | 47 of 48 |
| Count | 1.160 | 1.069 / 1.376 | 1.001 to 2.738 | 46 of 46 |

Every estimable interval is at least as wide as its Stage 2 counterpart, and the
median widening is about 16 to 18%. The reported Stage 2 intervals were
therefore too narrow, as the diagnostic implied, but by a median of roughly a
sixth rather than by a factor.

Point estimates also moved: median absolute shift 0.0403 on the log scale for
reporting (median 39.6% of the Stage 2 value) and 0.0103 for counts (median
20.5%). The largest relative moves are all species whose Stage 2 estimate was
near zero, where a percentage shift is not informative — Black Turnstone
reporting moves 718% because it starts at −0.0167.

---

## 4. Block slope variance across all 49 species and both outcomes

Reported for every species and both outcomes in
`blockaware_slope_variance.csv`.

| Outcome | Slope SD median | Quartiles | Range | At or below the frozen 0.0025 variance threshold |
|---|---|---|---|---|
| Reporting (48 estimable) | 0.125 | 0.067 / 0.209 | 0.0041 to 1.042 | 8 of 48 |
| Count (46 estimable) | 0.058 | 0.029 / 0.120 | 0.0050 to 0.424 | 19 of 46 |

The ten-species diagnostic of 28 July generalises: event-block slope
heterogeneity is not near zero across the family. On the count side 19 of 46
species do sit at or below the frozen near-zero point threshold, so the effect
is real but far from universal — it is concentrated rather than pervasive.

Largest count slope SDs: Surf Scoter 0.424, Bonaparte's Gull 0.318, Western
Grebe 0.307, Pacific Loon 0.209, Greater Scaup 0.200. Surf Scoter reproduces the
diagnostic's 0.424 exactly. On the multiplicative scale a one-SD block deviation
moves Surf Scoter's active-minus-pre count ratio between about 0.92 and 2.16.

Largest reporting slope SDs: Glaucous Gull 1.042, Brant 0.424, Lesser Scaup
0.424, Black Scoter 0.411, Bonaparte's Gull 0.398. Glaucous Gull's spread is
extreme — between about 0.94 and 7.55 across region-years — and it is also the
species with the smallest count support, so it should be read with care.

The intercept-slope correlation is poorly identified: its quartiles span
−0.877 to +1.000 for reporting and −0.907 to +0.451 for counts, with boundary
values of exactly ±1 occurring. This is consistent with the large number of
singular fits below.

---

## 5. Interval methods actually used, and one place the approved method could not run

The approved primary for counts is Kenward-Roger. **It ran for 21 of the 46
estimable count models and could not run for the other 25.**

`pbkrtest::vcovAdj` computes `chol2inv(chol(Sigma))` where `Sigma` is the n × n
marginal covariance, and that inverse is dense. The working set grows as n², and
the runtime as roughly n^2.6. Measured on this machine: 22 s at n = 2,023,
and 713 to 808 s at n = 8,109 with a peak near 13 GB against 31.5 GB of RAM. The
count models run from n = 185 to n = 112,180 with a median of 8,109, so the
larger half is out of reach. American Crow at n = 112,180 projects to about
1,400 GB. A row cap of 7,723, derived from a 12 GB budget, decides the split;
every skipped species records its projected footprint in
`blockaware_estimates_49x2.csv`.

Where Kenward-Roger could not run, the interval falls back to the Satterthwaite
denominator correction, which the approved spec names for exactly this purpose.
**The fallback corrects the denominator degrees of freedom but not the standard
error, so it is mildly anti-conservative relative to Kenward-Roger.** On the 21
species where both are available:

- Kenward-Roger standard error / Wald standard error: median 1.034, range 1.018
  to 1.212. So the SE correction the fallback misses is about 3% typically and
  at most 21%.
- Kenward-Roger df: median 85.3, range 14.5 to 260.4.
- Satterthwaite df: median 98.6, range 4.3 to 3,704.
- Disagreements at nominal 0.05 between the two: **zero of 21**.

The df correction is the more variable of the two. Ring-billed Gull's
Kenward-Roger df is 15.6, close to the 21.7 effective clusters from the
preflight, while Red-throated Loon's is 229. Satterthwaite's 3,704 upper end
shows it can be far too generous on some species, which is the honest cost of
the fallback.

Every row of `blockaware_estimates_49x2.csv` carries
`primary_interval_method`, `primary_denominator_df`, and the full Wald,
Satterthwaite and Kenward-Roger columns side by side, so any reader can rebuild
the family under a single uniform method. As noted in section 1, doing so does
not change either tally.

Reporting models are binomial. Kenward-Roger does not apply and lmerTest offers
no Satterthwaite denominator for a `glmerMod`, so all 48 estimable reporting
intervals are the prespecified Wald, **labelled in the output as the weaker
inference**. No CR0 or CR1 cluster-robust variance was computed.

---

## 6. Convergence failures and singular fits, retained not dropped

| Status | Reporting | Count |
|---|---|---|
| completed | 26 | 30 |
| completed with singular warning | 22 | 15 |
| completed with convergence warning | 0 | 1 |
| failed, insufficient support | 0 | 3 |
| failed, numerical fit, no fallback | 1 | 0 |

- The three count models with insufficient support are the same three as at
  Stage 2: Surfbird (n = 1,063), Rhinoceros Auklet (n = 1,816) and Glaucous Gull
  (n = 185). No regression.
- **One reporting model that Stage 2 fitted now fails outright: Common Murre**
  (`failed_numerical_fit_no_fallback`, n = 217,200). Adding the random slope
  makes it non-estimable. It is retained in the family with p = 1, not dropped.
  Common Murre was not a Stage 2 Benjamini-Hochberg survivor, so this costs no
  result, but it does mean the reporting family is 48 estimable models, not 49.
- Iceland Gull's count model completes with a convergence warning
  (max |gradient| 0.104) and is retained. It is one of the four species that
  left the count family, so the warning and the loss should be read together.
- 37 of 94 estimable fits are singular at the boundary, which is what a slope
  variance pinned near zero looks like. That is a caveat on the
  intercept-slope correlation, not on the fixed-effect contrast, and it is the
  expected consequence of adding a variance parameter that is genuinely zero for
  part of the family.

---

## 7. The bootstrap was not run

The 999-replicate event-block bootstrap was **not** run, and this is a
methodological decision rather than a resource compromise.

One-way resampling of event blocks cannot preserve the crossed dependence the
preflight measured. Checklists partition cleanly by block, but **2,495 of 29,248
observer clusters and 4,631 of 22,980 location clusters cross more than one
block** (8.5% and 20.2%). Resampling blocks as exchangeable units would break
those clusters apart and misstate the very dependence the bootstrap is meant to
capture. A design that respects both crossed factors is a separate
methodological extension, not a parameter change to this run.

For the record, the projection was also prohibitive: 97,902 model fits, 1,754
core-hours, 6.6 wall-clock days at 11 memory-bound workers.

---

## 8. What the author can no longer claim

1. **That the one separately estimable block variance was zero.** Section 4.4
   must go. Across the full family the median event-block slope SD is 0.125 for
   reporting and 0.058 for counts, and only 8 of 48 and 19 of 46 species sit at
   or below the frozen near-zero threshold.
2. **That 19 count species survive Benjamini-Hochberg.** It is 15.
3. **That the count and reporting intervals as published are correct.** Every
   estimable interval widens, by a median of about 16 to 18%.
4. **That the reporting result is only ever positive.** There are now three
   negative-direction survivors, not two.
5. **That Bald Eagle survives Benjamini-Hochberg on reporting.** It does not,
   and it left on a 13% estimate shift with essentially no widening, which means
   it was marginal all along.
6. **That the count intervals are uniformly Kenward-Roger corrected.** 21 of 46
   are; 25 carry a Satterthwaite denominator correction with an uncorrected
   standard error, understating the SE by about 3% typically and up to 21%
   relative to Kenward-Roger.
7. **That every species in the family is estimable under the block-aware
   specification.** Common Murre reporting is not.

What survives unchanged: the direction and rough magnitude of the headline
positive results. Fifteen count and thirteen positive reporting species still
clear Benjamini-Hochberg with a random slope in the estimand's own direction,
and the largest effects — Surf Scoter, Long-tailed Duck, Pacific Loon and
Short-billed Gull on counts; Glaucous Gull, Bonaparte's Gull and Brant on
reporting — are not the ones that moved.

---

## 9. Reproduction

```bash
pwsh scripts/run_post_stage4a_blockaware_v1.ps1 -Mode fixture
```

```bash
pwsh scripts/run_post_stage4a_blockaware_v1.ps1 -Mode production -Workers 5
```

Production requires the author-set shell acknowledgement, which the runner
verifies and never sets. `scripts/summarise_post_stage4a_blockaware_v1.R`
regenerates every number quoted above from the committed CSVs.

`pbkrtest` 0.5.5 and `lmerTest` 3.2.1 were installed into
`.analysis-library/blockaware_v1/R-4.5/x86_64-w64-mingw32` only. The frozen renv
library and `renv.lock` were verified unchanged before and after the run by a
gate inside the run itself; `blockaware_analysis_library_manifest.csv` records
every package version in both libraries. Count models are fitted by
`lmerTest::lmer`, which is `lme4::lmer` plus the stored deviance function the
Satterthwaite correction requires, verified on three species to give identical
fixed effects and variance components.

Elapsed 8,848 s in total: 6,108 s of fitting across 5 workers, then 2,716 s of
serial Kenward-Roger. Kenward-Roger runs serially and after the fitting pass
because two workers each holding a dense n × n inverse would exceed machine
memory.
