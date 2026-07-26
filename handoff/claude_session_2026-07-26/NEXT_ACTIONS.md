# Next actions

Ordered by what unblocks the most. Items 1 to 4 are writing and need no new
analysis. Items 5 onward need compute or the author.

---

## 1. Rewrite the Introduction against the author's comments

Nine comments land here: 33, 35, 36, 42, 44, 47, 54, 67, 68, 69, 70, 74, 76, 77,
83, 94. Read `AUTHOR_EDITS_v27.md` before touching anything.

Required changes of substance:

- Spawns at a shoreline are **more rapid** than the current "three or four days".
- Gulls also take **floating vegetation carrying eggs** and **herring pushed to
  the surface or into very shallow water**.
- Piscivores probably use **eggs as well as adults**; the current text asserts
  the clean version. Write it as an expectation, not an established fact.
- Name **genus or group names** where the text currently gestures at "loons,
  mergansers, grebes and cormorants".
- The Strait of Georgia is chosen because it has **the most data on both ends**.
  Say that rather than the ecological justification currently there.
- Cite **Dingwall et al. 2026**. The author asked for it; get the full reference
  from him, do not invent it.
- Replace the author's two placeholders: "display a degree of flexibility and
  search capacity" and "*put something here about bird and herring conservation
  and management*".
- Repair "cause birds to observed at a greater rate" (author typo).
- The closing paragraph needs the conventional shape of a final Introduction
  paragraph in a science paper.
- Say the two-week incubation **once**, not twice (comment 54).

Delete, do not rewrite: the four sentences flagged as bad closers (36, 47, 67,
74, 77).

## 2. Restructure Section 2

Comment 97 is a specific structural instruction:

```
2.1  Study Area
     with a placeholder map showing coastal bird migrations
     and the timing of major groups (shorebirds, etc.)
2.2  Data Sources
     2.2.1  eBird data: what it is, how it is collected, what was done to it
     2.2.2  Herring data: same treatment
     2.2.3  How the two were combined
```

Also here:

- **Capitalize section headings** (comment 98).
- Remove "estimand" from the Section 2.4 heading (comment 122). Nobody uses it.
- "The study was restricted to..." — "restricted" reads badly (comment 99).
- **Define "event block" in plain language** (comment 108). The author's own
  definition of X is the model: written from the user's point of view.
- Section 2.2 is not readable or well structured (comment 112).
- Do **not** reintroduce the taxonomy sentence or the exploratory disclosure.
  Both were deleted deliberately.

## 3. Fix the day-0 definition

See `PROJECT_STATE.md` section 3. Day 0 is the midpoint of the DFO StartDate and
EndDate fields, not an observed onset. Add one honest definition where the
periods are defined, with the supporting spread (median endpoint span 1 day,
75th percentile 2 days, 466 of 1,144 events same-day). After that, "recorded
onset" is defensible shorthand and does not need thirty edits.

## 4. Add the distance-band result

The review and proposed text are in `reviews/distance_band_review.md`. Since
that review was written the follow-up run added BH correction, terrestrial
controls and the tight contrast, so the text needs updating with:

- Tight contrast, days 0 to 3 against days −7 to −1, at 0 to 2 km: gull
  reporting 1.31, gull counts 1.40, eagle counts 1.22 survive BH; eagle
  reporting 1.23 does not.
- Neither terrestrial control shows a near-band spike at the anchor. American
  Robin is not flat overall: its reporting is elevated at 0 to 2 km during
  immediate pre-spawn, BH q = 0.039, and its full reporting profile changes at
  the anchor.
- 84 of 312 waterbird contrasts survive the declared 13-band BH families.
- The 0 to 2 km anchor cell holds 1,166 exposed checklists, the smallest in the
  grid, roughly half the support of the 8 to 12 km cells.

Place in Section 3.7 with the panel figures in the supplement. Add one sentence
to Section 4.4: at 2 km resolution the response sits well inside the 5 km near
zone, so that bound is conservative and dilutes the signal rather than creating
it. That partly answers the standing objection that the bounds were never
varied.

## 5. Block-aware intervals

The only outstanding item that could change the counts of 13 and 18. Commission
prompt at `prompts/codex_clustering_prompt.md`. Needs the authorization
variable, which only the author sets.

## 6. Figures as vector PDF

The one outright compliance failure. Six R scripts exist in the Claude session
outputs under `figures_ggplot2/` and have never been run, because R was not
available in that sandbox. Whoever picks this up with R should run them.

## 7. Refresh the compliance checklist

Stale at v15. Lives in the Claude session outputs as
`mer_submission_compliance_checklist.md`.

---

## Standing verification requirement

After **every** manuscript build, re-run the interval check: extract every
`X.XX (Y.YY–Z.ZZ)` triple from the body and match against
`figures_out/tableS_primary_contrast_49x2.csv` and
`outputs/referee_reads_v1/item2_specificity_comparators.csv`. It has caught two
real rounding errors. As of v27, 44 of 44 match.

Also check after every build: paragraph count, italic run count, placeholder
count, figure and equation paragraph count, reference count, and that no
heading was overwritten by an off-by-one index. All of those have failed at
least once in this project.
