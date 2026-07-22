#!/usr/bin/env Rscript

# Build the Stage 4A v2 manuscript audit package from frozen, privacy-safe
# aggregate outputs. This script performs no response-model fitting.

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args)) normalizePath(args[[1]], winslash = "/", mustWork = TRUE) else
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)

freeze_commit <- "c54b8e7f95a2fe3573e2e38633079cd223c5a783"
freeze_tag <- "stage4a-publication-v2-analysis-freeze"
generation_commit <- Sys.getenv("STAGE4A_MANUSCRIPT_GENERATION_COMMIT", "WORKTREE")

repo_file <- function(...) file.path(project_root, ...)
dir.create(repo_file("manuscript"), showWarnings = FALSE, recursive = TRUE)
dir.create(repo_file("manuscript", "generated"), showWarnings = FALSE, recursive = TRUE)
dir.create(repo_file("manuscript", "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(repo_file("manuscript", "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(repo_file("manuscript", "rendered"), showWarnings = FALSE, recursive = TRUE)

stopf <- function(...) stop(sprintf(...), call. = FALSE)
assert_true <- function(x, msg) if (!isTRUE(x)) stopf("%s", msg)
read_csv <- function(...) read.csv(repo_file(...), stringsAsFactors = FALSE,
                                    check.names = FALSE, na.strings = c(""))
write_csv <- function(x, path) {
  write.table(x, file = path, sep = ",", row.names = FALSE, col.names = TRUE,
              quote = TRUE, na = "", eol = "\n", fileEncoding = "UTF-8")
}
write_text <- function(x, path) writeLines(enc2utf8(x), con = path, useBytes = TRUE, sep = "\n")
key <- function(x, cols) do.call(paste, c(x[cols], sep = "|"))
assert_unique <- function(x, cols, label) {
  assert_true(!anyDuplicated(key(x, cols)), sprintf("%s key is not unique: %s", label, paste(cols, collapse = ", ")))
}
fmt_num <- function(x, digits = 2) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = digits))
fmt_q <- function(x) ifelse(is.na(x), "NA", ifelse(x < 0.001, formatC(x, format = "e", digits = 2), formatC(x, format = "f", digits = 3)))
fmt_int <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (.Platform$OS.type == "windows") {
    out <- system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE, stderr = TRUE)
    hit <- grep("^[0-9A-Fa-f]{64}$", trimws(out), value = TRUE)
  } else {
    out <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = TRUE)
    hit <- sub("[[:space:]].*$", "", out[grepl("^[0-9A-Fa-f]{64}[[:space:]]", out)])
  }
  assert_true(length(hit) == 1L, sprintf("Could not compute SHA-256 for %s", path))
  tolower(trimws(hit[[1]]))
}

md_escape <- function(x) gsub("\\|", "\\\\|", ifelse(is.na(x), "NA", as.character(x)))
md_table <- function(x, align = NULL) {
  x[] <- lapply(x, md_escape)
  if (is.null(align)) align <- rep("left", ncol(x))
  marks <- ifelse(align == "right", "---:", ifelse(align == "center", ":---:", "---"))
  rows <- apply(x, 1, function(z) paste0("| ", paste(z, collapse = " | "), " |"))
  c(paste0("| ", paste(names(x), collapse = " | "), " |"),
    paste0("| ", paste(marks, collapse = " | "), " |"), rows)
}

# Frozen source inventory.
primary <- read_csv("outputs", "stage4a_publication_v2", "primary_guild_table_v2.csv")
species <- read_csv("outputs", "stage4a_publication_v2", "priority_a_species_table_v2.csv")
event_time <- read_csv("outputs", "stage4a_publication_v2", "event_time_table_v2.csv")
sensitivity <- read_csv("outputs", "stage4a_publication_v2", "matched_sensitivity_table_v2.csv")
concordance <- read_csv("outputs", "stage4a_publication_v2", "sensitivity_concordance_v2.csv")
sens_summary <- read_csv("outputs", "stage4a_publication_v2", "sensitivity_summary_v2.csv")
pooling_summary <- read_csv("outputs", "stage4a_publication_v2", "pooling_repair_summary_v2.csv")
exclusion_summary <- read_csv("outputs", "stage4a_publication_v2", "supplementary_exclusion_summary_v2.csv")
effect_all <- read_csv("outputs", "stage4a_results", "effect_estimates.csv")
sample_all <- read_csv("outputs", "stage4a_results", "aggregate_sample_sizes.csv")
diagnostics <- read_csv("outputs", "stage4a_publication_sensitivity_v2", "model_diagnostics_v2.csv")
sens_effects <- read_csv("outputs", "stage4a_publication_sensitivity_v2", "sensitivity_effect_estimates_v2.csv")
region_registry <- read_csv("metadata", "stage4a_region_registry_v2.csv")

assert_true(nrow(primary) == 32L, "Expected 32 primary guild rows")
assert_true(nrow(species) == 20L, "Expected 20 priority-A species rows")
assert_true(nrow(event_time) == 160L, "Expected 160 event-time rows")
assert_true(nrow(sensitivity) == 128L, "Expected 128 matched sensitivity rows")
assert_true(sum(sensitivity$status == "completed_with_singular_warning") == 43L,
            "Expected 43 singular-warning components")
assert_true(sum(sensitivity$model_version_id %in% c("M27_v2", "M28_v2") & sensitivity$q_value < 0.05, na.rm = TRUE) == 0L,
            "Expected no BH-significant placebo component")
assert_true(all(sensitivity$status %in% c("completed", "completed_with_singular_warning")),
            "Every sensitivity must be completed or completed with singular warning")
assert_unique(diagnostics, c("model_version_id", "region", "unit_label", "outcome"), "diagnostic")
assert_unique(sens_effects, c("model_version_id", "region", "unit_label", "outcome"), "sensitivity effect")

pool_metric <- setNames(as.numeric(pooling_summary$value), pooling_summary$metric)
assert_true(pool_metric[["invalid_v1_finite_rows"]] == 6562, "Pooling invalid-row count changed")
assert_true(pool_metric[["invalid_v1_families"]] == 112, "Pooling invalid-family count changed")
assert_true(pool_metric[["estimable_v2_families"]] == 162, "Pooling estimable-family count changed")
assert_true(sum(as.numeric(exclusion_summary$rows)) == 6562, "Pooling disposition total changed")

# Join cardinality: diagnostics 1:1 sensitivity estimates on the declared component key.
join_cols <- c("model_version_id", "region", "unit_label", "outcome")
sing_diag <- diagnostics[diagnostics$singular_fit == "TRUE", , drop = FALSE]
sing <- merge(sing_diag, sens_effects, by = join_cols, all.x = TRUE, all.y = FALSE, sort = FALSE,
              suffixes = c("_diagnostic", "_estimate"))
assert_true(nrow(sing) == 43L, "Singular audit join did not retain 43 rows")
assert_true(all(is.finite(sing$estimate) & is.finite(sing$standard_error) &
                  is.finite(sing$conf_low) & is.finite(sing$conf_high)),
            "A singular-warning coefficient or interval is non-finite")

singular_audit <- data.frame(
  component_id = paste(sing$model_version_id, sing$region, sing$unit_label, sing$outcome, sep = "|"),
  model_version_id = sing$model_version_id,
  species_or_guild = sing$unit_label,
  region = sing$region,
  sensitivity_family = ifelse(sing$model_version_id == "M01_PRIMARY_v2", "matched_primary_reference",
    ifelse(sing$model_version_id == "M27_v2", "whole_bundle_date_placebo",
      ifelse(sing$model_version_id == "M28_v2", "whole_bundle_location_placebo",
        ifelse(grepl("DOMINANT", sing$model_version_id), "dominant_observer_holdout", "wcvi_2km")))),
  outcome = sing$outcome,
  intended_random_effects_structure = "random intercepts for event block, observer cluster, and generalized location cluster",
  singularity_diagnostic = "lme4 singular fit: one or more random-effect variance terms estimated on the boundary",
  effective_variance_structure = "effectively simpler than the intended three-intercept structure; released diagnostics do not identify the collapsed term",
  coefficient_estimate = sing$estimate,
  standard_error = sing$standard_error,
  conf_low = sing$conf_low,
  conf_high = sing$conf_high,
  coefficient_finite = TRUE,
  standard_error_and_interval_finite = TRUE,
  contributes_to_pooled_result = FALSE,
  appears_in_main_table = FALSE,
  appears_in_main_figure = TRUE,
  headline_claim_depends_on_component = FALSE,
  matched_primary_or_sensitivity_comparison = ifelse(sing$model_version_id == "M01_PRIMARY_v2",
    "matched reference for WCVI sensitivity comparisons", "compare with M01_PRIMARY_v2 for same region, guild, and outcome"),
  manuscript_treatment = ifelse(sing$model_version_id %in% c("M27_v2", "M28_v2"),
    "retain in main diagnostic figure; do not use as biological support; disclose warning and tabulate in supplement",
    "retain as qualified robustness evidence; disclose warning in main diagnostics and full supplement"),
  reason_for_treatment = "finite coefficient and interval, but boundary variance estimate weakens confidence in the intended clustering structure; no headline claim relies exclusively on this component",
  stringsAsFactors = FALSE
)
write_csv(singular_audit, repo_file("outputs", "stage4a_publication_v2", "singular_fit_claim_audit_v2.csv"))

# Non-null Strait of Georgia specificity/falsification panel.
fals <- effect_all[effect_all$model_id == "M29" & effect_all$region == "SoG", , drop = FALSE]
assert_true(nrow(fals) == 2L, "Expected exactly two SoG M29 specificity rows")
assert_true(all(fals$q_value < 0.05), "Expected both SoG specificity estimates to have BH q < 0.05")
falsification_audit <- data.frame(
  panel_id = "M29_SoG_detection",
  registered_purpose = "prespecified specificity and falsification panel; taxa were not assumed guaranteed biological nonresponders",
  model_id = fals$model_id,
  outcome = fals$outcome,
  species = fals$unit_label,
  region = fals$region,
  exposure = fals$contrast,
  estimate_log_odds = fals$estimate,
  standard_error = fals$standard_error,
  conf_low = fals$conf_low,
  conf_high = fals$conf_high,
  p_value = fals$p_value,
  bh_q_value = fals$q_value,
  n = fals$n,
  sign_and_magnitude_comparison = "positive and within the range of SoG primary guild detection coefficients",
  temporal_spatial_relation_to_true_exposure = "uses the same recorded active-near exposure and SoG checklist frame; it is not a shifted-exposure placebo",
  process_targeted = "biological specificity plus residual seasonal, spatial-access, checklist-submission, site-selection, or exposure-classification structure",
  directly_challenges = "causal, species-specific, and simple mechanism-specific interpretations of SoG detection associations",
  does_not_directly_address = "positive-count components, WCVI associations, population abundance, or whether eligible checklists are descriptively associated with recorded exposure",
  resulting_claim_qualification = "retain descriptive checklist-conditional association; downgrade ecological specificity and foreground residual confounding and classification explanations",
  inclusion_status = "main text and main diagnostic table",
  stringsAsFactors = FALSE
)
write_csv(falsification_audit, repo_file("outputs", "stage4a_publication_v2", "sog_falsification_claim_audit_v2.csv"))

# Claim-to-evidence matrix. Summary claims reference all required deterministic keys.
claim_cols <- c("claim_id", "provisional_manuscript_section", "proposed_claim_text", "classification",
                "estimand_identifier", "model_identifier_or_family", "species_or_guild", "region",
                "exposure_window", "source_output_file", "source_row_or_deterministic_key",
                "table_identifier", "figure_identifier", "individual_model_support", "pooled_family_support",
                "placebo_result", "wcvi_2km_result", "dominant_observer_result", "regional_or_falsification_result",
                "singular_fit_status", "multiplicity_status", "robustness_classification", "permitted_wording",
                "prohibited_wording", "required_qualification", "inclusion_status", "reason_for_status")
claims <- list(
  c("C001","Abstract; Results","The primary frames contained 217,200 eligible SoG checklist events from 2005 and 8,584 eligible WCVI checklist events from 2015, with responses read only through 2025.","methodological","eligible submitted complete checklist","M01/M02","all registered units","SoG; WCVI","registered frame","outputs/stage4a_results/aggregate_sample_sizes.csv","unique n by region","Table 1","Figure 1","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","robust","eligible checklist events in the frozen frame","bird population size or survey census","counts are checklist-frame sizes, not independent birds or population abundance","headline","directly verified in aggregate sample-size output"),
  c("C002","Results","SoG ecological guild detection associations were heterogeneous: five of seven estimates were positive and two were negative, with all seven BH q-values below 0.05.","confirmatory","active-near checklist detection log-odds","M01","seven ecological guilds","SoG","active-near","outputs/stage4a_publication_v2/primary_guild_table_v2.csv","model_id=M01|region=SoG|outcome=detection|unit_label!=falsification","Table 2","Figure 2","all seven individual coefficients reported","compatible v2 posterior shown","M27/M28 diagnostic only","not applicable","not applicable","M29 SoG panel non-null","ordinary fits","BH within registered M01 SoG detection family","supported with qualification","heterogeneous checklist-detection associations","universal positive response or causal aggregation effect","non-null specificity panel and checklist selection limit ecological specificity","headline","registered complete family; direction and multiplicity are transparent"),
  c("C003","Results","SoG ecological guild positive-count associations were heterogeneous, including positive, negative, and imprecise coefficients.","confirmatory","active-near positive log count conditional on numeric detection","M01","seven ecological guilds","SoG","active-near","outputs/stage4a_publication_v2/primary_guild_table_v2.csv","model_id=M01|region=SoG|outcome=positive_count|unit_label!=falsification","Table 2","Figure 2","all seven individual coefficients reported","compatible v2 posterior shown","M27/M28 diagnostic only","not applicable","not applicable","M29 is detection-only","ordinary fits","BH within registered family","supported with qualification","conditional positive-count association","abundance or biomass change","conditional on a positive numeric report; X is not a numeric count","main text","complete family prevents significance-only reporting"),
  c("C004","Abstract; Results","WCVI guild coefficients differed by guild and outcome; matched 2-km and dominant-observer sensitivities preserved the matched-reference sign in 15 of 16 components each.","secondary","matched M01 checklist detection and positive-log-count associations","M01_PRIMARY_v2; S4A11; S4A12","eight registered guilds","WCVI","active-near","outputs/stage4a_publication_v2/sensitivity_concordance_v2.csv","model_version_id in S4A11_WCVI_DOMINANT_OBSERVER_v2,S4A12_WCVI_2KM_v2","Table 3","Figure 4","matched reference reported","not pooled","not applicable","15/16 same sign","15/16 same sign","WCVI specificity panel not BH-significant","17 of 32 sensitivity/reference components in Figure 4 have singular warnings","BH within model-version x region x outcome family","supported with qualification","directional agreement in matched sensitivities","fully robust or unbiased WCVI effect","sparse geometry and singular random-effect fits remain visible","headline","two prespecified dimensions generally preserve sign but boundary fits preclude unqualified robustness"),
  c("C005","Results","Surf Scoter and Short-billed Gull had positive detection and conditional positive-count coefficients in both primary regions, while other priority species were region- or component-dependent.","confirmatory","M02 active-near detection and conditional positive count","M02","five priority-A species","SoG; WCVI","active-near","outputs/stage4a_publication_v2/priority_a_species_table_v2.csv","all 20 rows","Table 2","Supplementary Figure S1","all 20 individual coefficients reported","compatible v2 posterior available","not species-matched","not species-matched","not species-matched","SoG M29 panel weakens specificity","ordinary fits in frozen M02 table","BH within registered species-outcome family","supported with qualification","species- and component-dependent associations","all focal species aggregated or increased","interpretation is checklist-conditional and not movement evidence","main text","two species show cross-region direction while other prespecified species do not"),
  c("C006","Results","Registered event-time coefficients varied across guilds, outcomes, windows, and regions rather than forming one common monotone trajectory.","secondary","discrete event-time checklist associations","M05","eight guilds","SoG; WCVI","five frozen windows","outputs/stage4a_publication_v2/event_time_table_v2.csv","all 160 rows","Supplementary Table S3","Figure 3","all rows reported","compatible v2 posterior shown","not applicable","not applicable","not applicable","falsification guild included","ordinary source fits","BH within M05 region-outcome families","supported with qualification","heterogeneous discrete-window pattern","causal event study or continuous trajectory","windows are discrete registered contrasts and include the falsification guild","main text","complete 160-row family supports a heterogeneity statement"),
  c("C007","Abstract; Results","None of the 64 matched whole-bundle placebo components had BH q below 0.05.","methodological","matched shifted-bundle diagnostic association","M27_v2; M28_v2","eight guilds","SoG; WCVI","within-region-year shifted bundles","outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv","model_version_id in M27_v2,M28_v2","Table 3","Figure 5","64 components","not pooled","0/64 BH q<0.05","not applicable","not applicable","does not negate M29 true-exposure panel","20 components have singular warnings","BH within model-version x region x outcome family","robust","no BH-significant matched placebo component","placebos prove exchangeability or causal identification","diagnostic result only; null placebos do not erase residual confounding","headline","whole registered placebo bundle completed without failed components"),
  c("C008","Methods; Results","All 128 protected sensitivity components completed; 43 retained explicit singular-fit warnings and none failed.","methodological","execution completeness","publication sensitivity v2","all guild components","SoG; WCVI","all","outputs/stage4a_publication_sensitivity_v2/model_diagnostics_v2.csv","all 128 component keys","Table 3","Figure 4; Figure 5","finite estimates and intervals","not pooled","included","included","included","not applicable","43 singular; 85 ordinary","not an inferential multiplicity claim","robust","completed with explicit warning","all models fit without qualification","singularity implies one or more boundary variance terms; exact collapsed term is not in aggregate diagnostics","main text","direct execution accounting"),
  c("C009","Results; Discussion","The SoG specificity panel was non-null for both Gadwall and Northern Shoveler detection.","limitation","M29 active-near checklist detection","M29","Gadwall; Northern Shoveler","SoG","active-near","outputs/stage4a_results/effect_estimates.csv","M29|SoG|Gadwall,Northern Shoveler|detection","Table 3","none","2/2 positive with BH q<0.05","not pooled","not a shifted placebo","not applicable","not applicable","direct specificity warning","ordinary fits","BH within M29 SoG detection family","robust","non-null prespecified specificity panel","all falsification analyses were null or every primary association is spurious","targets detection specificity and shared seasonal/spatial/observation structure; it does not test positive counts","headline","materially changes interpretation and therefore belongs in the main manuscript"),
  c("C010","Discussion","The non-null SoG panel weakens causal and simple species-specific ecological interpretations but does not erase the descriptive checklist association.","limitation","claim-boundary interpretation","M29 relative to M01/M02","all affected SoG detection claims","SoG","active-near","outputs/stage4a_publication_v2/sog_falsification_claim_audit_v2.csv","all two rows","Table 3","none","localized comparison","not pooled","distinct from M27/M28","not applicable","not applicable","direct","ordinary fits","multiplicity already applied","supported with qualification","weakens specificity while retaining descriptive association","proof all primary associations are spurious","residual seasonal, spatial, submission, site-selection, and classification explanations remain plausible","main text","localized implication follows the registered purpose and observed magnitude"),
  c("C011","Methods; Supplement","The authoritative v1 pooling invalidation covers 6,562 finite rows in 112 historical families; v2 produced 162 compatible estimable families.","methodological","compatible-family partial pooling","pooling repair v2","all compatible units","all regions","all registered","outputs/stage4a_publication_v2/pooling_repair_summary_v2.csv","all metrics","Supplementary Table S4","Supplementary Figure S2; S3","individual estimates preserved","162/162 estimable","not applicable","not applicable","not applicable","not applicable","noncompleted and duplicates explicit NA","model-specific BH q preserved","robust","authoritative pooling-repair scope","v1 pooled fields remain valid","historical v1 artifacts were not modified","main text","hash-checked repair output and accepted invalidation scope"),
  c("C012","Methods; Supplement","The initial pooling audit undercounted because the registered North-region literal code NA was parsed as missing; typed column-specific parsing repaired the scope.","methodological","typed aggregate parsing","pooling repair v2","all North-region families","NA (North)","all registered","reports/stage4a_publication_methods_v2.md","typed parser disclosure","Supplementary Table S4","none","individual fields preserved","families repaired","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","robust","literal region code NA was preserved as a category","protected data were recovered or source missingness was imputed","repair used privacy-safe aggregate coefficients only","supplement","implementation history is essential for reproducibility but not ecological headline"),
  c("C013","Methods; Supplement","The v2 release contains 6,085 posterior rows, 439 duplicate M11/M12 representations as explicit NA, and 38 noncompleted rows as explicit NA.","methodological","pooling row disposition","pooling repair v2","all units","all regions","all registered","outputs/stage4a_publication_v2/supplementary_exclusion_summary_v2.csv","all three release categories","Supplementary Table S5","Supplementary Figure S2","canonical individual estimates retained","6,085 posterior rows","not applicable","not applicable","not applicable","not applicable","explicit NA reason codes","not applicable","robust","explicit NA dispositions","excluded rows are zero effects","duplicates are representations, not independent evidence","supplement","complete row accounting"),
  c("C014","Methods","M27/M28 moved the complete exposure bundle within region-year strata with zero fixed points and without reading response fields.","methodological","whole-bundle placebo construction","M27_v2; M28_v2","all guilds","SoG; WCVI","within-region-year","outputs/stage4a_publication_sensitivity_v2/transformation_audit_v2.csv","all strata and transformations","Supplementary Table S7","Figure 5","matched architectures","not pooled","construction passed","not applicable","not applicable","not applicable","not applicable","not applicable","robust","response-blind whole-bundle transformation","row-level independent randomization or causal permutation test","diagnostic preserves bundle distribution within strata","main text","registered transformation audit"),
  c("C015","Methods; Data availability","Surveyed-positive, surveyed-negative, and unmonitored-unknown DFO states remain distinct; missing herring components are not zero.","limitation","DFO monitoring-state exposure construction","registered exposure engine","all","all regions","all","reports/stage4a_publication_claim_boundaries_v2.md","monitoring-state rule","none","Figure 1","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","robust","unmonitored is unknown","missing DFO records are negative spawn observations","incomplete monitoring can misclassify recorded exposure","main text","frozen claim boundary and data-governance rule"),
  c("C016","Methods; Discussion","Inference is conditional on eligible submitted complete eBird checklists after registered adjustment.","methodological","checklist-conditional association","all Stage 4A models","all","all regions","all","reports/stage4a_publication_claim_boundaries_v2.md","supported wording","none","Figure 1","all models","all pooled summaries","diagnostic only","qualified","qualified","qualified","some sensitivity components singular","multiplicity does not change estimand","robust","among eligible submitted complete checklists","bird population response","submission and site selection remain possible","headline","core estimand boundary"),
  c("C017","Discussion","Observer and effort covariates reduce measured differences but do not eliminate unmeasured selection or submission bias.","limitation","adjustment interpretation","all Stage 4A models","all","all regions","all","metadata/stage4a_core_spec_v1.yml","fixed predictor and random intercept specification","none","Figure 1","adjusted estimates","adjusted pooled estimates","diagnostic only","observer holdout","observer holdout","M29 warning","singular warnings in WCVI sensitivities","not applicable","supported with qualification","adjusted for registered covariates","selection bias was eliminated","post-exposure visitation and unmeasured site choice may remain","main text","method adjustment cannot establish exchangeability"),
  c("C018","Methods; Reproducibility","M26 v1 was retired without replacement and is not interpreted inferentially.","methodological","model disposition","M26_v1","not applicable","SoG; WCVI","not applicable","outputs/stage4a_publication_sensitivity_v2/model_disposition_v2.csv","historical_model_id=M26","Supplementary Table S1","none","not used","not used","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","robust","retired without replacement","M26 estimates visitation effects","historical artifact remains provenance only","supplement","released summary lacked a registered contrast"),
  c("C019","Discussion","The analysis does not identify population abundance, biomass, occupancy, migration, individual movement, or causal effects.","limitation","claim boundary","all","all","all regions","all","reports/stage4a_publication_claim_boundaries_v2.md","prohibited inference list","none","none","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","not applicable","not estimable","checklist encounter and conditional reported count","population abundance, biomass, occupancy, migration, movement, or causal effect","different designs and assumptions would be required","headline","the fitted estimands do not identify these targets"),
  c("C020","Omit","The study demonstrates a causal effect of herring spawning on regional bird abundance.","limitation","unsupported target estimand","none","all","all regions","all","none","none","none","none","none","none","none","none","none","contradicted by M29 specificity warning","not applicable","not applicable","unsupported","none","causal effect or regional abundance","prohibited throughout","omit","outside the frozen estimand and contradicted by design limitations")
)
claim_matrix <- as.data.frame(do.call(rbind, claims), stringsAsFactors = FALSE)
names(claim_matrix) <- claim_cols
write_csv(claim_matrix, repo_file("metadata", "stage4a_publication_claim_evidence_matrix_v2.csv"))

# Publication tables.
region_n <- aggregate(as.numeric(n) ~ region, data = sample_all, FUN = function(z) unique(z)[1])
names(region_n)[2] <- "eligible_checklist_events"
scope <- merge(region_registry, region_n, by = "region", all.x = TRUE, sort = FALSE)
scope <- scope[match(region_registry$region, scope$region), ]
scope$period <- paste0(scope$registered_start_year, "-2025")
scope$role <- c("primary", "candidate primary", "hierarchical descriptive", "hierarchical descriptive")
scope_table <- scope[c("region", "period", "eligible_checklist_events", "role")]
write_csv(scope_table, repo_file("manuscript", "tables", "table1_study_scope_v2.csv"))
scope_md <- scope_table
names(scope_md) <- c("Region", "Period", "Eligible checklist events", "Inferential role")
scope_md[[3]] <- fmt_int(scope_md[[3]])
write_text(md_table(scope_md, c("left", "left", "right", "left")), repo_file("manuscript", "generated", "table1_study_scope_v2.md"))

species_table <- species[c("region", "unit_label", "outcome", "estimate", "conf_low", "conf_high", "q_value", "n", "status")]
species_table$outcome <- ifelse(species_table$outcome == "positive_count", "positive numeric count given detection", species_table$outcome)
write_csv(species_table, repo_file("manuscript", "tables", "table2_priority_species_v2.csv"))
det_species <- species_table[species_table$outcome == "detection", ]
cnt_species <- species_table[species_table$outcome == "positive numeric count given detection", ]
assert_unique(det_species, c("region", "unit_label"), "priority-species detection display")
assert_unique(cnt_species, c("region", "unit_label"), "priority-species positive-count display")
species_display <- merge(det_species, cnt_species, by = c("region", "unit_label"),
                         suffixes = c("_det", "_cnt"), sort = FALSE)
assert_true(nrow(species_display) == 10L, "Expected 10 paired priority-species display rows")
species_display <- species_display[order(match(species_display$region, c("SoG", "WCVI")),
                                         species_display$unit_label), ]
species_md <- data.frame(
  Region = species_display$region,
  Species = species_display$unit_label,
  Detection = sprintf("%s (%s, %s); q=%s; n=%s",
                      fmt_num(species_display$estimate_det), fmt_num(species_display$conf_low_det),
                      fmt_num(species_display$conf_high_det), fmt_q(species_display$q_value_det),
                      fmt_int(species_display$n_det)),
  `Positive numeric count (detected)` = sprintf("%s (%s, %s); q=%s; n=%s",
                      fmt_num(species_display$estimate_cnt), fmt_num(species_display$conf_low_cnt),
                      fmt_num(species_display$conf_high_cnt), fmt_q(species_display$q_value_cnt),
                      fmt_int(species_display$n_cnt)), check.names = FALSE
)
write_text(md_table(species_md, c("left", "left", "left", "left")),
           repo_file("manuscript", "generated", "table2_priority_species_v2.md"))

get_concord <- function(model) {
  z <- concordance[concordance$model_version_id == model, ]
  c(components = nrow(z), same_sign = sum(z$same_estimate_sign == "TRUE"),
    interval_overlap = sum(z$confidence_intervals_overlap == "TRUE"),
    q_lt_05 = sum(z$q_value < 0.05, na.rm = TRUE),
    singular = sum(z$status == "completed_with_singular_warning"))
}
placebo_rows <- sensitivity[sensitivity$model_version_id %in% c("M27_v2", "M28_v2"), ]
spec_q <- fals$q_value
diag_table <- data.frame(
  Analysis = c("M27/M28 whole-bundle placebos", "WCVI 2-km matched sensitivity",
               "WCVI dominant-observer holdout", "SoG M29 specificity panel"),
  Components = c(nrow(placebo_rows), get_concord("S4A12_WCVI_2KM_v2")[["components"]],
                 get_concord("S4A11_WCVI_DOMINANT_OBSERVER_v2")[["components"]], nrow(fals)),
  Result = c(sprintf("0/%d BH q < 0.05", nrow(placebo_rows)),
             sprintf("%d/%d same sign as matched reference", get_concord("S4A12_WCVI_2KM_v2")[["same_sign"]], get_concord("S4A12_WCVI_2KM_v2")[["components"]]),
             sprintf("%d/%d same sign as matched reference", get_concord("S4A11_WCVI_DOMINANT_OBSERVER_v2")[["same_sign"]], get_concord("S4A11_WCVI_DOMINANT_OBSERVER_v2")[["components"]]),
             "2/2 detection coefficients BH q < 0.05"),
  Singular_warnings = c(sum(placebo_rows$status == "completed_with_singular_warning"),
                        get_concord("S4A12_WCVI_2KM_v2")[["singular"]],
                        get_concord("S4A11_WCVI_DOMINANT_OBSERVER_v2")[["singular"]], 0),
  Interpretation = c("diagnostic; not proof of causal identification",
                     "qualified spatial-precision robustness",
                     "qualified observer-composition robustness",
                     "material warning against simple ecological specificity"),
  check.names = FALSE
)
write_csv(diag_table, repo_file("manuscript", "tables", "table3_sensitivity_falsification_v2.csv"))
diag_md <- diag_table
names(diag_md)[4] <- "Singular warnings"
write_text(md_table(diag_md, c("left", "right", "left", "right", "left")),
           repo_file("manuscript", "generated", "table3_sensitivity_falsification_v2.md"))

# Generated numerical narrative fragments.
eco <- primary[primary$unit_label != "falsification", ]
count_family <- function(region, outcome) {
  z <- eco[eco$region == region & eco$outcome == outcome, ]
  c(total = nrow(z), positive = sum(z$estimate > 0), negative = sum(z$estimate < 0),
    q_lt_05 = sum(z$q_value < 0.05), positive_q = sum(z$estimate > 0 & z$q_value < 0.05),
    negative_q = sum(z$estimate < 0 & z$q_value < 0.05))
}
sog_det <- count_family("SoG", "detection")
sog_cnt <- count_family("SoG", "positive_count")
wcvi_det <- count_family("WCVI", "detection")
wcvi_cnt <- count_family("WCVI", "positive_count")

write_text(c(
  sprintf("The frozen analytical frames contained **%s eligible checklist events in the Strait of Georgia (SoG; 2005-2025)** and **%s on the West Coast of Vancouver Island (WCVI; 2015-2025)**. The hierarchical descriptive frames contained %s Central Coast and %s North-region events (Table 1). These are checklist-frame sizes, not bird-population counts.",
          fmt_int(scope_table$eligible_checklist_events[scope_table$region == "SoG"]),
          fmt_int(scope_table$eligible_checklist_events[scope_table$region == "WCVI"]),
          fmt_int(scope_table$eligible_checklist_events[scope_table$region == "CC"]),
          fmt_int(scope_table$eligible_checklist_events[scope_table$region == "NA"])),
  "",
  "The protected sensitivity execution read no response year later than 2025; the recorded number of 2026-or-later rows read was zero."
), repo_file("manuscript", "generated", "results_sample_v2.md"))

write_text(c(
  sprintf("Among the seven ecological guilds in SoG, %d detection coefficients were positive and %d were negative; all %d had BH q < 0.05. For positive numeric count conditional on detection, %d coefficients were positive and %d negative, with %d of %d BH q-values below 0.05. The complete pattern therefore includes both positive and negative associations rather than a universal increase (Figure 2).",
          sog_det[["positive"]], sog_det[["negative"]], sog_det[["total"]], sog_cnt[["positive"]], sog_cnt[["negative"]], sog_cnt[["q_lt_05"]], sog_cnt[["total"]]),
  "",
  sprintf("WCVI estimates were less uniform. Detection coefficients were positive for %d of %d ecological guilds and BH q < 0.05 for %d; conditional positive-count coefficients were positive for %d of %d guilds and BH q < 0.05 for %d. Wider intervals and sparse geometry were most evident in the WCVI component and sensitivity fits.",
          wcvi_det[["positive"]], wcvi_det[["total"]], wcvi_det[["q_lt_05"]], wcvi_cnt[["positive"]], wcvi_cnt[["total"]], wcvi_cnt[["q_lt_05"]]),
  "",
  "At the priority-species level, Surf Scoter and Short-billed Gull had positive detection and positive-count coefficients in both primary regions. Glaucous-winged Gull had a positive SoG detection coefficient but an imprecise WCVI detection coefficient, while its conditional count coefficients were positive in both regions. Harlequin Duck and White-winged Scoter were component- or region-dependent (Table 2 and Supplementary Figure S1)."
), repo_file("manuscript", "generated", "results_primary_v2.md"))

event_group <- aggregate(cbind(estimate, q_value) ~ region + outcome + contrast, data = event_time,
                         FUN = function(z) c(median = median(z), below = sum(z < 0.05)))
write_text(c(
  "The 160 registered M05 rows showed window-, guild-, outcome-, and region-specific coefficients rather than a single monotone event trajectory (Figure 3). In SoG, the immediate-pre window had BH q < 0.05 for seven of eight guilds in each outcome, while the post window had seven of eight adjusted associations in each outcome and a negative median coefficient. WCVI patterns differed: detection associations were most frequent in the immediate-pre and post windows, whereas positive-count contrasts were more variable. These discrete coefficients are not a continuous causal event study."
), repo_file("manuscript", "generated", "results_event_time_v2.md"))

write_text(c(
  sprintf("All **%d of %d** protected sensitivity components completed: %d ordinary completions and %d completions with an explicit singular-fit warning; none failed. In each of the WCVI 2-km and dominant-observer comparisons, %d of %d components retained the sign of the matched sparse M01 reference (Figure 4). Because %d sensitivity/reference components shown in Figure 4 were singular, this is qualified directional robustness rather than evidence that the intended random-effects structure was fully supported.",
          sum(grepl("^completed", sensitivity$status)), nrow(sensitivity), sum(sensitivity$status == "completed"),
          sum(sensitivity$status == "completed_with_singular_warning"),
          get_concord("S4A12_WCVI_2KM_v2")[["same_sign"]], get_concord("S4A12_WCVI_2KM_v2")[["components"]],
          sum(sensitivity$model_version_id %in% c("M01_PRIMARY_v2", "S4A11_WCVI_DOMINANT_OBSERVER_v2", "S4A12_WCVI_2KM_v2") & sensitivity$status == "completed_with_singular_warning")),
  "",
  sprintf("The M27/M28 whole-bundle diagnostics completed all %d components, and none had BH q < 0.05 (Figure 5). These null shifted-exposure diagnostics do not establish exchangeability or causal identification.", nrow(placebo_rows))
), repo_file("manuscript", "generated", "results_sensitivity_v2.md"))

gad <- fals[fals$unit_label == "Gadwall", ]
sho <- fals[fals$unit_label == "Northern Shoveler", ]
write_text(c(
  sprintf("The prespecified SoG specificity panel was non-null. Gadwall detection was positively associated with recorded active-near exposure (log-odds coefficient %s, 95%% CI %s to %s; BH q = %s), as was Northern Shoveler detection (%s, %s to %s; BH q = %s). Both used the true exposure rather than a shifted placebo, and their magnitudes were within the range of primary SoG guild-detection coefficients. The panel therefore identifies plausible shared seasonal, spatial-access, checklist-submission, site-selection, or exposure-classification structure. It weakens causal and simple species-specific ecological interpretations of SoG detection associations, but it does not show that every association is spurious and it does not test the conditional positive-count component.",
          fmt_num(gad$estimate, 3), fmt_num(gad$conf_low, 3), fmt_num(gad$conf_high, 3), fmt_q(gad$q_value),
          fmt_num(sho$estimate, 3), fmt_num(sho$conf_low, 3), fmt_num(sho$conf_high, 3), fmt_q(sho$q_value))
), repo_file("manuscript", "generated", "results_falsification_v2.md"))

write_text(c(
  sprintf("The authoritative pooling repair invalidated %s finite v1 partial-pooling rows in %s historical families. Typed, column-specific parsing preserved the registered North-region literal code `NA`, and v2 produced %s compatible estimable families. The release contains %s posterior rows, with %s duplicate M11/M12 representations and %s noncompleted rows retained as explicit NA. Individual estimates, standard errors, intervals, p-values, and model-specific BH q-values were preserved; v1 artifacts were not modified.",
          fmt_int(pool_metric[["invalid_v1_finite_rows"]]), fmt_int(pool_metric[["invalid_v1_families"]]),
          fmt_int(pool_metric[["estimable_v2_families"]]), fmt_int(pool_metric[["v2_posterior_rows"]]),
          fmt_int(pool_metric[["duplicate_representations_explicit_na"]]), fmt_int(pool_metric[["noncompleted_rows_explicit_na"]]))
), repo_file("manuscript", "generated", "results_pooling_v2.md"))

write_text(c(
  sprintf("Among %s eligible SoG and %s eligible WCVI checklist events, registered guild and priority-species coefficients varied by region, response component, and taxon. WCVI 2-km and dominant-observer sensitivities each preserved the matched-reference sign in 15 of 16 components, but 43 of 128 protected components carried singular-fit warnings. None of 64 matched whole-bundle placebo components had BH q < 0.05. In contrast, both taxa in the prespecified SoG detection-specificity panel were non-null, requiring qualification of simple ecological-specificity interpretations.",
          fmt_int(scope_table$eligible_checklist_events[scope_table$region == "SoG"]),
          fmt_int(scope_table$eligible_checklist_events[scope_table$region == "WCVI"]))
), repo_file("manuscript", "generated", "abstract_results_v2.md"))

# Deterministic workflow SVG and copies of frozen publication figures.
workflow_svg <- c(
  "<svg xmlns='http://www.w3.org/2000/svg' width='1200' height='520' viewBox='0 0 1200 520' role='img' aria-labelledby='title desc'>",
  "<title id='title'>Stage 4A checklist-conditional analysis workflow</title>",
  "<desc id='desc'>A five-step workflow from permitted aggregate inputs through eligible complete checklists, exposure linkage, registered mixed models, and audited publication claims.</desc>",
  "<rect width='1200' height='520' fill='#ffffff'/>",
  "<style>text{font-family:Arial,sans-serif;fill:#17212b}.box{fill:#f5f8fa;stroke:#1f5a7a;stroke-width:2}.head{font-size:18px;font-weight:bold}.body{font-size:14px}.arrow{stroke:#7a5a00;stroke-width:3;fill:none;marker-end:url(#a)}.note{font-size:13px;fill:#596674}</style>",
  "<defs><marker id='a' markerWidth='10' markerHeight='10' refX='8' refY='3' orient='auto'><path d='M0,0 L0,6 L9,3 z' fill='#7a5a00'/></marker></defs>",
  "<text x='600' y='38' text-anchor='middle' font-size='24' font-weight='bold'>Checklist-conditional Stage 4A analysis and evidence audit</text>",
  "<rect class='box' x='35' y='105' rx='12' width='190' height='190'/><text class='head' x='130' y='140' text-anchor='middle'>Permitted inputs</text><text class='body' x='55' y='180'>Complete eBird checklists</text><text class='body' x='55' y='208'>DFO recorded spawn data</text><text class='body' x='55' y='236'>Frozen registries and hashes</text><text class='note' x='55' y='270'>No protected identifiers released</text>",
  "<rect class='box' x='275' y='105' rx='12' width='190' height='190'/><text class='head' x='370' y='140' text-anchor='middle'>Eligibility</text><text class='body' x='295' y='180'>Stationary or traveling</text><text class='body' x='295' y='208'>5-300 min; at most 5 km</text><text class='body' x='295' y='236'>1-10 observers; through 2025</text><text class='note' x='295' y='270'>Checklist is the independent row</text>",
  "<rect class='box' x='515' y='105' rx='12' width='190' height='190'/><text class='head' x='610' y='140' text-anchor='middle'>Exposure linkage</text><text class='body' x='535' y='180'>Spatial and temporal windows</text><text class='body' x='535' y='208'>All concurrent links additive</text><text class='body' x='535' y='236'>Monitoring states distinct</text><text class='note' x='535' y='270'>Unmonitored is unknown</text>",
  "<rect class='box' x='755' y='105' rx='12' width='190' height='190'/><text class='head' x='850' y='140' text-anchor='middle'>Registered models</text><text class='body' x='775' y='180'>Detection and positive count</text><text class='body' x='775' y='208'>Effort, observer, time, space</text><text class='body' x='775' y='236'>Pooling and BH families</text><text class='note' x='775' y='270'>Placebos and matched sensitivities</text>",
  "<rect class='box' x='995' y='105' rx='12' width='170' height='190'/><text class='head' x='1080' y='140' text-anchor='middle'>Claim audit</text><text class='body' x='1015' y='180'>Estimate + interval</text><text class='body' x='1015' y='208'>Multiplicity + fit status</text><text class='body' x='1015' y='236'>Sensitivity + falsification</text><text class='note' x='1015' y='270'>Qualified wording only</text>",
  "<line class='arrow' x1='225' y1='200' x2='267' y2='200'/><line class='arrow' x1='465' y1='200' x2='507' y2='200'/><line class='arrow' x1='705' y1='200' x2='747' y2='200'/><line class='arrow' x1='945' y1='200' x2='987' y2='200'/>",
  "<rect x='170' y='360' width='860' height='105' rx='10' fill='#fff8e8' stroke='#7a5a00'/><text x='600' y='395' text-anchor='middle' font-size='17' font-weight='bold'>Estimand boundary</text><text x='600' y='425' text-anchor='middle' font-size='15'>Associations among eligible submitted complete checklists; not causal effects or regional bird abundance, biomass, occupancy, migration, or movement.</text><text x='600' y='449' text-anchor='middle' class='note'>Current-data analyses remain exploratory or estimand-refining pending prospective confirmation.</text>",
  "</svg>"
)
write_text(workflow_svg, repo_file("manuscript", "figures", "figure1_workflow_v2.svg"))

figure_copies <- c(
  figure2_primary_guild_v2.svg = "reports/figures/stage4a_pooling_v2_primary_guild.svg",
  figure3_event_time_v2.svg = "reports/figures/stage4a_pooling_v2_event_time.svg",
  figure4_wcvi_robustness_v2.svg = "reports/figures/stage4a_publication_v2_wcvi_robustness.svg",
  figure5_placebo_v2.svg = "reports/figures/stage4a_publication_v2_placebo_comparison.svg",
  figureS1_priority_species_v2.svg = "reports/figures/stage4a_pooling_v2_priority_a_species.svg",
  figureS2_pooling_row_disposition_v2.svg = "reports/figures/stage4a_pooling_v2_row_disposition.svg",
  figureS3_pooling_tau_v2.svg = "reports/figures/stage4a_pooling_v2_tau_distribution.svg",
  figureS4_model_diagnostics_v2.svg = "reports/figures/stage4a_publication_v2_diagnostics.svg"
)
for (nm in names(figure_copies)) {
  ok <- file.copy(repo_file(figure_copies[[nm]]), repo_file("manuscript", "figures", nm), overwrite = TRUE)
  assert_true(ok, sprintf("Could not copy figure %s", nm))
}

# The frozen source plots used horizontal y-axis titles too close to their SVG
# view-box edge. Rotate those titles in the publication copies only; underlying
# analysis figures and all plotted values remain unchanged.
rotate_y_title <- function(path, x, y, label) {
  svg <- paste(readLines(path, warn = FALSE), collapse = "\n")
  needle <- sprintf("<text x='%s' y='%s' font-size='13' text-anchor='middle' font-weight='normal' class=''>%s</text>",
                    x, y, label)
  replacement <- sprintf("<text x='%s' y='%s' font-size='13' text-anchor='middle' font-weight='normal' class='' transform='rotate(-90 %s %s)'>%s</text>",
                         x, y, x, y, label)
  assert_true(grepl(needle, svg, fixed = TRUE), sprintf("Expected y-axis title not found in %s", basename(path)))
  write_text(sub(needle, replacement, svg, fixed = TRUE), path)
}
rotate_y_title(repo_file("manuscript", "figures", "figureS2_pooling_row_disposition_v2.svg"), 28, 205, "Affected rows")
rotate_y_title(repo_file("manuscript", "figures", "figureS3_pooling_tau_v2.svg"), 25, 195, "V2 families")

# Citation audit from independently verified Crossref and official records.
citation_audit <- data.frame(
  citation_key = c("rodway2003","lewis2007","lok2008","lok2012","sullivan2002","haegele1993","kelly2018",
                   "sullivan2009","kelling2019","johnston2018","johnston2021","bates2015","benjamini1995",
                   "haegele1985","hay1987","hay2009","rooper2024","grinnell2023","dfo_spawn_data","ebird_ebd"),
  full_reference = c(
    "Rodway MS et al. 2003. Aggregative response of Harlequin Ducks to herring spawning in the Strait of Georgia, British Columbia. Canadian Journal of Zoology 81(3):504-514.",
    "Lewis TL, Esler D, Boyd WS. 2007. Foraging Behaviors of Surf Scoters and White-Winged Scoters During Spawning of Pacific Herring. The Condor 109(1):216-222.",
    "Lok EK et al. 2008. Movements of Pre-migratory Surf and White-winged Scoters in Response to Pacific Herring Spawn. Waterbirds 31(3):385-393.",
    "Lok EK et al. 2012. Spatiotemporal associations between Pacific herring spawn and surf scoter spring migration: evaluating a silver wave hypothesis. Marine Ecology Progress Series 457:139-150.",
    "Sullivan TM, Butler RW, Boyd WS. 2002. Seasonal distribution of waterbirds in relation to spawning Pacific Herring in the Strait of Georgia. Canadian Field-Naturalist 116(3):366-370.",
    "Haegele CW. 1993. Seabird predation of Pacific Herring spawn in British Columbia. Canadian Field-Naturalist 107(1):73-82.",
    "Kelly JP, Rothenbach CA, Weathers WW. 2018. Echoes of numerical dependence: responses of wintering waterbirds to Pacific herring spawns. Marine Ecology Progress Series 597:243-257.",
    "Sullivan BL et al. 2009. eBird: A citizen-based bird observation network in the biological sciences. Biological Conservation 142(10):2282-2292.",
    "Kelling S et al. 2019. Using Semistructured Surveys to Improve Citizen Science Data for Monitoring Biodiversity. BioScience 69(3):170-179.",
    "Johnston A et al. 2018. Estimates of observer expertise improve species distributions from citizen science data. Methods in Ecology and Evolution 9(1):88-97.",
    "Johnston A et al. 2021. Analytical guidelines to increase the value of community science data. Diversity and Distributions 27(7):1265-1277.",
    "Bates D et al. 2015. Fitting Linear Mixed-Effects Models Using lme4. Journal of Statistical Software 67(1):1-48.",
    "Benjamini Y, Hochberg Y. 1995. Controlling the False Discovery Rate. Journal of the Royal Statistical Society Series B 57(1):289-300.",
    "Haegele CW, Schweigert JF. 1985. Distribution and Characteristics of Herring Spawning Grounds and Description of Spawning Behavior. CJFAS 42(S1):s39-s55.",
    "Hay DE, Kronlund AR. 1987. Factors Affecting the Distribution, Abundance, and Measurement of Pacific Herring Spawn. CJFAS 44(6):1181-1194.",
    "Hay DE et al. 2009. Spatial diversity of Pacific herring spawning areas. ICES Journal of Marine Science 66(8):1662-1666.",
    "Rooper CN et al. 2024. Evaluating factors affecting the distribution and timing of Pacific herring spawn in British Columbia. Marine Ecology Progress Series 741:251-269.",
    "Grinnell MH et al. 2023. Calculating the spawn index for Pacific Herring in British Columbia, Canada. Canadian Technical Report of Fisheries and Aquatic Sciences 3489.",
    "Fisheries and Oceans Canada. 2026. Pacific Herring Spawn Index Data. Open Government Portal record d892511c-d851-4f85-a0ec-708bc05d2810.",
    "eBird. 2026. eBird Basic Dataset, Version EBD_relMay-2026. Cornell Lab of Ornithology."
  ),
  doi_or_stable_identifier = c("10.1139/z03-032","10.1093/condor/109.1.216","10.1675/1524-4695-31.3.385","10.3354/meps09692","10.5962/p.363475","10.5962/p.357075","10.3354/meps12594","10.1016/j.biocon.2009.05.006","10.1093/biosci/biz010","10.1111/2041-210X.12838","10.1111/ddi.13271","10.18637/jss.v067.i01","10.1111/j.2517-6161.1995.tb02031.x","10.1139/f85-261","10.1139/f87-141","10.1093/icesjms/fsp139","10.3354/meps14274","Government of Canada catalogue 9.912189","Open Government record d892511c-d851-4f85-a0ec-708bc05d2810","EBD_relMay-2026"),
  source_type = c(rep("primary peer-reviewed",17),"official government technical report","official government dataset","official data documentation"),
  manuscript_claims_supported = c("localized Harlequin Duck aggregation","scoter foraging mechanism","scoter movement precedent","spawn phenology and scoter association","localized waterbird aggregation","spawn predation mechanism","wintering-waterbird response context","eBird data source","complete-checklist observation-process metadata","observer heterogeneity","eBird analytical safeguards","mixed-model software","BH multiplicity procedure","spawn-ground ecology","spawn measurement uncertainty","spatial heterogeneity of spawning","modern spawn timing and distribution","spawn-index construction and caveats","relative spawn-index and NA-state definition","EBD access, version, and terms"),
  verification_status = c(rep("verified against Crossref 2026-07-21",17),"verified against Government of Canada catalogue 2026-07-21","verified against Open Government Portal 2026-07-21","verified against eBird official help documentation 2026-07-21"),
  duplicate_status = "unique",
  missing_information_status = "none",
  stringsAsFactors = FALSE
)
write_csv(citation_audit, repo_file("metadata", "stage4a_publication_citation_audit_v2.csv"))

# Table/figure provenance. Every join used above is one-to-one or summary-only and asserted.
prov_rows <- list()
add_prov <- function(id, location, source, generation_script, filters, models, caption, privacy) {
  src <- do.call(repo_file, as.list(strsplit(source, "/", fixed = TRUE)[[1]]))
  data.frame(artifact_id = id, manuscript_location = location, source_file = source,
             source_hash = sha256_file(src), generation_script = generation_script,
             generation_commit = generation_commit, filters = filters, model_or_family_ids = models,
             caption = caption, privacy_classification = privacy, stringsAsFactors = FALSE)
}
prov_rows[[1]] <- add_prov("Figure 1","main","metadata/stage4a_core_spec_v1.yml","scripts/build_stage4a_manuscript_package_v2.R","registered workflow only","M01,M02,M05,M27,M28,M29,S4A11,S4A12","Stage 4A checklist-conditional workflow and estimand boundary.","public aggregate schematic")
prov_rows[[2]] <- add_prov("Figure 2","main","outputs/stage4a_publication_v2/primary_guild_table_v2.csv","R/stage4a_pooling_report_v2.R","M01; SoG and WCVI; both hurdle components","M01","Individual and v2 compatible-family posterior guild coefficients with 95% intervals.","public aggregate")
prov_rows[[3]] <- add_prov("Figure 3","main","outputs/stage4a_publication_v2/event_time_table_v2.csv","R/stage4a_pooling_report_v2.R","all 160 registered M05 rows","M05","Discrete registered event-time coefficients across guilds and outcomes.","public aggregate")
prov_rows[[4]] <- add_prov("Figure 4","main","outputs/stage4a_publication_v2/sensitivity_concordance_v2.csv","R/stage4a_publication_report_v2.R","WCVI matched reference, 2-km, dominant-observer","M01_PRIMARY_v2,S4A11,S4A12","Matched WCVI sensitivity coefficients with 95% intervals.","public aggregate")
prov_rows[[5]] <- add_prov("Figure 5","main","outputs/stage4a_publication_v2/sensitivity_concordance_v2.csv","R/stage4a_publication_report_v2.R","M27/M28 whole-bundle placebos","M27_v2,M28_v2","Matched primary and whole-bundle placebo coefficients with 95% intervals.","public aggregate")
prov_rows[[6]] <- add_prov("Table 1","main","outputs/stage4a_results/aggregate_sample_sizes.csv","scripts/build_stage4a_manuscript_package_v2.R","unique checklist-frame n by region","M01,M02","Frozen analytical populations and inferential roles.","public aggregate")
prov_rows[[7]] <- add_prov("Table 2","main","outputs/stage4a_publication_v2/priority_a_species_table_v2.csv","scripts/build_stage4a_manuscript_package_v2.R","all 20 priority-A rows","M02","Priority-A species coefficients, intervals, BH q-values, and component sample sizes.","public aggregate")
prov_rows[[8]] <- add_prov("Table 3","main","outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv","scripts/build_stage4a_manuscript_package_v2.R","placebo and matched WCVI summaries plus M29 audit","M27_v2,M28_v2,S4A11,S4A12,M29","Sensitivity, placebo, singular-fit, and specificity-panel summary.","public aggregate")
supp_sources <- c("metadata/stage4a_publication_model_disposition_v2.csv","outputs/stage4a_results/effect_estimates.csv","outputs/stage4a_publication_v2/event_time_table_v2.csv","outputs/stage4a_publication_v2/supplementary_family_table_v2.csv","outputs/stage4a_publication_v2/supplementary_exclusion_summary_v2.csv","outputs/stage4a_publication_v2/singular_fit_claim_audit_v2.csv","outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv","outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv","outputs/stage4a_publication_sensitivity_v2/matched_validation_v2.csv","metadata/stage4a_publication_table_figure_provenance_v2.csv")
supp_names <- c("model disposition","all individual aggregate estimates","all 160 event-time rows","162 pooling families","pooling exclusions and NA reasons","43 singular-fit components","64 placebo components","WCVI 2-km and observer sensitivities","four-fold validation","artifact and hash provenance")
for (i in seq_along(supp_sources)) {
  if (supp_sources[[i]] == "metadata/stage4a_publication_table_figure_provenance_v2.csv") next
  prov_rows[[length(prov_rows)+1]] <- add_prov(sprintf("Table S%d",i),"supplement",supp_sources[[i]],"scripts/build_stage4a_manuscript_package_v2.R","complete registered aggregate rows",ifelse(i==1,"all registered",ifelse(i==3,"M05","Stage 4A v2")),sprintf("Supplementary %s table.",supp_names[[i]]),"public aggregate")
}
supp_fig_src <- c("outputs/stage4a_publication_v2/priority_a_species_table_v2.csv","outputs/stage4a_publication_v2/supplementary_exclusion_summary_v2.csv","outputs/stage4a_publication_v2/supplementary_family_table_v2.csv","outputs/stage4a_publication_v2/model_diagnostic_summary_v2.csv")
supp_fig_cap <- c("Priority-A species coefficients and v2 posterior summaries.","Pooling row dispositions.","Between-component heterogeneity across compatible pooling families.","Model diagnostic and completion summary.")
for (i in seq_along(supp_fig_src)) prov_rows[[length(prov_rows)+1]] <- add_prov(sprintf("Figure S%d",i),"supplement",supp_fig_src[[i]],ifelse(i<4,"R/stage4a_pooling_report_v2.R","R/stage4a_publication_report_v2.R"),"complete publication aggregate","Stage 4A v2",supp_fig_cap[[i]],"public aggregate")
provenance <- do.call(rbind, prov_rows)
write_csv(provenance, repo_file("metadata", "stage4a_publication_table_figure_provenance_v2.csv"))

# Chart map required by the technical-report workflow.
chart_map <- c(
  "# Stage 4A v2 chart map",
  "",
  "All figures use public aggregate outputs. Intervals are 95% confidence or v2 compatible-family posterior intervals as labeled. No protected locality, coordinate, event token, or observer identifier is displayed.",
  "",
  "| Figure | Analytical question | Form | Fields | Supported claim | Palette and non-color distinction |",
  "|---|---|---|---|---|---|",
  "| Figure 1 | How does the frozen checklist-conditional analysis flow? | Workflow | registered inputs, eligibility, linkage, models, claims | estimand and governance boundary | blue outlines, gold arrows, explicit text |",
  "| Figure 2 | How do guild associations differ by region and hurdle component? | Faceted dot-and-interval | estimate, interval, guild, region, outcome | heterogeneous primary associations | open blue individual marks and filled gold pooled marks |",
  "| Figure 3 | How do discrete registered windows vary? | Faceted interval distribution | estimate, interval, window, guild, region, outcome | timing heterogeneity | interval marks plus gold descriptive median |",
  "| Figure 4 | Do WCVI cohort/observer sensitivities preserve direction? | Faceted dot-and-interval | matched reference and sensitivity coefficients | qualified directional robustness | position and mark style distinguish architectures |",
  "| Figure 5 | Do shifted whole-bundle placebos reproduce primary coefficients? | Faceted dot-and-interval | matched reference, M27, M28 coefficients | no placebo BH q below 0.05 | position and mark style distinguish models |",
  "| Figure S1 | Which priority species drive heterogeneous patterns? | Faceted dot-and-interval | species estimate, interval, posterior | species-level heterogeneity | open blue and filled gold marks |",
  "| Figure S2 | How were invalid v1 rows disposed? | Bar/count schematic | release category, rows | complete row accounting | restrained blue/gold categories plus labels |",
  "| Figure S3 | How much heterogeneity exists among compatible families? | Distribution | tau estimates | pooling diagnostic | single-root palette and explicit axis |",
  "| Figure S4 | Which fit and execution warnings remain? | Diagnostic summary | status, singularity, components | warning transparency | labeled categories; not color-only |"
)
write_text(chart_map, repo_file("manuscript", "stage4a_visual_chart_map_v2.md"))

message("Stage 4A manuscript aggregate package built successfully; no response model was fitted.")
