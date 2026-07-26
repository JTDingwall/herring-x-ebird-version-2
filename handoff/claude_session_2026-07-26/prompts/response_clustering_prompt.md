# Descriptive clustering of species response profiles

Run from the root of a local clone of `JTDingwall/herring-x-ebird-version-2`.
The manuscript under review is `mer_manuscript_v23.docx`, supplied separately.

This is a **descriptive, post-hoc, exploratory** analysis. It uses only archived
aggregate outputs. It fits no response model, reads no protected data, and needs
no authorization gate. If any step appears to require a refit or the protected
frame, stop and say so rather than improvising.

## Why this exists

Section 3.4 of the manuscript reports a meta-regression that takes seven
ecological guilds fixed in the species registry before any model was run, and
asks whether species timing contrasts differ among them. It rejects equal timing
in both outcomes (reported number Q = 117.3, p < 0.001; checklist reporting
Q = 15.0, p = 0.02).

That test imposes the groups. This analysis asks the complementary question:
does comparable structure appear in the response profiles **without** being told
what the guilds are? If clustering recovers something resembling the pre-assigned
guilds, the timing structure is not an artefact of where I happened to draw guild
boundaries. If it does not, that is equally worth knowing.

**The clustering must be blind to guild identity.** Guild labels are used only
after clusters are formed, to measure correspondence. If guild information enters
the feature set or the distance metric, the comparison is circular and the whole
exercise is worthless.

## Inputs, all archived aggregates

| File | Contents |
|---|---|
| `outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv` | per-species, per-outcome estimates and SEs for the six `did_<period>` contrasts against the days −28 to −15 baseline |
| `outputs/post_stage4a_sog_event_study_v1_1/active_minus_pre_contrasts_v1.csv` | the primary active-minus-pre-onset contrast |
| `outputs/referee_reads_followup_v1/item10_species_timing_contrasts.csv` | per-species timing contrast (`did_spawn_start` − `did_early_egg`) with exact standard errors from the persisted covariance |
| `figures_out/tableS_species_support.csv` | per-species detections, prevalence, quantified positive reports |
| `metadata/canonical_species_registry.csv` | guild assignments, **for post-hoc comparison only** |

## Feature sets, declared before you look at any cluster output

Run the analysis on two feature sets and report both. Do not add, drop or
transform features after seeing results. Everything is on the **link scale**, not
the ratio scale: ratios are exponentiated contrasts and clustering them puts the
geometry in the wrong space.

**Feature set A, response summary, 4 features per species**

1. active-minus-pre-onset contrast, checklist reporting
2. active-minus-pre-onset contrast, reported number
3. timing contrast (`did_spawn_start` − `did_early_egg`), checklist reporting
4. timing contrast, reported number

**Feature set B, full period profile, 12 features per species**

The six `did_<period>` estimates for each of the two outcomes, in event-time
order: `did_early_pre`, `did_immediate_pre`, `did_spawn_start`, `did_early_egg`,
`did_late_egg`, and `did_active_0_14_day`.

Set A asks whether species group by how much and when they moved. Set B asks
whether they group by the shape of the whole trajectory. They may disagree, and
if they do, say so rather than picking the tidier one.

## The trap that will ruin this if you ignore it

Species precision varies by roughly three orders of magnitude. American Crow
carries 112,180 quantified reports; Glaucous Gull carries 185. Bald Eagle's count
contrast is 1.063 with a 95% interval of 1.045 to 1.080; Bonaparte's Gull's is
1.163 with an interval of 0.869 to 1.556. Cluster the raw estimates and you will
substantially be clustering on sample size, and the resulting groups will track
prevalence rather than ecology.

Handle it three ways and report all three:

1. **Unweighted on standardized features.** Each feature centred and scaled to
   unit variance across species. The naive version, included so the reader can
   see what the precision problem does.
2. **Inverse-variance weighted.** Each species' contribution weighted by the
   precision of its estimates, using the exact standard errors where available
   (`exact_timing_standard_error` for the timing features) and archived standard
   errors otherwise. State which you used for each feature.
3. **Reliability-shrunk.** Shrink each species estimate toward the family mean in
   proportion to its standard error before clustering, so imprecise species sit
   near the centre rather than at spurious extremes.

If the cluster structure is similar under all three, say so and the result is
usable. If it changes, the honest conclusion is that the profiles do not support
clustering at this precision, and that is a legitimate finding to report.

Report the correlation between each species' cluster assignment stability and its
checklist prevalence. If stability tracks prevalence, the clusters are partly an
artefact of support.

## Method

Hierarchical clustering with Ward linkage on Euclidean distance is the default.
Also run PAM or k-means as a check that the structure is not an artefact of the
linkage rule. If you prefer a different standard ecological approach, use it and
say why.

**Choosing k.** Do not present a single k as though it were discovered. Report
silhouette width and gap statistic across k = 2 to 8 for both feature sets and
all three weighting schemes, as a table and a plot. Then pick k with a stated
rule, applied the same way to every run, and report the result at the chosen k
plus at k plus and minus one. A structure that only appears at one k is not a
structure.

**Stability.** This is not optional. Bootstrap the species set and report Jaccard
similarity per cluster across resamples (`fpc::clusterboot` is the standard tool;
an equivalent hand-rolled bootstrap is fine if you describe it). Clusters with
mean Jaccard below about 0.6 should be reported as unstable and must not be
described as groups in any summary. Report the number of bootstrap replicates and
the seed.

**Ordination for display.** A PCA or NMDS of the same feature matrix, with points
coloured by cluster and shaped by pre-assigned guild, is the figure that makes
this legible. Report the variance explained by the first two axes; if it is low,
say so on the figure rather than in a footnote.

## Correspondence with the pre-assigned guilds

This is the point of the exercise, so do it carefully.

- Cross-tabulate cluster against guild.
- Report the adjusted Rand index and normalized mutual information between the
  cluster partition and the guild partition.
- Test that correspondence by permuting the guild labels across species, at least
  9,999 times with a recorded seed, and report where the observed index sits in
  the permutation distribution. This is the only inferential statement this
  analysis is entitled to make, and it is a statement about correspondence
  between two partitions, not about whether clusters exist.
- Name the species that fall outside the cluster their guild mostly occupies.
  Those disagreements are the most interesting output of the whole analysis and
  should not be buried in a table.

Do not compute p-values on the clusters themselves. Clustering always returns
clusters.

## Handling non-estimable components

Checklist reporting is estimable for 48 of 49 species and reported number for 46.
Glaucous Gull has neither; Surfbird and Rhinoceros Auklet have no count model.

Use complete cases for each feature set, state exactly which species are dropped
from which analysis and why, and drop them for no other reason. **Do not remove
any species because of its prevalence, its interval width, or how it affects the
cluster solution.** The 49-species family is fixed and post-result exclusion is
the specific failure mode this project has been guarding against throughout.

If you also want to run an imputed version so all 49 appear, run it as a
sensitivity alongside the complete-case version, never instead of it.

## What is deliberately out of scope

**Spawn magnitude as a predictor.** The natural next question is whether bigger
spawns produce bigger responses. Do not attempt it here, for three reasons. It
requires the protected checklist frame and a new model specification, so it is a
gated refit and not a descriptive summary. The DFO Pacific Herring Spawn Index is
a relative index rather than absolute biomass, which the manuscript states, so a
dose-response reading imports the index's own measurement properties, including
changes in survey method across two decades. And it would move the paper's claim
from "observations changed around events" to "observations changed in proportion
to event size," which is a stronger claim needing a stronger defence than an
exploratory analysis can give it. It is a good question for a second paper.

**Event-level community composition.** Ordination of what was recorded near each
event before and after onset is the most literal reading of "community
composition," and it needs record-level checklist data and a new pipeline.
Different paper.

If either looks unexpectedly cheap once you are in the data, say so and ask
rather than starting it.

## Hard boundaries

1. Do not modify, regenerate or overwrite anything in
   `outputs/post_stage4a_sog_event_study_v1/`. Write to a new directory,
   `outputs/response_clustering_v1/`.
2. Do not remove or add taxa.
3. Do not read the 2026-2028 holdout.
4. Do not fit or refit any response model. If a step seems to need one, stop.
5. Do not set `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED`. Nothing here should
   need it; if something does, that means the task has drifted out of scope.
6. Do not `git add -A`.
7. Do not edit the manuscript or supplementary material.
8. Release aggregates only. Suppression threshold 20. No checklist, observer,
   locality, event, block or coordinate identifiers.

## Environment

R is preferred for consistency with the repository, and `cluster`, `fpc` and
`vegan` are the idiomatic tools. Check availability first: the locked local
library was recently found to be missing `numDeriv`, so do not assume a package
is present. Python with `scikit-learn` and `scipy` is an acceptable substitute if
the R packages are unavailable; say which you used. Do not install into the
locked library without saying so.

## Output

`RESPONSE_CLUSTERING_REPORT.md`, structured:

1. **Verdict, first.** In two or three sentences: does clustering recover
   structure resembling the pre-assigned guilds, is that structure stable, and
   would you put it in the paper. A negative answer is a perfectly good answer
   and is more useful than a hedged positive one.
2. Feature sets, weighting schemes, and what differed between them.
3. Choice of k, with the silhouette and gap tables.
4. Stability results, per cluster.
5. Cluster composition, named species per cluster.
6. Correspondence with guilds: cross-tabulation, adjusted Rand index,
   permutation result, and the named disagreements.
7. The prevalence-versus-stability check.
8. What you ran, what you wrote to disk, what you skipped and why.

Plus figures to `outputs/response_clustering_v1/`: the ordination coloured by
cluster and shaped by guild, the dendrogram, and the k-selection diagnostics.

## One thing to be honest about in the verdict

Based on the guild means already computed, three of seven guilds separate from
flat and four do not. A clustering is therefore likely to find a late-peaking
count group, an early reporting group, and a large undifferentiated remainder.
If that is what you find, say so plainly rather than describing three clusters as
though the third were a finding. The value of this analysis is in whether the two
informative groups emerge unprompted, not in the number of clusters.
