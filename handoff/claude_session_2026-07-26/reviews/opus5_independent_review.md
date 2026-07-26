# Independent scientific and editorial review

Manuscript reviewed: `mer_manuscript_unblinded_v12_clean.docx`
Target journal: Marine Environmental Research (Elsevier), Full-length Article
Repository inspected: `JTDingwall/herring-x-ebird-version-2` at commit
`1186d8eaaa29fba3a97da85c7a38298190592f05`
Style reference: `Dingwall et al. Main Text_MER_Revised_Version_2026_03_17_JD.docx`
Date of review: 24 July 2026

## Provenance note before anything else

The attached version 12 manuscript is treated as the article under review and as
the source of truth for its own numbers. The repository at the pinned commit is
one analytical version behind it: `REPO_MAP.md`, `CHANGES.md` and
`RECONCILIATION.md` at that commit all describe a version 7 manuscript source
(`manuscript/journal_submission/marine_environmental_research/source_v7/`). I did
not substitute any repository-rendered text for the attached manuscript, and I
did not mix version 7 and version 12 numbers.

What I could verify at that commit, and what I could not, is set out under issue
1 below and in the revision memo. Nothing in the repository indicated a
reproducibility error in the attached manuscript. Every number I was able to
recompute agreed with it.

## Overall editorial verdict

**Minor revision.**

This is a real paper with a real result, carefully bounded, and it belongs in
Marine Environmental Research. No new fieldwork, no new dataset, no redesign and
no change of estimand is required.

A note on how this verdict moved. My first pass said major revision, on the
strength of issues 1 and 2 below. That was the wrong standard. This brief asked
me to audit the manuscript against its own repository as well as to read it as an
editor, and a repository audit is far harsher than peer review. Issue 1 is a
reproducibility gap that most referees will never encounter, because most
referees do not open the archive. Issue 2 needs a statistically-minded referee to
be assigned and to care, and it does not touch the paper's central claim. Neither
should carry an editorial verdict on its own.

What remains before submission is one wording decision only the author can make
(issue 5), ten placeholder fills, and a figure export. The two computational items
are better handled if and when a referee asks for them, with the request in hand.

## The five most consequential scientific issues, in order

### 1. The primary contrast is not in the archived output

The frozen, hash-locked release at the inspected commit
(`outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv`, 1,372 core
rows across 14 contrasts per outcome) contains period-versus-baseline
difference-in-differences: `did_early_pre`, `did_immediate_pre`,
`did_spawn_start`, `did_early_egg`, `did_late_egg`, `did_pre_14_day`,
`did_pre_7_day`, `did_active_0_14_day`, and the six `near_minus_reference_*`
slopes. It contains no active-minus-pre-onset row.

The manuscript's primary estimand is a further linear contrast of those
coefficients. Its point estimates reproduce exactly. Taking the ratio of the
released `did_active_0_14_day` and `did_pre_14_day` ratios gives 1.3038 for Surf
Scoter reported number (manuscript: 1.30), 1.0034 for Surf Scoter reporting
(manuscript: 1.00, and the sensitivity comparison "1.00 to 0.71"), and 1.1503 for
Harlequin Duck reporting (manuscript: 1.15, and "1.15 to 0.84"). I also
recomputed Common Merganser, Glaucous-winged Gull, White-winged Scoter, Mallard
and Harlequin Duck in both outcomes; all agree with the manuscript's qualitative
claims. Figure 2 independently corroborates the family totals: I counted exactly
13 filled points in the reporting panel and exactly 18 in the reported-number
panel, and no filled point lies below one in either panel.

What cannot be checked is everything that depends on the joint covariance: the
confidence intervals, the p-values and, critically, the Benjamini–Hochberg
q-values for the primary contrast. The archived q-values belong to a different
contrast family (`core_species__<outcome>__did_active_0_14_day`). A referee
cannot presently verify a single interval in the abstract.

The fix is not analytical. It is to archive the active-minus-pre-onset contrast
table, estimate, standard error, 95% CI, p, q, for all 49 species and both
outcomes, together with the standardized absolute-scale predictions and the
nearest-event sensitivity output, and to cite that release in Code availability.
The version 12 revision memo refers to `active_minus_pre_contrasts.csv` and
`absolute_predictions.csv`; neither file exists at the inspected commit.

### 2. nAGQ = 0 underpins the headline reporting results, on the rarest taxa

The reporting models use `nAGQ = 0`, and the intervals are Wald intervals built
on that fit, so estimates and uncertainty inherit the approximation together. The
three strongest reporting contrasts are gulls: Bonaparte's Gull 1.48, American
Herring Gull 1.39, California Gull 1.32. The repository's own Phase 1 diagnostics
record that American Herring Gull is reported on 0.9% of eligible checklists and
Iceland Gull on 2.2%, and identify the `nAGQ = 1` reporting refit as "the highest-
value refit" for precisely this reason (`OPEN_QUESTIONS.md`, items S2 and D5).
That refit has not been run.

The manuscript's response is a single Laplace reporting refit and a single
zero-truncated negative-binomial count refit, each "for one representative
species", with neither species named and neither result given. As written the
check is uninterpretable: a reader cannot tell whether the representative species
was a common one, in which case it says nothing about the sparse gulls, or a rare
one, in which case it should be reported in full.

This is the one place where I think additional computation is genuinely required
before publication. It is bounded: refit the reporting models for the
adjusted-significant reporting species under a higher-accuracy quadrature, report
the comparison, and label it a sensitivity. I have written the limitation into
the revised manuscript honestly and have not implied that the refit was done.

Note that this issue does not touch the paper's central claim. The
reported-number results come from Gaussian mixed models and are unaffected.

### 3. Two different reference points are used for "the active period", without a signpost

Figure 2 plots active versus pre-onset. Figure 3 plots each period against the
days −28 to −15 baseline, and includes a "Pre-onset −14 to −1" point that a reader
will naturally take as the reference. The same species therefore carries
different numbers in the two figures, Surf Scoter reported number is 1.30 in
Figure 2 and 1.33 at early egg in Figure 3, with the pre-onset point at 0.96,
and version 12 moves between the two scales in §3.2 and §3.3 without warning. I
verified every plotted point in Figure 3 against the released `did_*` rows for
all five species I could reach; the figure is numerically correct. The problem is
purely one of reader guidance, and it is the single most likely source of a
misreading in the paper. Repaired in both captions and in the Results text.

### 4. The identifying assumption was never named (now resolved)

The design is a difference-in-differences in event time. Its validity rests on
the assumption that, absent spawning, the near-versus-reference gap would have
evolved from the pre-onset window into the active window in the same way in both
zones. Version 12 never states this. It should, because an ecologist or a
statistical referee will ask.

More usefully, the released output already contains `did_early_pre` (−14 to −8 d)
and `did_immediate_pre` (−7 to −1 d) for every species and both outcomes. Those
two windows, read against the baseline, are a pre-trend check that requires no
refitting at all, only reporting. Version 12 collapses them into a single
"days −14 to −1" summary and never used them diagnostically.

This has since been done. The assumption is named in the revised §2.4, and §3.6
reports the check: no checklist-reporting contrast survives adjustment in either
pre-onset window, the median contrast across species lies within 2% of one in
every window and outcome, and the two reported-number exceptions during days −7 to
−1 are named. One of them, Iceland Gull, also carries a positive active-period
reported-number contrast, and the manuscript now says so.

This is the only item in the review that ended up strengthening the paper rather
than qualifying it. The assumption went from unstated to stated and partly
examined, at the cost of one paragraph and no refitting.

### 5. Provenance language and comparator framing overstate two things

Two smaller items, but both are the kind that generate an integrity query rather
than a scientific one.

First, version 12 describes the antecedent work as "an earlier registered
analysis" in §2.1 and §2.6 with a placeholder for the identifier. The repository
records that no public registration exists and that the word was deliberately
qualified to "pre-committed and hash-locked" during the version 7 hardening
(`CHANGES.md` item 2; `OPEN_QUESTIONS.md` B2). Unless a public registration
exists, "registered" should not be used. Changed in the revision, with the
placeholder retained.

Second, the dabbling ducks are presented as taxa "without a narrow herring
expectation". The species registry assigns Mallard, American Wigeon and Northern
Pintail to a hypothesized weak surface- and vegetation-associated roe-use guild
(`OPEN_QUESTIONS.md` A2, D9). They are not mechanism-free comparators. This
weakens the specificity argument slightly and, more importantly, it is discoverable
by any referee who opens the repository. Disclosed in the revision. Relatedly,
Northern Shoveler's q-value is adjusted within a two-species comparator family;
the core-family value is 0.0115 and is also significant. Version 12 gestures at
the family distinction without giving readers the comparable number. Added.

## Major strengths

The estimand is the right one and it is described honestly. Comparing a
near/reference spatial contrast after onset with the same contrast before onset,
having removed the contrast already present two to four weeks earlier, is exactly
what is needed to stop spring migration and persistent shoreline differences from
being read as a herring response. Many community-science papers on resource
pulses do not do this.

The two-outcome decomposition is the paper's best idea and its most transportable
one. Separating "was the species reported" from "how many were reported when a
number was given" is not a technicality; it is what turns an ambiguous signal into
an interpretable one. The finding that reported number moved more consistently
than reporting, and survived a change in exposure encoding that several reporting
results did not, is a genuine contribution and is correctly presented as the
central result.

The fixed 49-species family is preserved, non-estimable components are shown as
gaps rather than deleted, and no taxon was dropped after its result was seen. The
complete-family forest plot makes this visible instead of asserting it. This is
better discipline than most comparable papers show.

The specificity check is used as a check rather than as decoration. The dabbling
duck and goose results are given real weight, and the conclusions are framed
around them rather than in spite of them.

The interpretive boundary holds throughout. The manuscript does not claim
occupancy, detection probability, consumption, movement, regional abundance
change, or demographic effect, and it repeatedly and correctly says that the
ratios are per-link contrasts rather than percentage changes in bird numbers.

The species-level ecological reading is good natural history, not filler. The
contrast between scoters (numbers up during egg availability, reporting flat) and
mergansers, gulls and eagles (both components up near onset) is the kind of
detail that makes the paper worth reading, and it is properly hedged.

## Likely reviewer criticisms, and whether the revision addresses them

**"This is a difference-in-differences and you have not defended parallel
trends."** Addressed. The assumption is named, the relevant methodological
literature is cited, and §3.6 now reports the pre-onset check: no reporting
contrast survives adjustment in either window, medians sit within 2% of one, and
the two reported-number exceptions are named. Issue 4 is closed.

**"nAGQ = 0 with rare species is not acceptable for the headline results."**
Partly addressed. The limitation is now stated concretely, with the prevalence
figures, and the outstanding refit is named as the most valuable next check. A
determined statistical referee will still ask for the refit. See issue 2.

**"Your ratios are per-link slopes; what does a reader do with that?"** Addressed.
The estimand is defined in words before symbols, a worked two-link example is
given, and the standardized predictions put three results on percentage-point and
bird-count scales. The revision adds an explicit list of what the ratio is not.

**"Time of day and day of year are standard eBird covariates and you have neither."**
Now disclosed. Version 12 omitted this entirely; the repository records that
neither field was carried into the analysis frame. A referee may still regard it
as a substantive gap, and they would be entitled to.

**"The 49 tests are not independent, so the FDR statement is weaker than it looks."**
Addressed; the manuscript says so directly.

**"Travelling checklists cross your 5 km boundary."** Addressed with the 12% and
3% figures and the direction-of-bias caveat.

**"You have not shown the numbers for 47 of 49 species."** Partly addressed. The
forest plot shows every species and both outcomes, but exact values are not in
the article. Given the three-figure, no-main-table structure, a supplementary
table of all 49 × 2 estimates is the right answer and is now requested in Code
availability.

**"Gull identification and taxonomic churn make a 21-year gull series unreliable."**
Addressed in Methods (versioned concept mapping, the three named split/lump
events) and revisited in the Discussion where the gull results are interpreted.

**"Aren't the gulls just attracting birders?"** Addressed directly, including the
observation that the standardized Glaucous-winged Gull reporting change is about
two percentage points despite a strongly significant relative contrast.

**"Why should I believe the quantified subset is unbiased?"** Addressed, and
correctly left open. The revision keeps the manuscript's refusal to claim the
count ratios are conservative, which is an improvement on the earlier repository
version, and adds that the 30 singular fits in the finite-versus-X family leave
that analysis underpowered.

## Is further analysis essential before submission?

**Essential:** none, in the sense of new data or a new design. One computational
item is close to essential and I would not defend the paper without it if a
statistical referee pressed: a higher-accuracy (`nAGQ` ≥ 1, or an equivalent
alternative-engine) refit of the checklist-reporting models for at least the 13
adjusted-significant reporting species, reported as a labelled sensitivity
alongside the primary result. This has already been specified in the project's
own plan and has not been executed.

Also essential, though it is archiving rather than analysis: release the
active-minus-pre-onset contrast table, the standardized predictions and the
nearest-event sensitivity output, so that every quoted value can be checked.

**Helpful but optional, and requiring no new model fits:**

- Report the two pre-onset windows against baseline as a pre-trend check. The
  estimates already exist in the frozen release.
- Add a supplementary table of all 49 species × 2 outcomes for the primary
  contrast.
- Name the species used for the Laplace and negative-binomial validation refits
  and give their estimates.
- Report Northern Shoveler's core-family q alongside its comparator-family q.

**Unnecessary:** a single-event restriction beyond what is reported; additional
spatial rings; a shoreline or alongshore reformulation; anything touching the
protected 2026–2028 records. The nearest-event sensitivity already does the work
the single-event subset was meant to do, and does it without losing two thirds of
the count models.

## Answers to the specific review questions

1. **Importance, novelty, scope.** Yes on all three. Herring spawn is a
   well-studied pulse for a handful of focal species; this is the first
   assessment I am aware of across a fixed 49-species coastal family over two
   decades, and the two-outcome decomposition is methodologically novel for this
   literature. Squarely within MER's scope.

2. **Are the data sources and linkage reproducible in logic?** Yes. Sources,
   release version, taxonomy version, eligibility rules, the near and reference
   definitions, the six periods, the event-block unioning and the 12 additive
   exposure variables are all specified well enough to rebuild the logic. Two
   gaps: the absence of day-of-year and start time is now disclosed, and the
   primary-contrast outputs are not archived (issue 1).

3. **Is the estimand described correctly and consistently?** Yes, and it is one
   of the manuscript's strengths. §2.4 defines it as a baseline-adjusted
   near/reference contrast of event-link slopes per additional recorded link, and
   §2.5, §3.2 and the figure captions repeat that framing without drifting.

4. **Could a reader mistake the ratios for abundance change?** In version 12,
   yes, in two places, the risk was mostly from the Figure 2 / Figure 3
   reference-point mismatch (issue 3) rather than from the wording, which was
   already careful. Both captions and the Results text now signpost the
   difference, and the "this is not" list in §2.4 has been extended to name
   occupancy and detection explicitly.

5. **Is the direct 0–14 versus −14 to −1 test separated from descriptive timing?**
   It is now. Version 12 stated it in the captions but let the Results prose blur
   it; §3.3 now opens by saying the period estimates use a different reference
   point and that the formal test is the Figure 2 quantity.

6. **Are the two outcomes clearly distinguished?** Yes, and consistently:
   checklist reporting, and reported number when quantified. The revision keeps
   the §2.2 paragraph that states a taxon can move in one without the other, and
   §4.3 explains why they behave differently.

7. **Is the finite-versus-X process handled without assuming the direction of
   selection?** Yes, and this is a point where version 12 is better than the
   earlier repository version, which concluded that the count ratios were
   conservative. The revision keeps the agnostic framing and adds that 30 singular
   fits make the null result weak evidence rather than reassurance.

8. **Multiplicity, failures, singular fits, convergence, nAGQ = 0, fixed family.**
   Now reported at the right level, after one correction. `model_diagnostics_v1.csv`
   at the pinned commit carries all 100 rows, and `converged` is TRUE for every one
   of the 96 fitted components. Version 12's claim that "one fit retained a
   convergence warning" is not supported: the only qualified fit is the singular
   Western Gull count model, which version 12 appears to have counted twice. That
   sentence has been corrected. The four failures are now named with their sample
   sizes rather than counted anonymously: both Glaucous Gull models (185 quantified
   reports), and the count models for Surfbird (1,063) and Rhinoceros Auklet
   (1,816). The BH family is stated explicitly as outcome-by-contrast across the 49
   species.

9. **Does the nearest-event sensitivity support the central conclusion?** Yes,
   and it is used correctly. All 18 reported-number directions preserved with 17
   still significant, against 11 of 13 reporting directions with seven still
   significant, is a clean asymmetry that supports the paper's main claim while
   licensing exactly the species-level caution the Discussion applies to Surf
   Scoter, Harlequin Duck, American Wigeon and Barrow's Goldeneye.

10. **Do the dabbling-duck and goose findings carry enough weight?** In version 12,
    almost. They had their own Results subsection and a Discussion subsection, and
    the Conclusion referred to them. What was missing was the disclosure that
    three of the five were assigned a weak roe-use pathway a priori, which makes
    them slightly less clean as comparators than the text implied. Added.

11. **Are causal and biological interpretations bounded?** Yes. I found no claim
    of consumption, herring-caused movement, occupancy, detection probability,
    regional abundance change or demographic effect anywhere in version 12, and
    the revision has not loosened any of them. If anything the revision tightens
    the sea-duck and eagle paragraphs.

12. **Are the three figures accurate, legible, explained and useful?** Scientifically
    accurate, I verified Figure 3 point by point for five species against the
    frozen output, and Figure 2's significance counts against the family totals.
    Legible at full-page width; Figure 2 is a tall two-panel forest plot with 49
    rows and will not survive single-column reduction. Well explained, and the
    captions now carry the cross-reference that was missing. Useful: Figure 1
    earns its place because the estimand is unfamiliar, Figure 2 is the honesty
    device that makes the fixed-family claim checkable, and Figure 3 is where the
    ecology actually lives. Two production points are in the compliance checklist:
    Figure 1's pixel width falls just below Elsevier's single-column raster
    threshold, and neither Figure 2 nor Figure 3 meets the full-page raster
    threshold at the stated resolution class.

13. **Is any major concern still unaddressed strongly enough to threaten
    publication?** Yes, issue 1, and issue 2 if a statistical referee is assigned.
    Neither threatens the science. Both threaten the paper's ability to withstand
    a referee who checks. Everything else on this list is a revision-cycle matter.

## What I did not do

I did not rerun, refit or redesign any analysis. I did not modify the repository,
push commits, merge pull requests or overwrite outputs. I did not access,
summarize or release any protected 2026–2028 record; the execution record at the
inspected commit shows `records_2026_plus_read: 0`, and nothing I fetched touched
them. I removed no taxon from the 49-species family and changed no reported
figure. Two references were added and both were verified independently; they are
listed in the revision memo.
