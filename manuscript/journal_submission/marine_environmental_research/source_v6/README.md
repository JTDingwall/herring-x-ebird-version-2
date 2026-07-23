# Marine Environmental Research manuscript v6 status

Version 6 is intentionally gated on the complete Strait of Georgia event-study
output family. Do not copy the historical M05 timing coefficients into the new
event-study sections and do not render a submission manuscript with placeholder
results.

After the production analysis reaches
`PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW`:

1. Run `scripts/build_mer_v6_event_study_assets.py`.
2. Review every model failure, singular warning, main-panel interval, and the two
   specificity-comparator families.
3. Revise the v5 abstract, Methods timing section, Results timing section,
   Discussion migration section, main species table, and Figures 3-4.
4. Keep the complete historical M05 and M08 results in the supplement, labeled
   as the registered Stage 4A analyses.
5. Describe the new model as a post-results, ecologically motivated refinement.
6. Render the DOCX and inspect every page before release.

The v6 front-facing interpretation should use:

- the 0-14 day duration-weighted difference-in-differences as the primary active
  contrast;
- the -7 to -1, 0 to 3, 4 to 14, and 15 to 28 day contrasts for timing;
- all 11 main ecological species;
- Gadwall and Northern Shoveler only as supplementary specificity comparators.

No v6 result claim is valid until the complete output family has run.
