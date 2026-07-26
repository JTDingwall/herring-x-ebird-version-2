#!/usr/bin/env Rscript

# Aggregate-only descriptive figures for conditional reported-number profiles.
# No checklist records are read and no response model is fit or refit.

options(stringsAsFactors = FALSE, warn = 1)

task_lib <- Sys.getenv("RESPONSE_CLUSTERING_R_LIB", unset = "")
if (nzchar(task_lib)) .libPaths(c(task_lib, .libPaths()))

required_packages <- c("vegan")
available <- vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
if (!all(available)) {
  stop("Missing required package(s): ", paste(names(available)[!available], collapse = ", "))
}

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "outputs", "count_only_response_profiles_v1")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

effects_path <- file.path(
  root, "outputs", "post_stage4a_sog_event_study_v1", "effect_estimates_v1.csv"
)
registry_path <- file.path(root, "metadata", "canonical_species_registry.csv")
stopifnot(file.exists(effects_path), file.exists(registry_path))

read_csv <- function(path) {
  read.csv(path, check.names = FALSE, na.strings = c("", "NA"),
           stringsAsFactors = FALSE)
}

write_csv <- function(x, name) {
  write.csv(x, file.path(out_dir, name), row.names = FALSE, na = "")
}

assert_unique <- function(x, keys, label) {
  key <- do.call(paste, c(x[keys], sep = "\r"))
  if (anyDuplicated(key)) {
    stop(label, " violates declared ", paste(keys, collapse = "+"), " uniqueness.")
  }
  invisible(TRUE)
}

period_definitions <- data.frame(
  contrast = c(
    "did_early_pre", "did_immediate_pre", "did_spawn_start",
    "did_early_egg", "did_late_egg", "did_active_0_14_day"
  ),
  short_label = c(
    "Early pre", "Immediate pre", "Spawn start",
    "Early egg", "Late egg", "Active 0–14"
  ),
  figure_label = c(
    "Early pre\n−14 to −8", "Immediate pre\n−7 to −1",
    "Spawn start\n0 to 3", "Early egg\n4 to 14",
    "Late egg\n15 to 28", "Active 0–14\ncomposite"
  ),
  minimum_day = c(-14, -7, 0, 4, 15, 0),
  maximum_day = c(-8, -1, 3, 14, 28, 14),
  duration_days = c(7, 7, 4, 11, 14, 15),
  role = c(rep("disjoint_period", 5), "duration_weighted_composite"),
  stringsAsFactors = FALSE
)
disjoint_periods <- period_definitions$contrast[
  period_definitions$role == "disjoint_period"
]
active_composite <- "did_active_0_14_day"
write_csv(period_definitions, "period_definitions.csv")

effects <- read_csv(effects_path)
count_rows <- effects[
  effects$analysis_role == "core_species" &
    effects$outcome == "positive_numeric_count_given_detection" &
    effects$contrast %in% period_definitions$contrast,
]
assert_unique(count_rows, c("analysis_taxon_id", "contrast"),
              "archived count-period effects")
if (nrow(count_rows) != 49 * 6) {
  stop("Expected 294 count-period rows for the fixed 49-species family.")
}

taxa <- unique(count_rows[, c("analysis_taxon_id", "unit_label")])
assert_unique(taxa, "analysis_taxon_id", "count-period taxa")
if (nrow(taxa) != 49) stop("Expected the fixed 49-species family.")

extract_feature <- function(contrast, field) {
  z <- count_rows[count_rows$contrast == contrast, ]
  setNames(as.numeric(z[[field]]), z$analysis_taxon_id)[taxa$analysis_taxon_id]
}

estimate_matrix_all <- sapply(
  period_definitions$contrast, extract_feature, field = "estimate"
)
se_matrix_all <- sapply(
  period_definitions$contrast, extract_feature, field = "standard_error"
)
status_matrix_all <- sapply(
  period_definitions$contrast,
  function(contrast) {
    z <- count_rows[count_rows$contrast == contrast, ]
    setNames(z$status, z$analysis_taxon_id)[taxa$analysis_taxon_id]
  }
)
rownames(estimate_matrix_all) <- rownames(se_matrix_all) <-
  rownames(status_matrix_all) <- taxa$analysis_taxon_id
colnames(estimate_matrix_all) <- colnames(se_matrix_all) <-
  colnames(status_matrix_all) <- period_definitions$contrast

complete <- apply(
  is.finite(estimate_matrix_all) & is.finite(se_matrix_all) & se_matrix_all > 0,
  1, all
)
expected_drop <- sort(c("Glaucous Gull", "Rhinoceros Auklet", "Surfbird"))
names_by_id <- setNames(taxa$unit_label, taxa$analysis_taxon_id)
actual_drop <- sort(unname(names_by_id[!complete]))
if (!identical(actual_drop, expected_drop) || sum(complete) != 46) {
  stop("Complete-case reconciliation failed: ", paste(actual_drop, collapse = ", "))
}

ids <- rownames(estimate_matrix_all)[complete]
raw_all <- estimate_matrix_all[ids, , drop = FALSE]
se_all <- se_matrix_all[ids, , drop = FALSE]
raw_disjoint <- raw_all[, disjoint_periods, drop = FALSE]
se_disjoint <- se_all[, disjoint_periods, drop = FALSE]
active <- raw_all[, active_composite]
active_se <- se_all[, active_composite]

if (any(!is.finite(raw_disjoint)) || any(!is.finite(se_disjoint)) ||
    any(se_disjoint <= 0)) {
  stop("Non-finite complete-case values remain.")
}

# These transformations are declared before any ordination result is inspected:
# - Raw heatmap: archived link-scale estimates.
# - Timing-shape heatmap: each species' five disjoint estimates minus its
#   across-period mean; this removes overall response level only for display.
# - PCA and NMDS: each of the five disjoint period features centred and scaled
#   across species; NMDS uses Euclidean distances on this same matrix.
timing_shape <- raw_disjoint - rowMeans(raw_disjoint)
standardized <- scale(raw_disjoint, center = TRUE, scale = TRUE)
if (any(!is.finite(standardized))) stop("Standardized matrix is non-finite.")

timing_hc <- hclust(dist(timing_shape, method = "euclidean"), method = "ward.D2")
species_order <- timing_hc$labels[timing_hc$order]

pca <- prcomp(standardized, center = FALSE, scale. = FALSE)
pca_variance <- 100 * pca$sdev^2 / sum(pca$sdev^2)

nmds_seed <- 20260726L
set.seed(nmds_seed)
nmds <- vegan::metaMDS(
  standardized, distance = "euclidean", k = 2, trymax = 200,
  autotransform = FALSE, wascores = FALSE, trace = FALSE
)
nmds_scores_raw <- as.data.frame(vegan::scores(nmds, display = "sites"))
nmds_scores_raw$analysis_taxon_id <- rownames(nmds_scores_raw)
original_dist <- as.vector(dist(standardized, method = "euclidean"))
nmds_dist <- as.vector(dist(nmds_scores_raw[, c("NMDS1", "NMDS2")]))
distance_correlation <- cor(original_dist, nmds_dist, method = "spearman")

# Guild is joined only after matrices, ordering, PCA, and NMDS have been fixed.
registry <- read_csv(registry_path)
assert_unique(registry, "analysis_taxon_id", "canonical species registry")
registry_idx <- match(ids, registry$analysis_taxon_id)
if (anyNA(registry_idx)) stop("Registry join has unmatched complete-case species.")
guild <- registry$guild_ids[registry_idx]
if (anyNA(guild) || length(unique(guild)) != 7) {
  stop("Expected seven non-missing guilds after the post-ordination join.")
}

posthoc <- data.frame(
  analysis_taxon_id = ids,
  common_name = unname(names_by_id[ids]),
  guild = guild,
  stringsAsFactors = FALSE
)

long_rows <- list()
for (j in seq_len(ncol(raw_all))) {
  contrast <- colnames(raw_all)[j]
  d <- period_definitions[period_definitions$contrast == contrast, ]
  long_rows[[j]] <- data.frame(
    analysis_taxon_id = ids,
    common_name = unname(names_by_id[ids]),
    contrast = contrast,
    short_label = d$short_label,
    minimum_day = d$minimum_day,
    maximum_day = d$maximum_day,
    role = d$role,
    estimate_link = raw_all[, j],
    standard_error = se_all[, j],
    ratio = exp(raw_all[, j]),
    conf_low_link = raw_all[, j] - 1.96 * se_all[, j],
    conf_high_link = raw_all[, j] + 1.96 * se_all[, j],
    ratio_conf_low = exp(raw_all[, j] - 1.96 * se_all[, j]),
    ratio_conf_high = exp(raw_all[, j] + 1.96 * se_all[, j]),
    stringsAsFactors = FALSE
  )
}
long_effects <- do.call(rbind, long_rows)
write_csv(long_effects, "count_period_effects_long.csv")

wide_matrix <- data.frame(
  analysis_taxon_id = ids,
  common_name = unname(names_by_id[ids]),
  raw_disjoint,
  active_0_14_composite = active,
  check.names = FALSE
)
write_csv(wide_matrix, "count_period_matrix.csv")

timing_shape_df <- data.frame(
  analysis_taxon_id = ids,
  common_name = unname(names_by_id[ids]),
  timing_shape,
  check.names = FALSE
)
write_csv(timing_shape_df, "count_timing_shape_matrix.csv")

standardized_df <- data.frame(
  analysis_taxon_id = ids,
  common_name = unname(names_by_id[ids]),
  standardized,
  check.names = FALSE
)
write_csv(standardized_df, "count_standardized_ordination_matrix.csv")

period_summary <- do.call(rbind, lapply(seq_len(nrow(period_definitions)), function(i) {
  contrast <- period_definitions$contrast[i]
  y <- raw_all[, contrast]
  data.frame(
    contrast = contrast,
    short_label = period_definitions$short_label[i],
    role = period_definitions$role[i],
    minimum_day = period_definitions$minimum_day[i],
    maximum_day = period_definitions$maximum_day[i],
    n_species = length(y),
    mean_link_equal_species = mean(y),
    standard_error_of_species_mean = sd(y) / sqrt(length(y)),
    median_link = median(y),
    q1_link = unname(quantile(y, 0.25)),
    q3_link = unname(quantile(y, 0.75)),
    minimum_link = min(y),
    maximum_link = max(y),
    proportion_positive = mean(y > 0),
    geometric_mean_ratio = exp(mean(y)),
    median_ratio = exp(median(y)),
    stringsAsFactors = FALSE
  )
}))
write_csv(period_summary, "count_period_summary.csv")

pca_scores <- data.frame(
  analysis_taxon_id = ids,
  common_name = unname(names_by_id[ids]),
  guild = guild,
  pca$x,
  check.names = FALSE
)
write_csv(pca_scores, "pca_scores.csv")

pca_loadings <- data.frame(
  contrast = rownames(pca$rotation),
  pca$rotation,
  check.names = FALSE
)
write_csv(pca_loadings, "pca_loadings.csv")

nmds_scores <- merge(
  posthoc, nmds_scores_raw, by = "analysis_taxon_id", sort = FALSE
)
nmds_scores <- nmds_scores[match(ids, nmds_scores$analysis_taxon_id), ]
write_csv(nmds_scores, "nmds_scores.csv")

ordination_diagnostics <- data.frame(
  method = c("PCA", "PCA", "NMDS", "NMDS"),
  metric = c(
    "PC1 variance explained percent",
    "PC2 variance explained percent",
    "Kruskal stress",
    "Spearman correlation of original and 2D ordination distances"
  ),
  value = c(pca_variance[1], pca_variance[2],
            nmds$stress, distance_correlation),
  seed = c(NA, NA, nmds_seed, nmds_seed)
)
write_csv(ordination_diagnostics, "ordination_diagnostics.csv")

exclusions <- data.frame(
  common_name = expected_drop,
  reason = c(
    "reported-number model not estimable",
    "reported-number model not estimable",
    "reported-number model not estimable"
  )
)
write_csv(exclusions, "complete_case_exclusions.csv")

join_audit <- data.frame(
  source = c("archived count-period effects", "canonical species registry"),
  rows_read = c(nrow(count_rows), nrow(registry)),
  declared_key = c("analysis_taxon_id + contrast", "analysis_taxon_id"),
  cardinality = "one-to-one at the declared key",
  duplicate_keys = 0,
  matched_complete_case_species = c(46, 46)
)
write_csv(join_audit, "join_cardinality_audit.csv")

chart_map <- data.frame(
  figure = c(
    "count_effect_heatmap_raw.png",
    "count_effect_heatmap_timing_shape.png",
    "count_profile_pca.png",
    "count_profile_nmds.png",
    "count_period_distribution_link.png",
    "count_period_distribution_ratio.png"
  ),
  question = c(
    "What are the archived adjusted count effects by species and disjoint period?",
    "How does each species' timing shape differ after removing its overall level?",
    "What linear structure is present in standardized count profiles?",
    "What rank-order geometry is present in the same standardized profiles?",
    "How are equal-species link effects distributed across periods?",
    "How are the same effects interpreted as reported-number ratios?"
  ),
  chart_type = c("diverging heatmap", "diverging heatmap", "PCA scatter",
                 "Euclidean NMDS scatter", "boxplot with species points",
                 "log-scale boxplot with species points"),
  data_grain = c(rep("species by archived period", 2),
                 rep("species", 2), rep("species by archived period", 2)),
  primary_caveat = c(
    rep("Conditional reported-number model contrasts, not total bird abundance.", 6)
  )
)
write_csv(chart_map, "chart_map.csv")

blue <- "#315A7D"
blue_light <- "#B9D1E1"
gold <- "#D2942A"
gold_dark <- "#8C5A13"
ink <- "#303030"
grid <- "#D7D7D7"
open <- "#F7F7F5"
diverging_palette <- c(
  colorRampPalette(c("#244A6B", "#A9C6D9", open))(128),
  colorRampPalette(c(open, "#E3B46C", "#92520C"))(128)[-1]
)

guild_levels <- sort(unique(guild))
guild_pch <- setNames(c(21, 22, 23, 24, 25, 7, 8), guild_levels)

plot_heatmap <- function(mat, filename, title, subtitle, order_ids) {
  m <- mat[rev(order_ids), , drop = FALSE]
  zlim <- max(abs(m))
  png(file.path(out_dir, filename), width = 2600, height = 3200, res = 220)
  layout(matrix(c(1, 2), nrow = 1), widths = c(6, 0.55))
  par(mar = c(10, 14, 6, 1), family = "sans")
  image(
    x = seq_len(ncol(m)), y = seq_len(nrow(m)), z = t(m),
    col = diverging_palette, zlim = c(-zlim, zlim),
    axes = FALSE, xlab = "", ylab = "", useRaster = TRUE
  )
  axis(1, at = seq_len(ncol(m)),
       labels = period_definitions$figure_label[
         match(colnames(m), period_definitions$contrast)
       ], las = 2, tick = FALSE, cex.axis = 0.78)
  axis(2, at = seq_len(nrow(m)),
       labels = unname(names_by_id[rownames(m)]),
       las = 2, tick = FALSE, cex.axis = 0.55)
  abline(v = seq(1.5, ncol(m) - 0.5, by = 1), col = "#FFFFFF90", lwd = 0.8)
  abline(h = seq(1.5, nrow(m) - 0.5, by = 1), col = "#FFFFFF45", lwd = 0.35)
  box(col = ink)
  title(main = title, line = 3, cex.main = 1.25)
  mtext(subtitle, side = 3, line = 1.2, cex = 0.8)
  mtext("Days are relative to recorded spawn onset; baseline is days −28 to −15.",
        side = 1, line = 8.3, cex = 0.7)
  par(mar = c(10, 0, 6, 4))
  image(
    x = 1, y = seq(-zlim, zlim, length.out = length(diverging_palette)),
    z = matrix(seq(-zlim, zlim, length.out = length(diverging_palette)), nrow = 1),
    col = diverging_palette, axes = FALSE, xlab = "", ylab = ""
  )
  axis(4, las = 2, cex.axis = 0.7)
  mtext("Link-scale effect", side = 4, line = 2.5, cex = 0.75)
  abline(h = 0, col = ink, lwd = 0.8)
  dev.off()
}

plot_heatmap(
  raw_disjoint,
  "count_effect_heatmap_raw.png",
  "Conditional reported-number effects by species and period",
  "Archived difference-in-differences estimates on the log-count scale; n=46 species",
  species_order
)

plot_heatmap(
  timing_shape,
  "count_effect_heatmap_timing_shape.png",
  "Within-species reported-number timing shapes",
  "Each row is centred on that species' five-period mean; ordering is Ward.D2 for display only",
  species_order
)

plot_ordination <- function(scores, filename, title, subtitle) {
  score_mat <- as.matrix(scores[, 1:2, drop = FALSE])
  scaled_scores <- scale(score_mat)
  radial <- rowSums(scaled_scores^2)
  radial_order <- names(sort(radial, decreasing = TRUE))
  label_ids <- character(0)
  for (candidate in radial_order) {
    sufficiently_separate <- length(label_ids) == 0 ||
      all(sqrt(rowSums(
        (scaled_scores[label_ids, , drop = FALSE] -
           matrix(scaled_scores[candidate, ], nrow = length(label_ids),
                  ncol = 2, byrow = TRUE))^2
      )) >= 0.45)
    if (sufficiently_separate) {
      label_ids <- c(label_ids, candidate)
    }
    if (length(label_ids) == min(10, nrow(score_mat))) break
  }
  x_cut <- quantile(score_mat[, 1], c(0.1, 0.9))
  label_pos <- ifelse(score_mat[label_ids, 1] <= x_cut[1], 4,
                      ifelse(score_mat[label_ids, 1] >= x_cut[2], 2, 3))
  bottom_ids <- label_ids[
    score_mat[label_ids, 2] <= quantile(score_mat[, 2], 0.1)
  ]
  if (length(bottom_ids) > 1) {
    bottom_order <- bottom_ids[order(score_mat[bottom_ids, 1])]
    label_pos[match(bottom_order, label_ids)] <-
      rep(c(4, 2), length.out = length(bottom_order))
  }
  guild_now <- guild[match(rownames(score_mat), ids)]

  png(file.path(out_dir, filename), width = 2400, height = 1800, res = 220)
  layout(matrix(c(1, 2), nrow = 1), widths = c(4.5, 1.5))
  par(mar = c(5, 5, 5, 1), family = "sans")
  plot(
    score_mat, type = "n", xlab = colnames(score_mat)[1],
    ylab = colnames(score_mat)[2], main = title
  )
  mtext(subtitle, side = 3, line = 0.4, cex = 0.8)
  abline(h = 0, v = 0, col = grid, lty = 3)
  points(
    score_mat, pch = unname(guild_pch[guild_now]),
    bg = blue_light, col = ink, cex = 1.2, lwd = 0.8
  )
  for (i in seq_along(label_ids)) {
    text(
      score_mat[label_ids[i], 1], score_mat[label_ids[i], 2],
      labels = unname(names_by_id[label_ids[i]]),
      pos = label_pos[i], cex = 0.52, col = ink
    )
  }
  par(mar = c(2, 0, 3, 1))
  plot.new()
  legend(
    "left", legend = gsub("_", " ", guild_levels),
    pch = guild_pch, pt.bg = blue_light, col = ink,
    title = "Pre-assigned guild (display only)", bty = "n", cex = 0.82
  )
  dev.off()
}

pca_plot_scores <- pca$x[, 1:2, drop = FALSE]
colnames(pca_plot_scores) <- c(
  sprintf("PC1 (%.1f%%)", pca_variance[1]),
  sprintf("PC2 (%.1f%%)", pca_variance[2])
)
plot_ordination(
  pca_plot_scores,
  "count_profile_pca.png",
  "PCA of standardized conditional count profiles",
  sprintf("Five disjoint periods; PC1+PC2 = %.1f%% of variance; n=46 species",
          sum(pca_variance[1:2]))
)

nmds_plot_scores <- as.matrix(nmds_scores_raw[, c("NMDS1", "NMDS2")])
rownames(nmds_plot_scores) <- nmds_scores_raw$analysis_taxon_id
plot_ordination(
  nmds_plot_scores,
  "count_profile_nmds.png",
  "Euclidean NMDS of standardized conditional count profiles",
  sprintf("Five disjoint periods; stress = %.3f; distance rho = %.3f; n=46 species",
          nmds$stress, distance_correlation)
)

plot_distribution <- function(values, filename, ratio_scale = FALSE) {
  period_cols <- c(disjoint_periods, active_composite)
  vals <- lapply(period_cols, function(x) values[, x])
  names(vals) <- period_definitions$figure_label[
    match(period_cols, period_definitions$contrast)
  ]
  fills <- c(rep(blue_light, 5), "#E8D2A5")
  png(file.path(out_dir, filename), width = 2600, height = 1800, res = 220)
  par(mar = c(11, 6, 6, 2), family = "sans")
  boxplot(
    vals, outline = FALSE, col = fills, border = ink, xaxt = "n",
    ylab = if (ratio_scale) "Reported-number ratio (log axis)" else "Link-scale effect",
    log = if (ratio_scale) "y" else "",
    main = if (ratio_scale)
      "Conditional reported-number ratios across species and periods"
    else
      "Conditional reported-number effects across species and periods"
  )
  axis(1, at = seq_along(vals), labels = names(vals), las = 2,
       tick = FALSE, cex.axis = 0.82)
  abline(h = if (ratio_scale) 1 else 0, col = ink, lty = 2, lwd = 1.2)
  abline(v = 5.5, col = "#888888", lty = 3)
  set.seed(20260727L)
  for (j in seq_along(vals)) {
    xj <- jitter(rep(j, length(vals[[j]])), amount = 0.13)
    points(
      xj, vals[[j]], pch = 21,
      bg = if (j == 6) "#E8D2A5AA" else "#B9D1E1AA",
      col = "#4A4A4A90", cex = 0.65, lwd = 0.5
    )
    points(j, mean(vals[[j]]), pch = 23, bg = gold, col = gold_dark, cex = 1.15)
  }
  mtext(
    "Each species has equal weight; diamonds are means. The final box is a duration-weighted composite, not a sixth period.",
    side = 3, line = 1.1, cex = 0.78
  )
  mtext(
    "Adjusted conditional count contrasts versus the days −28 to −15 baseline; n=46 species.",
    side = 3, line = 0.1, cex = 0.72
  )
  dev.off()
}

plot_distribution(
  raw_all,
  "count_period_distribution_link.png",
  ratio_scale = FALSE
)
plot_distribution(
  exp(raw_all),
  "count_period_distribution_ratio.png",
  ratio_scale = TRUE
)

package_availability <- data.frame(
  package = required_packages,
  available = available,
  version = vapply(required_packages, function(p) as.character(packageVersion(p)),
                   character(1)),
  library_path = vapply(required_packages, function(p) dirname(find.package(p)),
                        character(1))
)
write_csv(package_availability, "package_availability.csv")

run_record <- c(
  "analysis: aggregate-only conditional reported-number response profiles",
  paste0("run_timestamp: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  paste0("r_version: ", R.version.string),
  "source: outputs/post_stage4a_sog_event_study_v1/effect_estimates_v1.csv",
  "outcome: positive_numeric_count_given_detection",
  "disjoint_periods: early_pre, immediate_pre, spawn_start, early_egg, late_egg",
  "active_0_14_role: displayed_separately_as_duration_weighted_composite",
  paste0("complete_case_species: ", length(ids)),
  paste0("nmds_seed: ", nmds_seed),
  "nmds_distance: Euclidean",
  "nmds_dimensions: 2",
  "response_models_fit_or_refit: false",
  "protected_checklist_frame_accessed: false",
  "holdout_accessed: false",
  "authorization_gate_set: false",
  "manuscript_edited: false",
  paste0(
    "script_md5: ",
    unname(tools::md5sum(file.path(root, "scripts",
                                   "run_count_only_response_profiles_v1.R")))
  )
)
writeLines(run_record, file.path(out_dir, "execution_record.yml"), useBytes = TRUE)
session_lines <- sub("[[:space:]]+$", "", capture.output(sessionInfo()))
writeLines(session_lines, file.path(out_dir, "session_info.txt"))

cat("Completed aggregate-only count-profile figures.\n")
cat("Complete cases:", length(ids), "\n")
cat("Dropped:", paste(expected_drop, collapse = ", "), "\n")
cat("NMDS stress:", format(nmds$stress, digits = 5), "\n")
cat("Outputs:", out_dir, "\n")
