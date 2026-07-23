# D1 and D2 — Calendar-date and start-time balance (NOT COMPUTABLE)

Both checks require record-level fields that are absent from the frozen protected
frame.

- **D1 (day-of-year balance):** `stage4a_event_metadata` carries `checklist_year`
  but no calendar date. The link table carries `event_day`, which is event-
  relative (days from spawn onset), not a calendar day-of-year. No available file
  carries a calendar date.
- **D2 (start-time balance):** no checklist start-time field exists in any
  protected input.

Raw EBD, which holds both fields, is not in the repository (`data/raw/` contains
only a README) and is outside the frozen-spec boundary. These diagnostics cannot
be run without re-deriving the analysis frame from raw EBD, which is a
specification action, not a read-only diagnostic.

Consequence for the manuscript: the "same-day reference checklists" property is a
construction property of the link table (references are matched in event-relative
period), not a modelled control, and it **cannot be demonstrated empirically**
from the frozen frame. Likewise, time of day (a standard eBird detection
covariate, Johnston et al. 2018, 2021) cannot be balance-checked or added without
leaving the frozen boundary. This is a genuine limitation and is routed to
`OPEN_QUESTIONS.md`; whether to re-derive the frame with these fields is a
specification judgement, which is the author's to make.

## What can be said instead

The manuscript should not claim date or time balance it cannot show. The accurate
statement is that references are contemporaneous by construction in event-relative
period, that calendar day-of-year and start time were not carried into the frozen
frame, and that a prospective confirmation should retain both so the balance can
be tested and time of day can enter the detection model.
