# Descriptive clustering of species response profiles

## Verdict

Clustering does **not** recover a sufficiently stable, precision-robust version of the seven pre-assigned guilds. Feature Set A repeatedly separates a high-response, early-egg-count subset enriched for diving sea ducks and gulls, but its membership and even the selected number of clusters change with precision handling; Feature Set B is weaker, includes unstable clusters, and is sensitive to the clustering algorithm. **I would not put this clustering analysis in the paper**: it is useful as a negative robustness check, but it does not independently validate the guild boundaries.

The modest guild correspondence is real in the narrow permutation sense, especially for Feature Set A, but it is not strong recovery. Adjusted Rand indices range from 0.043 to 0.214, and the partitions disagree materially across weighting schemes and with PAM.

## 1. Feature sets, precision treatments, and analysis population

All features were kept on the link scale. Guild identity was excluded from feature construction, transformations, distances, clustering, selection of \(k\), and stability calculations. The species registry was joined only after every cluster solution had been fixed.

Feature Set A used four features:

1. active-minus-pre-onset checklist-reporting contrast;
2. active-minus-pre-onset reported-number contrast;
3. spawn-start-minus-early-egg checklist-reporting contrast; and
4. spawn-start-minus-early-egg reported-number contrast.

Feature Set B used the six archived `did_` period-versus-baseline estimates for each outcome, in the declared event-time order, for 12 features total.

The three predeclared precision treatments were:

- **Unweighted:** each raw feature was centred and divided by its across-species standard deviation.
- **Inverse variance:** the standardized value in each species-feature cell was multiplied by the square root of its inverse variance divided by the feature's mean inverse variance. Thus squared Euclidean contributions carried relative precision weight while the average relative weight of each feature remained one. Timing features used `exact_timing_standard_error`; active-minus-pre and full-period features used their archived standard errors. The weighted matrix was not re-standardized afterward because doing so would partly erase the intended precision weighting.
- **Reliability shrunk:** each feature was treated as a normal-normal measurement problem. The family mean was inverse-variance weighted, the between-species variance used the DerSimonian-Laird moment estimator, and each estimate was shrunk toward that mean by \(\tau^2/(\tau^2+SE_i^2)\). Posterior means were then standardized feature by feature.

Both feature sets had exactly 46 complete cases. The only exclusions were:

- **Glaucous Gull:** neither outcome estimable;
- **Rhinoceros Auklet:** reported-number model not estimable; and
- **Surfbird:** reported-number model not estimable.

No species was excluded for prevalence, interval width, leverage, cluster membership, or any post-result criterion. No imputed analysis was run because it was optional and the complete-case population reconciled exactly with the expected estimability pattern.

## 2. Choice of \(k\)

Ward.D2 hierarchical clustering on Euclidean distance was the primary method. For every feature-set/scheme combination, the same rule selected \(k\): the gap statistic's `firstSEmax` rule across \(k=2,\ldots,8\), using 500 reference bootstraps. Silhouette widths were reported but did not override that rule.

Five of six runs selected \(k=2\). Feature Set A under inverse-variance weighting selected \(k=3\), although its silhouette maximum was at \(k=2\); the third cluster is Bald Eagle alone. The diagnostics therefore provide no basis for describing a general three-group structure.

| Set | Scheme | k | Silhouette | Gap | Gap SE | Selected |
|---|---|---:|---:|---:|---:|:---:|
| A | unweighted | 2 | 0.302 | 0.640 | 0.079 | yes |
| A | unweighted | 3 | 0.188 | 0.600 | 0.081 |  |
| A | unweighted | 4 | 0.207 | 0.568 | 0.081 |  |
| A | unweighted | 5 | 0.207 | 0.580 | 0.084 |  |
| A | unweighted | 6 | 0.217 | 0.597 | 0.084 |  |
| A | unweighted | 7 | 0.221 | 0.581 | 0.087 |  |
| A | unweighted | 8 | 0.226 | 0.592 | 0.089 |  |
| A | inverse variance | 2 | 0.632 | 0.701 | 0.088 |  |
| A | inverse variance | 3 | 0.248 | 0.725 | 0.085 | yes |
| A | inverse variance | 4 | 0.256 | 0.779 | 0.084 |  |
| A | inverse variance | 5 | 0.280 | 0.797 | 0.084 |  |
| A | inverse variance | 6 | 0.271 | 0.790 | 0.084 |  |
| A | inverse variance | 7 | 0.212 | 0.806 | 0.086 |  |
| A | inverse variance | 8 | 0.206 | 0.798 | 0.088 |  |
| A | reliability shrunk | 2 | 0.310 | 0.541 | 0.079 | yes |
| A | reliability shrunk | 3 | 0.316 | 0.483 | 0.081 |  |
| A | reliability shrunk | 4 | 0.347 | 0.516 | 0.082 |  |
| A | reliability shrunk | 5 | 0.294 | 0.497 | 0.082 |  |
| A | reliability shrunk | 6 | 0.224 | 0.481 | 0.082 |  |
| A | reliability shrunk | 7 | 0.218 | 0.446 | 0.083 |  |
| A | reliability shrunk | 8 | 0.220 | 0.428 | 0.084 |  |
| B | unweighted | 2 | 0.265 | 0.768 | 0.071 | yes |
| B | unweighted | 3 | 0.283 | 0.784 | 0.064 |  |
| B | unweighted | 4 | 0.196 | 0.801 | 0.060 |  |
| B | unweighted | 5 | 0.196 | 0.797 | 0.058 |  |
| B | unweighted | 6 | 0.203 | 0.818 | 0.058 |  |
| B | unweighted | 7 | 0.131 | 0.819 | 0.059 |  |
| B | unweighted | 8 | 0.129 | 0.832 | 0.060 |  |
| B | inverse variance | 2 | 0.251 | 0.531 | 0.069 | yes |
| B | inverse variance | 3 | 0.219 | 0.473 | 0.064 |  |
| B | inverse variance | 4 | 0.197 | 0.450 | 0.066 |  |
| B | inverse variance | 5 | 0.200 | 0.438 | 0.064 |  |
| B | inverse variance | 6 | 0.210 | 0.454 | 0.062 |  |
| B | inverse variance | 7 | 0.196 | 0.468 | 0.061 |  |
| B | inverse variance | 8 | 0.202 | 0.490 | 0.061 |  |
| B | reliability shrunk | 2 | 0.161 | 0.569 | 0.069 | yes |
| B | reliability shrunk | 3 | 0.171 | 0.546 | 0.064 |  |
| B | reliability shrunk | 4 | 0.163 | 0.578 | 0.060 |  |
| B | reliability shrunk | 5 | 0.142 | 0.533 | 0.059 |  |
| B | reliability shrunk | 6 | 0.149 | 0.512 | 0.059 |  |
| B | reliability shrunk | 7 | 0.135 | 0.505 | 0.060 |  |
| B | reliability shrunk | 8 | 0.137 | 0.509 | 0.060 |  |

The full diagnostic is plotted in [`k_selection_diagnostics.png`](outputs/response_clustering_v1/k_selection_diagnostics.png), and the underlying values are in [`k_selection_metrics.csv`](outputs/response_clustering_v1/k_selection_metrics.csv).

### \(k-1\) and \(k+1\) sensitivity

For runs selected at the lower bound \(k=2\), \(k-1=1\) is not a clustering solution and was not presented as one; \(k=3\) is the available adjacent sensitivity. For the A/inverse-variance run, both \(k=2\) and \(k=4\) were evaluated.

| Set | Scheme | Role | k | Cluster sizes | ARI to selected |
|---|---|---|---:|---|---:|
| A | unweighted | selected | 2 | 35, 11 | 1.000 |
| A | unweighted | \(k+1\) | 3 | 15, 20, 11 | 0.465 |
| A | inverse variance | \(k-1\) | 2 | 45, 1 | 0.077 |
| A | inverse variance | selected | 3 | 24, 21, 1 | 1.000 |
| A | inverse variance | \(k+1\) | 4 | 24, 7, 1, 14 | 0.808 |
| A | reliability shrunk | selected | 2 | 29, 17 | 1.000 |
| A | reliability shrunk | \(k+1\) | 3 | 29, 10, 7 | 0.865 |
| B | unweighted | selected | 2 | 37, 9 | 1.000 |
| B | unweighted | \(k+1\) | 3 | 35, 9, 2 | 0.853 |
| B | inverse variance | selected | 2 | 29, 17 | 1.000 |
| B | inverse variance | \(k+1\) | 3 | 29, 10, 7 | 0.865 |
| B | reliability shrunk | selected | 2 | 11, 35 | 1.000 |
| B | reliability shrunk | \(k+1\) | 3 | 11, 28, 7 | 0.633 |

The especially low ARI for A/inverse variance at \(k=2\) occurs because \(k=2\) isolates Bald Eagle and merges the other 45 species, whereas the selected \(k=3\) partitions those 45 into groups of 24 and 21. This is an outlier-driven selection, not a recovered three-part ecological structure.

## 3. Bootstrap stability

`fpc::clusterboot` used 1,000 ordinary species bootstraps for every selected solution. Mean Jaccard below 0.6 is classified as unstable and is not treated as a group.

| Set | Scheme | k | Cluster | n | Mean Jaccard | Stable at 0.6 |
|---|---|---:|---:|---:|---:|:---:|
| A | unweighted | 2 | 1 | 35 | 0.816 | yes |
| A | unweighted | 2 | 2 | 11 | 0.625 | yes |
| A | inverse variance | 3 | 1 | 24 | 0.792 | yes |
| A | inverse variance | 3 | 2 | 21 | 0.623 | yes |
| A | inverse variance | 3 | 3 | 1 | 0.635 | yes, but singleton |
| A | reliability shrunk | 2 | 1 | 29 | 0.850 | yes |
| A | reliability shrunk | 2 | 2 | 17 | 0.735 | yes |
| B | unweighted | 2 | 1 | 37 | 0.825 | yes |
| B | unweighted | 2 | 2 | 9 | 0.486 | **no** |
| B | inverse variance | 2 | 1 | 29 | 0.802 | yes |
| B | inverse variance | 2 | 2 | 17 | 0.728 | yes |
| B | reliability shrunk | 2 | 1 | 11 | 0.475 | **no** |
| B | reliability shrunk | 2 | 2 | 35 | 0.664 | yes |

Feature Set A's within-run bootstrap scores are mostly acceptable, but this does not rescue it: the partitions themselves change across precision schemes. Feature Set B fails both within-run and across-scheme robustness. Its unweighted nine-species cluster and reliability-shrunk 11-species cluster are unstable and are not described as ecological groups.

## 4. Cluster composition

Cluster numbers are run-specific and have no meaning across schemes. The raw Feature Set A profiles show the recurring pattern: the smaller/high-response partition has larger active-minus-pre contrasts and a more negative count timing contrast, meaning counts are higher during early egg availability than at spawn start. Its exact membership is not stable to precision handling.

### Feature Set A

- **Unweighted, cluster 1 (n=35; Jaccard 0.816):** American Crow; American Herring Gull; American Wigeon; Bald Eagle; Barrow's Goldeneye; Black Oystercatcher; Black Turnstone; Black-bellied Plover; Brandt's Cormorant; Brant; Bufflehead; California Gull; Canada Goose; Common Loon; Common Merganser; Common Murre; Common Raven; Double-crested Cormorant; Dunlin; Glaucous-winged Gull; Great Blue Heron; Hooded Merganser; Horned Grebe; Iceland Gull; Mallard; Marbled Murrelet; Northern Pintail; Pacific Loon; Pelagic Cormorant; Pigeon Guillemot; Red-breasted Merganser; Red-necked Grebe; Red-throated Loon; Ring-billed Gull; Western Grebe.
- **Unweighted, cluster 2 (n=11; Jaccard 0.625):** Black Scoter; Bonaparte's Gull; Common Goldeneye; Greater Scaup; Harlequin Duck; Lesser Scaup; Long-tailed Duck; Short-billed Gull; Surf Scoter; Western Gull; White-winged Scoter.
- **Inverse variance, cluster 1 (n=24; Jaccard 0.792):** American Crow; Black Oystercatcher; Black Turnstone; Black-bellied Plover; Brandt's Cormorant; Canada Goose; Common Loon; Common Murre; Common Raven; Double-crested Cormorant; Dunlin; Hooded Merganser; Horned Grebe; Mallard; Marbled Murrelet; Pacific Loon; Pelagic Cormorant; Pigeon Guillemot; Red-breasted Merganser; Red-necked Grebe; Red-throated Loon; Ring-billed Gull; Western Grebe; Western Gull.
- **Inverse variance, cluster 2 (n=21; Jaccard 0.623):** American Herring Gull; American Wigeon; Barrow's Goldeneye; Black Scoter; Bonaparte's Gull; Brant; Bufflehead; California Gull; Common Goldeneye; Common Merganser; Glaucous-winged Gull; Great Blue Heron; Greater Scaup; Harlequin Duck; Iceland Gull; Lesser Scaup; Long-tailed Duck; Northern Pintail; Short-billed Gull; Surf Scoter; White-winged Scoter.
- **Inverse variance, cluster 3 (n=1; Jaccard 0.635):** Bald Eagle. This is an isolated species, not a group.
- **Reliability shrunk, cluster 1 (n=29; Jaccard 0.850):** American Crow; Bald Eagle; Barrow's Goldeneye; Black Oystercatcher; Black Scoter; Black Turnstone; Black-bellied Plover; Brandt's Cormorant; Bufflehead; Canada Goose; Common Loon; Common Murre; Common Raven; Double-crested Cormorant; Dunlin; Great Blue Heron; Hooded Merganser; Horned Grebe; Mallard; Marbled Murrelet; Pacific Loon; Pelagic Cormorant; Pigeon Guillemot; Red-breasted Merganser; Red-necked Grebe; Red-throated Loon; Ring-billed Gull; Western Grebe; Western Gull.
- **Reliability shrunk, cluster 2 (n=17; Jaccard 0.735):** American Herring Gull; American Wigeon; Bonaparte's Gull; Brant; California Gull; Common Goldeneye; Common Merganser; Glaucous-winged Gull; Greater Scaup; Harlequin Duck; Iceland Gull; Lesser Scaup; Long-tailed Duck; Northern Pintail; Short-billed Gull; Surf Scoter; White-winged Scoter.

The most ecologically recognizable result is the unweighted 11-species group: eight diving sea ducks plus Bonaparte's, Short-billed, and Western Gulls. But inverse-variance weighting expands the analogous group to 21 species, reliability shrinkage to 17, and several diving sea ducks move back to the remainder. This is precisely the precision sensitivity the analysis was designed to reveal.

### Feature Set B

- **Unweighted, cluster 1 (n=37; Jaccard 0.825):** American Crow; American Herring Gull; American Wigeon; Bald Eagle; Barrow's Goldeneye; Black Oystercatcher; Black Scoter; Black Turnstone; Black-bellied Plover; Brandt's Cormorant; Brant; Bufflehead; Canada Goose; Common Goldeneye; Common Loon; Common Merganser; Common Murre; Common Raven; Double-crested Cormorant; Dunlin; Great Blue Heron; Hooded Merganser; Horned Grebe; Mallard; Marbled Murrelet; Northern Pintail; Pacific Loon; Pelagic Cormorant; Pigeon Guillemot; Red-breasted Merganser; Red-necked Grebe; Red-throated Loon; Ring-billed Gull; Surf Scoter; Western Grebe; Western Gull; White-winged Scoter.
- **Unweighted, cluster 2 (n=9; Jaccard 0.486, unstable):** Bonaparte's Gull; California Gull; Glaucous-winged Gull; Greater Scaup; Harlequin Duck; Iceland Gull; Lesser Scaup; Long-tailed Duck; Short-billed Gull.
- **Inverse variance, cluster 1 (n=29; Jaccard 0.802):** American Crow; Barrow's Goldeneye; Black Oystercatcher; Black Scoter; Black Turnstone; Black-bellied Plover; Brandt's Cormorant; Brant; Bufflehead; Canada Goose; Common Loon; Common Murre; Common Raven; Double-crested Cormorant; Dunlin; Great Blue Heron; Hooded Merganser; Horned Grebe; Marbled Murrelet; Pacific Loon; Pelagic Cormorant; Pigeon Guillemot; Red-breasted Merganser; Red-throated Loon; Ring-billed Gull; Surf Scoter; Western Grebe; Western Gull; White-winged Scoter.
- **Inverse variance, cluster 2 (n=17; Jaccard 0.728):** American Herring Gull; American Wigeon; Bald Eagle; Bonaparte's Gull; California Gull; Common Goldeneye; Common Merganser; Glaucous-winged Gull; Greater Scaup; Harlequin Duck; Iceland Gull; Lesser Scaup; Long-tailed Duck; Mallard; Northern Pintail; Red-necked Grebe; Short-billed Gull.
- **Reliability shrunk, cluster 1 (n=11; Jaccard 0.475, unstable):** American Crow; Black Oystercatcher; Black-bellied Plover; Common Loon; Common Murre; Common Raven; Dunlin; Hooded Merganser; Pigeon Guillemot; Ring-billed Gull; Western Grebe.
- **Reliability shrunk, cluster 2 (n=35; Jaccard 0.664):** American Herring Gull; American Wigeon; Bald Eagle; Barrow's Goldeneye; Black Scoter; Black Turnstone; Bonaparte's Gull; Brandt's Cormorant; Brant; Bufflehead; California Gull; Canada Goose; Common Goldeneye; Common Merganser; Double-crested Cormorant; Glaucous-winged Gull; Great Blue Heron; Greater Scaup; Harlequin Duck; Horned Grebe; Iceland Gull; Lesser Scaup; Long-tailed Duck; Mallard; Marbled Murrelet; Northern Pintail; Pacific Loon; Pelagic Cormorant; Red-breasted Merganser; Red-necked Grebe; Red-throated Loon; Short-billed Gull; Surf Scoter; Western Gull; White-winged Scoter.

The Feature Set B partitions do not reproduce a stable early-reporting group plus late-count group. Instead they alternate among a gull/sea-duck-enriched subset, a broad high-response subset, and an unstable low-response subset.

## 5. Correspondence with pre-assigned guilds

Guild abbreviations in the cross-tabulation are: ALC = alcid piscivore, GUL = gull roe, SHB = intertidal roe shorebird, PIS = piscivore active spawn, SEA = roe diving sea duck, SCA = shoreline scavenger, and SUR = surface/vegetation roe.

| Set | Scheme | Cluster | ALC | GUL | SHB | PIS | SEA | SCA | SUR |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| A | unweighted | 1 | 3 | 5 | 4 | 12 | 2 | 4 | 5 |
| A | unweighted | 2 | 0 | 3 | 0 | 0 | 8 | 0 | 0 |
| A | inverse variance | 1 | 3 | 2 | 4 | 11 | 0 | 2 | 2 |
| A | inverse variance | 2 | 0 | 6 | 0 | 1 | 10 | 1 | 3 |
| A | inverse variance | 3 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| A | reliability shrunk | 1 | 3 | 2 | 4 | 11 | 3 | 4 | 2 |
| A | reliability shrunk | 2 | 0 | 6 | 0 | 1 | 7 | 0 | 3 |
| B | unweighted | 1 | 3 | 3 | 4 | 12 | 6 | 4 | 5 |
| B | unweighted | 2 | 0 | 5 | 0 | 0 | 4 | 0 | 0 |
| B | inverse variance | 1 | 3 | 2 | 4 | 10 | 5 | 3 | 2 |
| B | inverse variance | 2 | 0 | 6 | 0 | 2 | 5 | 1 | 3 |
| B | reliability shrunk | 1 | 2 | 1 | 3 | 3 | 0 | 2 | 0 |
| B | reliability shrunk | 2 | 1 | 7 | 1 | 9 | 10 | 2 | 5 |

Adjusted Rand index (ARI) and normalized mutual information (NMI) were compared with 9,999 permutations of guild labels. The upper-tail permutation result tests only whether the cluster partition corresponds to the guild partition more than random relabelling; it does not test whether clusters exist.

| Set | Scheme | k | ARI | NMI | ARI permutation p | NMI permutation p | ARI percentile | NMI percentile |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| A | unweighted | 2 | 0.099 | 0.325 | 0.0009 | 0.0002 | 99.95 | 99.99 |
| A | inverse variance | 3 | 0.214 | 0.372 | 0.0001 | 0.0001 | 100.00 | 100.00 |
| A | reliability shrunk | 2 | 0.105 | 0.255 | 0.0023 | 0.0015 | 99.81 | 99.86 |
| B | unweighted | 2 | 0.043 | 0.245 | 0.0419 | 0.0019 | 96.64 | 99.83 |
| B | inverse variance | 2 | 0.045 | 0.155 | 0.0538 | 0.0334 | 95.66 | 96.69 |
| B | reliability shrunk | 2 | 0.059 | 0.187 | 0.0153 | 0.0135 | 98.88 | 98.66 |

Feature Set A therefore has non-random but low-to-modest correspondence with guild. Feature Set B correspondence is weaker still; for inverse variance the ARI does not exceed the conventional 0.05 permutation cutoff, while NMI does. These permutation positions do not compensate for low effect size, instability, or scheme dependence.

### Species outside the cluster their guild mostly occupies

When a guild was tied across modal clusters, all tied modes were treated as modal rather than forcing an arbitrary choice.

- **A, unweighted:** Bonaparte's Gull, Short-billed Gull, Western Gull, Barrow's Goldeneye, and Bufflehead.
- **A, inverse variance:** Ring-billed Gull, Western Gull, Common Merganser, Bald Eagle, Great Blue Heron, Canada Goose, and Mallard.
- **A, reliability shrunk:** Ring-billed Gull, Western Gull, Common Merganser, Barrow's Goldeneye, Black Scoter, Bufflehead, Canada Goose, and Mallard.
- **B, unweighted:** American Herring Gull, Ring-billed Gull, Western Gull, Greater Scaup, Harlequin Duck, Lesser Scaup, and Long-tailed Duck.
- **B, inverse variance:** Ring-billed Gull, Western Gull, Common Merganser, Red-necked Grebe, Bald Eagle, Brant, and Canada Goose.
- **B, reliability shrunk:** Marbled Murrelet, Ring-billed Gull, Black Turnstone, Common Loon, Hooded Merganser, and Western Grebe.

The disagreements are not confined to marginal or low-support taxa. They include conspicuous representatives of the guilds that drive the manuscript's timing interpretation, which is another reason not to describe the blind clusters as confirmation of those guilds.

## 6. Precision-scheme and algorithm checks

The three selected partitions are not similar enough to call the result precision-robust.

| Set | Scheme comparison | k values | ARI | NMI |
|---|---|---|---:|---:|
| A | unweighted vs inverse variance | 2 vs 3 | 0.182 | 0.219 |
| A | unweighted vs reliability shrunk | 2 vs 2 | 0.296 | 0.226 |
| A | inverse variance vs reliability shrunk | 3 vs 2 | 0.630 | 0.609 |
| B | unweighted vs inverse variance | 2 vs 2 | 0.402 | 0.418 |
| B | unweighted vs reliability shrunk | 2 vs 2 | -0.106 | 0.116 |
| B | inverse variance vs reliability shrunk | 2 vs 2 | 0.014 | 0.219 |

PAM was run at the Ward-selected \(k\) on the identical matrix:

| Set | Scheme | Ward-selected k | Ward–PAM ARI | PAM mean silhouette |
|---|---|---:|---:|---:|
| A | unweighted | 2 | 0.397 | 0.291 |
| A | inverse variance | 3 | 0.756 | 0.273 |
| A | reliability shrunk | 2 | 0.469 | 0.319 |
| B | unweighted | 2 | 0.177 | 0.187 |
| B | inverse variance | 2 | 0.532 | 0.265 |
| B | reliability shrunk | 2 | -0.032 | 0.235 |

Only A/inverse variance shows strong Ward–PAM agreement, and that Ward solution contains a singleton. The remaining comparisons are weak to moderate, with B/reliability shrinkage effectively unrelated across algorithms.

## 7. Ordination and prevalence-versus-stability

The first two PCA axes explain 71.2%, 76.3%, and 71.7% of Feature Set A variance under unweighted, inverse-variance, and reliability-shrunk preprocessing. For Feature Set B the corresponding totals are 67.6%, 66.1%, and 65.5%. The two-axis displays therefore retain a useful majority of the matrix variation, and each figure reports its exact total.

Ordinations:

- [Feature A, unweighted](outputs/response_clustering_v1/ordination_feature_A_unweighted.png)
- [Feature A, inverse variance](outputs/response_clustering_v1/ordination_feature_A_inverse_variance.png)
- [Feature A, reliability shrunk](outputs/response_clustering_v1/ordination_feature_A_reliability_shrunk.png)
- [Feature B, unweighted](outputs/response_clustering_v1/ordination_feature_B_unweighted.png)
- [Feature B, inverse variance](outputs/response_clustering_v1/ordination_feature_B_inverse_variance.png)
- [Feature B, reliability shrunk](outputs/response_clustering_v1/ordination_feature_B_reliability_shrunk.png)

Species-level assignment stability came from a separate 1,000-replicate bootstrap, with bootstrap clusters aligned greedily to the original partition by descending Jaccard overlap. Spearman correlations with checklist prevalence were:

| Set | Scheme | Spearman rho |
|---|---|---:|
| A | unweighted | 0.286 |
| A | inverse variance | 0.118 |
| A | reliability shrunk | -0.092 |
| B | unweighted | 0.111 |
| B | inverse variance | 0.078 |
| B | reliability shrunk | 0.107 |

Assignment stability is not strongly associated with checklist prevalence after precision handling. The largest relationship is the naive A/unweighted analysis (\(\rho=0.286\)); all others have \(|\rho|\leq0.118\). This means prevalence is not the main explanation for the instability, but it does not make the partitions robust across schemes or algorithms.

## 8. What ran, what was written, and what was skipped

The analysis ran under R 4.5.1 with `cluster` 2.1.8.1, `fpc` 2.2.14, and `vegan` 2.7.5. The missing packages and their dependencies were installed into a temporary task-specific R library, not the locked project library. The fixed base seed was 20260725; component seeds are archived with each result.

The reproducible entry point is [`scripts/run_response_clustering_v1.R`](scripts/run_response_clustering_v1.R). Detailed machine-readable outputs are in [`outputs/response_clustering_v1/`](outputs/response_clustering_v1/), including:

- feature definitions, raw matrices, standard errors, transformed matrices, and shrinkage hyperparameters;
- join-cardinality audit and complete-case exclusions;
- full \(k\)-selection metrics;
- selected and adjacent-\(k\) assignments;
- per-cluster and per-species bootstrap stability;
- raw link-scale cluster profiles and named composition;
- guild cross-tabs, ARI, NMI, permutation results, and disagreements;
- PAM and cross-scheme comparisons;
- PCA variance;
- execution record, package record, and R session information; and
- six ordinations, six dendrograms, and the combined \(k\)-selection figure.

Dendrograms:

- [Feature A, unweighted](outputs/response_clustering_v1/dendrogram_feature_A_unweighted.png)
- [Feature A, inverse variance](outputs/response_clustering_v1/dendrogram_feature_A_inverse_variance.png)
- [Feature A, reliability shrunk](outputs/response_clustering_v1/dendrogram_feature_A_reliability_shrunk.png)
- [Feature B, unweighted](outputs/response_clustering_v1/dendrogram_feature_B_unweighted.png)
- [Feature B, inverse variance](outputs/response_clustering_v1/dendrogram_feature_B_inverse_variance.png)
- [Feature B, reliability shrunk](outputs/response_clustering_v1/dendrogram_feature_B_reliability_shrunk.png)

Skipped by design:

- no response model was fit or refit;
- no protected checklist frame or 2026–2028 holdout was read;
- no authorization environment variable was set;
- no taxon was added or removed;
- no prevalence-based exclusion was made;
- no imputed 49-species sensitivity was run;
- no spawn-magnitude or event-level community-composition analysis was attempted;
- no cluster-existence p-values were computed; and
- neither the manuscript nor its supplementary material was edited.

All released artifacts are aggregate species-level results. They contain no checklist, observer, locality, event, block, or coordinate identifiers, and the archived support counts meet the suppression threshold of 20.
