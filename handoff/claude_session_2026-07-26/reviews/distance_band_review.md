# Review: distance-band resource-pulse package (PR #17)

Reviewed against the full effect tables, not the README summary:
`outputs/post_stage4a_distance_band_sensitivity_v2/bald_eagle_distance_band_effects_v2.csv`
and `outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/glaucous_winged_gull_distance_band_effects_v1.csv`,
plus both `distance_heterogeneity_tests` files.

## Verdict

Include it. The analysis is sound and it adds something the paper does not
currently have. But the proposed manuscript language leads with the wrong claim,
and if it goes in as written a methods referee will find the problem in about
ten minutes.

**Lead with timing inside the nearest band, not with distance decay.**

## What is genuinely strong

The 0–<2 km timing profile is clean in both species and both outcomes. Ratios
against that band's own days −28 to −15 baseline:

| | early pre | immediate pre | spawn start | early egg | late egg |
|---|---:|---:|---:|---:|---:|
| Bald Eagle, reporting | 0.97 | 1.06 | **1.31** | 1.01 | 0.98 |
| Bald Eagle, counts | 0.97 | 1.02 | **1.24** | 1.02 | 0.96 |
| Glaucous-winged Gull, reporting | 0.98 | 1.01 | **1.32** | 1.16 | 1.03 |
| Glaucous-winged Gull, counts | 1.08 | 1.05 | **1.47** | 1.27 | 1.05 |

Flat through both pre-spawn windows, a sharp rise at onset, decay afterwards.
That is a pulse signature, it appears independently in two species and two
outcomes, and it is a within-band before-and-after comparison, which is the same
logic the paper already uses. It does not depend on any outer band behaving.

The distance heterogeneity tests are overwhelming at spawn start: Bald Eagle
counts give chi-square 235.8 on 12 df, Glaucous-winged Gull counts 210.9. The
global distance-by-timing tests are p < 1e-6 for both species and both outcomes.
Distance matters. That is established.

Bald Eagle counts also decay monotonically across the first three bands at spawn
start: 1.24, 1.13, 1.08. Gull counts do the same: 1.47, 1.15, 1.13.

## Four problems the packet does not surface

**1. Distance structure exists before spawning begins.** The period-specific
heterogeneity tests are significant in the pre-spawn windows too: Bald Eagle
counts give p = 0.022 in early pre-spawn and p = 0.0002 in immediate pre-spawn;
the gull gives p = 0.013 and p = 0.00007. Some of the distance pattern is a
standing spatial gradient rather than a response to spawning. The saving grace is
magnitude: chi-square 23.7 before onset against 235.8 at onset for the eagle
counts, a tenfold difference. Pre-existing structure that intensifies by an order
of magnitude at onset is defensible. Pretending it is absent is not.

**2. Several outer bands sit significantly below their own baseline, including
before onset.** Bald Eagle reporting at 8–<10 km: 0.92 in early pre-spawn
(p = 0.013), 0.89 in immediate pre-spawn (p = 0.0009), 0.88 at spawn start.
Bald Eagle counts in that band are significantly negative in all five periods.
The gull has significant negatives scattered at 6–8, 14–16, 16–18 and 24–26 km,
several of them pre-spawn. The README calls the outer bands "weaker and
non-monotonic", which is true and insufficient. They are in places significantly
negative before anything has happened, and the design cannot say why.

**3. The eagle headline rests on a four-day window.** For Bald Eagle reporting at
0–<2 km, the days 0–14 composite is 1.083 with p = 0.089, not significant. Only
the days 0–3 spawn-start window clears. The manuscript's primary window shows
nothing for that species and outcome in the nearest band. The count outcome does
clear at 1.074, so the pair is not symmetric and the text must not imply it is.

**4. No multiplicity correction on 312 contrasts.** 104 are nominally
significant against about 16 expected by chance, so there is abundant real
signal and I am not suggesting the result is noise. But no individual outer-band
cell should be quoted, and the paper corrects for multiple testing everywhere
else. That inconsistency will be noticed.

Two smaller things. The species are the second and fourth most frequently
reported in the family, at 41.2% and 38.8% of checklists, presumably because
only well-supported species can sustain thirteen bands; nothing here generalises
to the other 47. And the effects files record n = 217,199, one checklist short of
the 217,200 used everywhere else, which is trivial but should be explained or
reconciled.

## Proposed manuscript text

Replacing the candidate language in the package README. This claims less and is
harder to attack.

> Two of the most frequently reported species were examined at finer spatial
> resolution, in 2 km bands out to 26 km, with each band compared against its own
> days −28 to −15 baseline. Within 2 km of a recorded spawning event, both Bald
> Eagle and Glaucous-winged Gull were flat through the two pre-spawn windows and
> rose sharply at spawn start: reporting odds were 1.31 and 1.32 times higher and
> reported numbers 1.24 and 1.47 times higher than the same band's own baseline.
> Both fell back during egg availability. Reported numbers declined across the
> three nearest bands at spawn start, from 1.24 to 1.13 to 1.08 for Bald Eagle
> and from 1.47 to 1.15 to 1.13 for Glaucous-winged Gull. A test of whether the
> response varied with distance was highly significant at spawn start for both
> species, though it was also significant, an order of magnitude more weakly, in
> the pre-spawn windows, so some of the spatial structure is present before
> spawning begins. Beyond about 6 km the profiles are not smooth, and several
> bands sit significantly below their own baseline in periods before onset as
> well as after. These sensitivities are exploratory, cover two species, and
> carry no correction for multiple testing across bands; they describe where and
> when the association is strongest and do not establish a distance threshold,
> individual movement, or a change in abundance.

## Where it goes

Section 3.7, with the sensitivities, as one paragraph. The two four-panel figures
belong in the supplement rather than the main text, since this covers two species
out of 49.

One sentence is also worth adding to Section 4.4, where the paper already
concedes that the 5 km and 20 km bounds were set by judgement and never varied.
This partly answers that: at 2 km resolution the response is concentrated well
inside the 5 km near zone, which means the 5 km bound is conservative and dilutes
the signal rather than manufacturing it. That is a useful thing to be able to say
and it comes free with this analysis.

## What I would not do

Do not put this in the abstract. Do not describe it as showing "how concentrated
the pulse is" in the paper's own voice without the pre-spawn caveat attached in
the same sentence, because the pre-spawn heterogeneity is real and a referee who
opens the outputs will find it.
