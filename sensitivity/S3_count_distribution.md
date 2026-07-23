# S3 — Count-model distributional check

The primary conditional-count model is Gaussian on `log(numeric_count)` for
positive counts. A standard reviewer objection is that log-transformed counts
with a spike at `log(1) = 0` are poorly served by a Gaussian model. S3 has two
parts: a distributional diagnostic (no fit), and a negative-binomial GLMM
sensitivity (not run; see below).

## Distribution of positive counts (`sensitivity/S3_count_distribution.csv`)

| Species | n positive | frac = 1 | frac <= 2 | median | q95 | max |
|---|---|---|---|---|---|---|
| Bald Eagle | 83,359 | 0.479 | 0.732 | 2 | 7 | 268 |
| Common Raven | 60,940 | 0.491 | 0.786 | 2 | 6 | 200 |
| American Herring Gull | 1,851 | 0.501 | 0.697 | 1 | 14 | 200 |
| Hooded Merganser | 20,340 | 0.283 | 0.585 | 2 | 9 | 173 |
| Common Merganser | 27,776 | 0.242 | 0.481 | 3 | 21 | 976 |
| Iceland Gull | 4,317 | 0.280 | 0.416 | 4 | 210 | 3,500 |
| Long-tailed Duck | 2,946 | 0.212 | 0.373 | 4 | 200 | 7,100 |
| Short-billed Gull | 22,003 | 0.165 | 0.282 | 7 | 180 | 10,000 |
| White-winged Scoter | 4,706 | 0.165 | 0.308 | 6 | 200 | 10,000 |
| Glaucous-winged Gull | 85,053 | 0.154 | 0.308 | 5 | 62 | 30,000 |
| American Crow | 112,180 | 0.151 | 0.334 | 4 | 36 | 25,000 |
| Harlequin Duck | 12,030 | 0.063 | 0.245 | 5 | 30 | 493 |
| Surf Scoter | 16,632 | 0.074 | 0.154 | 12 | 500 | 45,000 |
| Mallard | 81,526 | 0.065 | 0.202 | 10 | 120 | 6,198 |

## What it shows

The spike-at-one concern is real but species-specific, and it lands where it
matters least. The species with the heaviest mass at 1 are Bald Eagle (48%),
Common Raven (49%), and American Herring Gull (50%) - and these are precisely
the species whose flock-size interaction is small or null (Bald Eagle count 1.07,
Common Raven 1.01). For them, "flock size" is largely "one or two birds present,"
and the geometric-mean-ratio interpretation is weak; their count results should
carry little weight regardless of estimator.

The strong flock-size responders have well-spread counts: Surf Scoter (median 12,
7% at one), Mallard (median 10), Short-billed Gull (median 7), White-winged
Scoter (median 6), Harlequin Duck (median 5), Glaucous-winged Gull (median 5).
For these the log-Gaussian model is on much firmer ground, and they are the ones
driving the manuscript's flock-size conclusion.

## Negative-binomial sensitivity: not run

`glmer.nb` with the three crossed random intercepts on the larger positive-count
subsets is as computationally intractable as `nAGQ = 1` (a single fit did not
complete within an hour). It is therefore not run here, for the same reason and
with the same recommendation as S2 (`sensitivity/S2_nAGQ1_note.md`): run it in
the revision compute environment, ideally via `glmmTMB`. The distributional
table above is the direct evidence a reviewer would want, and it points to
reporting the count result primarily for the well-spread species and
down-weighting the eagle and raven count ratios.
