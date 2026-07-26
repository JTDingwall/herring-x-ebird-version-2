#!/usr/bin/env Rscript

# Descriptive clustering of archived species response profiles.
# This script reads only aggregate outputs and never fits a response model.

options(stringsAsFactors = FALSE, warn = 1)

task_lib <- Sys.getenv("RESPONSE_CLUSTERING_R_LIB", unset = "")
if (nzchar(task_lib)) .libPaths(c(task_lib, .libPaths()))

required_packages <- c("cluster", "fpc", "vegan")
available <- vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
if (!all(available)) {
  stop("Missing required package(s): ", paste(names(available)[!available], collapse = ", "))
}

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "outputs", "response_clustering_v1")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

paths <- list(
  effects = file.path(root, "outputs", "post_stage4a_sog_event_study_v1",
                      "effect_estimates_v1.csv"),
  active = file.path(root, "outputs", "post_stage4a_sog_event_study_v1_1",
                     "active_minus_pre_contrasts_v1.csv"),
  timing = file.path(root, "outputs", "referee_reads_followup_v1",
                     "item10_species_timing_contrasts.csv"),
  support = file.path(root, "figures_out", "tableS_species_support.csv"),
  registry = file.path(root, "metadata", "canonical_species_registry.csv")
)
stopifnot(all(file.exists(unlist(paths))))

read_csv <- function(path) {
  read.csv(path, check.names = FALSE, na.strings = c("", "NA"), stringsAsFactors = FALSE)
}

write_csv <- function(x, name) {
  write.csv(x, file.path(out_dir, name), row.names = FALSE, na = "")
}

assert_unique <- function(x, keys, label) {
  key <- do.call(paste, c(x[keys], sep = "\r"))
  if (anyDuplicated(key)) stop(label, " violates declared ", paste(keys, collapse = "+"), " uniqueness.")
  invisible(TRUE)
}

join_one_to_one <- function(x, y, key, cols, label, require_all = TRUE) {
  assert_unique(x, key, paste0(label, " left"))
  assert_unique(y, key, paste0(label, " right"))
  idx <- match(x[[key]], y[[key]])
  if (require_all && anyNA(idx)) {
    stop(label, " has unmatched left keys: ", paste(x[[key]][is.na(idx)], collapse = ", "))
  }
  add <- y[idx, cols, drop = FALSE]
  dup <- intersect(names(x), names(add))
  if (length(dup)) names(add)[match(dup, names(add))] <- paste0(dup, "_joined")
  cbind(x, add)
}

comb2 <- function(x) x * (x - 1) / 2

adjusted_rand <- function(a, b) {
  tab <- table(a, b)
  n <- sum(tab)
  if (n < 2) return(NA_real_)
  sum_nij <- sum(comb2(tab))
  sum_ai <- sum(comb2(rowSums(tab)))
  sum_bj <- sum(comb2(colSums(tab)))
  expected <- sum_ai * sum_bj / comb2(n)
  maximum <- (sum_ai + sum_bj) / 2
  if (maximum == expected) return(ifelse(all(a == b), 1, 0))
  (sum_nij - expected) / (maximum - expected)
}

normalized_mutual_information <- function(a, b) {
  tab <- table(a, b)
  p <- tab / sum(tab)
  pa <- rowSums(p)
  pb <- colSums(p)
  nz <- which(p > 0, arr.ind = TRUE)
  mi <- sum(p[nz] * log(p[nz] / (pa[nz[, 1]] * pb[nz[, 2]])))
  ha <- -sum(pa[pa > 0] * log(pa[pa > 0]))
  hb <- -sum(pb[pb > 0] * log(pb[pb > 0]))
  if (ha == 0 || hb == 0) return(0)
  mi / sqrt(ha * hb)
}

scale_matrix <- function(x) {
  ans <- sweep(x, 2, colMeans(x), "-")
  s <- apply(ans, 2, sd)
  if (any(!is.finite(s) | s <= 1e-12)) {
    stop("At least one feature has zero or non-finite variance.")
  }
  sweep(ans, 2, s, "/")
}

dl_shrink <- function(y, se) {
  w <- 1 / se^2
  mu <- sum(w * y) / sum(w)
  q <- sum(w * (y - mu)^2)
  c_term <- sum(w) - sum(w^2) / sum(w)
  tau2 <- max(0, (q - (length(y) - 1)) / c_term)
  reliability <- tau2 / (tau2 + se^2)
  posterior <- mu + reliability * (y - mu)
  list(posterior = posterior, mean = mu, tau2 = tau2,
       reliability_min = min(reliability),
       reliability_median = median(reliability),
       reliability_max = max(reliability))
}

# Predeclared precision treatments:
# 1) z-score each raw link-scale feature.
# 2) multiply each z-score by sqrt(cell precision / feature mean precision).
#    Squared Euclidean contributions therefore carry relative inverse-variance
#    weight while each feature has mean relative precision one. No re-scaling
#    follows, because it would erase the intended precision weighting.
# 3) feature-wise normal-normal empirical-Bayes posterior means, using a
#    DerSimonian-Laird between-species variance and an inverse-variance family
#    mean, followed by feature-wise z-scoring.
prepare_schemes <- function(est, se, feature_set) {
  stopifnot(identical(dim(est), dim(se)), all(is.finite(est)),
            all(is.finite(se)), all(se > 0))
  unweighted <- scale_matrix(est)
  precision <- 1 / se^2
  relative_precision <- sweep(precision, 2, colMeans(precision), "/")
  inverse_variance <- unweighted * sqrt(relative_precision)

  shrunk_raw <- est
  hp <- vector("list", ncol(est))
  for (j in seq_len(ncol(est))) {
    sh <- dl_shrink(est[, j], se[, j])
    shrunk_raw[, j] <- sh$posterior
    hp[[j]] <- data.frame(
      feature_set = feature_set,
      feature = colnames(est)[j],
      family_mean = sh$mean,
      tau_squared = sh$tau2,
      reliability_min = sh$reliability_min,
      reliability_median = sh$reliability_median,
      reliability_max = sh$reliability_max
    )
  }
  shrunk <- scale_matrix(shrunk_raw)
  list(
    matrices = list(
      unweighted = unweighted,
      inverse_variance = inverse_variance,
      reliability_shrunk = shrunk
    ),
    shrunk_raw = shrunk_raw,
    hyperparameters = do.call(rbind, hp),
    relative_precision = relative_precision
  )
}

periods <- c(
  "did_early_pre", "did_immediate_pre", "did_spawn_start",
  "did_early_egg", "did_late_egg", "did_active_0_14_day"
)
outcomes <- c("detection", "positive_numeric_count_given_detection")
outcome_short <- c(
  detection = "reporting",
  positive_numeric_count_given_detection = "count"
)

support <- read_csv(paths$support)
assert_unique(support, "analysis_taxon_id", "species support")
if (nrow(support) != 49) stop("Expected the fixed 49-species support family.")
if (any(support$detections < 20, na.rm = TRUE) ||
    any(support$positive_numeric < 20, na.rm = TRUE)) {
  stop("Aggregate release would violate the suppression threshold of 20.")
}

active <- read_csv(paths$active)
active <- active[active$analysis_role == "core_species" &
                   active$contrast == "active_minus_pre_14_day", ]
assert_unique(active, c("analysis_taxon_id", "outcome"), "active-minus-pre contrasts")

timing_all <- read_csv(paths$timing)
# Deliberately discard guild_ids from this source before any feature construction.
timing <- timing_all[, c("analysis_taxon_id", "outcome", "timing_contrast",
                         "exact_timing_standard_error")]
assert_unique(timing, c("analysis_taxon_id", "outcome"), "exact timing contrasts")

effects <- read_csv(paths$effects)
effects <- effects[effects$analysis_role == "core_species" &
                     effects$contrast %in% periods, ]
assert_unique(effects, c("analysis_taxon_id", "outcome", "contrast"),
              "full-period effects")

ids <- support$analysis_taxon_id
names_by_id <- setNames(support$unit_label, support$analysis_taxon_id)

extract_vector <- function(df, outcome, value, feature_key = NULL) {
  z <- df[df$outcome == outcome, ]
  if (!is.null(feature_key)) z <- z[z$contrast == feature_key, ]
  setNames(as.numeric(z[[value]]), z$analysis_taxon_id)[ids]
}

a_est <- cbind(
  reporting_active_minus_pre = extract_vector(active, outcomes[1], "estimate"),
  count_active_minus_pre = extract_vector(active, outcomes[2], "estimate"),
  reporting_spawn_minus_early_egg = extract_vector(timing, outcomes[1], "timing_contrast"),
  count_spawn_minus_early_egg = extract_vector(timing, outcomes[2], "timing_contrast")
)
a_se <- cbind(
  reporting_active_minus_pre = extract_vector(active, outcomes[1], "standard_error"),
  count_active_minus_pre = extract_vector(active, outcomes[2], "standard_error"),
  reporting_spawn_minus_early_egg = extract_vector(timing, outcomes[1], "exact_timing_standard_error"),
  count_spawn_minus_early_egg = extract_vector(timing, outcomes[2], "exact_timing_standard_error")
)
rownames(a_est) <- rownames(a_se) <- ids

b_names <- unlist(lapply(unname(outcome_short), function(x) paste(x, periods, sep = "__")),
                  use.names = FALSE)
b_est <- matrix(NA_real_, nrow = length(ids), ncol = length(b_names),
                dimnames = list(ids, b_names))
b_se <- b_est
col <- 1
for (outcome in outcomes) {
  for (period in periods) {
    b_est[, col] <- extract_vector(effects, outcome, "estimate", period)
    b_se[, col] <- extract_vector(effects, outcome, "standard_error", period)
    col <- col + 1
  }
}

complete_a <- apply(is.finite(a_est) & is.finite(a_se) & a_se > 0, 1, all)
complete_b <- apply(is.finite(b_est) & is.finite(b_se) & b_se > 0, 1, all)
expected_drop <- sort(c("Glaucous Gull", "Surfbird", "Rhinoceros Auklet"))
drop_a <- sort(unname(names_by_id[!complete_a]))
drop_b <- sort(unname(names_by_id[!complete_b]))
if (!identical(drop_a, expected_drop) || !identical(drop_b, expected_drop)) {
  stop("Complete-case reconciliation failed. Set A drops: ",
       paste(drop_a, collapse = ", "), "; Set B drops: ", paste(drop_b, collapse = ", "))
}
if (sum(complete_a) != 46 || sum(complete_b) != 46 ||
    !identical(rownames(a_est)[complete_a], rownames(b_est)[complete_b])) {
  stop("Expected the same 46 complete cases for both feature sets.")
}

complete_ids <- rownames(a_est)[complete_a]
raw_sets <- list(
  A = list(est = a_est[complete_ids, , drop = FALSE],
           se = a_se[complete_ids, , drop = FALSE]),
  B = list(est = b_est[complete_ids, , drop = FALSE],
           se = b_se[complete_ids, , drop = FALSE])
)

feature_metadata <- data.frame(
  feature_set = c(rep("A", 4), rep("B", 12)),
  feature = c(colnames(a_est), colnames(b_est)),
  scale = "link",
  estimate_source = c(
    rep("active_minus_pre_contrasts_v1.csv", 2),
    rep("item10_species_timing_contrasts.csv", 2),
    rep("effect_estimates_v1.csv", 12)
  ),
  standard_error_source = c(
    rep("archived active-minus-pre standard_error", 2),
    rep("exact_timing_standard_error from persisted covariance", 2),
    rep("archived period standard_error", 12)
  )
)
write_csv(feature_metadata, "feature_metadata.csv")

exclusions <- data.frame(
  feature_set = rep(c("A", "B"), each = 3),
  common_name = rep(expected_drop, 2),
  reason = rep(c(
    "neither outcome estimable",
    "reported-number model not estimable",
    "reported-number model not estimable"
  )[match(expected_drop, c("Glaucous Gull", "Surfbird", "Rhinoceros Auklet"))], 2)
)
write_csv(exclusions, "complete_case_exclusions.csv")

join_audit <- data.frame(
  source = c("species support", "active-minus-pre", "exact timing",
             "full-period effects", "registry post-clustering"),
  rows_read = c(nrow(support), nrow(active), nrow(timing), nrow(effects), NA),
  declared_key = c("analysis_taxon_id",
                   "analysis_taxon_id + outcome",
                   "analysis_taxon_id + outcome",
                   "analysis_taxon_id + outcome + contrast",
                   "analysis_taxon_id"),
  cardinality = "one-to-one at the declared key",
  duplicate_keys = 0,
  matched_complete_case_species = c(46, 46, 46, 46, NA)
)

prep <- lapply(names(raw_sets), function(fs) {
  prepare_schemes(raw_sets[[fs]]$est, raw_sets[[fs]]$se, fs)
})
names(prep) <- names(raw_sets)

matrix_to_df <- function(mat, fs, scheme, type) {
  data.frame(
    feature_set = fs,
    scheme = scheme,
    matrix_type = type,
    analysis_taxon_id = rep(rownames(mat), each = ncol(mat)),
    common_name = rep(unname(names_by_id[rownames(mat)]), each = ncol(mat)),
    feature = rep(colnames(mat), times = nrow(mat)),
    value = as.vector(t(mat))
  )
}

matrix_exports <- list()
hp_exports <- list()
for (fs in names(prep)) {
  matrix_exports[[length(matrix_exports) + 1]] <-
    matrix_to_df(raw_sets[[fs]]$est, fs, "none", "raw_estimate")
  matrix_exports[[length(matrix_exports) + 1]] <-
    matrix_to_df(raw_sets[[fs]]$se, fs, "none", "standard_error")
  matrix_exports[[length(matrix_exports) + 1]] <-
    matrix_to_df(prep[[fs]]$shrunk_raw, fs, "reliability_shrunk", "posterior_mean")
  for (scheme in names(prep[[fs]]$matrices)) {
    matrix_exports[[length(matrix_exports) + 1]] <-
      matrix_to_df(prep[[fs]]$matrices[[scheme]], fs, scheme, "clustering_matrix")
  }
  hp_exports[[length(hp_exports) + 1]] <- prep[[fs]]$hyperparameters
}
write_csv(do.call(rbind, hp_exports), "shrinkage_hyperparameters.csv")

ward_fun <- function(x, k) {
  list(cluster = stats::cutree(stats::hclust(stats::dist(x), method = "ward.D2"), k = k))
}

gap_one_se <- function(gap, se) {
  idx <- cluster::maxSE(gap, se, method = "firstSEmax", SE.factor = 1)
  seq_along(gap)[idx] + 1
}

gap_replicates <- 500L
bootstrap_replicates <- 1000L
permutation_replicates <- 9999L
base_seed <- 20260725L

runs <- list()
k_rows <- list()
run_index <- 0L
for (fs in names(prep)) {
  for (scheme in names(prep[[fs]]$matrices)) {
    run_index <- run_index + 1L
    x <- prep[[fs]]$matrices[[scheme]]
    d <- dist(x, method = "euclidean")
    hc <- hclust(d, method = "ward.D2")
    silhouettes <- vapply(2:8, function(k) {
      mean(cluster::silhouette(cutree(hc, k), d)[, "sil_width"])
    }, numeric(1))
    gap_seed <- base_seed + 1000L * run_index
    set.seed(gap_seed)
    gap <- cluster::clusGap(x, FUNcluster = ward_fun, K.max = 8,
                            B = gap_replicates, d.power = 2,
                            spaceH0 = "scaledPCA")
    tab <- gap$Tab[2:8, , drop = FALSE]
    selected_k <- gap_one_se(tab[, "gap"], tab[, "SE.sim"])
    silhouette_k <- (2:8)[which.max(silhouettes)]
    k_rows[[run_index]] <- data.frame(
      feature_set = fs,
      scheme = scheme,
      k = 2:8,
      mean_silhouette = silhouettes,
      gap = tab[, "gap"],
      gap_standard_error = tab[, "SE.sim"],
      gap_bootstrap_replicates = gap_replicates,
      gap_seed = gap_seed,
      selected_by_gap_first_se_max = (2:8) == selected_k,
      maximum_silhouette = (2:8) == silhouette_k
    )
    runs[[paste(fs, scheme, sep = "__")]] <- list(
      feature_set = fs, scheme = scheme, x = x, d = d, hc = hc,
      selected_k = selected_k, silhouette_k = silhouette_k,
      gap = gap, gap_seed = gap_seed
    )
  }
}
k_selection <- do.call(rbind, k_rows)
write_csv(k_selection, "k_selection_metrics.csv")

# At this point all cluster solutions are fixed. Guild metadata is read only now.
registry <- read_csv(paths$registry)
assert_unique(registry, "analysis_taxon_id", "canonical species registry")
posthoc <- data.frame(
  analysis_taxon_id = complete_ids,
  common_name = unname(names_by_id[complete_ids])
)
posthoc <- join_one_to_one(posthoc, registry, "analysis_taxon_id",
                           c("guild_ids"), "post-clustering guild join")
posthoc <- join_one_to_one(posthoc, support, "analysis_taxon_id",
                           c("prevalence"), "post-clustering support join")
if (anyNA(posthoc$guild_ids) || length(unique(posthoc$guild_ids)) != 7) {
  stop("Expected seven non-missing post-hoc guild assignments.")
}
join_audit$rows_read[5] <- nrow(registry)
join_audit$matched_complete_case_species[5] <- nrow(posthoc)
write_csv(join_audit, "join_cardinality_audit.csv")

greedy_alignment <- function(original, boot, ids_boot, ids_all) {
  ok <- sort(unique(original))
  bk <- sort(unique(boot))
  scores <- expand.grid(original_cluster = ok, boot_cluster = bk)
  scores$jaccard <- mapply(function(o, b) {
    aa <- ids_all[original == o]
    bb <- unique(ids_boot[boot == b])
    length(intersect(aa, bb)) / length(union(aa, bb))
  }, scores$original_cluster, scores$boot_cluster)
  scores <- scores[order(-scores$jaccard, scores$original_cluster, scores$boot_cluster), ]
  chosen <- scores[0, ]
  used_o <- used_b <- integer()
  for (i in seq_len(nrow(scores))) {
    if (!(scores$original_cluster[i] %in% used_o) &&
        !(scores$boot_cluster[i] %in% used_b)) {
      chosen <- rbind(chosen, scores[i, ])
      used_o <- c(used_o, scores$original_cluster[i])
      used_b <- c(used_b, scores$boot_cluster[i])
    }
  }
  setNames(chosen$original_cluster, chosen$boot_cluster)
}

species_bootstrap_stability <- function(x, original, B, seed) {
  set.seed(seed)
  n <- nrow(x)
  stable <- present <- setNames(integer(n), rownames(x))
  for (b in seq_len(B)) {
    idx <- sample.int(n, n, replace = TRUE)
    xb <- x[idx, , drop = FALSE]
    boot <- cutree(hclust(dist(xb), method = "ward.D2"), k = length(unique(original)))
    map <- greedy_alignment(original, boot, rownames(xb), rownames(x))
    aligned <- unname(map[as.character(boot)])
    for (id in unique(rownames(xb))) {
      vals <- aligned[rownames(xb) == id]
      tab <- sort(table(vals), decreasing = TRUE)
      assigned <- as.integer(names(tab)[1])
      tied <- length(tab) > 1 && tab[1] == tab[2]
      present[id] <- present[id] + 1L
      if (!tied && assigned == original[id]) stable[id] <- stable[id] + 1L
    }
  }
  stable / present
}

permutation_correspondence <- function(cluster_assignment, guild, B, seed) {
  observed_ari <- adjusted_rand(cluster_assignment, guild)
  observed_nmi <- normalized_mutual_information(cluster_assignment, guild)
  set.seed(seed)
  null_ari <- null_nmi <- numeric(B)
  for (b in seq_len(B)) {
    perm <- sample(guild, replace = FALSE)
    null_ari[b] <- adjusted_rand(cluster_assignment, perm)
    null_nmi[b] <- normalized_mutual_information(cluster_assignment, perm)
  }
  data.frame(
    adjusted_rand_index = observed_ari,
    normalized_mutual_information = observed_nmi,
    ari_permutation_p_upper = (1 + sum(null_ari >= observed_ari)) / (B + 1),
    nmi_permutation_p_upper = (1 + sum(null_nmi >= observed_nmi)) / (B + 1),
    ari_percentile = 100 * mean(null_ari <= observed_ari),
    nmi_percentile = 100 * mean(null_nmi <= observed_nmi),
    permutations = B,
    seed = seed
  )
}

assign_rows <- list()
stability_rows <- list()
species_stability_rows <- list()
correspondence_rows <- list()
crosstab_rows <- list()
disagreement_rows <- list()
pam_rows <- list()
k_sensitivity_rows <- list()
pca_rows <- list()
run_index <- 0L

cluster_palette <- c("#315A7D", "#D2942A", "#B45F38", "#78834B",
                     "#A95F82", "#587F8C", "#80669D", "#7A6B59")
guild_levels <- sort(unique(posthoc$guild_ids))
guild_pch <- setNames(c(21, 22, 23, 24, 25, 7, 8), guild_levels)

for (run_name in names(runs)) {
  run_index <- run_index + 1L
  z <- runs[[run_name]]
  fs <- z$feature_set
  scheme <- z$scheme
  k <- z$selected_k
  original <- cutree(z$hc, k)
  names(original) <- rownames(z$x)
  sensitivity_ks <- sort(unique(c(max(2, k - 1), k, min(8, k + 1))))

  for (kk in sensitivity_ks) {
    ca <- cutree(z$hc, kk)
    role <- if (kk == k) "selected" else if (kk < k) "k_minus_1" else "k_plus_1"
    assign_rows[[length(assign_rows) + 1]] <- data.frame(
      feature_set = fs, scheme = scheme, algorithm = "Ward.D2",
      k = kk, selection_role = role,
      analysis_taxon_id = names(ca),
      common_name = unname(names_by_id[names(ca)]),
      cluster = unname(ca)
    )
    k_sensitivity_rows[[length(k_sensitivity_rows) + 1]] <- data.frame(
      feature_set = fs, scheme = scheme, k = kk, selection_role = role,
      ari_to_selected_partition = adjusted_rand(original, ca),
      ari_to_guild = adjusted_rand(ca, posthoc$guild_ids[match(names(ca), posthoc$analysis_taxon_id)]),
      nmi_to_guild = normalized_mutual_information(
        ca, posthoc$guild_ids[match(names(ca), posthoc$analysis_taxon_id)]
      ),
      cluster_sizes = paste(as.integer(table(ca)), collapse = "|")
    )
  }

  pam_fit <- cluster::pam(z$x, k = k, metric = "euclidean")
  pam_rows[[length(pam_rows) + 1]] <- data.frame(
    feature_set = fs, scheme = scheme, selected_k = k,
    ward_pam_adjusted_rand = adjusted_rand(original, pam_fit$clustering),
    pam_mean_silhouette = pam_fit$silinfo$avg.width
  )

  fpc_seed <- base_seed + 20000L + run_index
  cb <- fpc::clusterboot(
    z$x, B = bootstrap_replicates, bootmethod = "boot",
    clustermethod = fpc::hclustCBI, k = k, method = "ward.D2",
    scaling = FALSE, seed = fpc_seed, showplots = FALSE, count = FALSE
  )
  if (adjusted_rand(original, cb$partition) < 1 - 1e-12) {
    stop("fpc::clusterboot original partition does not match the declared Ward solution.")
  }
  cb_to_original <- apply(table(cb$partition, original), 1, function(v) {
    as.integer(names(v)[which.max(v)])
  })
  for (cl in seq_len(k)) {
    original_cl <- cb_to_original[as.character(cl)]
    stability_rows[[length(stability_rows) + 1]] <- data.frame(
      feature_set = fs, scheme = scheme, selected_k = k,
      cluster = original_cl,
      member_count = sum(original == original_cl),
      mean_bootstrap_jaccard = cb$bootmean[cl],
      dissolved_fraction = cb$bootbrd[cl] / bootstrap_replicates,
      recovered_fraction = cb$bootrecover[cl] / bootstrap_replicates,
      stable_at_0_6 = cb$bootmean[cl] >= 0.6,
      bootstrap_replicates = bootstrap_replicates,
      seed = fpc_seed
    )
  }

  species_seed <- base_seed + 30000L + run_index
  ss <- species_bootstrap_stability(z$x, original, bootstrap_replicates, species_seed)
  species_stability_rows[[length(species_stability_rows) + 1]] <- data.frame(
    feature_set = fs, scheme = scheme, selected_k = k,
    analysis_taxon_id = names(ss),
    common_name = unname(names_by_id[names(ss)]),
    cluster = unname(original[names(ss)]),
    assignment_stability = unname(ss),
    prevalence = posthoc$prevalence[match(names(ss), posthoc$analysis_taxon_id)],
    bootstrap_replicates = bootstrap_replicates,
    seed = species_seed
  )

  guild <- posthoc$guild_ids[match(names(original), posthoc$analysis_taxon_id)]
  perm_seed <- base_seed + 40000L + run_index
  pc <- permutation_correspondence(original, guild, permutation_replicates, perm_seed)
  correspondence_rows[[length(correspondence_rows) + 1]] <- cbind(
    data.frame(feature_set = fs, scheme = scheme, selected_k = k),
    pc
  )

  xt <- as.data.frame(table(cluster = original, guild = guild))
  xt <- xt[xt$Freq > 0, ]
  xt$feature_set <- fs
  xt$scheme <- scheme
  xt$selected_k <- k
  crosstab_rows[[length(crosstab_rows) + 1]] <- xt[, c(
    "feature_set", "scheme", "selected_k", "cluster", "guild", "Freq"
  )]

  guild_modes <- lapply(split(original, guild), function(v) {
    tt <- table(v)
    as.integer(names(tt)[tt == max(tt)])
  })
  for (i in seq_along(original)) {
    if (!(original[i] %in% guild_modes[[guild[i]]])) {
      disagreement_rows[[length(disagreement_rows) + 1]] <- data.frame(
        feature_set = fs, scheme = scheme, selected_k = k,
        common_name = unname(names_by_id[names(original)[i]]),
        guild = guild[i], assigned_cluster = original[i],
        guild_modal_cluster = paste(guild_modes[[guild[i]]], collapse = "|")
      )
    }
  }

  pca <- prcomp(z$x, center = FALSE, scale. = FALSE)
  variance <- 100 * pca$sdev^2 / sum(pca$sdev^2)
  pca_rows[[length(pca_rows) + 1]] <- data.frame(
    feature_set = fs, scheme = scheme,
    axis = seq_along(variance), variance_explained_percent = variance
  )

  png(file.path(out_dir, paste0("ordination_feature_", fs, "_", scheme, ".png")),
      width = 2400, height = 1800, res = 220)
  layout(matrix(c(1, 2), nrow = 1), widths = c(4.3, 1.7))
  par(mar = c(5, 5, 5, 1), family = "sans")
  scores <- pca$x[, 1:2, drop = FALSE]
  plot(scores, type = "n",
       xlab = sprintf("PC1 (%.1f%%)", variance[1]),
       ylab = sprintf("PC2 (%.1f%%)", variance[2]),
       main = paste("Species response ordination: feature set", fs, "—",
                    gsub("_", " ", scheme)))
  mtext(sprintf("Ward k=%d; PC1+PC2 = %.1f%% of variance; n=46",
                k, sum(variance[1:2])), side = 3, line = 0.4, cex = 0.82)
  abline(h = 0, v = 0, col = "#D8D8D8", lty = 3)
  points(scores, pch = unname(guild_pch[guild]), bg = cluster_palette[original],
         col = "#343434", cex = 1.25, lwd = 0.8)
  radial <- rowSums(scale(scores)^2)
  singleton_ids <- names(original)[table(original)[original] == 1]
  label_ids <- union(names(sort(radial, decreasing = TRUE))[seq_len(min(8, length(radial)))],
                     singleton_ids)
  x_cut <- quantile(scores[, 1], c(0.1, 0.9))
  label_pos <- ifelse(scores[label_ids, 1] <= x_cut[1], 4,
                      ifelse(scores[label_ids, 1] >= x_cut[2], 2, 3))
  for (ii in seq_along(label_ids)) {
    text(scores[label_ids[ii], 1], scores[label_ids[ii], 2],
         labels = unname(names_by_id[label_ids[ii]]), pos = label_pos[ii],
         cex = 0.55, col = "#343434")
  }
  par(mar = c(2, 0, 3, 1))
  plot.new()
  legend("topleft", legend = paste("Cluster", seq_len(k)),
         pch = 21, pt.bg = cluster_palette[seq_len(k)], col = "#343434",
         bty = "n", title = "Ward cluster")
  legend("left", legend = gsub("_", " ", guild_levels),
         pch = guild_pch, pt.bg = "white", col = "#343434", bty = "n",
         title = "Pre-assigned guild (post hoc)", cex = 0.78)
  text(0, 0.06, "Guild was not used in clustering.", adj = c(0, 0.5), cex = 0.72)
  dev.off()

  png(file.path(out_dir, paste0("dendrogram_feature_", fs, "_", scheme, ".png")),
      width = 3200, height = 1900, res = 220)
  par(mar = c(12, 5, 5, 2), family = "sans")
  plot(z$hc, labels = unname(names_by_id[z$hc$labels]), hang = -1, cex = 0.55,
       main = paste("Ward dendrogram:", fs, "/", gsub("_", " ", scheme)),
       sub = sprintf("Euclidean distance; selected k=%d; n=46", k),
       xlab = "", ylab = "Ward.D2 height")
  rect.hclust(z$hc, k = k, border = cluster_palette[seq_len(k)])
  dev.off()
}

cluster_assignments <- do.call(rbind, assign_rows)
stability <- do.call(rbind, stability_rows)
species_stability <- do.call(rbind, species_stability_rows)
guild_correspondence <- do.call(rbind, correspondence_rows)
guild_crosstab <- do.call(rbind, crosstab_rows)
guild_disagreements <- if (length(disagreement_rows)) do.call(rbind, disagreement_rows) else
  data.frame(feature_set = character(), scheme = character(), selected_k = integer(),
             common_name = character(), guild = character(), assigned_cluster = integer(),
             guild_modal_cluster = character())
pam_check <- do.call(rbind, pam_rows)
k_sensitivity <- do.call(rbind, k_sensitivity_rows)
pca_variance <- do.call(rbind, pca_rows)

selected_assignments <- cluster_assignments[
  cluster_assignments$selection_role == "selected", ]
cluster_profiles <- list()
cluster_composition <- list()
for (i in seq_len(nrow(stability))) {
  st <- stability[i, ]
  aa <- selected_assignments[
    selected_assignments$feature_set == st$feature_set &
      selected_assignments$scheme == st$scheme &
      selected_assignments$cluster == st$cluster, ]
  raw <- raw_sets[[st$feature_set]]$est[aa$analysis_taxon_id, , drop = FALSE]
  for (j in seq_len(ncol(raw))) {
    cluster_profiles[[length(cluster_profiles) + 1]] <- data.frame(
      feature_set = st$feature_set,
      scheme = st$scheme,
      selected_k = st$selected_k,
      cluster = st$cluster,
      stable_at_0_6 = st$stable_at_0_6,
      feature = colnames(raw)[j],
      member_count = nrow(raw),
      mean_raw_link_estimate = mean(raw[, j]),
      median_raw_link_estimate = median(raw[, j]),
      standard_deviation_raw_link_estimate = sd(raw[, j])
    )
  }
  cluster_composition[[length(cluster_composition) + 1]] <- data.frame(
    feature_set = st$feature_set,
    scheme = st$scheme,
    selected_k = st$selected_k,
    cluster = st$cluster,
    mean_bootstrap_jaccard = st$mean_bootstrap_jaccard,
    stable_at_0_6 = st$stable_at_0_6,
    common_name = aa$common_name,
    guild = posthoc$guild_ids[match(aa$analysis_taxon_id, posthoc$analysis_taxon_id)]
  )
}
cluster_profiles <- do.call(rbind, cluster_profiles)
cluster_composition <- do.call(rbind, cluster_composition)

prevalence_correlations <- do.call(rbind, lapply(
  split(species_stability, interaction(species_stability$feature_set,
                                       species_stability$scheme, drop = TRUE)),
  function(z) data.frame(
    feature_set = z$feature_set[1],
    scheme = z$scheme[1],
    selected_k = z$selected_k[1],
    spearman_rho_assignment_stability_vs_prevalence =
      cor(z$assignment_stability, z$prevalence, method = "spearman"),
    n_species = nrow(z)
  )
))

scheme_agreement <- list()
for (fs in unique(cluster_assignments$feature_set)) {
  aa <- cluster_assignments[cluster_assignments$feature_set == fs &
                              cluster_assignments$selection_role == "selected", ]
  schemes <- unique(aa$scheme)
  pairs <- combn(schemes, 2, simplify = FALSE)
  for (pair in pairs) {
    x <- aa[aa$scheme == pair[1], ]
    y <- aa[aa$scheme == pair[2], ]
    idx <- match(x$analysis_taxon_id, y$analysis_taxon_id)
    scheme_agreement[[length(scheme_agreement) + 1]] <- data.frame(
      feature_set = fs, scheme_1 = pair[1], scheme_2 = pair[2],
      k_1 = x$k[1], k_2 = y$k[1],
      adjusted_rand_index = adjusted_rand(x$cluster, y$cluster[idx]),
      normalized_mutual_information = normalized_mutual_information(x$cluster, y$cluster[idx])
    )
  }
}
scheme_agreement <- do.call(rbind, scheme_agreement)

write_csv(cluster_assignments, "cluster_assignments.csv")
write_csv(stability, "cluster_stability.csv")
write_csv(species_stability, "species_assignment_stability.csv")
write_csv(prevalence_correlations, "prevalence_stability_correlations.csv")
write_csv(guild_correspondence, "guild_correspondence.csv")
write_csv(guild_crosstab, "cluster_by_guild_crosstab.csv")
write_csv(guild_disagreements, "guild_disagreements.csv")
write_csv(pam_check, "pam_linkage_check.csv")
write_csv(k_sensitivity, "k_sensitivity_summary.csv")
write_csv(pca_variance, "pca_variance.csv")
write_csv(cluster_profiles, "cluster_feature_profiles.csv")
write_csv(cluster_composition, "cluster_composition.csv")
write_csv(scheme_agreement, "scheme_agreement.csv")
write_csv(do.call(rbind, matrix_exports), "feature_matrices.csv")

package_availability <- data.frame(
  package = required_packages,
  available = available,
  version = vapply(required_packages, function(p) as.character(packageVersion(p)), character(1)),
  library_path = vapply(required_packages, function(p) dirname(find.package(p)), character(1))
)
write_csv(package_availability, "package_availability.csv")

# K-selection diagnostic: silhouette and gap are shown together with distinct
# line/point types; the selected k uses the same gap first-SE-max rule in all runs.
png(file.path(out_dir, "k_selection_diagnostics.png"),
    width = 3000, height = 2200, res = 220)
par(mfrow = c(2, 3), mar = c(4.5, 4.5, 4, 4.5), family = "sans")
for (run_name in names(runs)) {
  z <- runs[[run_name]]
  zz <- k_selection[k_selection$feature_set == z$feature_set &
                      k_selection$scheme == z$scheme, ]
  ylim <- range(c(zz$mean_silhouette, zz$gap), finite = TRUE)
  plot(zz$k, zz$mean_silhouette, type = "b", pch = 21, bg = "#315A7D",
       col = "#315A7D", lwd = 2, ylim = ylim, xlab = "Number of clusters (k)",
       ylab = "Diagnostic value",
       main = paste("Feature set", z$feature_set, "—", gsub("_", " ", z$scheme)))
  mtext(sprintf("Gap first-SE-max: k=%d; silhouette maximum: k=%d",
                z$selected_k, z$silhouette_k),
        side = 3, line = 0.25, cex = 0.72)
  lines(zz$k, zz$gap, type = "b", pch = 22, bg = "#D2942A",
        col = "#9B671A", lwd = 2, lty = 2)
  arrows(zz$k, zz$gap - zz$gap_standard_error,
         zz$k, zz$gap + zz$gap_standard_error,
         angle = 90, code = 3, length = 0.03, col = "#9B671A")
  abline(v = z$selected_k, lty = 3, col = "#555555")
  legend("bottomright", legend = c("Mean silhouette", "Gap ± SE", "Selected k"),
         col = c("#315A7D", "#9B671A", "#555555"),
         lty = c(1, 2, 3), pch = c(21, 22, NA),
         pt.bg = c("#315A7D", "#D2942A", NA), bty = "n", cex = 0.8)
}
dev.off()

run_record <- c(
  "analysis: descriptive response-profile clustering",
  paste0("run_timestamp: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  paste0("r_version: ", R.version.string),
  paste0("complete_case_species: ", length(complete_ids)),
  paste0("gap_bootstrap_replicates: ", gap_replicates),
  paste0("cluster_stability_bootstrap_replicates: ", bootstrap_replicates),
  paste0("guild_label_permutations: ", permutation_replicates),
  paste0("base_seed: ", base_seed),
  "k_rule: gap statistic first-SE-max over k=2..8",
  "linkage: Ward.D2",
  "distance: Euclidean",
  "alternative_algorithm: PAM",
  "guild_access: after all cluster solutions were fixed",
  "response_models_fit_or_refit: false",
  "holdout_accessed: false",
  "authorization_gate_set: false",
  "imputed_analysis_run: false",
  paste0("script_md5: ", unname(tools::md5sum(file.path(root, "scripts",
                                                        "run_response_clustering_v1.R"))))
)
writeLines(run_record, file.path(out_dir, "execution_record.yml"), useBytes = TRUE)
session_lines <- sub("[[:space:]]+$", "", capture.output(sessionInfo()))
writeLines(session_lines, file.path(out_dir, "session_info.txt"))

cat("Completed response clustering.\n")
cat("Complete cases:", length(complete_ids), "\n")
cat("Dropped:", paste(expected_drop, collapse = ", "), "\n")
cat("Outputs:", out_dir, "\n")
