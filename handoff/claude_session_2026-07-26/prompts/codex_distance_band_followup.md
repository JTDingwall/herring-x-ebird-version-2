# Follow-up on the distance-band package (PR #17)

The analysis is sound and the near-band result is worth putting in the paper.
Four items would let it be stated more strongly, and a fifth would change how
much weight it can carry. All five are cheap relative to what has already run.

Same boundaries as before: do not modify the frozen Stage 4A release, do not
change the species family, do not read the 2026-2028 holdout, do not edit the
manuscript.

## 1. Multiplicity

There are 156 released contrasts per species and no adjusted p-values anywhere
in the effects tables. Across both species, 104 of 312 contrasts are nominally
significant against roughly 16 expected by chance, so there is abundant real
signal, but the manuscript applies Benjamini-Hochberg correction everywhere else
and a referee will notice the inconsistency.

Add adjusted p-values to both effects tables. State the family explicitly. My
suggestion is to adjust within species and outcome across the 13 bands for each
period, which gives 13-member families and matches how a reader will look at the
distance profile, but any stated and defensible family is fine. Report which
contrasts survive.

## 2. A direct test that the distance profile changes at onset

This is the most valuable item. The claim the paper wants to make is that the
spatial pattern *changes* when spawning starts. Neither existing test asks that
directly. `period_specific_distance_heterogeneity` tests whether bands differ
within a single period, and `global_five_period_distance_by_timing_heterogeneity`
pools all five periods.

What is missing is a linear hypothesis contrasting the spawn-start band profile
against the pooled pre-spawn band profile, on the 13 band coefficients jointly.
The exposure covariance matrices are already archived
(`exposure_covariance_v2.csv`, `exposure_covariance_v1.csv`), so this needs no
refit.

Report the statistic, degrees of freedom and p-value for each species and
outcome. If the profile at onset is significantly different from the profile
before onset, that is the sentence the manuscript should carry, and it is much
harder to attack than a series of per-band comparisons.

## 3. Put the asymmetries in the report

Two things are true in the effects tables and absent from the report, and both
will be found by anyone who opens the CSVs.

**The Bald Eagle reporting result at 0–<2 km does not clear over the
manuscript's primary window.** The days 0–14 composite is 1.083 with p = 0.089.
Only the days 0–3 spawn-start window clears, at 1.310. The count outcome does
clear at 1.074. State this for every species and outcome: does the 0–<2 km
active 0–14 contrast clear, yes or no.

**Several outer bands sit significantly below their own baseline during
pre-spawn periods.** Bald Eagle reporting at 8–<10 km is 0.917 in early
pre-spawn (p = 0.013) and 0.888 in immediate pre-spawn (p = 0.0009); Bald Eagle
counts in that band are significantly negative in all five periods; the gull has
similar cells at 14–<16 and 16–<18 km. The README describes the outer bands as
"weaker and non-monotonic", which understates it. List every band and period
where the contrast is significantly below one, separated into pre-spawn and
post-onset, so the pattern is visible rather than buried.

## 4. Two small reconciliations

`bald_eagle_distance_band_effects_v2.csv` records n = 217,199 while
`execution_record_v2.yml` records `eligible_checklists: 217200`, and the rest of
the project uses 217,200. One checklist. Explain or reconcile it.

Also report the support behind the headline. The 0–<2 km spawn-start cell holds
1,166 exposed checklists, the smallest cell in the grid, and the nearest band
carries roughly half the support of the 8–12 km bands. That belongs in the
report next to the 1.31 and 1.32, not only in `joint_exposure_support`.

## 5. A negative control, and why it matters more than the rest

Both species analysed are herring-associated, and both are among the four most
frequently reported birds in the family. As it stands, the result is consistent
with two explanations that the analysis cannot separate:

- birds that use herring concentrate within 2 km of a spawn, or
- checklists within 2 km of a recorded spawn point differ from other checklists
  in some way that has nothing to do with the species, for instance because
  those shorelines attract different observer behaviour once a spawn is visible
  from the road.

Running the same 13-band machinery on a well-supported species with no herring
expectation would separate them. If a control species shows no near-band spike
at onset, the concentration claim becomes much stronger. If it shows the same
spike, the result is about checklists and not about birds, and that is something
worth knowing before submission rather than after.

**The control must be a terrestrial bird, not a waterbird.** Every species in
the registry is a coastal taxon, and the two flattest well-supported candidates,
Great Blue Heron and Common Raven, both sit in the shoreline scavenger guild.
Either could plausibly respond to concentrated fish or to a strandline, so a
weak positive from either would be uninterpretable. They are not nulls.

What is needed is a bird that shares the checklist but not the resource. Use one
or two abundant terrestrial species that appear on the same coastal checklists,
have no route to herring of any kind, and are detectable in late winter and
early spring in this region:

- **American Robin** (*Turdus migratorius*). Abundant, conspicuous, terrestrial,
  and immediately legible to a reader as a null.
- **Chestnut-backed Chickadee** (*Poecile rufescens*) or **Dark-eyed Junco**
  (*Junco hyemalis*) as a second. Forest and edge birds with no shoreline
  association at all. Song Sparrow is a weaker choice because it does forage on
  beach wrack.

Two controls are much better than one. If both are flat, the argument is strong.
If they disagree, that is worth knowing.

Say in advance what each outcome would mean, and report against those
predictions rather than interpreting after the fact:

- **Control flat at 0–<2 km across all periods.** The near-band spike is a
  property of the water and not of the checklist. This is the result that lets
  the manuscript make the concentration claim.
- **Control spikes upward at onset.** Checklists near a spawn are inflated
  generally, presumably through attention or effort the covariates do not
  capture, and the waterbird result is confounded.
- **Control drops at onset.** Observers are redirecting attention to the water
  and recording fewer terrestrial birds. That is a different confound and it
  would inflate the waterbird results by a second route. A negative result in
  the control is therefore not automatically reassuring.

Run both outcomes for symmetry, though reporting is the cleaner one for a
terrestrial bird on a coastal checklist.

Two implementation notes. The control taxa sit **outside** the registered
49-species family and must not enter any Benjamini-Hochberg family of the
primary analysis; the distance-band work is already a separate exploratory
release with its own authorization record, so the control belongs there and not
in the frozen Stage 4A family. And confirm that seasonal changes in
detectability, which are large for these species in late winter, difference out:
each band is compared against its own baseline within the same event-time
window, and onset dates are spread across years and locations, so they should,
but say so rather than assume it.

Report the 0–<2 km timing profile for each control in the same layout as the two
existing species, and say plainly whether it spikes at onset.

## 6. A tight window around onset, in two stages

The sharpest available test of the concentration claim is whether the response
jumps at day 0 rather than drifting up across the season. Two versions of that
are worth having, and they differ enormously in cost.

### 6a. Free, and do it regardless

Every period in the current analysis is contrasted against the days −28 to −15
baseline, which sits three to four weeks earlier. Nothing reports **spawn start
(days 0 to 3) against immediate pre-spawn (days −7 to −1)** directly, within
band. That is a seven-day-before against four-day-after comparison, it is the
tightest pre-versus-post contrast the fitted model already supports, and it is a
linear contrast of two existing coefficients. The covariance matrices are
archived, so it needs no refit.

Report it for both species, both outcomes, for the 0–<2, 2–<4 and 4–<6 km bands
at minimum, with intervals and adjusted p-values. If the near-band jump survives
against a baseline one week earlier rather than four weeks earlier, that is a
much stronger sentence than anything in the current report, and it largely
disarms the seasonal-drift objection.

### 6b. A symmetric ±3 day window, conditional on one check

A −3 to −1 against 0 to +3 comparison would be tighter still and nearly free of
seasonal confounding. The +3 side is already fitted, since spawn start is
exactly days 0 to 3. The −3 side is not: immediate pre-spawn runs −7 to −1, so
this needs that period split into −7 to −4 and −3 to −1, which means a refit.

**Do not run it before checking onset-date precision.** The whole test lives
inside a six-day window, and the recorded onset date comes from Fisheries and
Oceans Canada survey visits rather than from continuous observation. If those
surveys are conducted at multi-day or weekly intervals, the recorded onset
carries error of the same order as the window, the comparison is attenuated
toward null, and a null result would mean nothing. The wider periods already in
use are robust to that error precisely because they are wide.

So, before any refit, report:

- how the recorded onset date is derived from the survey record;
- the distribution of intervals between consecutive surveys at the same
  location, or whatever equivalent quantifies how precisely onset is dated;
- the number of source events whose onset could be dated to within one day.

If onset is dated to a day or two, run 6b and report it alongside 6a. If it is
weekly, say so and stop, and note the limitation in the report so the manuscript
can state it. Either answer is useful, and the second is cheaper.

One further caution if 6b does run: at 0–<2 km the days 0 to 3 cell already
holds only 1,166 exposed checklists, and a three-day pre-window would hold
roughly 700. Report the support alongside the estimate, and expect wide
intervals rather than treating a wide interval as evidence of absence.

## What is not needed

Do not re-run the two existing species. Do not extend the bands beyond 26 km.
Do not attempt a smooth distance-decay model; the profiles are not smooth and
fitting a curve to them would claim more than the data support.

## Output

Append to the existing reports or write `DISTANCE_BAND_FOLLOWUP_REPORT.md`, with
item 2 first and item 5 second, since those are the two that change what the
manuscript can say.
