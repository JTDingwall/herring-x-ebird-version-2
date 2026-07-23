# D6 — Travelling-checklist boundary exposure

Eligible checklists travel up to 5 km; the near zone radius is also 5 km, so a
travelling checklist near the boundary can be classified into the wrong zone.
Artifact: `D6_travelling_boundary_exposure.csv` (checklist memberships over the
217,200 modeled rows).

| Zone | Checklists | Traveling | over 1 km | over 2.5 km | over 4 km |
|---|---|---|---|---|---|
| Near (any near link) | 26,123 | 66.4% | 35.6% | 11.8% | 2.9% |
| Reference (any ref link) | 81,707 | 69.1% | 36.7% | 14.5% | 3.1% |

About 12% of near-zone checklists are travelling protocols covering more than
2.5 km, and about 3% cover more than 4 km, so a minority sit close enough to the
5 km boundary that the point representation could straddle it. Misclassification
of this kind moves near and reference checklists toward each other, which biases
the interaction **toward the null** (dilution). It is a conservative bias, not
one that manufactures an effect. Recommended explicit sentence in Methods 2.3,
Phase 3 item 10.
