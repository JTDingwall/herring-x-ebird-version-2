# Block-aware random-slope reanalysis: external handoff

**Self-contained briefing.** Every number below is quoted from committed output;
you do not need repository access to use this document. Source of record:
`outputs/post_stage4a_blockaware_v1/` on branch
`codex/blockaware-random-slope-v1` (commit `7288e3f`), GitHub PR #22.

**Purpose.** This reanalysis supersedes the Stage 2 primary-contrast numbers in
the MER manuscript. It changes species counts, every interval, and one
manuscript section. Use it to revise the manuscript. Do not re-derive the
statistics; they are final unless flagged otherwise below.

---

## 1. What changed, in one paragraph

The Stage 2 specification put a random *intercept* on event block. That absorbs
differences in level between region-years but leaves heterogeneity in the
*slope* — the direction the estimand is actually defined on — in the residual,
so the published intervals were too narrow. This run replaces that intercept
with a correlated event-block intercept **plus one random slope in the
normalized active-minus-pre14 contrast direction**, for the full fixed
49-species family and both outcomes, and recomputes the primary contrast and
Benjamini-Hochberg from the new fits. Nothing else about the model changed.

## 2. Headline result

| Outcome | Stage 2 (fixed-49) | Block-aware | Change |
|---|---|---|---|
| Count, positive direction | 19 | **15** | −4 |
| Reporting, positive direction | 13 | **13** | 0 |
| Reporting, negative direction | 2 | **3** | +1 |

The effect is real; the precision was overstated. Every estimable interval is
wider than its Stage 2 counterpart — median 1.18× (reporting) and 1.16× (count),
maximum 2.74×. The species that dropped out were the marginal ones. The largest
effects did not move.

Baseline note: the Stage 2 fixed-49 baseline is **19 count and 13 positive
reporting**, not 20 and 13. Any manuscript text or figure gate citing "20 count"
is wrong independently of this reanalysis.

## 3. Method, for the Methods section

- **Random effects.** Correlated event-block intercept and slope; observer
  cluster and generalized location cluster random intercepts, unchanged. Two
  variance parameters and one correlation on event block. One slope on the exact
  linear combination being estimated, not twelve separate slopes.
- **Slope predictor.** If `c` is the registered fixed-effect contrast vector,
  the row-level predictor is `Xc/(c'c)`, so a unit random-slope deviation moves
  `c'beta` by one unit on the link scale.
- **Fixed effects.** Unchanged from Stage 2, including `minutes_from_sunrise`
  and both annual harmonic pairs.
- **Engines.** Counts: `lmerTest::lmer`, REML (identical to `lme4::lmer`, with
  the stored deviance function the Satterthwaite correction needs — verified on
  three species to give identical fixed effects and variance components).
  Reporting: `lme4::glmer`, binomial, `nAGQ=0`. Optimizer `nloptwrap`,
  `maxeval=10000`.
- **Count intervals.** Kenward-Roger via `pbkrtest`, which corrects both the
  standard error and the denominator degrees of freedom. See §7 for the 25
  species where it could not run.
- **Reporting intervals.** Kenward-Roger does not apply to a binomial GLMM and
  `lmerTest` offers no Satterthwaite denominator for a `glmerMod`, so all
  reporting intervals are the prespecified Wald. **These must be labelled the
  weaker inference.** No cluster-robust (CR0/CR1) variance was computed.
- **Multiplicity.** Benjamini-Hochberg within the fixed 49-species family, per
  outcome, family size 49, with non-estimable models assigned p = 1. The family
  membership did not change.
- **Population.** Strait of Georgia, 2005–2025, 217,200 checklists, 58 event
  blocks but only **21.7 effective clusters** by inverse Herfindahl. No 2026+
  records were read.

## 4. Species that changed Benjamini-Hochberg status

Mechanism is assigned by counterfactual Benjamini-Hochberg over the same fixed
family: `widening_only` pairs the Stage 2 point estimate with the block-aware
standard error and df; `point_movement_only` pairs the block-aware point
estimate with the Stage 2 standard error. Whichever counterfactual loses the
species is the mechanism.

### Count: four left, none entered

| Species | Stage 2 log-effect | Block-aware | Shift | Width ratio | Mechanism |
|---|---|---|---|---|---|
| Iceland Gull | 0.2120 | 0.1100 | −48% | 1.38 | point-estimate movement |
| Mallard | 0.0602 | 0.0398 | −34% | 1.82 | interval widening |
| Canada Goose | 0.0634 | 0.0394 | −38% | 1.55 | both |
| Common Loon | 0.0530 | 0.0198 | −63% | 1.44 | both |

All four fell in magnitude; in three the widening alone was also sufficient.

### Reporting: four left, five entered

Left: **Bald Eagle** (point movement), **Harlequin Duck** (point movement),
**Northern Pintail** (widening), **Iceland Gull** (neither alone — only the two
jointly).

Entered: **Glaucous Gull**, **Black Scoter**, **Long-tailed Duck**,
**White-winged Scoter**, **Black Oystercatcher**. All five moved *away* from
zero by 159–279% while widening only 34–56%; the movement outran the widening.

Bald Eagle deserves attention: it left on a 13% shift (0.0625 → 0.0544) with a
width ratio of 1.006, essentially no widening. It was marginal all along.

### The three negative-direction reporting results, reported separately

| Species | Ratio | 95% CI | q |
|---|---|---|---|
| Black Oystercatcher | 0.838 | 0.739–0.950 | 0.0212 |
| Bufflehead | 0.922 | 0.869–0.979 | 0.0253 |
| Common Raven | 0.941 | 0.895–0.989 | 0.0498 |

Black Oystercatcher is new (Stage 2 estimate −0.0467 → −0.1773). **Common
Raven's q = 0.0498 sits inside the threshold by a hair** and would not survive a
marginally different family; treat it as fragile.

## 5. Event-block slope variance, a result in its own right

The ten-species diagnostic generalises: slope heterogeneity is **not** near
zero across the family, but it is concentrated rather than pervasive.

| Outcome | Slope SD median | Quartiles | Range | At or below the frozen 0.0025 variance threshold |
|---|---|---|---|---|
| Reporting (48 estimable) | 0.125 | 0.067 / 0.209 | 0.004–1.042 | 8 of 48 |
| Count (46 estimable) | 0.058 | 0.029 / 0.120 | 0.005–0.424 | 19 of 46 |

Largest count slope SDs: Surf Scoter 0.424 (reproduces the diagnostic exactly),
Bonaparte's Gull 0.318, Western Grebe 0.307, Pacific Loon 0.209, Greater Scaup
0.200. On the multiplicative scale a one-SD block deviation moves Surf Scoter's
active-minus-pre count ratio between about 0.92 and 2.16.

Largest reporting slope SDs: Glaucous Gull 1.042, Brant 0.424, Lesser Scaup
0.424, Black Scoter 0.411, Bonaparte's Gull 0.398. Glaucous Gull's spread (about
0.94 to 7.55 across region-years) is extreme and it has the smallest count
support in the family (n = 185); read it cautiously.

The intercept-slope correlation is **poorly identified** — quartiles span −0.877
to +1.000 (reporting) and −0.907 to +0.451 (count), with boundary values of
exactly ±1. Do not interpret it substantively.

## 6. Full per-species results

### Count outcome, all 49 species

| Species | n | Ratio | 95% CI | q (BH-49) | BH | Stage 2 ratio | Width ratio | Method | df | Slope SD | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Bald Eagle | 83,359 | 1.073 | 1.055-1.092 | 4.3e-10 | **yes** | 1.079 | 1.09 | Satt | 76.6 | 0.014 | ok |
| Common Goldeneye | 21,195 | 1.179 | 1.130-1.230 | 1.7e-09 | **yes** | 1.185 | 1.06 | Satt | 67.8 | 0.023 | ok |
| Common Merganser | 27,776 | 1.118 | 1.074-1.163 | 7.2e-07 | **yes** | 1.116 | 1.00 | Satt | 5387.2 | 0.009 | singular_warning |
| Short-billed Gull | 22,003 | 1.334 | 1.212-1.467 | 8.0e-06 | **yes** | 1.310 | 1.71 | Satt | 32.7 | 0.169 | ok |
| Long-tailed Duck | 2,946 | 1.405 | 1.226-1.609 | 4.5e-05 | **yes** | 1.472 | 1.21 | KR | 65.8 | 0.122 | ok |
| Glaucous-winged Gull | 85,053 | 1.160 | 1.089-1.236 | 0.0002 | **yes** | 1.205 | 2.15 | Satt | 33.7 | 0.145 | ok |
| Pacific Loon | 6,049 | 1.387 | 1.200-1.603 | 0.0002 | **yes** | 1.175 | 1.32 | KR | 59.0 | 0.209 | singular_warning |
| Bufflehead | 50,039 | 1.083 | 1.046-1.122 | 0.0003 | **yes** | 1.105 | 1.33 | Satt | 31.8 | 0.051 | ok |
| Harlequin Duck | 12,030 | 1.160 | 1.085-1.240 | 0.0004 | **yes** | 1.214 | 1.45 | Satt | 32.1 | 0.098 | ok |
| Double-crested Cormorant | 29,011 | 1.111 | 1.058-1.166 | 0.0004 | **yes** | 1.102 | 1.12 | Satt | 43.2 | 0.048 | ok |
| California Gull | 6,644 | 1.269 | 1.128-1.427 | 0.0008 | **yes** | 1.179 | 1.46 | KR | 44.1 | 0.174 | ok |
| Red-breasted Merganser | 13,364 | 1.134 | 1.064-1.208 | 0.0012 | **yes** | 1.139 | 1.15 | Satt | 33.5 | 0.053 | ok |
| Greater Scaup | 4,514 | 1.294 | 1.110-1.508 | 0.0056 | **yes** | 1.197 | 1.43 | KR | 42.2 | 0.200 | ok |
| Surf Scoter | 16,632 | 1.411 | 1.160-1.715 | 0.0074 | **yes** | 1.330 | 2.74 | Satt | 13.5 | 0.424 | ok |
| White-winged Scoter | 4,706 | 1.166 | 1.043-1.304 | 0.0247 | **yes** | 1.161 | 1.06 | KR | 102.3 | 0.024 | ok |
| American Wigeon | 34,665 | 1.055 | 1.010-1.102 | 0.0513 | no | 1.053 | 1.00 | Satt | 8358.1 | 0.005 | singular_warning |
| Black Turnstone | 4,421 | 1.141 | 0.995-1.308 | 0.1640 | no | 1.127 | 1.05 | KR | 166.0 | 0.051 | singular_warning |
| Bonaparte's Gull | 4,025 | 1.408 | 0.985-2.013 | 0.1640 | no | 1.251 | 1.16 | KR | 156.4 | 0.318 | ok |
| Western Gull | 712 | 1.091 | 0.981-1.212 | 0.2572 | no | 1.088 | 1.38 | KR | 14.5 | 0.029 | singular_warning |
| Mallard | 81,526 | 1.041 | 0.990-1.093 | 0.2610 | no | 1.062 | 1.82 | Satt | 15.2 | 0.088 | ok |
| Iceland Gull | 4,317 | 1.116 | 0.971-1.283 | 0.2660 | no | 1.236 | 1.38 | KR | 52.3 | 0.199 | convergence_warning |
| Northern Pintail | 14,278 | 1.069 | 0.984-1.162 | 0.2660 | no | 1.060 | 1.12 | Satt | 79.9 | 0.084 | singular_warning |
| Canada Goose | 68,271 | 1.040 | 0.985-1.098 | 0.3119 | no | 1.065 | 1.55 | Satt | 26.4 | 0.092 | ok |
| American Herring Gull | 1,851 | 1.059 | 0.974-1.151 | 0.3660 | no | 1.066 | 1.06 | KR | 104.1 | 0.024 | singular_warning |
| Pelagic Cormorant | 18,881 | 1.028 | 0.978-1.081 | 0.5236 | no | 1.027 | 1.11 | Satt | 34.5 | 0.038 | ok |
| Black Scoter | 1,684 | 1.082 | 0.915-1.278 | 0.6155 | no | 1.046 | 1.23 | KR | 55.3 | 0.119 | ok |
| Hooded Merganser | 20,340 | 1.020 | 0.978-1.065 | 0.6155 | no | 1.023 | 1.14 | Satt | 32.4 | 0.030 | ok |
| Red-necked Grebe | 8,109 | 1.032 | 0.968-1.100 | 0.6155 | no | 1.029 | 1.05 | Satt | 242.9 | 0.040 | singular_warning |
| Black-bellied Plover | 3,973 | 0.959 | 0.852-1.079 | 0.6694 | no | 0.961 | 1.08 | KR | 78.2 | 0.023 | singular_warning |
| Brandt's Cormorant | 2,573 | 1.060 | 0.914-1.229 | 0.6694 | no | 1.051 | 1.06 | KR | 125.6 | 0.075 | ok |
| Common Loon | 15,359 | 1.020 | 0.969-1.074 | 0.6694 | no | 1.054 | 1.44 | Satt | 26.7 | 0.074 | ok |
| Horned Grebe | 13,054 | 1.019 | 0.967-1.074 | 0.6694 | no | 1.024 | 1.21 | Satt | 46.5 | 0.056 | ok |
| Marbled Murrelet | 3,103 | 1.066 | 0.916-1.241 | 0.6694 | no | 1.059 | 1.03 | KR | 260.4 | 0.025 | singular_warning |
| Red-throated Loon | 1,488 | 1.079 | 0.898-1.296 | 0.6694 | no | 1.082 | 1.03 | KR | 229.0 | 0.027 | singular_warning |
| Western Grebe | 1,346 | 1.159 | 0.771-1.743 | 0.6694 | no | 1.065 | 1.19 | KR | 113.6 | 0.307 | singular_warning |
| Common Raven | 60,940 | 1.005 | 0.987-1.024 | 0.7992 | no | 0.999 | 1.05 | Satt | 268.0 | 0.015 | singular_warning |
| Brant | 3,796 | 1.035 | 0.894-1.200 | 0.8405 | no | 1.071 | 1.44 | KR | 40.4 | 0.183 | ok |
| Common Murre | 2,023 | 0.946 | 0.734-1.218 | 0.8542 | no | 0.898 | 1.09 | KR | 116.8 | 0.120 | singular_warning |
| American Crow | 112,180 | 1.004 | 0.975-1.034 | 0.9552 | no | 1.012 | 1.25 | Satt | 41.9 | 0.036 | ok |
| Barrow's Goldeneye | 10,960 | 1.008 | 0.915-1.111 | 0.9552 | no | 1.028 | 1.25 | Satt | 35.3 | 0.111 | ok |
| Black Oystercatcher | 13,626 | 0.996 | 0.948-1.045 | 0.9552 | no | 0.992 | 1.16 | Satt | 27.5 | 0.042 | ok |
| Great Blue Heron | 50,285 | 0.995 | 0.956-1.035 | 0.9552 | no | 1.014 | 1.47 | Satt | 20.9 | 0.060 | ok |
| Lesser Scaup | 9,378 | 1.014 | 0.891-1.154 | 0.9552 | no | 0.998 | 1.15 | Satt | 53.4 | 0.115 | ok |
| Pigeon Guillemot | 6,342 | 1.007 | 0.926-1.095 | 0.9552 | no | 1.014 | 1.07 | KR | 156.0 | 0.047 | ok |
| Ring-billed Gull | 4,549 | 0.983 | 0.844-1.145 | 0.9552 | no | 0.985 | 1.31 | KR | 15.6 | 0.006 | singular_warning |
| Dunlin | 5,908 | 1.007 | 0.864-1.174 | 0.9868 | no | 0.986 | 1.10 | KR | 85.3 | 0.091 | ok |
| Glaucous Gull | 185 | n/a | n/a-n/a | 1.0000 | no | n/a | n/a | none | inf | n/a | failed_insufficient_support |
| Rhinoceros Auklet | 1,816 | n/a | n/a-n/a | 1.0000 | no | n/a | n/a | none | inf | n/a | failed_insufficient_support |
| Surfbird | 1,063 | n/a | n/a-n/a | 1.0000 | no | n/a | n/a | none | inf | n/a | failed_insufficient_support |

### Reporting outcome, all 49 species

| Species | n | Ratio | 95% CI | q (BH-49) | BH | Stage 2 ratio | Width ratio | Method | df | Slope SD | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| California Gull | 217,200 | 1.358 | 1.217-1.515 | 1.8e-06 | **yes** | 1.314 | 1.33 | Wald | inf | 0.163 | ok |
| Short-billed Gull | 217,200 | 1.237 | 1.145-1.337 | 1.8e-06 | **yes** | 1.254 | 1.18 | Wald | inf | 0.091 | ok |
| Brant | 217,200 | 1.532 | 1.276-1.840 | 8.2e-05 | **yes** | 1.163 | 1.65 | Wald | inf | 0.424 | singular_warning |
| Bonaparte's Gull | 217,200 | 1.746 | 1.364-2.236 | 0.0001 | **yes** | 1.400 | 1.28 | Wald | inf | 0.398 | ok |
| Black Scoter | 217,178 | 1.486 | 1.224-1.802 | 0.0004 | **yes** | 1.139 | 1.45 | Wald | inf | 0.411 | ok |
| Long-tailed Duck | 217,200 | 1.439 | 1.206-1.719 | 0.0004 | **yes** | 1.129 | 1.46 | Wald | inf | 0.374 | singular_warning |
| White-winged Scoter | 217,199 | 1.327 | 1.156-1.524 | 0.0004 | **yes** | 1.097 | 1.34 | Wald | inf | 0.266 | singular_warning |
| Common Merganser | 217,093 | 1.230 | 1.099-1.377 | 0.0019 | **yes** | 1.171 | 1.89 | Wald | inf | 0.248 | ok |
| Glaucous Gull | 217,200 | 2.664 | 1.486-4.776 | 0.0054 | **yes** | 1.459 | 1.56 | Wald | inf | 1.042 | singular_warning |
| Glaucous-winged Gull | 217,037 | 1.118 | 1.045-1.196 | 0.0063 | **yes** | 1.138 | 1.22 | Wald | inf | 0.085 | ok |
| Lesser Scaup | 216,290 | 1.409 | 1.136-1.748 | 0.0081 | **yes** | 1.318 | 1.54 | Wald | inf | 0.424 | ok |
| American Herring Gull | 217,179 | 1.231 | 1.065-1.422 | 0.0197 | **yes** | 1.409 | 1.19 | Wald | inf | 0.197 | singular_warning |
| Black Oystercatcher | 217,200 | 0.838 | 0.739-0.950 | 0.0212 | **yes** | 0.954 | 1.51 | Wald | inf | 0.267 | ok |
| Bufflehead | 217,200 | 0.922 | 0.869-0.978 | 0.0253 | **yes** | 0.929 | 1.02 | Wald | inf | 0.035 | singular_warning |
| American Wigeon | 217,190 | 1.089 | 1.020-1.163 | 0.0343 | **yes** | 1.088 | 1.07 | Wald | inf | 0.063 | singular_warning |
| Common Raven | 217,200 | 0.941 | 0.895-0.989 | 0.0498 | **yes** | 0.929 | 1.04 | Wald | inf | 0.031 | ok |
| Iceland Gull | 217,184 | 1.145 | 1.024-1.280 | 0.0511 | no | 1.317 | 1.21 | Wald | inf | 0.178 | singular_warning |
| Bald Eagle | 217,199 | 1.056 | 1.007-1.107 | 0.0632 | no | 1.064 | 1.01 | Wald | inf | 0.015 | singular_warning |
| Northern Pintail | 217,200 | 1.135 | 1.007-1.279 | 0.0963 | no | 1.160 | 1.26 | Wald | inf | 0.168 | ok |
| Red-breasted Merganser | 217,092 | 0.912 | 0.834-0.998 | 0.0990 | no | 0.979 | 1.18 | Wald | inf | 0.144 | singular_warning |
| Red-necked Grebe | 217,200 | 1.121 | 1.002-1.255 | 0.0990 | no | 1.068 | 1.22 | Wald | inf | 0.149 | ok |
| Surfbird | 217,200 | 1.453 | 1.006-2.100 | 0.0990 | no | 1.356 | 1.03 | Wald | inf | 0.175 | singular_warning |
| Western Gull | 216,824 | 1.318 | 1.011-1.717 | 0.0990 | no | 1.253 | 1.01 | Wald | inf | 0.074 | singular_warning |
| Black Turnstone | 217,200 | 0.872 | 0.746-1.019 | 0.1746 | no | 0.983 | 1.15 | Wald | inf | 0.225 | singular_warning |
| Common Loon | 217,199 | 0.934 | 0.862-1.013 | 0.1963 | no | 0.937 | 1.10 | Wald | inf | 0.066 | ok |
| American Crow | 217,200 | 1.046 | 0.990-1.105 | 0.2070 | no | 1.034 | 1.13 | Wald | inf | 0.060 | ok |
| Horned Grebe | 217,142 | 0.942 | 0.872-1.017 | 0.2327 | no | 0.926 | 1.01 | Wald | inf | 0.039 | singular_warning |
| Western Grebe | 217,186 | 0.823 | 0.625-1.082 | 0.2859 | no | 0.776 | 1.18 | Wald | inf | 0.373 | ok |
| Harlequin Duck | 217,200 | 1.074 | 0.963-1.197 | 0.3385 | no | 1.152 | 1.15 | Wald | inf | 0.151 | ok |
| Rhinoceros Auklet | 217,200 | 0.849 | 0.640-1.127 | 0.4204 | no | 0.783 | 1.02 | Wald | inf | 0.144 | singular_warning |
| Pigeon Guillemot | 217,200 | 0.931 | 0.819-1.057 | 0.4280 | no | 0.981 | 1.05 | Wald | inf | 0.106 | ok |
| Common Goldeneye | 216,892 | 1.040 | 0.958-1.129 | 0.5200 | no | 0.989 | 1.24 | Wald | inf | 0.107 | ok |
| Dunlin | 217,200 | 0.945 | 0.840-1.063 | 0.5200 | no | 1.011 | 1.06 | Wald | inf | 0.106 | ok |
| Pelagic Cormorant | 217,200 | 1.041 | 0.953-1.138 | 0.5391 | no | 1.055 | 1.07 | Wald | inf | 0.078 | ok |
| Double-crested Cormorant | 217,200 | 1.033 | 0.952-1.120 | 0.6191 | no | 1.007 | 1.19 | Wald | inf | 0.099 | ok |
| Greater Scaup | 216,227 | 1.044 | 0.928-1.175 | 0.6400 | no | 1.103 | 1.28 | Wald | inf | 0.159 | ok |
| Pacific Loon | 217,200 | 0.958 | 0.848-1.081 | 0.6428 | no | 0.931 | 1.18 | Wald | inf | 0.126 | ok |
| Barrow's Goldeneye | 216,814 | 1.037 | 0.917-1.172 | 0.6891 | no | 1.032 | 1.40 | Wald | inf | 0.203 | ok |
| Canada Goose | 217,083 | 0.983 | 0.932-1.037 | 0.6891 | no | 0.978 | 1.00 | Wald | inf | 0.014 | singular_warning |
| Surf Scoter | 217,183 | 1.028 | 0.939-1.125 | 0.6891 | no | 1.017 | 1.24 | Wald | inf | 0.114 | ok |
| Great Blue Heron | 217,200 | 1.013 | 0.958-1.071 | 0.7794 | no | 1.012 | 1.00 | Wald | inf | 0.004 | singular_warning |
| Black-bellied Plover | 217,200 | 0.974 | 0.856-1.108 | 0.8059 | no | 0.979 | 1.00 | Wald | inf | 0.006 | singular_warning |
| Brandt's Cormorant | 217,200 | 0.970 | 0.824-1.142 | 0.8127 | no | 1.016 | 1.04 | Wald | inf | 0.122 | singular_warning |
| Marbled Murrelet | 217,200 | 0.975 | 0.795-1.194 | 0.8759 | no | 0.959 | 1.00 | Wald | inf | 0.051 | ok |
| Red-throated Loon | 217,200 | 0.962 | 0.709-1.303 | 0.8759 | no | 0.992 | 1.10 | Wald | inf | 0.340 | singular_warning |
| Hooded Merganser | 217,200 | 1.007 | 0.917-1.106 | 0.9181 | no | 0.980 | 1.23 | Wald | inf | 0.124 | ok |
| Ring-billed Gull | 217,200 | 0.990 | 0.868-1.127 | 0.9181 | no | 1.024 | 1.02 | Wald | inf | 0.068 | singular_warning |
| Common Murre | 217,200 | n/a | n/a-n/a | 1.0000 | no | 0.851 | n/a | none | inf | n/a | failed_numerical_fit_no_fallback |
| Mallard | 217,200 | 1.000 | 0.945-1.058 | 1.0000 | no | 1.008 | 1.02 | Wald | inf | 0.032 | singular_warning |

Column notes. `Width ratio` is the block-aware interval width divided by the
Stage 2 width. `Method` is the interval actually used: KR = Kenward-Roger,
Satt = Satterthwaite denominator df, Wald = normal-reference Wald. `df` is the
denominator degrees of freedom (`inf` = normal reference). `Slope SD` is the
event-block random-slope standard deviation. `singular_warning` means the fit hit
a variance boundary. Rows with `n/a` are non-estimable and carry p = 1 in the
Benjamini-Hochberg family.

---

## 7. The one methodological caveat that must appear in the paper

**Kenward-Roger, the prespecified count interval, ran for only 21 of the 46
estimable count models.**

`pbkrtest::vcovAdj` computes `chol2inv(chol(Sigma))` where `Sigma` is the n × n
marginal covariance matrix, and that inverse is dense. The working set therefore
grows as n² and the runtime as roughly n^2.6. Measured on the analysis machine
(31.5 GB RAM): 22 s at n = 2,023; 713–808 s at n = 8,109 with a peak near 13 GB.
The count models run from n = 185 to n = 112,180 with a median of 8,109, so the
larger half is unreachable — American Crow at n = 112,180 projects to about
1,400 GB. A row cap of 7,723 (from a 12 GB budget) decides the split.

The other 25 species fall back to the **Satterthwaite denominator correction**,
which corrects the degrees of freedom but **not** the standard error, and is
therefore mildly anti-conservative relative to Kenward-Roger. Quantified on the
21 species where both were computable:

- Kenward-Roger SE / Wald SE: median **1.034**, range 1.018–1.212. So the SE
  correction the fallback misses is about 3% typically, at most 21%.
- Kenward-Roger df: median 85.3, range **14.5–260.4**.
- Satterthwaite df: median 98.6, range **4.3–3,704**.
- Disagreements at nominal 0.05 between the two methods: **zero of 21**.

Two things follow. First, the df correction matters and varies enormously —
Ring-billed Gull's Kenward-Roger df is 15.6, close to the 21.7 effective
clusters, while Red-throated Loon's is 229. Satterthwaite's 3,704 upper end shows
it can be far too generous on particular species. Second, and importantly for
the manuscript's defensibility: **substituting a uniform Satterthwaite family, or
a uniform Wald family, for the mixed primary column changes neither tally** — 15
count and 13 positive reporting under all three. The result is not an artefact of
mixing interval methods.

Suggested framing: report the tallies as given, state that Kenward-Roger was
applied wherever computationally feasible and the Satterthwaite denominator
correction elsewhere, give the SE-ratio range above, and note the
method-invariance of the tally. A full Kenward-Roger family would need a
Woodbury-identity implementation that avoids the dense inverse; that is new
methodology, not a settings change.

## 8. Convergence and estimability, retained not dropped

| Status | Reporting | Count |
|---|---|---|
| completed | 26 | 30 |
| completed, singular warning | 22 | 15 |
| completed, convergence warning | 0 | 1 |
| failed, insufficient support | 0 | 3 |
| failed, numerical fit | 1 | 0 |

- The three count models with insufficient support are the same three as at
  Stage 2 — Surfbird (n = 1,063), Rhinoceros Auklet (n = 1,816), Glaucous Gull
  (n = 185). No regression.
- **Common Murre reporting, estimable at Stage 2, now fails outright** under the
  random slope (`failed_numerical_fit_no_fallback`). It is retained in the family
  with p = 1, not dropped. It was not a Stage 2 survivor, so no result is lost,
  but the reporting family is 48 estimable models, not 49.
- Iceland Gull's count model completes with a convergence warning
  (max |gradient| 0.104) and is retained. It is also one of the four count
  species that left, so warning and loss should be read together.
- 37 of 94 estimable fits are singular at the boundary. That is what a slope
  variance genuinely at zero looks like for part of the family. It is a caveat on
  the intercept-slope correlation, not on the fixed-effect contrast.

## 9. The bootstrap was deliberately not run

The 999-replicate event-block bootstrap was **not** run, on methodological
grounds rather than cost. One-way resampling of event blocks cannot preserve the
crossed dependence in the design: checklists partition cleanly by block, but
**2,495 of 29,248 observer clusters (8.5%) and 4,631 of 22,980 location clusters
(20.2%) cross more than one block**. Resampling blocks as exchangeable units
would tear those clusters apart and misstate the dependence the bootstrap is
meant to capture. A resampling design respecting both crossed factors is a
separate methodological extension. (The projection was also prohibitive: 97,902
fits, 1,754 core-hours, 6.6 wall-clock days.)

If a referee asks for a bootstrap, this is the answer: not omitted, but
inapplicable in its one-way form.

## 10. Manuscript edits this forces

1. **Delete the §4.4 claim that the one separately estimable block variance was
   zero.** It is falsified. Replace with the §5 distribution above. Rewrite,
   do not defend.
2. **Change the count tally from 19 to 15** everywhere, and check for any
   surviving "20 count" text, which was wrong before this run.
3. **Restate every per-species interval** in the primary-contrast tables from §6.
   All of them widened.
4. **Add the third negative-direction reporting species** (Black Oystercatcher)
   and keep the negative results reported separately from the positive ones.
5. **Remove Bald Eagle from the reporting survivor set.** If Bald Eagle is used
   as a worked example anywhere, that passage needs rewriting — it is now a
   non-survivor that left on almost no widening.
6. **Add the Kenward-Roger feasibility caveat** from §7 to the Methods, with the
   SE-ratio range and the method-invariance statement.
7. **Label the reporting inference as the weaker of the two** wherever both
   outcomes are presented together.
8. **Note Common Murre reporting as non-estimable** under the block-aware
   specification.
9. **Figures are stale and must be regenerated after these edits.** They plot
   per-species estimates and BH status, both of which changed. The existing
   figure instructions contain a hard gate of "20 count and 13 reporting" — that
   gate is wrong twice over and must become **15 and 13** before anyone runs it.
   Filled points for BH survivors, open for the rest; BH status must come from
   the block-aware `q_value_bh_fixed49` column, not Stage 2 and not the published
   run.

## 11. Claims that can no longer be made

1. That the one separately estimable block variance was zero.
2. That 19 count species survive Benjamini-Hochberg. It is 15.
3. That the published intervals are correct. All widened, median ~16–18%.
4. That the reporting result is only ever positive. Three negatives now.
5. That Bald Eagle survives Benjamini-Hochberg on reporting.
6. That the count intervals are uniformly Kenward-Roger corrected.
7. That every family member is estimable under this specification.

**What survives unchanged:** the direction and rough magnitude of the headline
results. Fifteen count and thirteen positive reporting species still clear
Benjamini-Hochberg with a random slope in the estimand's own direction, and the
largest effects — Surf Scoter, Long-tailed Duck, Pacific Loon, Short-billed Gull
on counts; Glaucous Gull, Bonaparte's Gull, Brant on reporting — are not the ones
that moved. The honest one-line summary: **the effect is real, the precision was
overstated, and the count family is a quarter smaller than published.**

## 12. Guardrails for whoever uses this document

- Do not recompute or "improve" these estimates. They come from a gated,
  hash-verified run against protected data you do not have.
- Do not infer any number not printed here. In particular, do not interpolate
  Kenward-Roger values for the 25 species where it was not computed.
- The 2026–2028 holdout was not touched and must stay untouched.
- If a number here contradicts an older manuscript draft, audit file, or figure,
  **this document is the later source** — but flag the contradiction rather than
  silently overwriting, because several stale artefacts (including a "20 count"
  gate) are known to exist in the repository.
- Reporting intervals are Wald and weaker. Do not present them as equivalent in
  strength to the count intervals.

---

*Generated from `outputs/post_stage4a_blockaware_v1/` (7 files, all SHA-256
manifest hashes verified). Run: 8,848 s total — 6,108 s fitting across 5 workers,
2,716 s serial Kenward-Roger. R 4.5.1, lme4 2.0-6, pbkrtest 0.5.5, lmerTest
3.2.1; the last two installed in a separate versioned analysis library with the
frozen renv library and lockfile verified unchanged. 65 unit tests pass.*
