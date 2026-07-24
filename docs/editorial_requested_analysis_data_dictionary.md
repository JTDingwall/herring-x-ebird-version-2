# Editorial-requested analysis data dictionary

All tables are privacy-safe aggregates or model summaries. Blank numeric fields indicate suppression, non-estimability, or nonapplicability as specified by the row status. No table contains checklist, observer, event, block, locality, or coordinate identifiers.

## `verified_dataset_totals.csv`

Verified privacy-safe population and model inventory.

| Field | R type | Definition |
|---|---|---|
| `metric` | character | Name of an inventory quantity. |
| `value` | integer | Verified numerical value of the inventory quantity. |
| `unit` | character | Unit associated with value. |
| `scope` | character | Population and time scope of the inventory row. |
| `qa_status` | character | QA disposition for the row or requested analysis. |

## `period_zone_support.csv`

Checklist, source-event-link, and source-event support by frozen period and zone.

| Field | R type | Definition |
|---|---|---|
| `period` | character | Frozen event-study temporal period. |
| `zone` | character | Frozen spatial zone: near 0 to <5 km or reference 5 to 20 km. |
| `term` | character | Joint period-by-zone exposure predictor name. |
| `checklists` | integer | Privacy-safe number of eligible checklists in the category. |
| `event_links` | integer | Number of source-event-to-checklist links in the category. |
| `source_events` | integer | Number of distinct source herring events represented in the category. |

## `event_link_distribution.csv`

Exact and grouped additive source-event-link distributions.

| Field | R type | Definition |
|---|---|---|
| `distribution` | character | Link-count distribution being summarized. |
| `category` | integer | Exact or grouped link-count category. |
| `checklists` | integer | Privacy-safe number of eligible checklists in the category. |
| `proportion` | numeric | Share of the distribution total in the category. |

## `active_minus_pre_contrasts.csv`

Complete 49-species primary A14 and secondary A7 contrast results for both primary outcomes.

| Field | R type | Definition |
|---|---|---|
| `analysis_version` | character | Version identifier for the analysis that produced the row. |
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `comparison` | character | Compound timing contrast: A14 active-minus-pre14 or secondary A7 active-minus-pre7. |
| `primary_comparison` | logical | TRUE for the frozen primary A14 comparison. |
| `active_estimate` | numeric | Duration-weighted active-period baseline-adjusted near/reference estimate on the link scale. |
| `active_standard_error` | numeric | Standard error of active_estimate from the full fixed-effect covariance matrix. |
| `pre_estimate` | numeric | Pre-onset baseline-adjusted near/reference estimate on the link scale. |
| `pre_standard_error` | numeric | Standard error of pre_estimate from the full fixed-effect covariance matrix. |
| `active_pre_covariance` | numeric | Estimated covariance between the active and pre compound contrasts. |
| `estimate` | numeric | Compound contrast estimate on the fitted link scale, or the named absolute prediction quantity. |
| `standard_error` | numeric | Standard error of estimate. |
| `conf_low` | numeric | Lower bound of the two-sided 95% confidence interval. |
| `conf_high` | numeric | Upper bound of the two-sided 95% confidence interval. |
| `ratio` | numeric | Exponentiated link-scale contrast estimate. |
| `ratio_conf_low` | numeric | Lower 95% confidence bound after exponentiation. |
| `ratio_conf_high` | numeric | Upper 95% confidence bound after exponentiation. |
| `p_value` | numeric | Two-sided Wald p-value; blank when the model or contrast is not estimable. |
| `q_value` | numeric | Benjamini-Hochberg adjusted p-value within the stated outcome-by-comparison family. |
| `n` | integer | Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed. |
| `full_covariance_used` | logical | Whether all fixed-effect variance and covariance terms were used for the compound contrast. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `multiplicity_family` | character | Exact family within which BH adjustment was applied. |

## `observed_summaries.csv`

Observed unadjusted species summaries in each nonexclusive period-zone cell.

| Field | R type | Definition |
|---|---|---|
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `period` | character | Frozen event-study temporal period. |
| `zone` | character | Frozen spatial zone: near 0 to <5 km or reference 5 to 20 km. |
| `checklist_denominator` | integer | Linked eligible checklists contributing to the nonexclusive observed cell. |
| `event_links` | integer | Number of source-event-to-checklist links in the category. |
| `source_events` | integer | Number of distinct source herring events represented in the category. |
| `reported_checklists` | integer | Eligible linked checklists reporting the species; counts below 20 are suppressed. |
| `reporting_proportion` | numeric | Observed unadjusted reported_checklists divided by checklist_denominator. |
| `finite_numeric_reports` | integer | Reported occurrences stored as exact positive finite numeric counts; counts below 20 are suppressed. |
| `unquantified_x_reports` | integer | Reported occurrences stored as unquantified X; counts below 20 are suppressed. |
| `lower_bound_reports` | integer | Reported occurrences stored as lower-bound counts; counts below 20 are suppressed. |
| `other_reported_states` | integer | Reported occurrences in retained states other than finite numeric, X, or lower bound. |
| `finite_numeric_proportion_among_reports` | numeric | Observed share of reported occurrences with a positive finite numeric count. |
| `x_proportion_among_reports` | numeric | Observed share of reported occurrences recorded as X. |
| `positive_finite_count_q25` | integer | Observed first quartile of positive finite numeric counts. |
| `positive_finite_count_median` | integer | Observed median of positive finite numeric counts. |
| `positive_finite_count_q75` | numeric | Observed third quartile of positive finite numeric counts. |
| `observed_unadjusted` | logical | TRUE when the row is a descriptive, unadjusted summary. |
| `suppressed_below_20` | logical | Whether the applicable cell was suppressed for having fewer than 20 rows. |

## `finite_vs_x_observed_summary.csv`

Species totals and class support for finite numeric versus X assignment.

| Field | R type | Definition |
|---|---|---|
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `reported_occurrences` | integer | All reported occurrences before restriction to finite numeric or X states. |
| `finite_vs_x_denominator` | integer | Unambiguous reported occurrences eligible for the finite-numeric-versus-X comparison. |
| `finite_numeric_reports` | integer | Reported occurrences stored as exact positive finite numeric counts; counts below 20 are suppressed. |
| `unquantified_x_reports` | integer | Reported occurrences stored as unquantified X; counts below 20 are suppressed. |
| `finite_numeric_proportion` | numeric | Observed finite-numeric share of the finite-or-X denominator, released only with support in both classes. |
| `event_blocks` | integer | Number of represented leakage-control event-block random-effect levels; counts below 20 are suppressed. |
| `observer_clusters` | integer | Number of represented privacy-safe observer-cluster levels; counts below 20 are suppressed. |
| `generalized_locations` | integer | Number of represented generalized-location random-effect levels; counts below 20 are suppressed. |

## `finite_vs_x_results.csv`

Complete 49-species exploratory finite-numeric-versus-X A14 and A7 results.

| Field | R type | Definition |
|---|---|---|
| `analysis_version` | character | Version identifier for the analysis that produced the row. |
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `comparison` | character | Compound timing contrast: A14 active-minus-pre14 or secondary A7 active-minus-pre7. |
| `primary_comparison` | logical | TRUE for the frozen primary A14 comparison. |
| `active_estimate` | numeric | Duration-weighted active-period baseline-adjusted near/reference estimate on the link scale. |
| `active_standard_error` | numeric | Standard error of active_estimate from the full fixed-effect covariance matrix. |
| `pre_estimate` | numeric | Pre-onset baseline-adjusted near/reference estimate on the link scale. |
| `pre_standard_error` | numeric | Standard error of pre_estimate from the full fixed-effect covariance matrix. |
| `active_pre_covariance` | numeric | Estimated covariance between the active and pre compound contrasts. |
| `estimate` | numeric | Compound contrast estimate on the fitted link scale, or the named absolute prediction quantity. |
| `standard_error` | numeric | Standard error of estimate. |
| `conf_low` | numeric | Lower bound of the two-sided 95% confidence interval. |
| `conf_high` | numeric | Upper bound of the two-sided 95% confidence interval. |
| `ratio` | numeric | Exponentiated link-scale contrast estimate. |
| `ratio_conf_low` | numeric | Lower 95% confidence bound after exponentiation. |
| `ratio_conf_high` | numeric | Upper 95% confidence bound after exponentiation. |
| `p_value` | numeric | Two-sided Wald p-value; blank when the model or contrast is not estimable. |
| `q_value` | numeric | Benjamini-Hochberg adjusted p-value within the stated outcome-by-comparison family. |
| `n` | integer | Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed. |
| `full_covariance_used` | logical | Whether all fixed-effect variance and covariance terms were used for the compound contrast. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `multiplicity_family` | character | Exact family within which BH adjustment was applied. |

## `absolute_predictions.csv`

Adjusted absolute levels and contrasts under two documented prediction configurations.

| Field | R type | Definition |
|---|---|---|
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `prediction_configuration` | character | Standardized profile or observed-covariate standardization. |
| `quantity` | character | Named predicted level or compound absolute-scale contrast. |
| `estimate` | numeric | Compound contrast estimate on the fitted link scale, or the named absolute prediction quantity. |
| `conf_low` | numeric | Lower bound of the two-sided 95% confidence interval. |
| `conf_high` | numeric | Upper bound of the two-sided 95% confidence interval. |
| `interval_method` | character | Method used to propagate fixed-effect covariance to the 95% interval. |
| `random_effect_handling` | character | How random effects were treated in prediction. |
| `covariate_handling` | character | Values or distribution used for non-exposure covariates. |
| `population` | character | Population to which the prediction configuration applies. |

## `model_diagnostics.csv`

Fit, convergence, gradient, rank, singularity, and random-effect diagnostics.

| Field | R type | Definition |
|---|---|---|
| `analysis_version` | character | Version identifier for the analysis that produced the row. |
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `engine` | character | Model-fitting engine, likelihood family, and approximation. |
| `n` | integer | Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed. |
| `event_blocks` | integer | Number of represented leakage-control event-block random-effect levels; counts below 20 are suppressed. |
| `observer_clusters` | integer | Number of represented privacy-safe observer-cluster levels; counts below 20 are suppressed. |
| `generalized_locations` | integer | Number of represented generalized-location random-effect levels; counts below 20 are suppressed. |
| `converged` | logical | Whether the fitted model met the repository convergence classification. |
| `singular_fit` | logical | Whether one or more fitted random-effect variance components were on the boundary at tolerance 1e-4. |
| `rank_deficient` | logical | Whether the fixed-effect model matrix lost rank. |
| `optimizer_code` | integer | Native optimizer return code; zero means the optimizer completed. |
| `convergence_message` | character | Truncated optimizer or lme4 convergence message. |
| `maximum_absolute_gradient` | numeric | Maximum absolute raw derivative component reported by the fitted model. |
| `event_block_variance` | numeric | Estimated variance of the event-block random intercept. |
| `observer_variance` | numeric | Estimated variance of the observer-cluster random intercept. |
| `location_variance` | numeric | Estimated variance of the generalized-location random intercept. |
| `residual_variance` | numeric | Estimated residual variance for the log-Gaussian count model; blank for binomial models. |
| `reproduction_max_abs_estimate_difference` | numeric | Maximum absolute difference from matching frozen historical component estimates. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |

## `model_term_support.csv`

Outcome-specific support for every joint exposure term.

| Field | R type | Definition |
|---|---|---|
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `term` | character | Joint period-by-zone exposure predictor name. |
| `exposed_rows` | integer | Model rows with a positive value of the named exposure term; counts below 20 are suppressed. |
| `finite_numeric_rows` | logical | Finite-numeric model rows exposed in the named term; counts below 20 are suppressed. |
| `unquantified_x_rows` | logical | Unquantified-X model rows exposed in the named term; counts below 20 are suppressed. |

## `event_block_influence_support.csv`

Outcome-blind distribution of event-block checklist support.

| Field | R type | Definition |
|---|---|---|
| `checklist_support_bin` | character | Outcome-blind bin of eligible-checklist support per event block. |
| `event_blocks` | integer | Number of represented leakage-control event-block random-effect levels; counts below 20 are suppressed. |
| `checklists` | integer | Privacy-safe number of eligible checklists in the category. |
| `influence_basis` | character | Statement that block influence potential uses support only and no response inspection. |

## `sensitivity_comparisons.csv`

Sensitivity A14/A7 estimates joined to matching primary estimates.

| Field | R type | Definition |
|---|---|---|
| `analysis_version` | character | Version identifier for the analysis that produced the row. |
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `comparison` | character | Compound timing contrast: A14 active-minus-pre14 or secondary A7 active-minus-pre7. |
| `primary_comparison` | logical | TRUE for the frozen primary A14 comparison. |
| `active_estimate` | numeric | Duration-weighted active-period baseline-adjusted near/reference estimate on the link scale. |
| `active_standard_error` | numeric | Standard error of active_estimate from the full fixed-effect covariance matrix. |
| `pre_estimate` | numeric | Pre-onset baseline-adjusted near/reference estimate on the link scale. |
| `pre_standard_error` | numeric | Standard error of pre_estimate from the full fixed-effect covariance matrix. |
| `active_pre_covariance` | numeric | Estimated covariance between the active and pre compound contrasts. |
| `estimate` | numeric | Compound contrast estimate on the fitted link scale, or the named absolute prediction quantity. |
| `standard_error` | numeric | Standard error of estimate. |
| `conf_low` | numeric | Lower bound of the two-sided 95% confidence interval. |
| `conf_high` | numeric | Upper bound of the two-sided 95% confidence interval. |
| `ratio` | numeric | Exponentiated link-scale contrast estimate. |
| `ratio_conf_low` | numeric | Lower 95% confidence bound after exponentiation. |
| `ratio_conf_high` | numeric | Upper 95% confidence bound after exponentiation. |
| `p_value` | numeric | Two-sided Wald p-value; blank when the model or contrast is not estimable. |
| `n` | integer | Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed. |
| `full_covariance_used` | logical | Whether all fixed-effect variance and covariance terms were used for the compound contrast. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `multiplicity_family` | character | Exact family within which BH adjustment was applied. |
| `sensitivity_id` | character | Frozen identifier for the exposure encoding or cohort restriction. |
| `sensitivity_q_value` | numeric | BH-adjusted p-value within the sensitivity, outcome, and comparison family. |
| `primary_estimate` | numeric | Matching primary A14/A7 link-scale estimate. |
| `primary_standard_error` | numeric | Standard error of the matching primary estimate. |
| `primary_conf_low` | numeric | Lower 95% confidence bound for the matching primary estimate. |
| `primary_conf_high` | numeric | Upper 95% confidence bound for the matching primary estimate. |
| `primary_ratio` | numeric | Exponentiated matching primary estimate. |
| `primary_ratio_conf_low` | numeric | Lower exponentiated 95% confidence bound for the primary estimate. |
| `primary_ratio_conf_high` | numeric | Upper exponentiated 95% confidence bound for the primary estimate. |
| `primary_q_value` | numeric | BH-adjusted p-value for the matching primary estimate. |
| `primary_status` | character | Completion or warning status of the matching primary model. |
| `estimate_difference_from_primary` | numeric | Sensitivity estimate minus matching primary estimate on the link scale. |
| `direction_concordant` | logical | Whether the sensitivity and primary link-scale estimates have the same sign. |
| `model_n` | integer | Privacy-safe row count used by the sensitivity model. |
| `model_event_blocks` | integer | Event-block random-effect levels represented in the sensitivity model. |
| `model_observer_clusters` | integer | Observer-cluster random-effect levels represented in the sensitivity model. |
| `model_generalized_locations` | integer | Generalized-location random-effect levels represented in the sensitivity model. |
| `retained_checklists` | integer | Eligible checklists retained after the outcome-blind sensitivity transformation. |
| `retained_fraction` | integer | retained_checklists divided by the 217,200-checklist primary frame. |
| `changed_component` | character | Exact exposure encoding or cohort component changed by the sensitivity. |

## `sensitivity_diagnostics.csv`

Model diagnostics for completed full-family sensitivities.

| Field | R type | Definition |
|---|---|---|
| `analysis_version` | character | Version identifier for the analysis that produced the row. |
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `engine` | character | Model-fitting engine, likelihood family, and approximation. |
| `n` | integer | Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed. |
| `event_blocks` | integer | Number of represented leakage-control event-block random-effect levels; counts below 20 are suppressed. |
| `observer_clusters` | integer | Number of represented privacy-safe observer-cluster levels; counts below 20 are suppressed. |
| `generalized_locations` | integer | Number of represented generalized-location random-effect levels; counts below 20 are suppressed. |
| `converged` | logical | Whether the fitted model met the repository convergence classification. |
| `singular_fit` | logical | Whether one or more fitted random-effect variance components were on the boundary at tolerance 1e-4. |
| `rank_deficient` | logical | Whether the fixed-effect model matrix lost rank. |
| `optimizer_code` | integer | Native optimizer return code; zero means the optimizer completed. |
| `convergence_message` | character | Truncated optimizer or lme4 convergence message. |
| `maximum_absolute_gradient` | numeric | Maximum absolute raw derivative component reported by the fitted model. |
| `event_block_variance` | numeric | Estimated variance of the event-block random intercept. |
| `observer_variance` | numeric | Estimated variance of the observer-cluster random intercept. |
| `location_variance` | numeric | Estimated variance of the generalized-location random intercept. |
| `residual_variance` | numeric | Estimated residual variance for the log-Gaussian count model; blank for binomial models. |
| `reproduction_max_abs_estimate_difference` | logical | Maximum absolute difference from matching frozen historical component estimates. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `sensitivity_id` | character | Frozen identifier for the exposure encoding or cohort restriction. |

## `sensitivity_support.csv`

Outcome-blind retained cohort and transformed-link support by sensitivity.

| Field | R type | Definition |
|---|---|---|
| `sensitivity_id` | character | Frozen identifier for the exposure encoding or cohort restriction. |
| `retained_checklists` | integer | Eligible checklists retained after the outcome-blind sensitivity transformation. |
| `retained_fraction` | integer | retained_checklists divided by the 217,200-checklist primary frame. |
| `event_blocks` | integer | Number of represented leakage-control event-block random-effect levels; counts below 20 are suppressed. |
| `observer_clusters` | integer | Number of represented privacy-safe observer-cluster levels; counts below 20 are suppressed. |
| `generalized_locations` | integer | Number of represented generalized-location random-effect levels; counts below 20 are suppressed. |
| `transformed_event_link_total` | integer | Sum of the 12 transformed joint link predictors across retained checklists. |
| `checklists_with_transformed_links` | integer | Retained checklists with at least one positive transformed exposure term. |
| `maximum_transformed_link_total` | integer | Maximum row sum of transformed joint exposure terms. |
| `changed_component` | character | Exact exposure encoding or cohort component changed by the sensitivity. |
| `unchanged_components` | character | Model components explicitly held fixed in the sensitivity. |
| `response_fields_read_for_transform` | integer | Count of response fields used to define the outcome-blind transformation; required to be zero. |

## `link_count_outcome_support.csv`

Privacy-suppressed observed outcome support at each exact term-specific link count.

| Field | R type | Definition |
|---|---|---|
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `term` | character | Joint period-by-zone exposure predictor name. |
| `zone` | character | Frozen spatial zone: near 0 to <5 km or reference 5 to 20 km. |
| `period` | character | Frozen event-study temporal period. |
| `link_count` | integer | Exact additive source-event-link count for the named term. |
| `checklist_rows` | integer | Eligible rows at the exact link count; suppressed below 20. |
| `reported_checklists` | integer | Eligible linked checklists reporting the species; counts below 20 are suppressed. |
| `reporting_proportion` | numeric | Observed unadjusted reported_checklists divided by checklist_denominator. |
| `positive_finite_numeric_reports` | integer | Rows at the exact link count with a reported positive finite numeric count. |
| `positive_finite_numeric_median` | numeric | Observed median positive finite numeric count at the exact link count. |
| `unquantified_x_reports` | integer | Reported occurrences stored as unquantified X; counts below 20 are suppressed. |
| `suppressed_below_20` | logical | Whether the applicable cell was suppressed for having fewer than 20 rows. |
| `observed_unadjusted` | logical | TRUE when the row is a descriptive, unadjusted summary. |

## `family_timing_summary.csv`

Descriptive full-family A14 sign, BH, and distribution summary.

| Field | R type | Definition |
|---|---|---|
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `comparison` | character | Compound timing contrast: A14 active-minus-pre14 or secondary A7 active-minus-pre7. |
| `family_species` | integer | Species rows in the frozen inferential family. |
| `estimable_species` | integer | Species with finite compound estimate and standard error. |
| `completed_species` | integer | Species whose model status begins with completed. |
| `failed_or_unsupported_species` | integer | Species without a finite compound estimate. |
| `singular_warning_species` | integer | Completed species models carrying a singular-fit warning. |
| `convergence_warning_species` | integer | Completed species models carrying a convergence warning. |
| `positive_estimates` | integer | Finite compound estimates above zero. |
| `negative_estimates` | integer | Finite compound estimates below zero. |
| `bh_q_lt_0_05` | integer | Finite estimates with BH q-value below 0.05. |
| `bh_positive` | integer | BH-significant estimates above zero. |
| `bh_negative` | integer | BH-significant estimates below zero. |
| `median_link_estimate` | numeric | Median finite compound estimate on the link scale. |
| `q25_link_estimate` | numeric | First quartile of finite compound estimates on the link scale. |
| `q75_link_estimate` | numeric | Third quartile of finite compound estimates on the link scale. |
| `dependence_aware_family_test` | character | Disposition of the cross-species dependence-aware family test. |

## `completion_failure_log.csv`

Complete model-component counts by outcome, status, and analysis group.

| Field | R type | Definition |
|---|---|---|
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `model_components` | integer | Number of species-by-outcome model components in the status group. |
| `analysis_group` | character | Primary/finite-X family or named sensitivity to which the status count applies. |

## `analysis_status.csv`

Machine-readable disposition of every editorial request.

| Field | R type | Definition |
|---|---|---|
| `requested_analysis` | character | Editorial-requested analysis component. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `exact_input_and_model` | character | Concise specification of the exact input, transformation, and model. |
| `estimand` | character | Quantity targeted by the requested analysis. |
| `sample_and_event_support` | character | Verified or referenced checklist, species, event, or block support. |
| `output_path` | character | Repository-relative artifact path. |
| `qa_status` | character | QA disposition for the row or requested analysis. |
| `principal_caveat` | character | Most important limitation on interpretation. |
| `could_change_manuscript_wording` | character | Whether the component could materially affect manuscript wording. |

## `engine_validation_results.csv`

Representative glmmTMB A14/A7 estimates joined to their primary counterparts.

| Field | R type | Definition |
|---|---|---|
| `analysis_version` | character | Version identifier for the analysis that produced the row. |
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `comparison` | character | Compound timing contrast: A14 active-minus-pre14 or secondary A7 active-minus-pre7. |
| `primary_comparison` | logical | TRUE for the frozen primary A14 comparison. |
| `active_estimate` | numeric | Duration-weighted active-period baseline-adjusted near/reference estimate on the link scale. |
| `active_standard_error` | numeric | Standard error of active_estimate from the full fixed-effect covariance matrix. |
| `pre_estimate` | numeric | Pre-onset baseline-adjusted near/reference estimate on the link scale. |
| `pre_standard_error` | numeric | Standard error of pre_estimate from the full fixed-effect covariance matrix. |
| `active_pre_covariance` | numeric | Estimated covariance between the active and pre compound contrasts. |
| `estimate` | numeric | Compound contrast estimate on the fitted link scale, or the named absolute prediction quantity. |
| `standard_error` | numeric | Standard error of estimate. |
| `conf_low` | numeric | Lower bound of the two-sided 95% confidence interval. |
| `conf_high` | numeric | Upper bound of the two-sided 95% confidence interval. |
| `ratio` | numeric | Exponentiated link-scale contrast estimate. |
| `ratio_conf_low` | numeric | Lower 95% confidence bound after exponentiation. |
| `ratio_conf_high` | numeric | Upper 95% confidence bound after exponentiation. |
| `p_value` | numeric | Two-sided Wald p-value; blank when the model or contrast is not estimable. |
| `q_value` | logical | Benjamini-Hochberg adjusted p-value within the stated outcome-by-comparison family. |
| `n` | integer | Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed. |
| `full_covariance_used` | logical | Whether all fixed-effect variance and covariance terms were used for the compound contrast. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `engine` | character | Model-fitting engine, likelihood family, and approximation. |
| `primary_estimate` | numeric | Matching primary A14/A7 link-scale estimate. |
| `primary_standard_error` | numeric | Standard error of the matching primary estimate. |
| `primary_conf_low` | numeric | Lower 95% confidence bound for the matching primary estimate. |
| `primary_conf_high` | numeric | Upper 95% confidence bound for the matching primary estimate. |
| `primary_ratio` | numeric | Exponentiated matching primary estimate. |
| `primary_q_value` | numeric | BH-adjusted p-value for the matching primary estimate. |
| `estimate_difference_from_primary` | numeric | Sensitivity estimate minus matching primary estimate on the link scale. |
| `direction_concordant` | logical | Whether the sensitivity and primary link-scale estimates have the same sign. |

## `engine_validation_diagnostics.csv`

Convergence, Hessian, gradient, dispersion, and random-effect diagnostics for representative glmmTMB fits.

| Field | R type | Definition |
|---|---|---|
| `analysis_taxon_id` | character | Privacy-safe stable analysis taxon token; not an eBird record identifier. |
| `species` | character | English common name under the frozen v2025 taxonomy crosswalk. |
| `outcome` | character | Modeled observation process: checklist reporting, conditional positive numeric count, or finite numeric versus X. |
| `engine` | character | Model-fitting engine, likelihood family, and approximation. |
| `n` | integer | Privacy-safe number of rows used by the fitted model; counts below 20 are suppressed. |
| `event_blocks` | integer | Number of represented leakage-control event-block random-effect levels; counts below 20 are suppressed. |
| `observer_clusters` | integer | Number of represented privacy-safe observer-cluster levels; counts below 20 are suppressed. |
| `generalized_locations` | integer | Number of represented generalized-location random-effect levels; counts below 20 are suppressed. |
| `optimizer_code` | integer | Native optimizer return code; zero means the optimizer completed. |
| `positive_definite_hessian` | logical | Whether the glmmTMB standard-error Hessian was positive definite. |
| `maximum_absolute_gradient` | numeric | Maximum absolute raw derivative component reported by the fitted model. |
| `singular_fit` | logical | Whether one or more fitted random-effect variance components were on the boundary at tolerance 1e-4. |
| `event_block_variance` | numeric | Estimated variance of the event-block random intercept. |
| `observer_variance` | numeric | Estimated variance of the observer-cluster random intercept. |
| `location_variance` | numeric | Estimated variance of the generalized-location random intercept. |
| `dispersion_parameter` | numeric | Estimated glmmTMB negative-binomial dispersion parameter; nonapplicable to the binomial validation. |
| `convergence_message` | character | Truncated optimizer or lme4 convergence message. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |

## `qa_summary.csv`

Deterministic checkpoint, algebra, key, holdout, and privacy QA results.

| Field | R type | Definition |
|---|---|---|
| `check` | character | Name of a deterministic QA gate. |
| `status` | character | Completion, warning, failure, support, or feasibility classification. |
| `observed` | character | Value observed by the QA gate. |
| `expected` | character | Required value or range for the QA gate. |
| `tolerance` | numeric | Absolute numerical tolerance where applicable. |

## `output_hash_manifest.csv`

SHA-256 manifest for released editorial output files.

| Field | R type | Definition |
|---|---|---|
| `file` | character | Repository-relative output file included in the hash manifest. |
| `sha256` | character | SHA-256 digest of the exact file bytes. |
