# CHANGES — MER v7 pre-submission hardening

Every manuscript edit below, with the check ID or review item that motivated it.
Edits are in place on `mer_manuscript_unblinded_v7.qmd` and
`mer_supplement_v7.qmd`; the git diff on branch
`codex/mer-v7-presubmission-hardening` is the clean record. **No model was
refitted and no primary estimate changed.** Every number added or altered was
verified against the frozen `effect_estimates_v1.csv` (Table 2: 26 rows, 0
mismatches; all inline additions confirmed).

## Phase 3 — reporting additions

| # | Section | Edit | Source |
|---|---|---|---|
| 1 | Abstract | Added "In a post-result refinement of an earlier registered analysis" to state exploratory status | item 1 |
| 2 | Methods 2.1, Code availability | Qualified "registered" as "pre-committed and hash-locked" and added `[AUTHOR TO SUPPLY registration identifier or repository DOI]`; no public registration exists in the repo | item 2 / B2 |
| 3 | Results 3.3 | Inserted the materialised Table 2 (26 rows: all BH-significant negatives and off-panel positives) in place of a caption pointing at a CSV | item 3 / D11 |
| 4 | Methods 2.1, 2.2; Supplement | Added taxonomy version (eBird/Clements v2025), the three split-affected gulls, the versioned concept mapping, and the count-state table (numeric / X / ambiguity_affected) | item 4 / D7 |
| 5 | Methods 2.4 | Stated the CI method (Wald z on the link scale, exponentiated) and an `nAGQ = 0` caveat with the mitigating support figures | item 5 / D10 |
| 6 | Results 3.1 | Clarified that the 46 estimable count models include the singular Western Gull fit | item 6 |
| 7 | Results 3.1 | Removed the frame-size sentence duplicated verbatim from Methods 2.1 | item 7 |
| 8 | Results 3.3 | Added in-text support for the three headline species (1,957 / 4,763 / 3,070 detections) | item 8 / D5 |
| 9 | Methods 2.6 | Explained the 20-checklist-year suppression threshold and its eBird data-use rationale | item 9 |
| 10 | Methods 2.3 | Added the travelling-checklist boundary sentence with the dilution direction (12% travel >2.5 km, 3% >4 km) | item 10 / D6 |
| 11 | Discussion 4.2 | Added the unquantified-`X` quantification-selection caveat (Iceland Gull ~10% to ~18%), concluding the count ratios are conservative | item 11 / D3 |
| 12 | Methods 2.3 | Added the multi-cell occupancy result (5,163 checklists span baseline and active) and the VIF range (1.22–1.26) | item 12 / D4 |
| 13 | Abstract, Discussion 4.1, 4.3 | Reworded "nominated herring user" comparisons to compare against the discussed panel | item 13 / A3 |
| 14 | Results 3.3, Discussion 4.5 | Clarified "the five support-qualified dabbling ducks" and Shoveler's cross-family standing | item 14 / D8, D9 |
| 15 | Discussion (Limitations) | Stated that date and start-time balance cannot be shown because those fields are absent from the frozen frame | item 15 / D1, D2 |
| — | Discussion (Limitations) | Added the S4 and S3 sensitivity results and noted the S2/NB refits deferred to the revision environment | Phase 2 |

## Phase 4 — prose and line edits

| Section | Edit | Motivation |
|---|---|---|
| Intro 1, Methods 2.4 | Removed bold from the research question and the "not the set of largest effects" sentence | Elsevier strips bold; reads as raised voice |
| Results 3.5 | Retitled "Five species selected to span contrasting predictions" to "Contrasting response profiles"; deleted the circular closing sentence | Phase 4 |
| Discussion 4.5 | Replaced "the comparator design was the right instinct executed at too small a scale" with a statement about bounding the false-positive rate | Phase 4 |
| Results 3.6 | "which falsifies our third prediction" to "which our third prediction did not anticipate" | Phase 4 (a q-value threshold is not falsification) |
| Discussion 4.3 | "sets an upper bound on how much ... trophic ecology can carry" to "limits how much ..." | Phase 4 (not a formal bound) |
| Results 3.3 | "Gadwall was the exception rather than the rule" to "Gadwall was the only exception" | Phase 4 |
| Discussion 4.1 | "The baseline comparison earns its place as a diagnostic" to "functions as a diagnostic" | Phase 4 |
| Intro 1 | Sharpened the soft closer "conspicuousness does not make the community response simple" | Phase 4 |
| Methods 2.4, Code availability | Moved the panel-gate and fixture-testing repository facts to Code Availability | Phase 4 |
| Methods 2.5; throughout | Defined the residual-confounder set once as "zone-differential confounders" and refer back, instead of restating the list | Phase 4 (caveat consolidation) |
| Abstract, Methods, Discussion, Conclusions | "same-day" reference checklists to "contemporaneous / same event-relative period" | A1 (design matches event-relative period, not calendar day; D1 shows calendar date is absent) |
| Results 3.3, Discussion | Softened "no roe-feeding pathway" to "no strong or established direct pathway; weak surface/vegetation roe guild" | A2 (registry assigns the core dabblers a `surface_vegetation_roe` guild) |

## Phase 4 — structural (E1)

- Folded the former top-level "Limitations and future directions" into the
  Discussion as its final subsection (`## Limitations and future directions`),
  and removed its opening paragraph, which duplicated Methods 2.1.
- Cut Conclusions from two paragraphs to a single tight paragraph that states
  what the paper adds beyond the abstract: the value of the contemporaneous
  baseline-subtracted contrast, the flock-size-over-detection asymmetry, the
  post-onset concentration, and the dabbling-duck ceiling on trophic attribution.
- Result: sections renumber to 1 Introduction … 4 Discussion, 5 Conclusions, 6
  Data availability, verified in the rendered DOCX.

## Phase 5 — submission mechanics

- **Abstract** 250 words (cap 250) after the Phase 3 addition; **7 keywords**;
  **5 Highlights** all <= 85 characters (unchanged, still valid).
- **References**: every in-text citation resolves to a reference and every
  reference is cited (0 orphans). The four difference-in-differences references
  added in the v7 PR were verified against Crossref and match the bib exactly
  (butsic2017 Basic Appl. Ecol. 19:1-10; larsen2019 Methods Ecol. Evol.
  10(7):924-934; wing2018 Annu. Rev. Public Health 39:453-469; roth2023 J.
  Econom. 235(2):2218-2244).
- **Figures** 1-3 are 500 dpi PNG in Times New Roman; the forest plots are
  single-hue and the timing heat map uses a red-blue diverging scale.
- **Placeholders** remaining (author-supply by design): postal address,
  telephone, funding, generative-AI disclosure, additional acknowledgments, and
  the new registration-identifier placeholder.
- **Author guidelines** checked against the repo capture
  `journal_requirements_2026-07-22.md` (structure, abstract <= 250, 1-7 keywords,
  numbered sections with unnumbered abstract, Highlights, data statement, CRediT,
  declarations) — all satisfied.

## Rendering and verification

- Manuscript and supplement re-rendered to DOCX and HTML. All 25 DOCX styles are
  Times New Roman; no non-Times font appears in the body. Section headings
  renumber correctly. No LaTeX span is mangled (the `1.78 × 10⁻¹⁵` and `4/15`
  spans render cleanly).
- `RECONCILIATION.md` and `sensitivity/`, `diagnostics/` remain the evidence
  base; `OPEN_QUESTIONS.md` records the items that still need author judgement,
  including the registration identifier (B2), the Shoveler BH-family reporting
  choice (B1), and whether to re-derive the frame with date/time fields (C1).
