# Handoff: MER manuscript, Claude session 26 July 2026

You are picking up a manuscript in late revision for Marine Environmental
Research. The science is done and verified. What remains is mostly writing, plus
one outstanding analysis and one production task.

## Read in this order

1. **`PROJECT_STATE.md`** — what the paper is, what the analysis does, what has
   been verified, what constraints apply. Fifteen minutes.
2. **`AUTHOR_EDITS_v27.md`** — the author's 25 comments and 78 tracked changes
   on the current draft. This is the most important document here.
3. **`WRITING_STYLE.md`** — the voice. Section 9 is derived from the author's own
   edits and outranks the rest.
4. **`NEXT_ACTIONS.md`** — the work queue.

Then `OPEN_QUESTIONS.md` for decisions only the author can make.

## Three things that will save you from the obvious mistakes

**Day 0 is not an observed onset.** It is the midpoint of two DFO date fields.
The manuscript does not yet say so. See `PROJECT_STATE.md` section 3.

**The 49-species family is fixed and must not be trimmed.** Removing
low-support taxa after seeing results was proposed once and rejected: a
top-25-by-prevalence cut would have deleted 12 of the 31 significant results
including all three headline gull ratios.

**Verify every number you write.** There is an automated check described at the
end of `NEXT_ACTIONS.md`. It has caught two real rounding errors that survived
manual reading. Run it after every build.

## Where the files are

Manuscript builds have lived in a Claude session scratch directory, not in this
repository. Current copies are in `manuscript/` beside this README:

- `mer_manuscript_v27.docx` — current draft, **with the author's tracked changes
  and comments**
- `mer_supplementary_material_v27.docx` — nine tables, three figures

Analysis outputs are all in the repository under `outputs/`. See
`PROJECT_STATE.md` section 6 for what each directory contains.

`reviews/` holds the substantive reviews written during this session.
`prompts/` holds ready-to-run commission prompts for analysis agents.

## How the manuscript gets built

Each version is produced by a Python script using `python-docx`, rebuilding from
the previous `.docx` so that images, OMML equations, styles, page numbering and
continuous line numbering survive. Text is replaced paragraph by paragraph by
index, which is fast but brittle: several bugs in this project came from
off-by-one indices overwriting a heading or a figure. Always re-verify structure
after a build.

Scripts are named `build_vNN.py` and live in the Claude session outputs
directory. They are not in this repository. If you do not have them, rebuild
from `mer_manuscript_v27.docx` directly.

## What the author cares about

Concise and direct. No em dashes. Must not read like AI writing, and the author
will tell you when it does. Effort belongs in the Results and the ecological
Discussion, not in Methods. A reader of this journal wants to know what the
birds did.
