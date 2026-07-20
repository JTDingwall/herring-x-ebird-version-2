# Stage 2 outcome-blind design lock — human scientific approval record

**Stage gate:** `PASS_STAGE2_HUMAN_SCIENTIFIC_APPROVAL_RECORDED`
**Human scientific decision:** `APPROVED_SOURCE_POINT_PRIMARY`
**Validation:** `PENDING_HUMAN_APPROVAL_GATE_CI`

> SUPPORT_ONLY_NOT_AN_EFFECT_ESTIMATE. Current analyses remain exploratory and estimand-refining until prospective confirmation.

## Executive conclusion

Human scientific approval selects immutable source points as the primary event geometry. EDGE_TYPE 100 alongshore geometry is restricted to SoG and WCVI as a sensitivity; EDGE_TYPE 150 remains unavailable until local visual validation. Incomplete shoreline coverage stays visible and is never treated as coastwide, but it no longer prevents identification of the separately defined source-point primary. Stage 3 entry and response models remain unauthorized.

No herring–bird response model was fitted. No exposure-specific bird summary, contrast, coefficient, p-value, interval, posterior summary, spawn-phase co-occurrence change, or biological response plot was calculated or displayed. Free-text comments were not read.

## Design freeze and amendment chain

The original candidate grid remains unchanged: canonical-LF SHA-256 `8b9ba99dbded84273cb7860d530e09b6b3d50b09603d082e6013742245127a81`, original Windows-CRLF SHA-256 `f7e5e9df7a96e1fff82a66734371fc427d70d8d6bbb2b4725409aa94475e7f91`, frozen `2026-07-20 05:27:38 UTC`. The scientific-gate amendment SHA-256 is `7323b02f2c5ea3e2fccde6de73f123200694242d24cca087561e5939a7aa6835`; the human-approval record SHA-256 is `c2d075a8aa644c12d552d87d17ea5082d977f0e6e6fd9a80b337f613b915de18`; the prospective specification SHA-256 is `3f69cda08e3e1963df068a1ee96e66c4e5da1e4f03fa1b132c2d2e448170609d`.

The candidate grid was frozen and hashed before any species detection or numeric-count values were read. The repair amendment preserves those original timestamps and hashes and records its implementation-only YAML correction history.

## Repair resolution 1 — EBD/SED membership and zero filling

| EBD rows | EBD keys | SED keys | EBD-only | SED-only | SED-only ≤2025 | SED-only ≥2026 | Primary zero-fill | Treatment |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 37407250 | 2944079 | 2961400 | 0 | 17321 | 15564 | 1176 | FALSE | structurally_unknown_excluded_from_primary_zero_fill |

SED-only checklists are structural unknowns, never observed absences. They are excluded from primary zero filling and retained only for an explicit non-zero-filled eligibility sensitivity.

## Repair resolution 2 — shoreline and actual geometry

| Geometry | Role | Available | Common set | EDGE100 median m | EDGE100 p90 m | >2 km | Actual line built | Gate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| source_point | coastwide_primary_human_approved | 13208 | 3899 | 51322.28 | 387152.5 | 7798 | TRUE | PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED |
| edge100_nearest_shoreline_point | supported_region_sensitivity_human_approved | 13208 | 3899 | 51322.28 | 387152.5 | 7798 | TRUE | PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED |
| edge150_nearest_shoreline_point | separate_sensitivity_after_visual_validation | 13208 | 3899 | 51322.28 | 387152.5 | 7798 | TRUE | PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED |
| derived_alongshore_length | supported_region_sensitivity_human_approved |  3899 | 3899 | 51322.28 | 387152.5 | 7798 | TRUE | PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED |
| derived_alongshore_length_width | registered_sensitivity |  3851 | 3899 | 51322.28 | 387152.5 | 7798 | TRUE | PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED |
| event_complex_member_union | registered_sensitivity |  1364 | 3899 | 51322.28 | 387152.5 | 7798 | TRUE | PASS_SOURCE_POINT_PRIMARY_SHORELINE_SENSITIVITY_SCOPED |

| Region | Valid source points | Inside-bundle share | Median snap km | >2 km | Core eligible | Coverage |
| --- | --- | --- | --- | --- | --- | --- |
| A27 |  332 | 0.00000 |  60.54290 |  332 |    0 | FAIL_NO_SOURCE_POINTS_INSIDE_BUNDLE_EXTENT |
| A2W |  642 | 0.00000 | 465.89423 |  642 |    0 | FAIL_NO_SOURCE_POINTS_INSIDE_BUNDLE_EXTENT |
| CC | 2699 | 0.00000 | 135.38282 | 2699 |    0 | FAIL_NO_SOURCE_POINTS_INSIDE_BUNDLE_EXTENT |
| HG | 1313 | 0.00000 | 299.86262 | 1313 |    0 | FAIL_NO_SOURCE_POINTS_INSIDE_BUNDLE_EXTENT |
| PRD | 1283 | 0.00000 | 407.53472 | 1283 |    0 | FAIL_NO_SOURCE_POINTS_INSIDE_BUNDLE_EXTENT |
| SoG | 2145 | 0.99953 |   0.08115 |    1 | 2095 | PASS_CANDIDATE_COVERAGE |
| WCVI | 1599 | 0.95921 |   0.45887 |  624 |  943 | PASS_CANDIDATE_COVERAGE |
| NA | 3195 | 0.74097 |   0.96470 |  904 | 2261 | PASS_CANDIDATE_COVERAGE |

| Representation | Sample | Eligible events | Interpretation |
| --- | --- | --- | --- |
| source_point | all_available | 13208 | representation-specific availability; do not interpret differences as geometry effects |
| derived_alongshore_length | all_available |  3899 | representation-specific availability; do not interpret differences as geometry effects |
| source_point | common_eligible_events |  3899 | same eligible event set for geometry comparison |
| derived_alongshore_length | common_eligible_events |  3899 | same eligible event set for geometry comparison |

The human-approved primary is the immutable source point, available for 13,208 source records. EDGE_TYPE 100 and actual alongshore substrings are restricted to SoG/WCVI sensitivities on a common eligible event set. Class 150 remains unavailable until local visual validation. Large snap distances continue to document incomplete bundle coverage and unsupported regions never enter shoreline-linked sensitivities.

## Repair resolution 3 — event complexes and review packet

| Definition | Complexes | Members max | Max days | Max km | >21 days | >25 km | Flagged | Role |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| source_record | 13332 |   1 |  0 |  0.00000 |  0 |  0 | 627 | safe_primary |
| complex_1km_3d |  6954 |  94 | 41 |  2.81133 |  1 |  0 | 636 | registered_sensitivity |
| complex_2km_7d |  5541 |  94 | 66 | 11.08784 |  2 |  0 | 673 | provisional_pending_human_review |
| complex_2km_7d_antichain |  5544 |  94 | 18 | 11.08784 |  0 |  0 | 673 | deterministic_anti_chaining_sensitivity |
| complex_5km_14d |  3077 | 118 | 71 | 44.33298 | 32 | 15 | 753 | registered_sensitivity |

The immutable source record is the safe primary. The original 2 km / 7 day connected-component rule remains provisional because chaining produces two complexes over 21 days, including a 66-day maximum. The deterministic anti-chain sensitivity caps temporal span at 21 days and spatial diameter at 25 km without crossing Region. Every flagged complex—not a sample—is included in the generalized review packet.

## Repair resolution 4 — sustained region-year support

| Region | Start | Passing years | Assessed years | Max fail run | Role |
| --- | --- | --- | --- | --- | --- |
| A27 | 2005 |  0 | 21 | 21 | descriptive_or_hierarchical_only_due_unsustained_support |
| A2W | 2005 |  0 | 21 | 21 | descriptive_or_hierarchical_only_due_unsustained_support |
| CC | 2005 |  4 | 21 | 11 | descriptive_or_hierarchical_only_due_unsustained_support |
| HG | 2005 |  0 | 21 | 21 | descriptive_or_hierarchical_only_due_unsustained_support |
| NA | 2005 |  7 | 21 |  9 | descriptive_or_hierarchical_only_due_unsustained_support |
| PRD | 2005 |  2 | 21 | 19 | descriptive_or_hierarchical_only_due_unsustained_support |
| SoG | 2005 | 21 | 21 |  0 | candidate_primary_period |
| WCVI | 2015 | 10 | 11 |  1 | candidate_primary_period |

The response-free sustained rule supports SoG from 2005 and WCVI from 2015. All other regions, including A27 and A2W, remain descriptive or hierarchical-only because no candidate start passes the frozen year-by-year rule.

## Repair resolution 5 — protocol, effort, and shared checklists

| Definition | Protocols | Minutes | Travel km max | Observers | Role |
| --- | --- | --- | --- | --- | --- |
| standardized_primary | Stationary\|Traveling | 5-300 | 5 | 1-10 | candidate_primary |
| broad_sensitivity | Stationary\|Traveling | 1-360 | 10 | 1-20 | broad_sensitivity |
| complete_area_separate | Complete Area | separate_registered_rule | not_pooled | separate_registered_rule | separate_analysis |

| Source rows | Analysis checklists | Shared | Disagreements | Disagreements with EBD | Wholly SED-only | Primary | Observer rule | Primary rule |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2961400 | 2612815 | 258780 | 6938 | 6903 | 16007 | 2589905 | shared_group_composite_cluster_not_first_source_row | exclude_from_primary_registered_sensitivity |

Standardized complete Stationary/Traveling effort is primary; broader effort is a sensitivity and Complete Area remains separate. Shared groups use a composite observer cluster. Effort-disagreement groups are excluded from the primary and retained as a registered sensitivity with fieldwise ranges and missing consensus values.

## Repair resolution 6 — registry and specificity panel

| Model | Role | Choice group | Evidence objects |
| --- | --- | --- | --- |
| M21 | mutually_exclusive_primary_alternative_selected_by_one_latent_pilot | community_latent_primary_choice | 1 |
| M35 | mutually_exclusive_primary_alternative_selected_by_one_latent_pilot | community_latent_primary_choice | 1 |

M21 and M35 are mutually exclusive primary alternatives selected by one detection-first latent pilot and contribute one evidence object, not two. Gadwall and Northern Shoveler are a specificity/falsification panel; they are not asserted to be guaranteed biological nonresponders. All 45 models remain registered and unfitted.

## Repair resolution 7 — prospective integrity

The confirmation horizon is fixed at complete 2026–2028 releases, with one evaluation after the complete horizon, no interim response looks, and no early stopping. The prior mechanical scan is disclosed. The precise claim is: `no_2026_plus_response_was_summarized_viewed_for_direction_or_used_in_model_or_design_selection`. Repaired extraction filters observation date before selecting or persisting response fields.

## Repair resolution 8 — bookkeeping, QA, and privacy

The parent successful GitHub Actions reference is run #10; run #9 is explicitly superseded as incorrect. The substantive repair commit passed GitHub Actions run #15 (run ID 29761640213). Every join declares and tests cardinality. Concurrent event memberships remain additive exposure links and never duplicate checklists as independent rows. Detection, numeric, X, lower-bound, and ambiguity states remain distinct; missing herring components are not zero and relative spawn index is not absolute biomass.

The response-access audit lists these EBD fields: `CATEGORY`, `TAXON CONCEPT ID`, `COMMON NAME`, `SCIENTIFIC NAME`, `OBSERVATION COUNT`, `BEHAVIOR CODE`, `SAMPLING EVENT IDENTIFIER`. It asserts noncomputation of: detection_rate_by_exposure, bird_count_summary_by_exposure, active_reference_contrast, ratio_or_odds_ratio, effect_size_or_coefficient, p_value, confidence_or_posterior_interval, posterior_summary, cooccurrence_change_by_spawn_phase_or_distance, biological_response_plot, herring_exposure_response_model.

## Taxonomy and outcome-blind support dispositions

| Taxon | Taxonomy | Named role | Guild role | Count role | Co-occurrence role |
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

## Human scientific approval and next gate

Approval record `stage2_human_scientific_approval_v1` selects immutable source points as primary and approves the repaired Stage 2 rules. Its SHA-256 is `c2d075a8aa644c12d552d87d17ea5082d977f0e6e6fd9a80b337f613b915de18`.

EDGE_TYPE 100 alongshore analyses are limited to SoG and WCVI sensitivities. EDGE_TYPE 150 remains pending local visual validation and cannot enter an analysis until validation is recorded.

Stop here. Stage 2 approval does not authorize Stage 3 entry implementation or a herring–bird response model. A separate authorization is required after the remaining checklist-construction and blocked-validation safeguards are ready.
