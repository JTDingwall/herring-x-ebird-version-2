# Block-aware inference over the 58 event blocks

Supersedes `claude_code_clustering_prompt.md`, which was written before
`REFEREE_READS_REPORT.md` and `REFEREE_READS_FOLLOWUP.md` came back. Read this
one instead; the scoping has changed because of what those reports found.

Run from the root of a local clone of `JTDingwall/herring-x-ebird-version-2`.
The manuscript under review is `mer_manuscript_v21.docx`, supplied separately.

This is the last outstanding item from the referee report and the only one that
can change a number in the abstract.

## The objection

The primary estimand is `did_active_0_14_day` minus `did_pre_14_day` on the link
scale: a difference in differences comparing the near/reference association
during days 0 to 14 with the same association during days −14 to −1, where the
association is the slope on the number of recorded checklist-to-event links in
each period-by-zone cell.

There are 58 event blocks. The contrast varies at the event and zone level. The
model's only concession to event-level dependence is a random intercept for
block, and the reported intervals are Wald intervals from that fit.

A random intercept absorbs differences in level between blocks. It does not
absorb correlated departures in the period-by-zone slopes, and the estimand is
defined on those slopes. With 58 effective clusters, the intervals as reported
may be too narrow, and the counts of 13 adjusted-significant reporting contrasts
and 18 count contrasts are the quantities that would move.

Section 4.4 of v21 currently states this limitation and says the intervals "may
therefore be narrower than a block-aware calculation would give." Your job is to
replace that hedge with a number, in whichever direction the number goes.

**This objection does not extend to the other two random intercepts.** There are
29,248 observer clusters and 22,980 generalized location clusters. At those
counts the asymptotics behind the model-based intervals are unproblematic and
the random intercept is adequate. Do not scope this run to them.

## What the earlier reports already established

Read these before choosing a method. Two of them bear directly on how large the
correction is likely to be.

1. **The contrast is identified overwhelmingly within blocks.** Of 93,342
   checklists exposed in at least one of the twelve period-by-zone cells, 93,152
   (99.8%) belong to a block represented in both zones. 850 of 1,120 source
   events and 51 of 58 blocks contribute links in both zones. A between-block
   comparison is not doing much of the work, which argues for a modest
   correction.
2. **The one directly estimated block variance was zero.** The Western Gull
   count model converged to a singular fit in which the event-block random
   intercept variance went to zero, with observer variance 0.0614 and
   generalized-location variance 0.0020. That is one component out of 96 and is
   not evidence about the rest, but it points the same way.
3. **Fixed effects and covariance matrices are already persisted** for all 96
   fitted components, in `outputs/post_stage4a_sog_event_study_v1_1/` and
   `outputs/post_stage4a_sog_event_study_model_summaries_v1/`. That closes the
   model-based side and means you do not need to refit to get the comparison
   baseline. It does not by itself give you a cluster-robust variance, which
   needs per-cluster score contributions.
4. **A single `nAGQ = 1` reporting fit did not complete in an hour** with four
   parallel workers. The primary `nAGQ = 0` fits are much faster, since the
   original run completed 96 components, but you do not have a recorded per-fit
   time for them. Get one before committing to anything with a B in it.
5. **`numDeriv` is missing from the locked local library**, which is why the
   reproduction run recorded `gradient_check_status = numDeriv_unavailable` for
   every component. Check for `clubSandwich`, `sandwich` and `boot` before you
   plan around them, and report what is and is not available rather than
   installing into the locked library.

## Step 0, before anything expensive

Time one refit of the primary specification for a single mid-prevalence species,
both outcomes, and report the wall-clock cost. Then state which of the options
below is affordable and pick accordingly. Do not start a bootstrap on the
assumption that fits are cheap.

If a single component takes more than about two minutes, a 999-replicate
bootstrap over 96 components is not happening and you should say so in the
report rather than quietly running a smaller B.

## Method

58 is a small number of clusters, and that governs everything. A naive CR0
sandwich under-corrects badly in this range and would produce a result that is
wrong in a way that looks reassuring. **Do not report CR0 alone.**

In order of preference:

**1. Cluster bootstrap over event blocks.** Resample the 58 block labels with
replacement, assemble the resampled data, refit, recompute the
active-minus-pre-onset contrast, and take the percentile interval across
replicates. Makes no distributional assumption about the slope deviations and
treats the binomial GLMM and the Gaussian LMM identically.

One trap that will silently ruin this: when a block is drawn more than once, its
copies must be given **distinct block identifiers** in the resampled frame.
Otherwise the block random intercept pools the duplicates as one group and the
resample understates between-block variability. Say explicitly in the report
that you handled this.

**2. Wild cluster bootstrap with Rademacher weights**, imposing the null on the
contrast. Cheaper for the Gaussian count models and standard practice in the
difference-in-differences literature at this cluster count. Less straightforward
for the binomial GLMM; if you use it there, state what you did about the link
scale.

**3. CR2 sandwich with Satterthwaite degrees of freedom.** The bias-reduced
sandwich, not CR0 and not CR1. Cheapest by far, and the only option that does
not require refits, if you can recover the per-cluster score contributions.
Report the estimated degrees of freedom per component, because a CR2 interval on
6 effective degrees of freedom means something different from one on 50.

Run whichever is affordable. If more than one is affordable, run more than one
and report them side by side. Agreement between a bootstrap and a CR2 interval
is informative and disagreement is more informative still.

**Do not attempt random slopes for the exposure terms by block.** Twelve slopes
across 58 blocks will not converge and the attempt will consume the budget.

## Scope

Preferred: all 49 species and both outcomes, 96 estimable components.

If runtime forbids that, scope to the 31 adjusted-significant components, the 13
reporting and the 18 count, and say clearly which components were excluded. That
subset is the one whose significance could change.

If runtime forbids even that, do the count outcome first. It carries the paper's
central conclusion and the manuscript says so.

**Multiplicity is not optional.** If intervals widen, the p-values change, and
the counts of 13 and 18 are Benjamini–Hochberg counts, not counts of intervals
excluding one. Recompute BH within each complete 49-species family using the
block-aware p-values, exactly as the primary run does, keyed
`analysis_role__outcome__contrast`. If you have scoped to a subset, you cannot
recompute BH over the subset and must say so: a subset-adjusted q-value is not
comparable with the primary families and must not be reported as though it were.
In that case report the block-aware intervals and p-values for the subset and
state plainly that the revised counts of 13 and 18 could not be produced.

Bootstrap replicates: aim for B = 999. B = 199 detects a serious problem and is
not enough to report a percentile interval with confidence; if you run 199, say
so and label the intervals accordingly.

## What to report

1. **The revised counts.** How many reporting and how many count contrasts
   remain adjusted-significant under block-aware inference, against the observed
   13 and 18. First paragraph, before anything else.

2. **Which species dropped out**, by name, for each outcome.

3. **The six ratios quoted in the article, with revised intervals.** Bonaparte's
   Gull 1.48 (1.22 to 1.79), American Herring Gull 1.39 (1.23 to 1.57),
   California Gull 1.32 (1.21 to 1.43) for reporting; Long-tailed Duck 1.43
   (1.29 to 1.60), Surf Scoter 1.30 (1.21 to 1.40), Short-billed Gull 1.30 (1.23
   to 1.37) for reported number. Point estimates must not move. If any of them
   does, stop and report that instead, because it means the resampling changed
   the estimator and not just its variance.

4. **A per-species table**: species, outcome, point estimate, model-based
   interval, block-aware interval, ratio of interval widths, model-based
   q-value, block-aware q-value.

5. **The median ratio of interval widths per outcome.** This single number is
   what goes into the manuscript if the individual results hold, and it is the
   most useful thing you can hand back.

6. **Estimated between-block variance in the period-by-zone slopes**, if the
   method you used exposes it. The three facts in the section above all suggest
   it is small. A direct estimate would settle it and would justify the
   manuscript's current framing in one sentence.

7. **Convergence and failure counts across replicates.** If a meaningful share
   failed, the percentile intervals are conditional on convergence and the
   report must say so.

8. **Method, degrees of freedom if CR2, replicate count and seeds.**

## The three possible outcomes

All three are publishable and none of them should be softened.

If the pattern holds with wider intervals, §4.4 replaces its hedge with the
actual comparison and the article reports both sets of counts. Given the 99.8%
within-block figure, this is the likely case.

If the counts fall substantially, the block-aware counts become primary and the
model-based ones become the naive comparison. The paper's argument does not
depend on 13 and 18 specifically; it depends on the asymmetry between the two
outcomes, which is a statement about proportions and is more robust than either
count.

If the counts collapse to near zero, that is the most important sentence you
will write and it goes at the top.

Do not select a method because it gives a more favourable answer, do not report
only the most favourable of several methods run, and do not adjust the scope
after seeing partial results.

## Hard boundaries

1. Do not modify, regenerate or overwrite anything in
   `outputs/post_stage4a_sog_event_study_v1/`. Write to a new versioned
   directory.
2. Do not remove or add taxa. The family is fixed at 49 core species plus 2
   comparators.
3. Do not touch the 2026-2028 holdout.
4. Do not set `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED` yourself. This task
   needs it. If it is unset, stop and say so rather than working around it.
5. Do not `git add -A`.
6. Do not edit the manuscript or the supplementary material.
7. Do not release any checklist, observer, locality, event, block or coordinate
   identifier. Aggregates only, suppression threshold 20.

## Out of scope for this run

The referee also asked for sensitivity to the 5 km and 20 km distance bounds. Do
not fold it in here. It is a different question, it doubles or triples the
compute, and mixing the two makes it impossible to attribute any change to
either. If the authorized session is already open and the marginal cost of one
extra specification is genuinely small, say so in the report and ask before
running it rather than deciding yourself.

## Output

`CLUSTERING_REPORT.md`, with the revised counts in the first paragraph.

While the fits are in memory, persist whatever the run produces per component so
that no future question about these intervals requires another overnight run.
