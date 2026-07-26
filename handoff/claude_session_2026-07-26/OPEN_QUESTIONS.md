# Open questions

Decisions only Jacob can make. Do not resolve these by guessing.

---

## 1. Spawn biomass as an exposure variable

**Status: explicitly deferred by the author, 26 July 2026.**

Section 2.2 currently states that only the presence, location and timing of a
recorded spawning event enter the models, and that the index value itself is
never used, because the DFO Pacific Herring Spawn Index is relative rather than
absolute and unsurveyed coastline yields no record rather than a zero.

The author disagrees (comment 105):

> "I don't necessarily agree with this. I think we should try analysis using the
> biomass because we treat is as pretty true in the herring research world."

This is a scientific judgment and a gated refit, not a rewrite. It would also
move the paper's claim from "observations changed around events" toward
"observations changed in proportion to event size", which is a stronger claim
needing a stronger defence. Do not soften the Methods text unilaterally and do
not commission the analysis without asking.

## 2. The Dingwall et al. 2026 reference

The author asked for his own paper to be cited (comment 42) and inserted
"; Dingwall et al. 2026" into the Introduction. **The full reference does not
exist anywhere in the manuscript or repository.** Get it from him. Do not
construct it.

## 3. Two author placeholders in the draft

The author left these in his own tracked changes and they are his to fill:

- "display a degree of flexibility and search capacity" — flagged in comment 33
  as "Something like this but not this exact wording". A rewrite can be proposed
  but the intended meaning should be confirmed.
- "*put something here about bird and herring conservation and management*" — a
  placeholder for the Introduction's closing. Needs the author's angle before
  anyone writes it.

## 4. Six `[[AUTHOR INPUT REQUIRED]]` placeholders

Still in the manuscript:

- Repository DOI, in Data availability and Code availability
- Funding statement, including grant numbers and sponsor role
- Declaration of generative AI use, naming tools and versions
- Additional acknowledgements
- One on validation refit species

## 5. Whether the author has reviewed past Section 2.2

Comment 123 says "This is as far as Ive provided edits for now." Everything from
Section 2.3 onward has not been through his review. Do not assume silence means
approval; the Results and Discussion were substantially rewritten in v24 and v25
and he may not have read them in the current form.

---

## Resolved, for the record

These were open for several versions and are now settled by the author's edits.
Do not reopen them.

- **The exploratory disclosure in Section 2.1.** Deleted in full by the author.
  The repository still records `analysis_status:
  post_result_ecologically_motivated_refinement` in
  `outputs/post_stage4a_sog_event_study_v1/execution_record_v1.yml` and in
  `metadata/post_stage4a_sog_event_study_spec_v1.yml`, and
  `metadata/post_stage4a_branch_reconciliation.yml` records
  `created_after_stage4a_results_available: true`. The author chose to delete the
  manuscript disclosure with that on the record. His call, made with the conflict
  in front of him.
- **The taxonomy sentence.** Deleted in full, even in one-clause form.
- **First person.** Removed from the body. "I thank" stays in the
  Acknowledgements. A personal observation keeps the parenthetical form
  "(J. T. Dingwall, personal observation)".
- **The limitations sentence in the abstract.** Removed. Ecology abstracts do not
  end on a disclaimer.
- **The ±3 day symmetric window test.** Correctly not run. Survey cadence is
  unavailable and the anchor is not an observed onset, so the gate failed:
  `FAIL_NO_SURVEY_CADENCE_AND_ANCHOR_IS_NOT_OBSERVED_ONSET`.
