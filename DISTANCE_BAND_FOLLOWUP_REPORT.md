# Distance-band follow-up report

The direct archived-covariance test finds that the 13-band waterbird profile
changes at the recorded event-time anchor for both species and both outcomes.
The terrestrial controls show no BH-significant 0–<2 km spike at that anchor,
which argues against general near-spawn checklist inflation. The controls are
not a perfectly clean null, however: American Robin reporting changes across
the full 13-band profile and is elevated in the immediate-pre period. The
strongest defensible conclusion is therefore a localized waterbird response,
not an absence of all event-time structure in terrestrial controls.

A necessary terminology correction applies throughout: event day 0 is the
midpoint of the DFO `StartDate` and `EndDate` fields (or the available endpoint),
not a continuously observed biological onset date. Existing “spawn start”
labels below identify the archived days 0–3 period but should not be read as
four days after a precisely observed onset.

## 1. Direct test that the distance profile changes at the event-time anchor

The linear hypothesis compares the 13 spawn-start coefficients (days 0–3) with
the duration-weighted pooled pre-spawn profile. Early pre-spawn (days −14 to
−8) and immediate pre-spawn (days −7 to −1) each contain seven days, so pooled
pre-spawn is `0.5 × early_pre + 0.5 × immediate_pre`. The days −28 to −15
baseline coefficients cancel. Each 13-vector was tested with its exact
archived fixed-effect covariance matrix; neither waterbird model was refit.

| Species | Outcome | Wald χ² | df | p |
|---|---|---:|---:|---:|
| Bald Eagle | Checklist reporting | 36.985 | 13 | 0.000417 |
| Bald Eagle | Positive reported number | 319.928 | 13 | 1.61 × 10⁻⁶⁰ |
| Glaucous-winged Gull | Checklist reporting | 55.842 | 13 | 2.87 × 10⁻⁷ |
| Glaucous-winged Gull | Positive reported number | 288.012 | 13 | 7.72 × 10⁻⁵⁴ |

All four tests reject equality of the onset-anchor and pooled-pre profiles.
This is direct evidence that the adjusted 13-band coefficient vector changes;
it does not by itself prove smooth distance decay, individual movement, or a
causal threshold.

Exact results are in
[`direct_onset_profile_tests_v1.csv`](outputs/post_stage4a_distance_band_followup_v1/direct_onset_profile_tests_v1.csv)
and the 52 component contrasts are in
[`direct_onset_band_contrasts_v1.csv`](outputs/post_stage4a_distance_band_followup_v1/direct_onset_band_contrasts_v1.csv).

## 2. Terrestrial negative controls

American Robin was mandatory. Chestnut-backed Chickadee was selected before
any control effect was fitted because its weakest positive-count term had 334
rows versus 322 for Dark-eyed Junco. All 78 terms passed the 20-row support
gate for every candidate. The controls remain outside the registered
49-species family and outside every primary-analysis BH family.

| Control | Reporting rows | Positive-count rows | Weakest positive-count term | 0–<2 km anchor-period count support |
|---|---:|---:|---:|---:|
| American Robin | 217,176 | 125,407 | 549 | 549 |
| Chestnut-backed Chickadee | 217,183 | 72,498 | 334 | 334 |

All four control components converged without singularity or rank deficiency.
At 0–<2 km, none met the locked definition of an upward or downward spike:
the anchor-period contrast versus the same-band baseline and the tight contrast
versus immediate pre-spawn did not both survive the separate 13-band BH
families.

| Control | Outcome | Days 0–3 vs same-band baseline, ratio (95% CI); BH q | Days 0–3 vs days −7 to −1, ratio (95% CI); BH q |
|---|---|---:|---:|
| American Robin | Reporting | 0.996 (0.878–1.131); 0.956 | 0.867 (0.753–0.999); 0.551 |
| American Robin | Positive number | 0.942 (0.886–1.002); 0.249 | 1.003 (0.939–1.073); 0.922 |
| Chestnut-backed Chickadee | Reporting | 0.872 (0.759–1.001); 0.165 | 0.892 (0.762–1.044); 0.926 |
| Chestnut-backed Chickadee | Positive number | 0.965 (0.914–1.019); 0.653 | 0.998 (0.939–1.061); 0.950 |

The American Robin reporting tight contrast is nominally below one because its
unadjusted 95% interval just excludes one, but it does not survive the declared
13-band BH family. This direction would be consistent with attention diversion
if confirmed; it is not adjusted evidence of that mechanism.

The two controls are not uniformly flat:

- Chestnut-backed Chickadee is flat at 0–<2 km in every period after BH
  correction, and neither 13-band direct profile test is significant
  (reporting χ² = 15.264, p = 0.291; count χ² = 13.203, p = 0.432).
- American Robin has no 0–<2 km spike at the event-time anchor, but reporting
  is elevated during immediate pre-spawn at 0–<2 km: 1.149
  (1.021–1.294), BH q = 0.039. Its full reporting profile also changes at
  the anchor (χ² = 30.894, 13 df, p = 0.00349), driven by positive
  anchor-versus-baseline contrasts in seven outer bands. Its count-profile
  test is null (χ² = 12.863, p = 0.458).

Thus neither terrestrial species shows the focal near-band upward onset-anchor
spike seen in the waterbirds. That result weighs against a general increase in
reporting on all checklists within 2 km, but the Robin result prevents calling
the entire control analysis flat.

Seasonality is reduced, not proven absent. Every distance band is compared
with its own days −28 to −15 coefficient; the models include checklist year,
effort terms, and event-block, observer, and location random intercepts. The
linked source frame spans 21 years and 176 source location codes. These
features reduce a simple calendar-season explanation, but neither same-band
differencing nor broad temporal/spatial coverage guarantees removal of all
species-specific seasonal detectability.

The reviewed figure is
[`terrestrial_control_near_band_timing_v1.png`](outputs/post_stage4a_distance_band_followup_v1/terrestrial_control_near_band_timing_v1.png).
Complete estimates, exact covariance contrasts, diagnostics, and the locked
classification are in the same output directory.

## 3. Multiplicity

Benjamini–Hochberg adjustment is now applied within species, outcome, and
period across the 13 distance bands. Each period-specific family therefore has
13 members; the active 0–14 composite is its own 13-member family. The two
terrestrial controls use separate diagnostic families and never enter a
waterbird or registered-family correction.

Of the 312 released waterbird contrasts, 104 are nominally significant and 84
survive the declared BH correction. Additive, versioned copies of both effect
tables include `bh_family_id`, `bh_family_size`, `p_value_bh_13`, and survival
flags:

- [`bald_eagle_distance_band_effects_bh_v1.csv`](outputs/post_stage4a_distance_band_followup_v1/bald_eagle_distance_band_effects_bh_v1.csv)
- [`glaucous_winged_gull_distance_band_effects_bh_v1.csv`](outputs/post_stage4a_distance_band_followup_v1/glaucous_winged_gull_distance_band_effects_bh_v1.csv)

The surviving bands in every waterbird family are:

| Species/outcome | Period → BH-significant bands |
|---|---|
| Bald Eagle reporting | Early pre: none. Immediate pre: 2–<4, 8–<10. Days 0–3: 0–<2, 2–<4, 8–<10. Early egg: 8–<10. Late egg: none. Active 0–14: 2–<4, 8–<10. |
| Bald Eagle positive number | Early pre: 8–<10. Immediate pre: 4–<6, 8–<10, 12–<14, 24–26. Days 0–3: 0–<2, 2–<4, 4–<6, 8–<10. Early egg: 8–<10. Late egg: 8–<10, 18–<20. Active 0–14: 0–<2, 2–<4, 4–<6, 6–<8, 8–<10, 10–<12. |
| Glaucous-winged Gull reporting | Early pre: none. Immediate pre: 16–<18. Days 0–3: 0–<2, 6–<8, 8–<10, 16–<18, 22–<24, 24–26. Early egg: 0–<2, 6–<8, 8–<10, 14–<16, 16–<18, 18–<20, 24–26. Late egg: 2–<4, 6–<8, 14–<16, 16–<18, 24–26. Active 0–14: 0–<2, 6–<8, 8–<10, 14–<16, 16–<18, 22–<24, 24–26. |
| Glaucous-winged Gull positive number | Early pre: 14–<16. Immediate pre: 6–<8, 14–<16. Days 0–3: 0–<2, 2–<4, 4–<6, 8–<10, 14–<16, 22–<24, 24–26. Early egg: 0–<2, 2–<4, 4–<6, 12–<14, 14–<16, 16–<18, 18–<20, 20–<22, 22–<24. Late egg: 12–<14, 14–<16, 16–<18, 24–26. Active 0–14: 0–<2, 2–<4, 4–<6, 8–<10, 14–<16, 16–<18, 18–<20, 20–<22, 22–<24. |

## 4. Near-band active-window asymmetry and below-baseline cells

The 0–<2 km active 0–14 result clears as follows:

| Species | Outcome | Active 0–14 ratio (95% CI) | p | BH q | Clears? |
|---|---|---:|---:|---:|---|
| Bald Eagle | Reporting | 1.083 (0.988–1.187) | 0.0891 | 0.290 | No |
| Bald Eagle | Positive number | 1.074 (1.042–1.107) | 3.18 × 10⁻⁶ | 4.13 × 10⁻⁵ | Yes |
| Glaucous-winged Gull | Reporting | 1.203 (1.078–1.343) | 0.000967 | 0.00251 | Yes |
| Glaucous-winged Gull | Positive number | 1.320 (1.256–1.388) | 1.17 × 10⁻²⁷ | 1.52 × 10⁻²⁶ | Yes |

The Bald Eagle reporting headline is therefore specific to days 0–3, not the
full active 0–14 window. Its positive-number outcome does clear the active
window.

The following is the exhaustive inventory of nominally significant
below-baseline cells. Ratios are followed by unadjusted p and BH q; “BH”
identifies those that survive the declared family. The machine-readable
inventory, including every negative but nonsignificant row, is
[`below_baseline_inventory_v1.csv`](outputs/post_stage4a_distance_band_followup_v1/below_baseline_inventory_v1.csv).

### Pre-spawn

- **Bald Eagle reporting:** early pre 8–<10 (0.917; p = 0.0131,
  q = 0.170); immediate pre 8–<10 (0.888; p = 0.000891,
  q = 0.0116, BH).
- **Bald Eagle positive number:** early pre 8–<10 (0.962; p = 0.00315,
  q = 0.0410, BH); immediate pre 8–<10 (0.966; p = 0.0102,
  q = 0.0434, BH); immediate pre 12–<14 (0.947; p = 0.000586,
  q = 0.00762, BH).
- **Glaucous-winged Gull reporting:** immediate pre 8–<10 (0.892;
  p = 0.00809, q = 0.0526); early pre 16–<18 (0.916; p = 0.0328,
  q = 0.426); immediate pre 16–<18 (0.868; p = 0.000587,
  q = 0.00763, BH).
- **Glaucous-winged Gull positive number:** early pre 14–<16 (0.923;
  p = 0.00119, q = 0.0154, BH); immediate pre 14–<16 (0.922;
  p = 0.00109, q = 0.0142, BH).

### Post-anchor periods and active composite

- **Bald Eagle reporting:** late egg 4–<6 (0.939; p = 0.0483,
  q = 0.314); days 0–3 8–<10 (0.878; p = 0.00296,
  q = 0.0128, BH); early egg 8–<10 (0.914; p = 0.00286,
  q = 0.0372, BH); active 0–14 8–<10 (0.904; p = 0.000288,
  q = 0.00374, BH); days 0–3 18–<20 (0.906; p = 0.0362,
  q = 0.118); late egg 18–<20 (0.935; p = 0.0314, q = 0.314).
- **Bald Eagle positive number:** late egg 0–<2 (0.963; p = 0.0265,
  q = 0.110); early egg 6–<8 (0.976; p = 0.0346, q = 0.150);
  active 0–14 6–<8 (0.974; p = 0.0142, q = 0.0368, BH);
  days 0–3 8–<10 (0.951; p = 0.00191, q = 0.00622, BH);
  early egg 8–<10 (0.966; p = 0.00237, q = 0.0308, BH);
  late egg 8–<10 (0.955; p = 9.29 × 10⁻⁶, q = 0.000121, BH);
  active 0–14 8–<10 (0.962; p = 0.000214, q = 0.00139, BH);
  late egg 18–<20 (0.966; p = 0.00237, q = 0.0154, BH).
- **Glaucous-winged Gull reporting:** early egg 2–<4 (0.907;
  p = 0.0364, q = 0.0591); late egg 2–<4 (0.895; p = 0.0103,
  q = 0.0268, BH); days 0–3 6–<8 (0.843; p = 0.00136,
  q = 0.00589, BH); early egg 6–<8 (0.918; p = 0.0220,
  q = 0.0409, BH); late egg 6–<8 (0.887; p = 0.000554,
  q = 0.00240, BH); active 0–14 6–<8 (0.897; p = 0.00157,
  q = 0.00340, BH); days 0–3 8–<10 (0.856; p = 0.00399,
  q = 0.0130, BH); early egg 8–<10 (0.895; p = 0.00324,
  q = 0.0105, BH); active 0–14 8–<10 (0.885; p = 0.000378,
  q = 0.00123, BH); days 0–3 14–<16 (0.891; p = 0.0302,
  q = 0.0561); early egg 14–<16 (0.855; p = 4.41 × 10⁻⁵,
  q = 0.000429, BH); late egg 14–<16 (0.846; p = 5.52 × 10⁻⁶,
  q = 7.18 × 10⁻⁵, BH); active 0–14 14–<16 (0.864;
  p = 4.12 × 10⁻⁵, q = 0.000268, BH); days 0–3 16–<18
  (0.846; p = 0.00121, q = 0.00589, BH); early egg 16–<18
  (0.868; p = 6.61 × 10⁻⁵, q = 0.000429, BH); late egg 16–<18
  (0.865; p = 1.42 × 10⁻⁵, q = 9.22 × 10⁻⁵, BH);
  active 0–14 16–<18 (0.862; p = 4.58 × 10⁻⁶,
  q = 5.95 × 10⁻⁵, BH); early egg 18–<20 (0.918; p = 0.0216,
  q = 0.0409, BH); days 0–3 22–<24 (0.888; p = 0.0211,
  q = 0.0458, BH); active 0–14 22–<24 (0.926; p = 0.0197,
  q = 0.0365, BH); days 0–3 24–26 (0.867; p = 0.0153,
  q = 0.0397, BH); early egg 24–26 (0.861; p = 0.000301,
  q = 0.00131, BH); late egg 24–26 (0.884; p = 0.00155,
  q = 0.00505, BH); active 0–14 24–26 (0.862; p = 0.000120,
  q = 0.000520, BH).
- **Glaucous-winged Gull positive number:** early egg 12–<14 (0.937;
  p = 0.0128, q = 0.0238, BH); late egg 12–<14 (0.937;
  p = 0.00749, q = 0.0243, BH); days 0–3 14–<16 (0.923;
  p = 0.00675, q = 0.0125, BH); early egg 14–<16 (0.878;
  p = 1.35 × 10⁻⁹, q = 8.78 × 10⁻⁹, BH); late egg 14–<16
  (0.904; p = 6.88 × 10⁻⁷, q = 4.47 × 10⁻⁶, BH);
  active 0–14 14–<16 (0.890; p = 2.24 × 10⁻⁹,
  q = 1.46 × 10⁻⁸, BH); early egg 16–<18 (0.921;
  p = 0.000129, q = 0.000419, BH); late egg 16–<18 (0.897;
  p = 1.23 × 10⁻⁷, q = 1.60 × 10⁻⁶, BH); active 0–14
  16–<18 (0.939; p = 0.00136, q = 0.00220, BH); early egg
  18–<20 (0.924; p = 0.000192, q = 0.000499, BH);
  active 0–14 18–<20 (0.933; p = 0.000243, q = 0.000632, BH);
  days 0–3 24–26 (0.909; p = 0.00200, q = 0.00434, BH);
  late egg 24–26 (0.937; p = 0.00197, q = 0.00852, BH).

## 5. Bald Eagle denominator and headline-cell support

The eligible SoG frame contains 217,200 checklists. Bald Eagle reporting uses
217,199 because one checklist is a prespecified structural unknown: an
ambiguity mask is present without a resolved Bald Eagle reported state. No
effort covariate complete case was dropped. The discrepancy is therefore
expected response handling, not a join or row-loss error.

The 0–<2 km days 0–3 cell has 1,166 exposed checklists, 1,593 source-event
links, 40 event blocks, and 20 checklist years. It is the smallest cell in the
13 × 6 grid. The 8–<10 and 10–<12 km cells have 2,327 and 2,401 exposed
checklists, so the nearest cell has 50.1% and 48.6% as much checklist support.

With that support, the days 0–3 reporting ratios are 1.310
(1.139–1.507) for Bald Eagle and 1.321 (1.123–1.553) for
Glaucous-winged Gull. The Bald Eagle reporting component uses all 1,166
exposed rows in that cell; the gull uses 1,165 complete reporting rows.
The corresponding positive-count cells contain 736 and 702 model rows.

## 6. Tight archived contrast: days 0–3 versus days −7 to −1

These are exact linear contrasts of archived coefficients and covariance
matrices. BH adjustment is within species and outcome across all 13 bands, not
only the three displayed here.

| Species | Outcome | Band | Ratio (95% CI) | p | BH q | Survives |
|---|---|---|---:|---:|---:|---|
| Bald Eagle | Reporting | 0–<2 | 1.232 (1.053–1.441) | 0.00917 | 0.119 | No |
| Bald Eagle | Reporting | 2–<4 | 1.033 (0.910–1.173) | 0.612 | 0.815 | No |
| Bald Eagle | Reporting | 4–<6 | 1.106 (0.993–1.232) | 0.0672 | 0.291 | No |
| Bald Eagle | Positive number | 0–<2 | 1.220 (1.167–1.275) | 9.51 × 10⁻¹⁹ | 1.24 × 10⁻¹⁷ | Yes |
| Bald Eagle | Positive number | 2–<4 | 1.133 (1.086–1.181) | 4.77 × 10⁻⁹ | 3.10 × 10⁻⁸ | Yes |
| Bald Eagle | Positive number | 4–<6 | 1.042 (1.004–1.082) | 0.0298 | 0.103 | No |
| Glaucous-winged Gull | Reporting | 0–<2 | 1.310 (1.092–1.572) | 0.00361 | 0.0469 | Yes |
| Glaucous-winged Gull | Reporting | 2–<4 | 1.061 (0.917–1.227) | 0.427 | 0.720 | No |
| Glaucous-winged Gull | Reporting | 4–<6 | 0.945 (0.829–1.076) | 0.391 | 0.720 | No |
| Glaucous-winged Gull | Positive number | 0–<2 | 1.400 (1.295–1.513) | 2.09 × 10⁻¹⁷ | 2.72 × 10⁻¹⁶ | Yes |
| Glaucous-winged Gull | Positive number | 2–<4 | 1.143 (1.058–1.234) | 0.000697 | 0.00453 | Yes |
| Glaucous-winged Gull | Positive number | 4–<6 | 1.098 (1.023–1.178) | 0.00960 | 0.0384 | Yes |

The tight comparison therefore supports a nearest-band jump for gull reporting
and for both positive-number outcomes after BH correction. Bald Eagle
reporting is nominally positive at 0–<2 km but does not survive the 13-band
family.

All 52 results are in
[`tight_spawn_start_vs_immediate_pre_v1.csv`](outputs/post_stage4a_distance_band_followup_v1/tight_spawn_start_vs_immediate_pre_v1.csv).

## 7. Symmetric-window precision gate: stopped without refitting

The existing event anchor is derived as
`floor((StartDate + EndDate) / 2)` when both endpoints exist, otherwise the
available endpoint. In the 0–26 km linked frame:

- 1,144 source events are represented;
- 1,143 have both date endpoints and one has only `StartDate`;
- 466 have same-day endpoints, 744 have endpoints no more than one day apart,
  and 904 have endpoints no more than two days apart;
- endpoint-span days have median 1, 75th percentile 2, 95th percentile 4, and
  maximum 72;
- the representative midpoint is a median 0 days and 95th percentile 2 days
  after `StartDate`.

These endpoint spans are not intervals between consecutive survey visits.
The release has no survey-visit history or cadence data, and `StartDate` is not
documented as the date on which biological onset was continuously observed.
Consequently, the number of source events whose true onset was dated to within
one day is **not identifiable**. The count 744 describes endpoint width only
and must not be substituted for onset precision.

The ±3-day gate therefore fails:
`FAIL_NO_SURVEY_CADENCE_AND_ANCHOR_IS_NOT_OBSERVED_ONSET`. The immediate-pre
period was not split and no symmetric-window model was fitted. This is the
required stop, not a missing analysis.

## Boundaries, reproducibility, and files

- Frozen Stage 4A outputs, locks, and checkpoints were not modified.
- Bald Eagle and Glaucous-winged Gull were not refit.
- The registered species family was not changed.
- No 2026–2028 response was persisted or analysed.
- No manuscript file was edited.
- Protected checklist, observer, locality, taxon-source, source-event token,
  and coordinate fields are absent from the released artifacts.

The authorization, specification, and pre-effect control selection are:

- [`post_stage4a_distance_band_followup_authorization_v1.yml`](metadata/post_stage4a_distance_band_followup_authorization_v1.yml)
- [`post_stage4a_distance_band_followup_spec_v1.yml`](metadata/post_stage4a_distance_band_followup_spec_v1.yml)
- [`post_stage4a_distance_band_followup_control_selection_v1.yml`](metadata/post_stage4a_distance_band_followup_control_selection_v1.yml)

All additive results are under
[`outputs/post_stage4a_distance_band_followup_v1/`](outputs/post_stage4a_distance_band_followup_v1/).
The archived recomputation and terrestrial-control manifests record the
released SHA-256 hashes. The final numeric, privacy, boundary, link, manifest,
and visual checks are recorded in
[`validation_record_v1.yml`](outputs/post_stage4a_distance_band_followup_v1/validation_record_v1.yml).
