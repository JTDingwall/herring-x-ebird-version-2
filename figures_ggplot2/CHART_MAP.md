# Stage 2 figure chart map

All panels answer a manuscript question using privacy-safe aggregate Stage 2
outputs. The shared visual grammar is defined in `00_theme_mer.R`: marine blue
for checklist reporting, ochre for reported number, open marks for estimates
that do not meet the stated positive-BH rule, and the existing MER sans-serif
theme.

| Output | Question | Chart family | Data and encodings | Intended takeaway |
|---|---|---|---|---|
| Figure 1 | How does the study design produce the two response contrasts? | Schematic | Boxes and arrows only; no estimates | The same event-anchored design feeds reporting and count models. |
| Figure 2 | Which of the 49 species show active-minus-pre effects? | Two-panel forest | x = ratio on log scale; y = species; colour/shape = outcome; fill = positive BH survivor | Count effects are more consistently positive than reporting effects. |
| Figure 3 | How do eight ecologically varied species change through event time? | Small-multiple profiles | x = four event periods; y = same-species ratio to baseline; colour/type = outcome; whiskers = 95% CI | Species differ in timing and the two outcomes can separate. |
| Figure 4 | How are count ratios distributed over event time across estimable species? | Dot-and-box distribution | x = four periods plus active composite; y = ratio; dots = species; diamond = mean | The family-wide count distribution shifts most during the active windows. |
| Figure 5 | How do three species' profiles vary over 2-km distance bands? | Faceted distance profiles | x = 13 distance bands; y = same-band ratio to baseline; colour/type = period; ribbon = 95% CI | Waterbird responses are spatially localized; American Robin is a comparison species only. |
| Figure S1 | Is there pre-onset drift? | Faceted dot distribution | x = two pre-onset windows; y = ratio; fill = BH status; annotation = median and BH count | Pre-onset estimates center close to one. |
| Figure S2 | What are the complete count-response profiles? | Cluster-ordered heatmap | x = five periods; y = 46 estimable species; fill = log ratio; Ward.D2 orders rows only | Count timing is heterogeneous rather than a set of tested clusters. |

QA gates are implemented in the scripts: input key uniqueness, fixed family
cardinality, the exact 13 reporting and 20 count positive-BH survivor counts,
finite interval checks, 46 estimable count species for Figures 4/S2, 13 bands
for every Figure 5 species-outcome-period combination, and non-empty PDF/PNG
exports.
