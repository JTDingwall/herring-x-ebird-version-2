# Marine Environmental Research submission compliance checklist

Assessed file: `mer_manuscript_v15.docx`
Companion file: `mer_highlights_v15.docx`
Date: 24 July 2026 (revised through v15)

## How these requirements were established

The official guide at
`https://www.sciencedirect.com/journal/marine-environmental-research/publish/guide-for-authors`
is a client-rendered page; direct fetching returned an empty document shell, and
browser rendering was unavailable in this session. Requirements below therefore
come from three sources, and each row records which one applies:

- **[live]**, confirmed from the current published guide text retrieved via
  search on 24 July 2026 (abstract limit, keyword range, highlights format).
- **[capture]**, from the repository's own capture of the guide,
  `manuscript/journal_submission/marine_environmental_research/journal_requirements_2026-07-22.md`,
  dated 22 July 2026, two days before this review.
- **[Elsevier general]**, Elsevier house requirements that apply across the
  portfolio and were confirmed independently.

**One correction to the capture.** The repository capture states that MER uses
numbered citations in square brackets with a citation-ordered reference list.
That is wrong. MER uses author–year (Harvard) style, confirmed both by
independent search and by the author's own recent MER manuscript
(`Dingwall et al. Main Text_MER_Revised_Version_2026_03_17_JD.docx`), which uses
author–year throughout with an alphabetical list. The manuscript's existing
author–year style is correct and was retained. Before submission the author
should re-read the live guide directly, since one demonstrable error in the
capture means the rest of it should not be trusted blindly.

## Checklist

| # | Requirement | Source | Status | Note |
|---|---|---|---|---|
| 1 | Within journal scope | capture | **Pass** | Coastal marine ecology, forage-fish/predator interactions, BC nearshore. Squarely in scope. |
| 2 | Article type: Full-length Article | capture | **Pass** | Original research with detailed methods and comprehensive results. |
| 3 | Length 5,000–10,000 words | capture | **Pass** | 8,326 words, title through Acknowledgements. |
| 4 | No more than 50 references | capture | **Pass** | 32. |
| 5 | Editable Word source, single column | capture | **Pass** | `.docx`, single column, 1-inch margins, Letter page size. |
| 6 | Concise, informative title, no abbreviations or formulae | capture | **Pass** | 19 words; no abbreviations. Names the taxa, the resource and the data source. Note that "responses" is a slightly stronger verb than the paper's own hedging, so the abstract's first result sentence carries the load of preventing an abundance reading. |
| 7 | Abstract ≤250 words, factual, standalone, unstructured | live | **Pass** | 241 words. Version 12 was 256 and would have failed. No references, no uncommon abbreviations; *Clupea pallasii* defined at first use. |
| 8 | 1–7 keywords, English | live | **Pass** | 7: Pacific herring; eBird; community science; resource pulse; coastal birds; checklist reporting; reported counts. None uses "and" or "of". Note that "eBird" and "Pacific herring" now duplicate title words and buy nothing extra in indexing; swapping them for terms not in the title would widen reach. |
| 9 | Consecutively numbered sections and subsections; abstract unnumbered | capture | **Pass** | Abstract unnumbered; 1 Introduction … 5 Conclusion with 2.1–2.6, 3.1–3.6, 4.1–4.5. |
| 10 | Acknowledgements in a separate section directly before the references | capture | **Pass** | Restructured in v13. In v12 it was section 9 followed directly by References, which also passed, but the back matter is now unnumbered to match journal convention and the author's own recent MER manuscript. |
| 11 | Page numbers | capture / review convenience | **Pass** | Page-number footer inherited from v12. |
| 12 | Continuous line numbering | capture / review convenience | **Pass** | `lnNumType countBy="1" restart="continuous"` present. Note: the capture records that MER states no line-numbering mandate; it is supplied for reviewer convenience. |
| 13 | Figures cited and numbered in sequence | capture | **Pass** | Figures 1–3, cited in order in §2.3, §3.2 and §3.3. |
| 14 | Each figure supplied as a separate, logically named file with a caption | capture | **Author input required** | The three figures are embedded in the Word file, which is correct for the review copy. Separate uploads are still needed at submission. Extracted at 1734×1492, 2348×2704 and 2970×1858 px respectively for Figures 1, 2 and 3. |
| 15 | Raster figure resolution: combination art ≥500 dpi, ≥1772 px single column, ≥3740 px full page | capture / Elsevier general | **Fail (production)** | Figure 1 is 1734 px wide, just under the 1772 px single-column threshold. Figures 2 and 3 exceed the single-column threshold but fall short of the 3740 px full-page threshold, and neither can be reduced to single-column width and stay legible: Figure 2 is a 49-row two-panel forest plot and Figure 3 is a 2×4 panel grid. Regenerate all three at full-page width and ≥500 dpi, or supply vector PDF/EPS, which the guide accepts and which sidesteps the pixel thresholds entirely. |
| 16 | Colour figures understandable to readers with colour-vision impairment | capture | **Pass** | Restrained blue/orange palette. Redundant encodings throughout: Figure 2 separates the two outcomes into labelled panels and uses filled versus open markers for significance; Figure 3 uses dashed lines with open squares against solid lines with filled circles. All three read correctly in greyscale. |
| 17 | Figure captions supplied and self-contained | capture | **Pass** | All three captions define the estimand, the reference period and the interpretive limit. Figures 2 and 3 now cross-reference each other's differing reference points, which was the main legibility defect in v12. |
| 18 | Tables editable, numbered, cited | capture | **Not applicable** | No tables. The guide sets no minimum and advises using tables sparingly. |
| 19 | Author–year in-text citations, consistently applied | live (see correction above) | **Pass** | Author–year throughout; alphabetical reference list. One ordering correction made (Lok 2008 now precedes Lok 2012). |
| 20 | Complete reference metadata; DOIs recommended | capture | **Pass** | All 32 entries carry a DOI or a stable publisher/agency URL. The four added references (Larsen 2019, Wing 2018, Bishop and Green 2001, Clements et al. 2025) were verified independently before insertion. |
| 21 | Every citation resolves to a reference and every reference is cited | Elsevier general | **Pass** | Checked. No orphans in either direction. |
| 22 | Data availability statement | capture | **Author input required** | Statement present, names both sources and their release versions, and explains why record-level eBird data cannot be redistributed (Option C: explain why sharing is not possible for part). Repository DOI is a placeholder. |
| 23 | Code availability wording | capture | **Author input required** | Section present. Repository DOI is a placeholder, and a second placeholder asks the author to confirm that the archived release contains the active-minus-pre-onset contrast outputs, the standardized predictions and the nearest-event sensitivity output. See the review, issue 1: currently the article's headline intervals cannot be checked against the archive. |
| 24 | CRediT authorship contribution statement | capture | **Pass** | Own heading; ten roles listed for the sole author. |
| 25 | Funding disclosure, including sponsor role | capture | **Author input required** | Placeholder. If there was no funding, the journal's standard no-funding sentence is required rather than silence. |
| 26 | Competing-interest declaration | capture | **Pass (form still required)** | Standard Elsevier wording present in the manuscript. The declarations tool output must still be completed and uploaded separately at submission. |
| 27 | Ethics / permits declaration | capture | **Pass** | Accurate: existing biodiversity and fisheries-monitoring records, no animal handling. |
| 28 | Generative-AI declaration, placed before the references, after human review | capture | **Author input required** | Section present, positioned correctly. The placeholder specifies what a compliant declaration must contain: each tool, its version, the purpose, and the statement that the author reviewed and edited the output and takes full responsibility. Given that the author's recent MER manuscript carries such a declaration and that this manuscript was prepared with AI assistance, an accurate declaration is mandatory, not optional. |
| 29 | Title-page information: names, affiliations with full postal address and country, corresponding author with current contact details | capture | **Author input required** | Name, institution, country, email and ORCID present. Full postal address and telephone are placeholders. |
| 30 | Highlights: separate editable file, 3–5 bullets, ≤85 characters each including spaces | live | **Pass** | `mer_highlights_v13.docx`; 5 bullets; longest 78 characters. File name contains "highlights". |
| 31 | Graphical abstract | capture | **Not applicable** | Encouraged, not required. Not supplied. |
| 32 | Supplementary material cited and captioned | capture | **Not applicable** | None supplied. The article is deliberately standalone. See recommendation below. |
| 33 | Cover letter | capture | **Author input required** | No journal-specific mandatory content, but one should accompany the submission. It should state the post-result exploratory status of the refinement explicitly, so that the editor is not left to discover it in §2.1. |
| 34 | Single anonymized review; author identity remains in the manuscript | capture | **Pass** | Unblinded manuscript is correct for this journal. |
| 35 | Confirmation of originality, exclusive submission, approval to submit, preprint status | capture | **Author input required** | Handled in the submission system, not the manuscript. |
| 36 | No bold or coloured text in the manuscript body | author preference | **Pass** | 0 bold runs; every run set to explicit black. |
| 37 | No internal labels, workflow codes, hashes, fixtures or repository shorthand | author preference | **Pass** | Checked programmatically. None found. |

## Summary

- Pass: 21
- Author input required: 9
- Fail: 1 (figure raster dimensions, item 15, a production issue, not a scientific one)
- Not applicable: 4

Nothing on this list blocks submission except item 15, which is resolved by
re-exporting the three figures at full-page width or as vector PDF, and the nine
author-input items, none of which requires judgement beyond the author's own
records.

## Two recommendations that go slightly beyond compliance

**Add a supplementary table of all 49 species × 2 outcomes** for the primary
contrast, with estimate, 95% CI and q-value. The journal sets no table limit and
the manuscript's three-figure, no-main-table structure is worth preserving, so
this belongs in the supplement rather than the main text. Without it, a reader
who wants a number for any species other than the six quoted has to read it off a
forest plot or open the repository, which sits awkwardly against the manuscript's
own claim to be standalone.

**Re-read the live guide before submission.** The repository capture used during
the version 7 hardening contains at least one demonstrable error (citation
style). The items marked [capture] above should be re-confirmed against the
current page, particularly the length range, the reference limit and the figure
resolution classes.
