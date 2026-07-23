# Marine Environmental Research manuscript v7

Version 7 revises v6 in response to an editorial and reviewer-style read of the
v6 draft. It is the same Strait of Georgia, post-result ecological refinement of
the same executed analysis: **no model was refitted and no estimate changed.**
Every number in v7 was verified against
`outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv`.

Files:

- `mer_manuscript_unblinded_v7.qmd`: main manuscript;
- `mer_supplement_v7.qmd`: complete-family status, family extremes, specificity,
  failures, and the immutable historical inventory;
- `mer_highlights_v7.qmd`: journal-required Highlights (5 bullets, all ≤85
  characters);
- `mer_references_v7.bib`: reference library;
- `mer_v7_times_new_roman_reference.docx`: Word style reference enforcing Times
  New Roman;
- `mer_v7_print.css`: print stylesheet applying Times New Roman to HTML/PDF.

Figures and tables are rebuilt by `scripts/build_mer_v7_event_study_assets.py`
into `figures_v7/`, `tables_v7/`, and `generated_v7/`.

## Substantive changes from v6

1. **Species-panel transparency.** v6 discussed 11 species and, in doing so,
   omitted the three largest interactions in the family (American Herring Gull
   1.49, Iceland Gull 1.43 detection; Long-tailed Duck 1.49 count) and five of
   the six BH-significant negative detection results. v7 states that the panel
   was fixed before execution and is not the set of largest effects, adds a
   Results subsection and Table 2 reporting the extremes, and adds Figure 2
   showing all 49 species with the 11 marked.
2. **All negative results named.** v6 reported "six were negative" and named
   only Common Raven, the smallest. v7 names all six.
3. **Gull guild contradiction resolved.** Ring-billed Gull declined in both
   components while four other gulls rose; v7 says so and explains why a
   guild-level mechanism cannot accommodate it.
4. **Figure 3 (timing) now matches its caption.** The v6 timing figure plotted
   `did_pre_7_day` (−7 to −1 d) under a caption naming the 14-day pre-spawn
   summary, and the v6 Results text reported `did_pre_14_day` counts. v7 plots
   `did_pre_14_day`, and reports the immediate pre-spawn counts separately in
   the text and in Table S2.
5. **Figure 1 now draws the asterisks its caption promises.** The v6 forest plot
   never marked BH significance.
6. **Baseline vs pre-spawn terminology.** v6 called the −28 to −15 d baseline
   "the pre-spawn baseline" in the Figure 1 title and the Conclusions, colliding
   with its own definition of pre-spawn as −14 to −1 d. Fixed throughout.
7. **Falsified prediction stated as such.** Northern Shoveler's positive
   interaction falsified prediction three; v7 says so in the Introduction,
   Results, Discussion, and Conclusions instead of hedging around it.
8. **Symmetric inference.** White-winged Scoter's consistently negative
   detection trend, American Crow's late-egg 0.94 (0.90–0.99), and Common
   Raven's baseline count 0.98 (0.96–0.99) are now reported rather than
   described as "near one."
9. **Audit apparatus moved out of the argument.** Hash gates, BH reproduction to
   1.78 × 10⁻¹⁵, and the internal "pass with qualifications" gate language are
   in the supplement, not the Methods and Results.
10. **Length and redundancy.** Discussion cut from 31 to 15 paragraphs,
    Limitations from 9 to 4, Introduction from 12 to 7. Body text is ~6,700
    words, within the 5,000–10,000 range.
11. **Overclaiming.** "These totals reject a universal community increase"
    became "inconsistent with a community-wide increase"; the Abstract's
    "demonstrating" became "showing"; Figure 1's title no longer asserts a
    "bird response."
12. **Methodological citations added** for the difference-in-differences design
    (see verification note below).

## Journal-compliance fixes

| Item | v6 | v7 |
|---|---|---|
| Abstract length | 262 words | 249 (cap 250) |
| Keywords | 8 | 7 (cap 7) |
| Abstract numbering | numbered "1. Abstract" | unnumbered, per the guide |
| Highlights | absent for v6; v2/v3 files described the superseded two-region analysis | `mer_highlights_v7.qmd`, 5 bullets ≤85 chars |
| LaTeX in DOCX | rendered as `(1.78^{-15})` and `((4/15))` | plain text, verified in the rendered file |
| Supplementary citation | "the supplement", no file cited | Tables S1–S3 cited by number |
| Duplicate table number | two different `Table_4_*` files | single Table 1, 2, S1, S2, S3 series |
| Figure resolution | 400 dpi | 500 dpi |
| Figure/table sequence | — | verified cited in numerical order |

## Author action still required

- `[AUTHOR TO SUPPLY]` placeholders remain for the full postal address,
  corresponding-author telephone, funding statement, and the generative-AI
  declaration. These are author-supplied by design.
- **Verify the four added references before submission.** `butsic2017`,
  `larsen2019`, `wing2018`, and `roth2023` were added to support the
  difference-in-differences design, which v6 used but never cited. Confirm the
  volume, page, and DOI fields against the publisher records.
- The species panel is now disclosed rather than justified by a quantitative
  rule. If a reviewer presses on selection, the strongest available answer is
  that the panel was fixed before execution and that Figure 2 shows the full
  family; consider whether to drop the panel framing entirely at revision.
