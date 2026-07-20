# Stage 2 outcome-blind design lock

**Stage gate:** `PASS_READY_FOR_HUMAN_SCIENTIFIC_APPROVAL`
**Validation:** `PASS_LOCAL_VALIDATION_REMOTE_CI_PENDING`
**Candidate-grid SHA-256:** `f7e5e9df7a96e1fff82a66734371fc427d70d8d6bbb2b4725409aa94475e7f91`
**Frozen at:** `2026-07-20 05:27:38 UTC`

> SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE. Current analyses remain exploratory and estimand-refining until prospective confirmation.

## Outcome boundary and executive conclusion

Lay summary: The design choices were frozen before any bird detection or numeric-count value was accessed. This stage measured whether the data can support later analyses; it did not estimate whether birds respond to herring spawning.

The frozen grid contains 105 options. Its hash was independently verified before support-only outcome access. The exact EBD fields read were: `CATEGORY`, `TAXON CONCEPT ID`, `COMMON NAME`, `SCIENTIFIC NAME`, `OBSERVATION COUNT`, `BEHAVIOR CODE`, `SAMPLING EVENT IDENTIFIER`. Comments were not read. All 2026 and later outcomes remained frozen.

The audit explicitly checked noncomputation of: detection_rate_by_exposure, bird_count_summary_by_exposure, active_reference_contrast, ratio_or_odds_ratio, effect_size_or_coefficient, p_value, confidence_or_posterior_interval, posterior_summary, cooccurrence_change_by_spawn_phase_or_distance, biological_response_plot, herring_exposure_response_model. No biological response plot was created and none of the 45 registered herring-bird response models was fitted.

## Ten design decisions

Lay summary: Each recommendation is outcome-blind and remains subject to human scientific approval.

| ID | Decision | Recommendation | Sensitivity |
| --- | --- | --- | --- |
| D01 | species eligibility | Retain all 58; assign outcome-blind core, exploratory, guild/community-only, sparse-retained, or falsification status from frozen thresholds | nearby thresholds retained |
| D02 | multi-guild membership | One non-overlapping primary guild per species; secondary mechanism traits may overlap | secondary trait flags |
| D03 | event complex | 2 km / 7 day complex as candidate primary after manual review of flagged long-span cases | source record and 5 km / 14 day |
| D04 | event geometry | Source point and derived length-informed alongshore footprint as parallel core design families; snapped point for linkage; length-plus-width and complex unions as sensitivities | source point\|snapped point\|length\|length-width\|complex union |
| D05 | regions periods protocols effort | All BC hierarchical coverage without a forced pooled coastwide effect; broad complete Stationary/Traveling candidate primary; standardized sensitivity; complete area separate | 2005\|2010\|2015 starts and 1988 long window |
| D06 | count tails likelihood | Separate detection; hurdle lognormal candidate primary positive-count family with truncated NB2 parallel sensitivity; no primary winsorization | top 1%\|top 0.5%\|ordinal\|upper-tail |
| D07 | multispecies latent factors | Detection-first; compare 2, 3, 4, 5 factors plus no-factor and no-pooling comparators using hash-identical pilot and one-SE rule; no factor count selected now | 2\|3\|4\|5 factors and two comparators |
| D08 | behaviour and comments | Structured behaviour codes may support aggregate analyses at released cell size at least 20; free-text comment audit deferred and comments were not read | local-only dictionary audit only after privacy approval |
| D09 | multiplicity evidence synthesis | Primary ecological families separated; hierarchical synthesis; species visible; BH only within coherent species families; no omnibus Holm over 45 | geometry\|complex\|tail\|region\|period\|holdout roles frozen |
| D10 | prospective confirmation | Freeze all 2026+ outcomes and events; evaluate only after complete/versioned releases under unchanged signed hash-recorded specification | candidate external regions frozen before outcome access |

## Taxonomy and support disposition for all 58 taxa

Lay summary: Sparse taxa were retained rather than deleted. Gadwall and Northern Shoveler remain a separate falsification panel.

| Taxon | Taxonomy | Named-species role | Guild role | Count role | Co-occurrence role |
| --- | --- | --- | --- | --- | --- |
| American Crow | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| American Herring Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| American Wigeon | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Bald Eagle | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Barrow's Goldeneye | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Black Oystercatcher | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Black Scoter | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Black Turnstone | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Black-bellied Plover | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Bonaparte's Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Brandt's Cormorant | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Brant | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Bufflehead | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| California Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Canada Goose | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Caspian Tern | approve_exact_v2025_species_concept | named_species_exploratory | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Clark's Grebe | approve_exact_v2025_species_concept | retain_registry_sparse_not_named | retain_with_partial_pooling_support_warning | detection_component_only_or_bounded_sensitivity | not_in_reduced_pairwise_set |
| Common Goldeneye | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Common Loon | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Common Merganser | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Common Murre | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Common Raven | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Common Tern | approve_exact_v2025_species_concept | guild_or_community_only | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Double-crested Cormorant | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Dunlin | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Eared Grebe | approve_exact_v2025_species_concept | named_species_exploratory | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Gadwall | approve_exact_v2025_species_concept | separate_falsification_panel | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Glaucous Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Glaucous-winged Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Great Blue Heron | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Greater Scaup | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Harlequin Duck | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Hooded Merganser | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Horned Grebe | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Iceland Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Lesser Scaup | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Long-tailed Duck | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Mallard | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Marbled Murrelet | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Northern Pintail | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Northern Shoveler | approve_exact_v2025_species_concept | separate_falsification_panel | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Osprey | approve_exact_v2025_species_concept | named_species_exploratory | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Pacific Loon | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Pelagic Cormorant | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Pigeon Guillemot | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Red-breasted Merganser | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Red-necked Grebe | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Red-throated Loon | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Rhinoceros Auklet | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Ring-billed Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Rock Sandpiper | approve_exact_v2025_species_concept | named_species_exploratory | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Sanderling | approve_exact_v2025_species_concept | named_species_exploratory | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Short-billed Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Surf Scoter | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Surfbird | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Western Grebe | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| Western Gull | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |
| White-winged Scoter | approve_exact_v2025_species_concept | named_species_core | eligible_primary_guild_membership | positive_count_component_eligible | pairwise_support_audit_eligible |

Technical note: The complete pooled support metrics and explicit threshold reasons are in `outputs/stage2_design_lock/species_support_summary.csv`; all 6,090 taxon-by-candidate support rows are in `species_support_by_design_cell.csv`. These are support counts only, never effect estimates.

## Event-complex recommendation

Lay summary: Keep the source record immutable. Use the 2 km / 7 day complex as the candidate primary after manual review of its flagged long-span cases; retain 1 km / 3 day and source-record alternatives, with 5 km / 14 day broad sensitivity only.

| Definition | Complexes | Members p90 | Members max | Max days | Max km | >21 days | >25 km |
| --- | --- | --- | --- | --- | --- | --- | --- |
| source_record | 13332 |  1 |   1 |  0 |  0.00000 |  0 |  0 |
| complex_1km_3d |  6954 |  3 |  94 | 41 |  2.81133 |  1 |  0 |
| complex_2km_7d |  5541 |  5 |  94 | 66 | 11.08784 |  2 |  0 |
| complex_5km_14d |  3077 | 10 | 118 | 71 | 44.33298 | 32 | 15 |

Every source record is retained in the hashed crosswalk. Merges never cross stock-assessment Region; StatisticalArea crossings are flagged. The 100-case generalized map review contains no eBird coordinates.

## Geometry and quality tiers

Lay summary: Source-point and observed-Length alongshore geometries remain parallel core design families because they answer different proximity questions. Width and complex-union geometries are sensitivities.

| Geometry | Role | Success | Failure | Tier A | Tier B | Tier C |
| --- | --- | --- | --- | --- | --- | --- |
| source_point | parallel_core | 13208 |  124 | 5163 | 136 | 7622 |
| nearest_marine_shoreline_point | linkage | 13208 |  124 | 5163 | 136 | 7622 |
| derived_alongshore_length | parallel_core |  5163 | 8169 | 5163 | 136 | 7622 |
| derived_alongshore_length_width | sensitivity |  5102 | 8230 | 5163 | 136 | 7622 |
| event_complex_member_union | complex_sensitivity |  1905 | 3652 | 5163 | 136 | 7622 |

Technical note: EPSG:3005 is mandatory. Missing Length or Width is never inferred. Section polygons and centroids are not event footprints. The complete hashed geometry crosswalk releases snap-distance bands, not exact coordinates. Human review must confirm the provider meaning of shoreline EDGE_TYPE 100 and 150.

## Regions, periods, protocols, and effort

Lay summary: Use all BC hierarchically without forcing one coastwide effect. The response-free coverage rule selects 2005 for supported regions; A27 and A2W remain descriptive or hierarchically pooled until their structural support is approved.

| Region | Primary start | Role |
| --- | --- | --- |
| A27 | none | descriptive_or_hierarchical_only_due_structural_support |
| A2W | none | descriptive_or_hierarchical_only_due_structural_support |
| CC | 2005 | candidate_primary_period |
| HG | 2005 | candidate_primary_period |
| NA | 2005 | candidate_primary_period |
| PRD | 2005 | candidate_primary_period |
| SoG | 2005 | candidate_primary_period |
| WCVI | 2005 | candidate_primary_period |

Broad candidate primary: complete Stationary and Traveling checklists, duration 1-360 minutes, Traveling distance at most 10 km, 1-20 observers. Standardized sensitivity: 5-300 minutes, at most 5 km, 1-10 observers. Complete area protocols remain separate.

## Count tails and likelihood family

Lay summary: Keep detection separate from positive reported flock size. Use a hurdle lognormal as the candidate primary positive-count family and a hurdle truncated NB2 as a parallel sensitivity; keep high counts in the primary analysis.

Selection is based only on synthetic recovery, block-held-out log score, calibration, tail behavior, numerical stability, and the one-standard-error rule. `X` is detection-only, lower bounds enter a bounded sensitivity, and ambiguity remains distinct. All simulation rows are labelled SYNTHETIC.

## Multispecies latent-factor procedure

No observed biological JSDM/GLLVM was fitted. The future hash-identical detection-first pilot compares 2, 3, 4, and 5 factors plus no-factor and no-pooling comparators. Selection uses held-out predictive score, convergence/posterior geometry, synthetic residual-association recovery, and a one-standard-error rule. No factor count is selected at Stage 2.

## Behaviour and comment privacy

Structured behaviour codes may be used only as aggregate supporting evidence with released cells of at least 20. Free-text comments were not read and the comment audit is deferred unless local-only processing, a versioned dictionary, rare-string scanning, and path-leakage tests are approved.

## Multiplicity and evidence synthesis

The registry keeps local aggregation, event-time/distance, redistribution, community/co-occurrence, spawn dose, and phenology as separate ecological families. Species estimates remain visible; hierarchical synthesis is primary; Benjamini-Hochberg applies only within coherent species families; no omnibus Holm adjustment spans all 45 models. Diagnostics and falsification do not compete with primary ecological models.

## Prospective confirmation

The confirmation specification SHA-256 is `2640276fad585c9d3b537f407bb3efeb0167cb5acbdc38674fbb8d6e91b1cbb7`. All 2026+ outcomes and events are frozen. Evaluation requires complete/versioned eBird and herring releases and unchanged code, species, guilds, geometry, windows, distance functions, and decision thresholds. No refitting or selection may occur before the primary evaluation.

## QA, privacy, and join cardinality

Every join declares and tests cardinality. Concurrent event links are additive exposure memberships and never independent checklist rows. Detection, numeric, X, lower-bound, ambiguity, and missingness remain distinct. Missing herring components remain missing, and relative spawn index is never called absolute biomass.

Validation status: `PASS_LOCAL_VALIDATION_REMOTE_CI_PENDING`. Detailed checks are recorded in the stage gate and repository test outputs.

## Questions requiring human scientific approval

1. Approve the 58 taxonomy/support dispositions and the nearby-threshold sensitivity policy.
2. Approve 2 km / 7 day as candidate primary after reviewing all flagged long-span cases and the 100-case map packet.
3. Confirm the marine shoreline EDGE_TYPE dictionary and the 2 km candidate snap limit.
4. Approve region-period coverage rules, including descriptive/hierarchical treatment of A27 and A2W.
5. Approve hurdle lognormal primary and truncated NB2 parallel sensitivity before any herring-effect fit.
6. Approve the latent-factor pilot, behaviour-code boundary, multiplicity registry, and signed prospective protocol.

No Stage 3 model may open or fit until this gate receives human scientific approval.
