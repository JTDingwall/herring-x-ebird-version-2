# Stage 4: block-aware intervals for the primary contrast

For GPT-5.6 (sol High). Run this **before** regenerating figures. It can change
which species survive Benjamini-Hochberg, and the figures plot that.

---

## 1. Why this is now necessary

The ten-species random-slope diagnostic of 28 July settled a question the
manuscript had been leaving open.

Nine of ten species showed event-block slope variance whose 95% profile interval
excluded zero. Only Common Goldeneye met the frozen near-zero criterion. Surf
Scoter's slope standard deviation was 0.424 on the log count-contrast scale,
which puts the active-minus-pre effect roughly between 0.87 and 2.0 across
region-years around a mean ratio of 1.330.

The cluster distribution is also far more concentrated than the block count
suggests. Ninety-three thousand three hundred and ninety-one exposed checklists
sit in 57 blocks with a Herfindahl index of 0.04604, giving **21.72 effective
clusters**, not 58. The largest block holds 10.16% and the five largest hold
32.34%.

Current intervals come from a model with a block random *intercept* only. That
absorbs differences in level between blocks and leaves heterogeneity in the
slope, which is the direction the estimand is defined on, in the residual. The
reported intervals are therefore narrower than they should be.

Section 4.4 of the manuscript currently says the one separately estimable block
variance was zero. That claim is now falsified and is being removed.

---

## 2. What to fit

**Reuse the diagnostic's random-effect structure exactly.** It is already proven
to fit and it is the cheap form.

Replace the event-block random intercept with a **correlated event-block
intercept plus one random slope in the normalized active-minus-pre contrast
direction**. One slope on the exact linear combination being estimated, not
twelve separate slopes. Two variance parameters and one correlation.

Everything else is unchanged from Stage 2: all fixed effects including
`minutes_from_sunrise` and the two annual harmonics, and the observer and
generalized location random intercepts.

Run the **full fixed 49-species family, both outcomes**. Do not subset.

**Do not compute profile-likelihood intervals.** The diagnostic spent almost all
of its 2,390 seconds on ten profiles. The fixed-effect contrast and its interval
are what is needed here, and they come out of the fit directly.

---

## 3. Intervals

**Count models.** Gaussian, so apply **Kenward-Roger** via `pbkrtest` to the
active-minus-pre contrast. It corrects both the standard error and the
denominator degrees of freedom for the small effective cluster count, and it is
cheap for a linear mixed model. This is the primary interval for counts.

**Reporting models.** Binomial, so Kenward-Roger does not apply. Use the
random-slope Wald interval and label it in the output as the weaker of the two.
If a Satterthwaite-type denominator correction is available for the fitted
object, report it as a second column rather than replacing the Wald.

Recompute **Benjamini-Hochberg within the fixed 49-species family, per outcome**,
from the new p-values. The family does not change. No species is added or
removed.

---

## 4. What to report even if it is bad news

The current tallies are **20 count and 13 reporting**. Expect them to fall. Two
mechanisms, and both should be reported separately so the author can tell them
apart:

- **Interval widening**, which loses species that were marginal.
- **Point estimate movement**, because the random slope reweights away from the
  blocks that currently dominate the precision-weighted average. Report the
  Stage 2 and Stage 4 point estimates side by side with the percentage shift.

A smaller tally that is correct is the deliverable. Do not tune anything to
protect the current numbers, and do not drop species that fail to converge:
report them as failures.

**Report the block slope variance for all 49 species and both outcomes**, not
just the ten already done. The spread of the response across region-years is a
result in its own right and the manuscript will use it.

---

## 5. Outputs

```
outputs/post_stage4a_blockaware_v1/
  blockaware_estimates_49x2.csv     estimate, SE, CI, df, p, BH q, n, fit status
  blockaware_vs_stage2.csv          side by side, point shift and width ratio
  blockaware_slope_variance.csv     block slope variance and correlation, 49x2
  blockaware_bh_changes.csv         species entering or leaving BH, per outcome
  execution_record_v1.yml
```

Plus `BLOCKAWARE_REPORT.md` at the repository root:

1. **New tallies in the first two sentences**, against 20 and 13.
2. Which species left, which entered, and whether widening or point movement did it.
3. Median and range of the interval width ratio against Stage 2.
4. The slope variance distribution across the 49, both outcomes.
5. Convergence failures, retained not dropped.
6. What the author can no longer claim.

---

## 6. Standing constraints

Unchanged. Authorization verified in the shell and never set by you. No 2026 to
2028 records. Parent, Stage 1, Stage 2, Stage 3 and diagnostic outputs
unmodified. Branch, commit, push, open a pull request, do not merge.
