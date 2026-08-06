# Continuation prompt

Paste the text below into a fresh session with this repository available.

---

You are continuing work on a manuscript in late revision for *Marine
Environmental Research*. It is sole-authored by Jacob T. Dingwall and reports
coastal bird responses to Pacific herring spawning in the Strait of Georgia,
using 217,200 eBird checklists linked to 1,120 DFO spawn records.

The science is finished and verified. What remains is mostly writing.

**Start by reading, in this order, from `handoff/claude_session_2026-07-26/`:**

1. `README.md`
2. `PROJECT_STATE.md` — the full state of the project
3. `AUTHOR_EDITS_v27.md` — the author's 25 comments and 78 tracked changes on
   the current draft. This is the most important document.
4. `WRITING_STYLE.md` — the voice. Section 9 is derived from the author's own
   edits and outranks the rest of that file.
5. `NEXT_ACTIONS.md` — the work queue
6. `OPEN_QUESTIONS.md` — do not resolve these yourself

**Your task is items 1 to 4 of `NEXT_ACTIONS.md`:** rewrite the Introduction
against the author's comments, restructure Section 2 as he specified, fix the
day-0 definition, and add the distance-band result. Work from
`handoff/claude_session_2026-07-26/manuscript/mer_manuscript_v27.docx`, which
carries his tracked changes and comments. Produce v28.

**Rules that are not negotiable.**

- Never invent, estimate or back-calculate a number, interval, p-value, date,
  species total, citation or DOI. If you cannot verify it in the repository, say
  so and leave a `[[AUTHOR INPUT REQUIRED: ...]]` marker.
- The 49-species family is fixed. Do not drop taxa for low support or any other
  post-result reason.
- Do not modify anything in `outputs/post_stage4a_sog_event_study_v1/`, do not
  read 2026–2028 holdout records, and do not set
  `POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED` yourself.
- No em dashes anywhere. No first person in the body; "I thank" stays in the
  Acknowledgements.
- Do not reintroduce the taxonomy sentence or the exploratory disclosure. The
  author deleted both deliberately.

**After every manuscript build, run this check and report the result.** Extract
every `X.XX (Y.YY–Z.ZZ)` interval triple from the body and match each against
`figures_out/tableS_primary_contrast_49x2.csv` and
`outputs/referee_reads_v1/item2_specificity_comparators.csv`, allowing only
rounding difference. It has caught two real errors that survived manual reading.
As of v27, 44 of 44 match. Also verify after each build: paragraph count, italic
run count, `[[AUTHOR INPUT REQUIRED]]` count, figure and equation paragraph
count, reference count, and that no heading was overwritten. Every one of those
has failed at least once in this project.

**How the manuscript is built.** Each version comes from a Python script using
`python-docx`, rebuilding from the previous `.docx` so images, OMML equations,
styles and continuous line numbering survive. Text is replaced paragraph by
paragraph by index. That is fast and brittle: several bugs came from off-by-one
indices silently overwriting a heading or a figure paragraph. Dump the paragraph
index map before editing and re-verify structure after.

**Three traps.** Day 0 is the midpoint of two DFO date fields, not an observed
onset, and the manuscript does not yet say so. The author's comments stop part
way through Section 2.2, so nothing after that has been through his review.
And he will tell you when prose reads as AI-generated, so read section 9 of the
style guide before writing a word.

Ask him about anything in `OPEN_QUESTIONS.md`. In particular, the question of
using spawn biomass as an exposure variable is explicitly deferred; do not act
on it.
