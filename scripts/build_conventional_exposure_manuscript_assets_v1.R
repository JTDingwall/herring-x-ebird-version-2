#!/usr/bin/env Rscript

# Build privacy-safe narrative and supplementary-document sources from the
# released conventional nearest-event comparison. This script fits no models.

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
library_path <- Sys.getenv("EDITORIAL_R_LIBRARY", "")
if (nzchar(library_path)) .libPaths(c(library_path, .libPaths()))

source(file.path("R", "editorial_requested_analysis_v1.R"), local = FALSE)

output_dir <- "outputs/conventional_exposure_sensitivity_v1"
results_path <- file.path(
  output_dir, "conventional_exposure_sensitivity_results.csv"
)
status_path <- file.path(output_dir, "component_status.csv")
results <- utils::read.csv(results_path, stringsAsFactors = FALSE)
status <- utils::read.csv(status_path, stringsAsFactors = FALSE)

if (nrow(results) != 98L || nrow(status) != 245L) {
  stop("CONVENTIONAL_ASSET_ROW_GATE: unexpected release rows", call. = FALSE)
}

starts_completed <- function(x) grepl("^completed", x)
outcome_order <- c(
  "checklist_reporting", "conditional_positive_numeric_count"
)
summaries <- lapply(outcome_order, function(outcome) {
  x <- results[results$outcome == outcome, , drop = FALSE]
  primary_ok <- starts_completed(x$primary_status)
  sensitivity_ok <- starts_completed(x$sensitivity_status)
  paired <- primary_ok & sensitivity_ok &
    is.finite(x$primary_estimate) & is.finite(x$sensitivity_estimate)
  primary_bh <- primary_ok & is.finite(x$primary_q_value) &
    x$primary_q_value < 0.05
  primary_bh_paired <- primary_bh & paired
  data.frame(
    outcome = outcome,
    primary_estimable = sum(primary_ok),
    sensitivity_estimable = sum(sensitivity_ok),
    paired_estimable = sum(paired),
    sign_concordant = sum(x$sign_agreement[paired]),
    sign_concordance_fraction = mean(x$sign_agreement[paired]),
    primary_bh_significant = sum(primary_bh),
    primary_bh_paired = sum(primary_bh_paired),
    primary_bh_sign_preserved = sum(
      primary_bh_paired & x$sign_agreement
    ),
    primary_bh_remains_bh_significant = sum(
      primary_bh_paired & is.finite(x$sensitivity_q_value) &
        x$sensitivity_q_value < 0.05
    ),
    sensitivity_bh_significant = sum(
      sensitivity_ok & is.finite(x$sensitivity_q_value) &
        x$sensitivity_q_value < 0.05
    ),
    sensitivity_bh_positive = sum(
      sensitivity_ok & is.finite(x$sensitivity_q_value) &
        x$sensitivity_q_value < 0.05 & x$sensitivity_estimate > 0
    ),
    sensitivity_bh_negative = sum(
      sensitivity_ok & is.finite(x$sensitivity_q_value) &
        x$sensitivity_q_value < 0.05 & x$sensitivity_estimate < 0
    ),
    direction_reversals = sum(paired & !x$sign_agreement),
    bh_threshold_crossings = sum(
      paired & !is.na(x$bh_threshold_crossing) &
        x$bh_threshold_crossing
    ),
    material_interpretation_changes = sum(
      paired & x$interpretation_changes_materially
    ),
    stringsAsFactors = FALSE
  )
})
summary_table <- do.call(rbind, summaries)
summary_path <- file.path(output_dir, "comparison_summary.csv")
editorial_write_csv_v1(summary_table, summary_path)

changes <- results[
  results$interpretation_change_class !=
    "same_direction__compatible_magnitude" |
    (!is.na(results$bh_threshold_crossing) &
       results$bh_threshold_crossing),
  , drop = FALSE
]
changes_path <- file.path(output_dir, "interpretation_changes.csv")
editorial_write_csv_v1(changes, changes_path)

outcome_label <- function(x) {
  unname(c(
    checklist_reporting = "Checklist reporting",
    conditional_positive_numeric_count =
      "Conditional positive numeric reported count",
    finite_numeric_vs_x = "Finite numeric versus X"
  )[x])
}
fmt_num <- function(x, digits = 3L) {
  ifelse(is.finite(x), formatC(x, digits = digits, format = "f"), "—")
}
fmt_count <- function(x) {
  ifelse(is.finite(x), formatC(x, digits = 0L, format = "f"), "—")
}
fmt_q <- function(x) {
  ifelse(
    is.finite(x),
    ifelse(
      x < 0.001,
      formatC(x, digits = 2L, format = "e"),
      formatC(x, digits = 3L, format = "f")
    ),
    "—"
  )
}
fmt_ratio_ci <- function(ratio, low, high) {
  ifelse(
    is.finite(ratio) & is.finite(low) & is.finite(high),
    paste0(
      formatC(ratio, digits = 2L, format = "f"), " (",
      formatC(low, digits = 2L, format = "f"), "–",
      formatC(high, digits = 2L, format = "f"), ")"
    ),
    "—"
  )
}
truth_label <- function(x) {
  ifelse(is.na(x), "—", ifelse(x, "yes", "no"))
}
md_escape <- function(x) {
  x <- ifelse(is.na(x), "—", as.character(x))
  x <- gsub("\\|", "\\\\|", x)
  gsub("[\r\n]+", " ", x)
}
markdown_table <- function(x, align = NULL) {
  x[] <- lapply(x, md_escape)
  if (is.null(align)) align <- rep("---", ncol(x))
  c(
    paste0("| ", paste(names(x), collapse = " | "), " |"),
    paste0("| ", paste(align, collapse = " | "), " |"),
    apply(x, 1L, function(row) {
      paste0("| ", paste(row, collapse = " | "), " |")
    })
  )
}

summary_display <- summary_table
summary_display$outcome <- outcome_label(summary_display$outcome)
summary_display$sign_concordance <- paste0(
  summary_display$sign_concordant, "/",
  summary_display$paired_estimable, " (",
  formatC(
    100 * summary_display$sign_concordance_fraction,
    digits = 1L, format = "f"
  ), "%)"
)
summary_display$nearest_bh_direction <- paste0(
  summary_display$sensitivity_bh_positive,
  " positive / ",
  summary_display$sensitivity_bh_negative,
  " negative"
)
summary_display <- summary_display[, c(
  "outcome", "primary_estimable", "sensitivity_estimable",
  "sign_concordance", "primary_bh_significant",
  "nearest_bh_direction", "direction_reversals",
  "material_interpretation_changes"
)]
names(summary_display) <- c(
  "Outcome", "Primary estimable", "Nearest-event estimable",
  "Sign concordance", "Primary BH q < 0.05",
  "Nearest-event BH positive / negative", "Sign reversals",
  "Material interpretation changes"
)

change_display <- if (nrow(changes)) {
  data.frame(
    Species = changes$species,
    Outcome = outcome_label(changes$outcome),
    `Primary ratio (95% CI)` = fmt_ratio_ci(
      changes$primary_ratio,
      changes$primary_ratio_conf_low,
      changes$primary_ratio_conf_high
    ),
    `Nearest-event ratio (95% CI)` = fmt_ratio_ci(
      changes$sensitivity_ratio,
      changes$sensitivity_ratio_conf_low,
      changes$sensitivity_ratio_conf_high
    ),
    `Primary q` = fmt_q(changes$primary_q_value),
    `Nearest-event q` = fmt_q(changes$sensitivity_q_value),
    `BH threshold crossed` = truth_label(
      changes$bh_threshold_crossing
    ),
    Classification = changes$interpretation_change_class,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
} else {
  data.frame(
    Result = "No direction, threshold, or interval-compatibility changes.",
    stringsAsFactors = FALSE
  )
}

reporting_summary <- summary_table[
  summary_table$outcome == "checklist_reporting", , drop = FALSE
]
count_summary <- summary_table[
  summary_table$outcome == "conditional_positive_numeric_count",
  , drop = FALSE
]
material_total <- sum(summary_table$material_interpretation_changes)
primary_bh_robustness <- paste0(
  reporting_summary$primary_bh_sign_preserved, "/",
  reporting_summary$primary_bh_paired,
  " primary-BH reporting signs and ",
  count_summary$primary_bh_sign_preserved, "/",
  count_summary$primary_bh_paired,
  " primary-BH count signs were preserved; ",
  reporting_summary$primary_bh_remains_bh_significant, " and ",
  count_summary$primary_bh_remains_bh_significant,
  ", respectively, remained BH-significant"
)
defensibility <- if (material_total == 0L) {
  paste0(
    "The nearest-event sensitivity does not materially change the ",
    "primary scientific interpretation under the fixed pre-result comparison ",
    "rule. ", primary_bh_robustness, ". It supports describing the main ",
    "conclusions as robust to this ",
    "conventional one-event exposure encoding, while the observational and ",
    "noncausal limitations remain."
  )
} else {
  paste0(
    "The nearest-event sensitivity identifies ", material_total,
    " material interpretation change(s) under the fixed pre-result comparison ",
    "rule. ", primary_bh_robustness, ". The main conclusions therefore ",
    "require the species- and ",
    "outcome-specific qualifications listed below; observational and ",
    "noncausal limitations remain."
  )
}

memo_lines <- c(
  "# Conventional exposure sensitivity: interpretation memo",
  "",
  "## Frozen design choice",
  "",
  paste0(
    "Deterministic nearest-event assignment was selected before model fitting. ",
    "Complete single-event restriction retained 72,443 of 217,200 checklists ",
    "and supported conditional positive numeric reported-count models for ",
    "19 of 49 species. Nearest-event assignment retained all 217,200 ",
    "checklists, preserved full fixed-effect rank, and supported the count ",
    "model for 41 of 49 species. Both candidates supported checklist ",
    "reporting for all 49 species. The decision used only design support and ",
    "geometry; no response estimate or fitted result was read."
  ),
  "",
  "## Primary-versus-sensitivity comparison",
  "",
  markdown_table(summary_display),
  "",
  defensibility,
  "",
  paste0(
    "BH-threshold crossing alone is not classified as a material change. ",
    "Same-direction interval nonoverlap is flagged but is not treated as a ",
    "material change because the exposure units differ. A material change is ",
    "a sign reversal with at least one 95% confidence interval excluding zero."
  ),
  "",
  "## Changes requiring explicit review",
  "",
  markdown_table(change_display),
  "",
  "## Component-status handling",
  "",
  paste0(
    "All primary, finite-number-versus-X, and nearest-event components are ",
    "retained in `component_status.csv`, including failures and warnings. ",
    "Failed components are statuses rather than null biological results. ",
    "The table explicitly flags Surfbird, Rhinoceros Auklet, Glaucous Gull, ",
    "Red-throated Loon, Western Gull, Common Goldeneye, Marbled Murrelet, ",
    "and Western Grebe."
  ),
  "",
  "## Scientific boundary",
  "",
  paste0(
    "The sensitivity changes only the exposure encoding. Eligibility, zones, ",
    "periods, A14 active-minus-pre comparison, covariates, random effects, ",
    "confidence intervals, and BH families remain unchanged. Results concern ",
    "checklist reporting and conditional positive numeric reported counts; ",
    "they do not establish detection probability, occupancy, regional ",
    "abundance, diet, movement, or causation."
  )
)
memo_path <- file.path(output_dir, "interpretation_memo.md")
writeLines(enc2utf8(memo_lines), memo_path, useBytes = TRUE)

result_display <- data.frame(
  Species = results$species,
  Outcome = outcome_label(results$outcome),
  Primary = paste0(
    fmt_ratio_ci(
      results$primary_ratio,
      results$primary_ratio_conf_low,
      results$primary_ratio_conf_high
    ),
    "; q=", fmt_q(results$primary_q_value),
    "; ", results$primary_status
  ),
  `Nearest event` = paste0(
    fmt_ratio_ci(
      results$sensitivity_ratio,
      results$sensitivity_ratio_conf_low,
      results$sensitivity_ratio_conf_high
    ),
    "; q=", fmt_q(results$sensitivity_q_value),
    "; ", results$sensitivity_status
  ),
  `Same sign` = truth_label(results$sign_agreement),
  `Interpretation classification` =
    results$interpretation_change_class,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
result_display <- result_display[
  order(match(results$outcome, outcome_order), results$species),
  , drop = FALSE
]

group_summary <- paste0(
  "event=", fmt_count(status$event_blocks),
  "; observer=", fmt_count(status$observer_clusters),
  "; location=", fmt_count(status$generalized_locations)
)
diagnostic_summary <- paste0(
  "converged=", truth_label(status$converged),
  "; singular=", truth_label(status$singular_fit),
  "; rank deficient=", truth_label(status$rank_deficient),
  "; optimizer=", ifelse(
    is.na(status$optimizer_code) | !nzchar(status$optimizer_code),
    "—", status$optimizer_code
  ),
  "; max |gradient|=", fmt_num(status$maximum_absolute_gradient, 4L)
)
variance_summary <- paste0(
  "event=", fmt_num(status$event_block_variance, 4L),
  "; observer=", fmt_num(status$observer_variance, 4L),
  "; location=", fmt_num(status$location_variance, 4L)
)
status_failure <- ifelse(
  !is.na(status$failure_reason) & nzchar(status$failure_reason),
  paste0(status$status, ": ", status$failure_reason),
  status$status
)
status_display <- data.frame(
  Analysis = status$analysis,
  Component = paste0(
    status$species, " — ", outcome_label(status$outcome)
  ),
  `Engine / n / grouping levels` = paste0(
    status$engine, "; n=", fmt_count(status$n), "; ", group_summary
  ),
  Diagnostics = diagnostic_summary,
  Variances = paste0(
    variance_summary,
    "; residual=", fmt_num(status$residual_variance, 4L)
  ),
  `Status / failure reason` = status_failure,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
status_display <- status_display[order(
  status$analysis, status$outcome, status$species
), , drop = FALSE]

formula_display <- unique(status[, c(
  "analysis", "outcome", "engine", "exposure_encoding", "model_formula"
)])
formula_display <- formula_display[order(
  formula_display$analysis, formula_display$outcome
), , drop = FALSE]
formula_display$component <- paste0(
  outcome_label(formula_display$outcome), " — ", formula_display$engine
)
formula_display <- formula_display[, c(
  "analysis", "component", "exposure_encoding", "model_formula"
)]
names(formula_display) <- c(
  "Analysis", "Outcome and engine", "Exposure encoding", "Model formula"
)

source_dir <- file.path(
  "manuscript", "journal_submission", "marine_environmental_research",
  "source_v9"
)
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
supplement_lines <- c(
  "---",
  'title: "Supplementary material: Event-linked coastal-bird checklist reporting and counts during Pacific herring spawning"',
  "author:",
  '  - name: "Jacob T. Dingwall"',
  'date: ""',
  "format:",
  "  docx:",
  "    reference-doc: ../source_v7/mer_v7_times_new_roman_reference.docx",
  "    toc: true",
  "    toc-depth: 3",
  "    number-sections: true",
  "execute:",
  "  enabled: false",
  "lang: en",
  "---",
  "",
  "# Scope and governance",
  "",
  paste0(
    "This supplement accompanies manuscript v9 and its single conventional ",
    "nearest-event exposure sensitivity. The work is a post-result ",
    "exploratory refinement. It does not overwrite the earlier registered ",
    "analysis or the protected Stage 4A record. Only privacy-safe aggregate ",
    "results are included; no checklist, observer, locality, source-event ",
    "identifier, exact coordinate, model object, checkpoint, or record-level ",
    "derivative is released."
  ),
  "",
  "# Estimand and frozen sensitivity design",
  "",
  paste0(
    "The primary model retains all concurrent checklist-to-event links ",
    "additively. The conventional sensitivity assigns each checklist to one ",
    "minimum-distance event within the modeled window, using a deterministic ",
    "source-token tie break. The sensitivity retains the same checklist ",
    "eligibility, <5 km near and 5–20 km reference zones, six timing periods, ",
    "A14 active-minus-pre contrast, adjustment variables, three random ",
    "intercepts, 95% confidence intervals, and 49-species BH families."
  ),
  "",
  paste0(
    "The A14 estimate compares the duration-weighted active period ",
    "(days 0–14) with days −14 to −1 after applying the same baseline-adjusted ",
    "near/reference construction. Primary estimates are per additional ",
    "recorded event link; nearest-event estimates use a single selected link. ",
    "Neither is a percentage change in occupancy or regional abundance."
  ),
  "",
  paste0(
    "Release assembly declares the contrast-to-diagnostic relationship as ",
    "many-to-one across A14/A7 rows and one-to-one after collapse to ",
    "species–outcome. The primary-diagnostic relationship is many-to-one ",
    "from the two sensitivity outcomes into the three-outcome primary family. ",
    "Uniqueness, complete matching, and expected row cardinalities are tested ",
    "before any release table is written."
  ),
  "",
  "## Model formulas and engines",
  "",
  markdown_table(formula_display),
  "",
  "# Comparison summary",
  "",
  markdown_table(summary_display),
  "",
  defensibility,
  "",
  "# Complete primary and nearest-event A14 results",
  "",
  paste0(
    "Table S1 reports every member of the 49-species family for checklist ",
    "reporting and conditional positive numeric reported count. An em dash ",
    "marks a failed or unsupported component; the status field is the result ",
    "for that component. BH-threshold changes alone are not classified as ",
    "material interpretation changes. Same-direction interval nonoverlap is ",
    "flagged but is not material because the exposure units differ."
  ),
  "",
  markdown_table(result_display),
  "",
  "# Complete component status and diagnostics",
  "",
  paste0(
    "Table S2 retains 147 historical primary/finite-number-versus-X ",
    "components and 98 nearest-event components. Group counts, convergence ",
    "flags, singularity, rank deficiency, optimizer codes, maximum absolute ",
    "gradients, all random-intercept variances, residual variance, and failure ",
    "reasons are displayed. Failed components are not biological null results."
  ),
  "",
  markdown_table(status_display),
  "",
  "# Interpretation limits",
  "",
  paste0(
    "Checklist reporting is not occupancy or formal detection probability. ",
    "Conditional positive numeric reported count excludes unquantified X ",
    "reports and conditions on the species being reported with a finite ",
    "number. The sensitivity does not establish herring consumption, ",
    "herring-induced movement, or a change in total Strait of Georgia ",
    "abundance. Habitat, migration, access, event classification, exposure ",
    "encoding, and observer behaviour remain plausible explanations."
  ),
  "",
  "# Machine-readable companion files",
  "",
  paste0(
    "- `conventional_exposure_sensitivity_results.csv`: complete 49 × 2 A14 ",
    "primary-versus-nearest-event comparison."
  ),
  paste0(
    "- `component_status.csv`: complete 245-component status, diagnostics, ",
    "formulas, and variance release."
  ),
  paste0(
    "- `comparison_summary.csv`: outcome-level estimability, sign ",
    "concordance, BH, reversal, and material-change counts."
  ),
  paste0(
    "- `interpretation_changes.csv`: components requiring explicit ",
    "direction, threshold, or interval-compatibility review."
  ),
  paste0(
    "- `sensitivity_execution_record.yml`: authorization, input hashes, ",
    "code commit, and zero prospective-record access."
  )
)
supplement_path <- file.path(source_dir, "mer_supplement_v9.qmd")
writeLines(enc2utf8(supplement_lines), supplement_path, useBytes = TRUE)

highlight_material <- if (material_total == 0L) {
  "- No component met the prespecified material-change rule"
} else {
  paste0(
    "- ", material_total,
    " component(s) met the prespecified material-change rule"
  )
}
highlight_lines <- c(
  "---",
  'title: "Highlights"',
  "author:",
  '  - name: "Jacob T. Dingwall"',
  'date: ""',
  "format:",
  "  docx:",
  "    reference-doc: ../source_v7/mer_v7_times_new_roman_reference.docx",
  "    toc: false",
  "    number-sections: false",
  "execute:",
  "  enabled: false",
  "lang: en",
  "---",
  "",
  "- Nearest-event sensitivity retained all 217,200 eligible checklists",
  paste0(
    "- Exposure signs agreed for ",
    reporting_summary$sign_concordant, "/",
    reporting_summary$paired_estimable, " reporting and ",
    count_summary$sign_concordant, "/",
    count_summary$paired_estimable, " count estimates"
  ),
  "- Reported-count associations were more often BH-significant than reporting",
  highlight_material,
  "- Results are event-linked associations, not occupancy or abundance effects"
)
highlight_path <- file.path(source_dir, "mer_highlights_v9.qmd")
writeLines(enc2utf8(highlight_lines), highlight_path, useBytes = TRUE)

revision_lines <- c(
  "# Revision memo: manuscript v9 conventional exposure sensitivity",
  "",
  "## Scope and branch basis",
  "",
  paste0(
    "This additive revision starts from the exact head of PR #13 ",
    "(`167489b54d506748c17ab8fb77a6c92d5c58be19`), because that head ",
    "contains the PR #12 verified analytical base and the v9 manuscript. ",
    "The protected Stage 4A history and the original PR #13 v9 files remain ",
    "unchanged; the revised clean manuscript is a new file."
  ),
  "",
  "## Single new analysis",
  "",
  paste0(
    "A prefit comparison used only support and geometry. Complete ",
    "single-event restriction retained 72,443 checklists and supported ",
    "conditional positive numeric reported-count models for 19 of 49 ",
    "species. Deterministic nearest-event assignment retained all 217,200 ",
    "checklists, full fixed-effect rank, and count-model support for 41 ",
    "species, so it was frozen as the sole conventional sensitivity before ",
    "any model was fitted. No other new sensitivity, engine, species family, ",
    "bootstrap, influence analysis, radius, travel/stationary restriction, ",
    "observer restriction, placebo, or hierarchical model was run."
  ),
  "",
  "## Verified comparison",
  "",
  markdown_table(summary_display),
  "",
  defensibility,
  "",
  "## Manuscript changes",
  "",
  paste0(
    "- Abstract: replaces the incomplete nearest-event statement with the ",
    "verified estimability and sign-concordance results and remains within ",
    "the 250-word limit."
  ),
  paste0(
    "- Methods: records the prefit single-event versus nearest-event support ",
    "comparison, deterministic tie handling, unchanged estimand components, ",
    "and the prohibition on outcome-informed design choice."
  ),
  paste0(
    "- Results: reports nearest-event estimability, BH counts, sign ",
    "concordance, and every material change or reversal under the fixed rule."
  ),
  paste0(
    "- Discussion and Conclusion: state how the conventional sensitivity ",
    "affects robustness without weakening the noncausal, observation-process, ",
    "or regional-abundance limitations."
  ),
  paste0(
    "- Submission formatting: continuous line numbering and page-number ",
    "fields are added to the revised clean manuscript."
  ),
  paste0(
    "- Terminology: the revision uses checklist reporting and reported counts; ",
    "it does not recast them as detection, occupancy, flock size, or abundance."
  ),
  "",
  "## Complete status handling",
  "",
  paste0(
    "The synchronized Supplement and `component_status.csv` retain all 245 ",
    "primary, finite-number-versus-X, and nearest-event components. Status, ",
    "formula, engine, model sample size, grouping levels, convergence flags, ",
    "singularity, rank deficiency, optimizer code, maximum absolute gradient, ",
    "random-effect variances, residual variance, and failure reason are ",
    "reported. Failed components are not displayed as estimates and are not ",
    "described as biological null results."
  ),
  "",
  paste0(
    "The status table explicitly flags Surfbird, Rhinoceros Auklet, Glaucous ",
    "Gull, Red-throated Loon, Western Gull, Common Goldeneye, Marbled ",
    "Murrelet, and Western Grebe."
  ),
  "",
  "## Material changes and reversals",
  "",
  markdown_table(change_display),
  "",
  "## Author inputs retained",
  "",
  paste0(
    "Visible placeholders remain for the full postal address, telephone ",
    "number, registration/repository DOI, funding statement, ",
    "journal-compliant generative-AI disclosure, and additional ",
    "acknowledgements."
  ),
  "",
  "## Deliverables",
  "",
  paste0(
    "- Revised clean manuscript: ",
    "`mer_manuscript_unblinded_v9_revised_clean.docx`."
  ),
  "- Synchronized Supplement: `mer_supplement_v9.docx`.",
  "- Updated highlights: `mer_highlights_v9.docx`.",
  paste0(
    "- Machine-readable results, comparison summary, interpretation changes, ",
    "component statuses, execution record, and output hashes in ",
    "`outputs/conventional_exposure_sensitivity_v1/`."
  ),
  "",
  "## Interpretation boundary",
  "",
  paste0(
    "The sensitivity supports only robustness to one conventional exposure ",
    "encoding. It does not establish formal detection probability, occupancy, ",
    "regional abundance, diet, individual movement, or causation. The current ",
    "analysis remains exploratory and estimand-refining until prospective ",
    "confirmation using the complete locked release."
  )
)
revision_path <- file.path(
  "manuscript", "journal_submission", "marine_environmental_research",
  "rendered_v9", "mer_manuscript_v9_conventional_sensitivity_revision_memo.md"
)
writeLines(enc2utf8(revision_lines), revision_path, useBytes = TRUE)

editorial_privacy_column_gate_v1(c(
  results_path, status_path, summary_path, changes_path
))
release_names <- c(
  "design_selection.csv",
  "sensitivity_comparisons.csv",
  "sensitivity_diagnostics.csv",
  "sensitivity_support.csv",
  "sensitivity_execution_record.yml",
  "conventional_exposure_sensitivity_results.csv",
  "component_status.csv",
  "comparison_summary.csv",
  "interpretation_changes.csv",
  "interpretation_memo.md"
)
release_paths <- file.path(output_dir, release_names)
if (!all(file.exists(release_paths))) {
  stop(
    "CONVENTIONAL_RELEASE_MANIFEST_GATE: missing release file(s)",
    call. = FALSE
  )
}
manifest <- data.frame(
  file = release_names,
  bytes = unname(file.info(release_paths)$size),
  sha256 = vapply(release_paths, editorial_sha256_v1, character(1L)),
  stringsAsFactors = FALSE
)
editorial_write_csv_v1(
  manifest, file.path(output_dir, "output_hash_manifest.csv")
)
message(
  "CONVENTIONAL_MANUSCRIPT_ASSETS=PASS; material_changes=",
  material_total,
  "; reporting_sign_concordance=",
  reporting_summary$sign_concordant, "/",
  reporting_summary$paired_estimable,
  "; count_sign_concordance=",
  count_summary$sign_concordant, "/",
  count_summary$paired_estimable
)
