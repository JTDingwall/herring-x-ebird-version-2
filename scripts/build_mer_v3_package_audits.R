#!/usr/bin/env Rscript

# Build versioned v3 companion tables, anonymized sources, claim/citation audits,
# and figure/table provenance from tracked aggregate artifacts only.

options(stringsAsFactors = FALSE, scipen = 999)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stopifnot(file.exists(file.path(root, "AGENTS.md")))

pkg <- file.path(root, "manuscript", "journal_submission", "marine_environmental_research")
src <- file.path(pkg, "source_v3")
tab <- file.path(pkg, "tables_v3")
aud <- file.path(pkg, "audits")
dir.create(src, recursive = TRUE, showWarnings = FALSE)
dir.create(tab, recursive = TRUE, showWarnings = FALSE)
dir.create(aud, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(p) read.csv(file.path(root, p), check.names = FALSE, na.strings = "")
write_csv <- function(x, p) write.csv(x, p, row.names = FALSE, na = "")
copy_csv <- function(from, to, filter = NULL) {
  x <- read_csv(from)
  if (!is.null(filter)) x <- filter(x)
  write_csv(x, file.path(tab, to))
  invisible(x)
}

# Complete supplementary tables.
all_effects <- copy_csv("outputs/stage4a_results/effect_estimates.csv",
                        "Table_S14_complete_effect_release_v3.csv")
copy_csv("outputs/stage4a_results/effect_estimates.csv",
         "Table_S1_all_species_effects_v3.csv", function(x) x[x$model_id == "M02", ])
copy_csv("outputs/stage4a_results/effect_estimates.csv",
         "Table_S2_all_M05_time_distance_effects_v3.csv", function(x) x[x$model_id == "M05", ])
copy_csv("outputs/stage4a_publication_v2/event_time_table_v2.csv",
         "Table_S2a_guild_event_time_effects_v3.csv")
file.copy(file.path(tab, "Table_S_temporal_sampling_support_v3.csv"),
          file.path(tab, "Table_S3_temporal_sampling_support_v3.csv"), overwrite = TRUE)
copy_csv("outputs/stage4a_publication_sensitivity_v2/sensitivity_effect_estimates_v2.csv",
         "Table_S4_all_sensitivity_effects_v3.csv")
copy_csv("outputs/stage4a_publication_sensitivity_v2/matched_validation_v2.csv",
         "Table_S5_all_validation_v3.csv")
copy_csv("outputs/stage4a_results/model_geometry.csv", "Table_S6_model_geometry_v3.csv")
copy_csv("outputs/stage4a_publication_v2/singular_fit_claim_audit_v2.csv",
         "Table_S7_singular_fit_audit_v3.csv")
copy_csv("outputs/stage4a_publication_v2/model_disposition_v2.csv",
         "Table_S8_model_disposition_v3.csv")
copy_csv("outputs/stage4a_results/truncated_nb2_sensitivity.csv",
         "Table_S9_zero_truncated_nb2_v3.csv")
copy_csv("outputs/stage4a_publication_v2/supplementary_family_table_v2.csv",
         "Table_S10_pooling_families_v3.csv")
copy_csv("outputs/stage4a_publication_v2/supplementary_exclusion_summary_v2.csv",
         "Table_S11_pooling_exclusions_v3.csv")
copy_csv("outputs/stage4a_results/effect_estimates.csv",
         "Table_S12_M08_active_minus_reference_v3.csv", function(x) x[x$model_id == "M08", ])
copy_csv("outputs/stage4a_results/effect_estimates.csv",
         "Table_S13_all_M29_components_v3.csv", function(x) x[x$model_id == "M29", ])

# V3 claim-to-evidence matrix. The v2 record is preserved; corrected v3 fields
# are appended without rewriting any frozen claim record.
claims <- read_csv("metadata/stage4a_publication_claim_evidence_matrix_v2.csv")
claims$v3_evidence_hierarchy <- ifelse(claims$inclusion_status == "headline", "primary_or_headline",
  ifelse(claims$inclusion_status == "main text", "secondary_main", "supplementary_or_context"))
claims$v3_classification <- claims$classification
claims$v3_classification[claims$classification == "confirmatory"] <-
  "registered_hypothesis_driven_exploratory_or_estimand_refining"
claims$v3_classification[claims$classification == "secondary"] <-
  "registered_secondary_exploratory_or_estimand_refining"
claims$v3_claim_text <- claims$proposed_claim_text
claims$v3_claim_text[claims$claim_id == "C006"] <- paste(
  "Registered event-time coefficients varied across guilds, outcomes, and regions",
  "across six windows (five nonbaseline coefficients) rather than forming one common trajectory.")
claims$v3_estimand_baseline <- ifelse(grepl("M08", claims$model_identifier_or_family),
  "active-near minus contemporaneous reference",
  ifelse(grepl("M01|M02|M29", claims$model_identifier_or_family),
         "active-near versus omitted other class", "as specified in source family"))
claims$v3_engine_provenance <- ifelse(grepl("M01_PRIMARY_v2|M27_v2|M28_v2|S4A11|S4A12",
                                            claims$model_identifier_or_family),
  "sparse lme4 engine determinable; no simplified fallback",
  ifelse(grepl("M02|M05|M08|M29", claims$model_identifier_or_family),
         "legacy per-component engine not identifiable from public aggregate release",
         "not applicable or inherited source record"))
claims$v3_required_language <- paste(
  "Checklist-conditional association; no causal, abundance, biomass, occupancy, migration, or movement claim.")
claims$v3_review_status <- "retained_with_v3_estimand_engine_and_hierarchy_audit"
write_csv(claims, file.path(aud, "claim_to_evidence_matrix_v3.csv"))

# Citation audit: no reference identity changed and no citation was added.
cit <- read_csv("metadata/stage4a_publication_citation_audit_v2.csv")
cit$v3_use_status <- "retained"
cit$v3_verification_note <- paste(
  "Reference identity unchanged from v2 verification; v3 introduces no new bibliography entry.")
cit$v3_checked_date <- "2026-07-22"
write_csv(cit, file.path(aud, "citation_audit_v3.csv"))

# Mechanical double-anonymous companion. Scientific content is unchanged.
unblinded_path <- file.path(src, "mer_manuscript_unblinded_v3.qmd")
blind_path <- file.path(src, "mer_manuscript_blinded_companion_v3.qmd")
txt <- paste(readLines(unblinded_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
txt <- sub('author:\n  - name: "Jacob T. Dingwall"\n    orcid: "0009-0007-8389-6947"',
           'author:\n  - name: "Anonymous"', txt, fixed = TRUE)
txt <- sub('**Affiliation:** University of Victoria, [AUTHOR TO SUPPLY: full postal address], Canada<br>\n**Corresponding author:** Jacob T. Dingwall; dingwalljake@gmail.com; [AUTHOR TO SUPPLY: telephone number]<br>\n**ORCID:** 0009-0007-8389-6947',
           '**Author information:** Omitted for double-anonymous review', txt, fixed = TRUE)
txt <- gsub("https://github.com/JTDingwall/herring-x-ebird-version-2",
            "[repository URL withheld for double-anonymous review]", txt, fixed = TRUE)
txt <- gsub("<[repository URL withheld for double-anonymous review]>",
            "[repository URL withheld for double-anonymous review]", txt, fixed = TRUE)
txt <- sub("# Declarations[\\s\\S]*?# Acknowledgments",
           paste("# Declarations\n\nAuthor contribution, funding, competing-interest, ethics, and",
                 "AI-assistance declarations are supplied on the separate title page and are omitted",
                 "here for double-anonymous review.\n\n# Acknowledgments"), txt, perl = TRUE)
txt <- sub("# Acknowledgments[\\s\\S]*?# References",
           "# Acknowledgments\n\nAcknowledgments are omitted for double-anonymous review.\n\n# References",
           txt, perl = TRUE)
writeLines(txt, blind_path, useBytes = TRUE)

supp_unblind <- file.path(src, "mer_supplement_v3.qmd")
supp_blind <- file.path(src, "mer_supplement_blinded_companion_v3.qmd")
stxt <- paste(readLines(supp_unblind, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
stxt <- sub('author:\n  - name: "Jacob T. Dingwall"', 'author:\n  - name: "Anonymous"', stxt, fixed = TRUE)
stxt <- gsub("https://github.com/JTDingwall/herring-x-ebird-version-2",
             "[repository URL withheld for double-anonymous review]", stxt, fixed = TRUE)
stxt <- gsub("<[repository URL withheld for double-anonymous review]>",
             "[repository URL withheld for double-anonymous review]", stxt, fixed = TRUE)
writeLines(stxt, supp_blind, useBytes = TRUE)

# Separate abstract source.
abstract <- sub("^[\\s\\S]*?# Abstract\\n+", "", txt, perl = TRUE)
abstract <- sub("\\n+\\*\\*Keywords:[\\s\\S]*$", "", abstract, perl = TRUE)
writeLines(c("# Abstract", "", abstract), file.path(src, "mer_abstract_v3.md"), useBytes = TRUE)

# Anonymization log.
anon <- c(
  "# V3 anonymization log",
  "",
  "- Replaced the author name and ORCID with `Anonymous` in the blinded manuscript and supplement.",
  "- Replaced affiliation, email, and telephone fields with an author-information omission notice.",
  "- Replaced the identifiable repository URL with a double-anonymous placeholder.",
  "- Replaced contribution, funding, conflict, ethics, AI, and acknowledgment sections with blinded notices.",
  "- Retained scientific methods, aggregate data, code names, frozen commit/tag, and model provenance.",
  "- No protected identifier was introduced or transformed."
)
writeLines(anon, file.path(pkg, "anonymization_log_v3.md"), useBytes = TRUE)

# Provenance. Source hashes use SHA-256 from the digest package.
suppressPackageStartupMessages(library(digest))
sha <- function(p) digest(file = p, algo = "sha256", serialize = FALSE)
generation_revision <- Sys.getenv("MER_V3_GENERATION_COMMIT", unset = "WORKTREE_V3_PENDING")

fig_sources <- data.frame(
  artifact_id = c("Figure 1", "Figure 2", "Figure 3", "Figure 4", "Figure 5", "Figure 6",
                  paste0("Figure S", 1:6)),
  file = c("Figure_1_study_area_map_v3.png", "Figure_2_descriptive_bird_patterns_v3.png",
           "Figure_3_focal_species_effects_v3.png", "Figure_4_event_time_v3.png",
           "Figure_5_specificity_distribution_v3.png", "Figure_6_regional_comparison_v3.png",
           "Figure_S1_exposure_design_v3.png", "Figure_S2_sampling_support_map_v3.png",
           "Figure_S3_complete_species_matrix_v3.png", "Figure_S4_guild_synthesis_v3.png",
           "Figure_S5_sensitivities_placebos_v3.png", "Figure_S6_diagnostics_v3.png"),
  source = c("outputs/stage3_phase3_validation/fold_balance.csv",
             "outputs/stage4a_results/aggregate_sample_sizes.csv",
             "outputs/stage4a_results/effect_estimates.csv",
             "outputs/stage4a_publication_v2/event_time_table_v2.csv",
             "outputs/stage4a_results/effect_estimates.csv;outputs/stage4a_publication_v2/sog_falsification_claim_audit_v2.csv",
             "outputs/stage4a_results/effect_estimates.csv",
             "scripts/Stage3Phase3BlockedValidation.cs;scripts/Stage4AProtectedBuilder.cs",
             "outputs/stage3_phase3_validation/fold_balance.csv",
             "outputs/stage4a_results/effect_estimates.csv",
             "outputs/stage4a_publication_sensitivity_v2/sensitivity_effect_estimates_v2.csv",
             "outputs/stage4a_publication_sensitivity_v2/sensitivity_effect_estimates_v2.csv",
             "outputs/stage4a_results/model_geometry.csv;outputs/stage4a_publication_v2/singular_fit_claim_audit_v2.csv"),
  filter = c("four released regions; region totals only", "selected 14 taxa; SoG/WCVI",
             "selected 12 taxa; M02; SoG/WCVI", "four selected guilds; all six windows",
             "all completed SoG M02 detection plus two M29 comparators",
             "selected eight taxa; M02; SoG/WCVI", "executed coding bounds; conceptual only",
             "four released regions; region totals only", "all M02 SoG/WCVI species components",
             "M01_PRIMARY_v2", "WCVI detection reference/sensitivities/placebos",
             "all legacy geometry categories plus 43 singular components"),
  model_ids = c("sampling support", "descriptive M02 states", "M02", "M05", "M02;M29", "M02",
                "M01;M02;M08", "sampling support", "M02", "M01_PRIMARY_v2",
                "M01_PRIMARY_v2;S4A11;S4A12;M27;M28", "all released geometry; v2 sensitivities"),
  privacy = c("public coastline and region aggregates", "public aggregate", "public aggregate",
              "public aggregate", "public aggregate", "public aggregate", "nongeographic schematic",
              "public coastline and region aggregates", rep("public aggregate", 4)),
  stringsAsFactors = FALSE)

prov <- lapply(seq_len(nrow(fig_sources)), function(i) {
  f <- file.path(pkg, "figures_v3", fig_sources$file[i])
  data.frame(artifact_id = fig_sources$artifact_id[i], artifact_type = "figure",
             artifact_file = paste0("figures_v3/", fig_sources$file[i]), artifact_hash = sha(f),
             source_file = fig_sources$source[i], generation_script = "scripts/build_mer_v3_descriptives_and_figures.R",
             generation_revision = generation_revision, filters = fig_sources$filter[i],
             model_or_family_ids = fig_sources$model_ids[i], privacy_classification = fig_sources$privacy[i],
             stringsAsFactors = FALSE)
})

table_files <- list.files(tab, pattern = "\\.csv$", full.names = TRUE)
table_prov <- lapply(table_files, function(f) data.frame(
  artifact_id = tools::file_path_sans_ext(basename(f)), artifact_type = "table",
  artifact_file = paste0("tables_v3/", basename(f)), artifact_hash = sha(f),
  source_file = "see source and availability columns or supplementary inventory",
  generation_script = if (grepl("descriptive|Table_1|Table_3|Table_4|temporal_sampling", basename(f)))
    "scripts/build_mer_v3_descriptives_and_figures.R" else "scripts/build_mer_v3_package_audits.R",
  generation_revision = generation_revision, filters = "deterministic aggregate-only v3 transformation or versioned copy",
  model_or_family_ids = "as named in artifact", privacy_classification = "public aggregate",
  stringsAsFactors = FALSE))
provenance <- do.call(rbind, c(prov, table_prov))
write_csv(provenance, file.path(aud, "figure_table_provenance_v3.csv"))

# Submission file inventory before rendering; render outputs are appended by the
# validation script after they exist.
inventory_files <- c(list.files(src, full.names = TRUE), list.files(tab, full.names = TRUE),
                     list.files(file.path(pkg, "figures_v3"), full.names = TRUE),
                     list.files(aud, pattern = "v3", full.names = TRUE))
inventory <- data.frame(
  file = substring(normalizePath(inventory_files, winslash = "/"), nchar(normalizePath(pkg, winslash = "/")) + 2L),
  bytes = file.info(inventory_files)$size,
  sha256 = vapply(inventory_files, sha, character(1)),
  role = ifelse(grepl("blinded", inventory_files), "blinded companion",
                ifelse(grepl("figures_v3", inventory_files), "figure",
                       ifelse(grepl("tables_v3", inventory_files), "table",
                              ifelse(grepl("audits", inventory_files), "audit", "source document")))),
  stringsAsFactors = FALSE)
write_csv(inventory, file.path(aud, "submission_file_inventory_v3.csv"))

message("Built MER v3 companion tables, blinded sources, and audits.")
