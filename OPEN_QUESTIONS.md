# OPEN_QUESTIONS — items requiring author judgement

Everything here needs a decision the diagnostics cannot make, a place where a
diagnostic conflicts with a manuscript claim, or a structural change the plan
says to propose rather than execute. The frozen specification, the species-roles
registry, and the earlier registered analysis outputs are untouched.

**Update (edits applied).** With author authorization, the diagnostic-vs-claim
wording changes A1 (same-day to contemporaneous), A2 (dabbler roe-pathway
softening), and A3 (nominated-user rewording) have now been applied to the
manuscript, and the section E1 restructuring (Limitations folded into the
Discussion, Conclusions cut) has been executed. See `CHANGES.md`. The items that
still require an author decision are B1, B2, and C1 below.

## A. Diagnostic conflicts with a current manuscript claim

**A1. "Same-day reference checklists" is not what the design matches.** The
manuscript says the reference checklists are "same-day" in three places (abstract,
Methods 2.5, Discussion 4.1). The design matches references to the same
**event-relative period**, not the same calendar day, and D1 shows calendar date
was not carried into the frozen frame, so same-calendar-day matching can be
neither enforced nor checked. A within-checklist reading gives the phrase partial
cover (a single checklist's near and reference links are trivially same-day), but
the estimated contrast is a population regression coefficient across checklists.
Recommended: replace "same-day" with "contemporaneous in event time" or
"matched to the same event-relative period." **This is a wording change against a
diagnostic finding, so it is flagged, not made.**

**A2. Dabbling ducks described as having "no roe-feeding pathway."** Discussion
4.1 and 4.3 frame the dabbling ducks and geese as taxa "with no roe-feeding
pathway." The registry assigns Mallard, American Wigeon, and Northern Pintail to
a `surface_vegetation_roe` guild, i.e. a hypothesised weak surface- and
vegetation-associated roe-use pathway (D9). They are not mechanism-free. This
weakens, but does not remove, the point that dabbler responses are hard to
attribute to herring. Recommended: soften to "no strong or established direct
roe-feeding pathway" and acknowledge the weak hypothesised guild. Flagged, not
made.

**A3. "Nominated herring user" comparison in 4.3/4.1.** The abstract and 4.1 say
Northern Pintail's detection interaction "exceeded that of every nominated herring
user." Under the registry, Northern Pintail itself sits in a roe guild, so it is
arguably a (weak) nominated user, which makes the sentence slightly circular.
Recommended rewording to compare against the eleven text-panel species
explicitly. Flagged.

## B. Reporting-standard decisions

**B1. Which BH family for the "four of five dabbling ducks" claim (D8).**
Northern Shoveler's reported active-detection q (0.0056) is correct for its
2-species comparator family. Adjusted inside the 49-species core family it is
0.0115, still significant. The author should choose one framing and state it:
either (a) report Shoveler's core-family q (0.0115) so all five are on one
standard, or (b) present four core species plus a separately adjusted comparator
and say so. Both are defensible; the manuscript currently pools them without
saying which standard applies. This is Phase 3 item 14.

**B2. Registration identifier is missing (Phase 3 item 2).** The manuscript
invokes "an earlier registered analysis" (Methods 2.1, 2.4; Code Availability) but
gives no registration ID, DOI, or repository link, and none was found in the repo.
If a public registration exists, supply it at each invocation. If the "registered"
status refers only to the in-repo frozen Stage 4A locks and hashes rather than a
public registry, the word "registered" should be qualified accordingly (e.g.
"pre-committed and hash-locked"). Author input required.

## C. Specification judgements (author only; do not cross the frozen boundary)

**C1. Date and time fields (D1, D2).** Calendar day-of-year and checklist start
time were not carried into the frozen frame, so date balance cannot be shown and
time of day (a standard eBird detection covariate) cannot be added. Re-deriving
the frame from raw EBD to obtain these is a specification action outside the
frozen boundary and outside this task. Decision for the author: either state the
limitation plainly and defer both to the prospective confirmation, or authorise a
frame re-derivation (a new specification, not a hardening edit).

## D. Phase 2 sensitivity refits (GATED — awaiting confirmation)

Each is a labelled sensitivity that would sit alongside the primary result, never
replacing it. Do not start without explicit confirmation. Recommended relevance
from Phase 1:

- **S1 (calendar + diel covariates):** cannot be run as specified. Day-of-year
  and start time are absent (D1, D2). Would require a frame re-derivation (C1).
  Author must decide the spline df in any case.
- **S2 (nAGQ = 1 detection refit):** relevant. Intervals are Wald z on the
  nAGQ = 0 covariance (D10), and the largest detection effects are on rare gulls
  (D5: American Herring Gull 0.9% prevalence, Iceland 2.2%), exactly where
  nAGQ = 0 can bias fixed effects. This is the highest-value refit.
- **S3 (count distribution check + NB sensitivity):** relevant. The count model
  is Gaussian on log positive counts; the mass at small counts is a standard
  reviewer objection, and D3 shows the numeric subset is itself selected. QQ and
  residual diagnostics plus a negative-binomial sensitivity for the panel are
  worthwhile.
- **S4 (single-event restriction):** relevant but lower stakes. D4 shows only
  5.5% of exposed checklists span baseline and active via different events and
  collinearity is negligible (max VIF 1.26), so the non-exclusivity S4 targets is
  modest. Still a clean robustness check.

## E. Structural proposal (Phase 4; propose, do not execute)

**E1. Fold Limitations (section 5) into the Discussion and cut Conclusions
(section 6).** Section 5 substantially restates Discussion 4.1 and 4.3 (the
non-causal limitation and the residual-confounder list), and section 6 restates
the abstract almost point for point. Proposal: move the three or four limitation
points that are not already in the Discussion into a single "Limitations"
subsection at the end of the Discussion, and cut Conclusions to four or five
sentences that state what the paper adds beyond the abstract (the migration-
adjusted spatial contrast; the flock-size-over-detection asymmetry; the dabbling-
duck ceiling on trophic attribution). This is a section-level change, so it is
proposed here for approval rather than executed.

## F. Prose and caveat consolidation (Phase 4; queued, not yet applied)

Recorded for when Phase 3/4 is authorised (these are edits, not open questions,
listed so nothing is lost):

- Caveat repetition: the non-causal limitation appears in the abstract, 2.5, 4.1
  (twice), 4.3, 5, and 6; the residual-confounder list appears in five variants.
  Define the confounder set once, name it, refer back. Target: once in Methods as
  a design assumption, once in Discussion as what it means here.
- Line edits from the review (remove bold in 1 and 2.4; retitle 3.5 to
  "Contrasting response profiles" and drop its circular closing sentence; rewrite
  the 4.5 "right instinct executed at too small a scale" sentence; change "which
  falsifies our third prediction" to "was not supported"; change the 4.3 "upper
  bound" language to "limits" unless a formal comparison is computed; "Gadwall was
  the exception rather than the rule" to "Gadwall was the only exception"; "earns
  its place as a diagnostic" to "functions as a diagnostic"; move the code-halt and
  fixture-tested repository facts to Code Availability).
- Sole-author "we" against the single-name contributions block: MER permits "we"
  for sole authors; flagged for author confirmation, not changed.

## G. Phase 3 additions supported by Phase 1 (queued)

Numbers are ready; insertion awaits Phase 3 authorisation.

- Abstract sentence stating the post-result exploratory status (2.1 already says
  it).
- Table 2 as a real table (D11).
- Taxonomy version and state rules paragraph, plus a supplementary state table
  (D7): eBird Taxonomy v2025; `count_type` states numeric / X / ambiguity_affected.
- CI method sentence (D10) and an nAGQ = 0 caveat (informed by S2 if run).
- 3.1 clarification that the 46 estimable count models include the singular
  Western Gull fit; remove the sample-size sentence duplicated from 2.1.
- Headline support figures (D5).
- Suppression-rule explanation (threshold 20 checklist years).
- Boundary-misclassification sentence with dilution direction (D6).
- Quantification-selection caveat in 4.2 (D3).
- Cell non-exclusivity number in 2.3 (D4: 5,163 checklists; max VIF 1.26).
