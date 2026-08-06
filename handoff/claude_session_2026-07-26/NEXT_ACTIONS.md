# Next actions

Rewritten 27 July 2026. The previous list ran to seven items; items 1 to 4 are
done. See `STATUS_2026-07-27.md` for the full picture.

---

## Done since the last version of this file

1. ~~Rewrite the Introduction against the author's comments~~ — v31 to v33
2. ~~Restructure Section 2~~ — v31, with Table 1 added for the period definitions
3. ~~Fix the day-0 definition~~ — v31, stated once with the endpoint spread
4. ~~Add the distance-band result~~ — v33, moved into Section 3.4 as a case study

Plus, unplanned: the whole manuscript was rebuilt as tracked changes, the 15
author comments were answered and resolved, the ordination was removed, 17
headings were retitled, and three rounds of prose work were done on AI-sounding
constructions.

---

## 1. Fill the seven author placeholders

**Owner: Jacob.** Repository DOI (appears twice), funding statement,
generative-AI declaration, acknowledgements, study-area map, and the full
reference for **Dingwall et al. 2026**.

The Dingwall reference is the one that blocks submission. It is cited in the
Introduction and sits in the bibliography as a placeholder. It does not exist
anywhere in the repository. Do not construct it.

## 1b. Run the staged refit

**Owner: Jacob to authorize, then compute.** Prompt at
`prompts/codex_staged_refit_prompt.md`. This supersedes
`prompts/codex_spawn_dose_prompt.md`, which became Stage 3 of it.

Three pending changes each require refitting the same 98 models, so they run as
one job in three isolated stages:

1. **Anchor.** Day 0 moves from the midpoint of the recorded spawn window to the
   first recorded spawn date. The data dictionary already declares `start_date`
   the preferred anchor; the frozen spec departed from it. Most events will not
   move at all, since a span of zero or one day floors to a zero-day shift.
2. **Detectability.** Adds minutes from sunrise and annual harmonics for day of
   year, closing the eBird gap. Harmonics rather than a cyclic spline, because
   the engines are lme4 and not mgcv.
3. **Dose.** Spawn index as exposure, decomposed within and between locations.

It also regenerates every figure as vector PDF, which clears the one outright
compliance failure, and produces Figure 5, which is currently a placeholder.

Blocked on `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED`.

Returns `STAGED_REFIT_REVIEW.md` on a pull request. Read section 2 of that
document first: it lists every sentence in v42 that the new numbers invalidate.

## 2. Produce Figure 5

**Owner: compute.** Currently a grey placeholder. The caption describes what it
should show: event-time profiles at 2 km resolution for Bald Eagle,
Glaucous-winged Gull and American Robin across the 13 distance bands, reporting
and count ratios against the same-band baseline.

Source data is in `outputs/post_stage4a_distance_band_sensitivity_v2/`,
`outputs/post_stage4a_gwgu_distance_band_sensitivity_v1/` and
`outputs/post_stage4a_distance_band_followup_v1/`.

## 3. Figures as vector PDF

**Owner: anyone with R.** The one outright compliance failure. Six scripts in
`figures_ggplot2/` have never been executed. Run `00_theme_mer.R` first.

## 4. Block-aware intervals

**Owner: Jacob, then compute.** The only outstanding item that could change the
counts of 13 and 18. Prompt at `prompts/codex_clustering_prompt.md`. Blocked on
`POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED`, which only the author sets.

If it runs and the counts move, Section 4.4 already states the concern honestly,
so the change would be a strengthening rather than a correction.

## 5. Spawn biomass as an exposure

**Owner: Jacob.** Explicitly deferred on 26 July. Comment 105: "I think we
should try analysis using the biomass because we treat is as pretty true in the
herring research world." Section 2.2 currently states the opposite. Do not soften
that text or commission the refit without a decision.

## 6. Refresh the compliance checklist

Stale at v15. Lives in the Claude session outputs as
`mer_submission_compliance_checklist.md`.

---

## Standing verification requirement

Run after **every** build, without exception:

```
python3 tools/verify_v33.py          # structure, numbers, italics, comments
python3 tools/ai_tells_scan.py <doc> # prose
```

The interval check extracts every `X.XX (Y.YY–Z.ZZ)` triple from the body and
matches it against `figures_out/tableS_primary_contrast_49x2.csv` and
`outputs/referee_reads_v1/item2_specificity_comparators.csv`. It has caught two
real rounding errors that survived manual reading. As of v39, 43 of 43 match.

Also check every time: paragraph count, italic runs including inside tracked
changes, placeholder count, figure and equation count, reference count, comment
anchors, and that no heading was overwritten by an off-by-one index. Every one
of those has failed at least once in this project, several of them silently.

**If a build uses tracked changes, verify both directions.** Accepting
everything must reproduce the target text; rejecting everything must reproduce
the baseline exactly. Both have caught real bugs, including one that deleted the
model equation paragraph.
