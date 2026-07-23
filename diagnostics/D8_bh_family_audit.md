# D8 — BH family audit and Northern Shoveler cross-family recomputation

## Families

BH adjustment was applied within families keyed by
`analysis_role __ outcome __ contrast` (`R/post_stage4a_sog_event_study_v1.R`,
`post_stage4a_adjust_multiplicity_v1`). Full enumeration in
`D8_bh_families.csv`.

- **42 families total.**
- **28 core-species families**: 14 contrasts x 2 outcomes, 49 species each.
- **14 comparator families**: 14 contrasts x 1 outcome (detection only), 2
  species each (Gadwall, Northern Shoveler).
- The 14 contrasts are the 6 `near_minus_reference_*` spatial differences, the
  5 single-period `did_*` interactions, and `did_pre_14_day`, `did_pre_7_day`,
  `did_active_0_14_day`.

The BH reimplementation used for the recomputation below reproduces the reported
core active-detection q-values to a maximum absolute difference of 1e-15.

## The cross-family question

The manuscript's "four of five dabbling ducks" statement pools four core species
(Mallard, Northern Pintail, American Wigeon, Canada Goose is a goose; the four
dabblers are Mallard, Northern Pintail, American Wigeon, Northern Shoveler) with
Northern Shoveler, a **specificity comparator**. Shoveler's reported q was
adjusted inside its 2-species comparator family, a different and far weaker
standard than the 49-species core family. This mixes adjustment families.

## Recomputation

Adjusting Northern Shoveler's active-detection p-value (raw p = 0.00282) inside
the 49-species core detection family, alongside the 48 estimable core species:

| Quantity | Value |
|---|---|
| Shoveler active detection ratio | 1.24 |
| Reported q (2-species comparator family) | 0.0056 |
| **Recomputed q (49-species core family)** | **0.0115** |
| Survives q < 0.05 in the core family | **Yes** |

The three dabbling ducks that are core species were already adjusted in the
49-species family: Northern Pintail (q = 7.3e-7), American Wigeon (q = 1.4e-4),
Mallard detection (q = 0.312, not significant; Mallard's significant response is
in flock size). Gadwall does not respond (q = 0.70).

## Conclusion

Northern Shoveler survives the stricter 49-species adjustment. The "four of five
dabbling ducks" claim is defensible under a single common standard, but the
manuscript must say which standard it is using. Recommended wording routes to
`OPEN_QUESTIONS.md` and Phase 3 item 14: report Shoveler's core-family q (0.0115)
explicitly, so the claim does not silently pool two adjustment families.
