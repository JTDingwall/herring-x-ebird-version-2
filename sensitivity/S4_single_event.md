# S4 — Single-event restriction

Refit of the eleven panel species, both outcomes, on the 72,443 checklists
linked to exactly one recorded event (`concurrent_links == 1`), addressing the
cell non-exclusivity documented in D4. Comparison table:
`sensitivity/S4_single_event.csv` (all four active-period contrasts; the
active 0-14 d rows are summarised here). This is a labelled sensitivity; it does
not replace the primary, which uses all 217,200 checklists.

## Active 0-14 d interaction, primary vs single-event

| Species | Detection primary -> S4 | Count primary -> S4 |
|---|---|---|
| Surf Scoter | 0.99 -> 1.78 | 1.25 -> 2.18 |
| White-winged Scoter | 0.91 -> 1.55 | 1.31 -> 1.73 |
| Harlequin Duck | 1.09 -> 0.85 | 1.22 -> 1.43 |
| Common Merganser | 1.19 -> 1.12 | 1.11 -> 1.21 |
| Hooded Merganser | 0.97 -> 1.46 | 1.01 -> 1.30 |
| Glaucous-winged Gull | 1.12 -> 1.15 | 1.21 -> 1.19 |
| Short-billed Gull | 1.22 -> 2.34 | 1.36 -> 1.69 |
| Bald Eagle | 1.08 -> 1.20 | 1.07 -> 0.97 |
| Mallard | 1.04 -> 1.28 | 1.11 -> 1.25 |
| American Crow | 1.01 -> 1.15 | 1.00 -> 1.04 |
| Common Raven | 0.94 -> 0.99 | 1.01 -> 1.03 |

## Reading

The single-event subset is smaller and each checklist occupies a single
period-by-zone cell, so the interaction is now estimated purely between
checklists; point estimates move and confidence intervals widen.

- **Flock size is robust and often stronger.** Ten of eleven count interactions
  agree in direction, and the strong aggregators increase (Surf Scoter 1.25 to
  2.18, White-winged Scoter 1.31 to 1.73, Harlequin 1.22 to 1.43, Short-billed
  Gull 1.36 to 1.69, Mallard 1.11 to 1.25). The one flip is Bald Eagle count
  (1.07 to 0.97, CI 0.88-1.06, i.e. null both ways), whose count response was
  the weakest of the two-component species.
- **Detection is consistent where it was supported and noisy where it was not.**
  The species with a supported primary detection response stay positive (Common
  Merganser, Glaucous-winged Gull, Short-billed Gull, Bald Eagle). The direction
  flips (Surf Scoter, White-winged Scoter, Harlequin, Hooded Merganser) are all
  among primary estimates that were near one and non-significant, on a subset
  with far fewer checklists.

## Conclusion

The cell non-exclusivity that S4 targets does not drive the findings. The
flock-size signal, which is the manuscript's main result, survives the single-
event restriction and tends to strengthen. No primary conclusion is contradicted.
