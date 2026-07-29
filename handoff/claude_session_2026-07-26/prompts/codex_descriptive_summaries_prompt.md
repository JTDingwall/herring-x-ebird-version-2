# Descriptive summaries for the opening of the Results

For GPT-5.6 (sol High) in VS Code, working in `herring-x-ebird-version-2`.

Small job. No models, no tests, no p-values, no multiplicity. Every number here
is a median, an interquartile range, a count or a percentage. If you find
yourself fitting something, stop.

---

## 1. Scope and gates

Requires `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED`, verified in the shell and
never set by you. Standing constraints unchanged: no 2026 to 2028 records, no
record-level release, no modification of
`outputs/post_stage4a_sog_event_study_v1/`, and the suppression rule that
released counts below 20 are withheld.

**Use the start-date anchor adopted at Stage 1**, not the original midpoint.
Day 0 is the first date on which spawn was recorded at a location.

Definitions, matching the main analysis:

- Near zone: within 5 km of a recorded event. Reference zone: 5 to 20 km.
- Pre-spawn window: days −14 to −1. Active window: days 0 to 14.
- Registered species: the fixed 49. Richness means how many of those 49 appear.
- Checklists: eligible complete checklists **linked to an event**. Report the
  unlinked total once so coverage is visible, then work with the linked set.

---

## 2. Spawning events

Report for the events used in the analysis, and give the all-Strait total in one
line so coverage is visible.

1. Number of events; number per year, median and range
2. Recorded span in days (end minus start): median, IQR, and the full
   distribution binned 0–1, 2–3, 4–5, 6–7, 8 or more. Report the maximum.
3. Day of year of first recorded spawn: median and IQR
4. Within-year season span, first to last event date in each year: median, IQR,
   and the per-year series
5. Relative spawn index per event, aggregated as the sum of the three
   components with unrecorded components treated as zero: median, IQR,
   minimum, maximum, and the number of events where no component was recorded
6. Length and width: medians and IQRs, with missing counts
7. Survey method: counts and percentages for Surface, Dive, Incomplete, missing
8. Distinct locations and sections represented; how many locations recorded
   spawn in more than one year, and the distribution of years per location

Item 4 supports a claim in the Introduction about the season shortening, so give
the per-year series as a small table, not only a summary.

Item 5 note: the data dictionary currently reads "missing is not zero" for the
three components. The author has confirmed the total index is their sum, so
missing components are treated as zero when summing to the event total. Amend
the dictionary line accordingly in the same commit, and report how many records
that affects.

---

## 3. Bird assemblage

At checklist level, restricted to the 49 registered species, split by zone and
period into four cells.

1. Checklists per cell
2. Registered-species richness: median, IQR, mean
3. Total individuals from numeric counts: median and IQR, reported as a **lower
   bound**
4. Percentage of checklists holding at least one registered species
5. Median duration in minutes, distance travelled in km, and number of observers
6. Percentage of positive records carrying an unquantified X rather than a count
7. Ten species by percentage of checklists, near zone during the active window
8. Ten species by summed individuals, near zone during the active window
9. Guild shares of registered-species richness, near zone during the active window

Also give a one-line "typical checklist": the median near-zone active checklist
by protocol, duration, distance, richness and individuals.

**Diversity indices are excluded by default.** Shannon and Simpson need
abundances, and X entries are missing not-at-random precisely when flocks are
large, which is the situation near an active spawn. If you compute them anyway
as a supplementary column, restrict to the counted subset and label the bias
direction explicitly. Richness is the primary measure.

---

## 4. Outputs

```
outputs/post_stage4a_descriptive_summaries_v1/
  spawn_event_summaries.csv       items 1 to 8 of section 2
  spawn_season_by_year.csv        the per-year series
  assemblage_by_zone_period.csv   the four-cell table
  assemblage_top_species.csv      items 7 and 8
  assemblage_guild_shares.csv     item 9
  execution_record_v1.yml         versions, timings, any record dropped and why
```

Plus `DESCRIPTIVE_SUMMARIES_REPORT.md` at the repository root, structured so the
numbers can be dropped straight into manuscript placeholders:

1. The four-cell table, formatted as it would appear as Table 2
2. The spawn paragraph values, listed in the order of section 2
3. The assemblage paragraph values, in the order of section 3
4. Anything dropped, and the count
5. Any number you would advise against reporting, and why

---

## 5. Two things to be careful about

**Effort belongs in the four-cell table, not in a footnote.** Richness scales
with duration and observer skill, and Stage 1 found duration about 1.13% higher
near an event during the active window. A reader must be able to see effort and
richness in the same table and judge for themselves.

**Do not test the cells against each other.** No p-values on the descriptive
table. The difference-in-differences models already handle inference with effort
and dependence accounted for, and an unadjusted comparison sitting beside them
would invite exactly the wrong reading.

---

## 6. Git

Branch off the current head, commit the outputs and the data-dictionary
amendment separately, push, and open a pull request. Do not merge.
