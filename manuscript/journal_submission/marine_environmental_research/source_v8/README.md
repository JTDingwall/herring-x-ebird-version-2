# Marine Environmental Research manuscript v8

Version 8 is an ecology-focused revision of v7 prepared from the existing
manuscript, tables, and released privacy-safe aggregate outputs. No model was
rerun, and no coefficient, confidence interval, p-value, q-value, sample size,
or diagnostic result was estimated for this revision.

The revision:

- makes the complete 49-species family the primary inferential set;
- defines the estimand as a baseline-adjusted near/reference contrast of
  additive event-link slopes;
- uses `checklist reporting` and `conditional positive numeric count` as the
  response names;
- treats the timing pattern as descriptive pending direct active-minus-pre
  contrasts;
- narrows causal and migration claims to match the observational design;
- treats unquantified `X` reports as a potentially informative third
  observation process; and
- separates missing analyses and author inputs from completed results.

## Files

- `mer_manuscript_unblinded_v8.qmd`: clean revised manuscript source;
- `mer_references_v8.bib`: reference library retained from v7;
- `mer_v8_times_new_roman_reference.docx`: Word style reference;
- `mer_v8_print.css`: print stylesheet;
- `revision_memo_v8.md`: major changes and section-level change log; and
- `outstanding_analyses_and_author_inputs_v8.md`: prioritized remaining work.

Rendered Word documents are in `../rendered_v8/`. Figures, tables, and the
aggregate result handoff can be regenerated from the released aggregate
outputs with:

```bash
python scripts/build_mer_v8_event_study_assets.py
```

True Word tracked changes were not preserved. The clean manuscript is
accompanied by the section-level change log in the revision memo.
