cluster_bootstrap_indices <- function(cluster, replicates = 999L, seed = 1988L) {
  if (replicates < 1L) stop("replicates must be positive", call. = FALSE)
  set.seed(seed)
  clusters <- unique(cluster[!is.na(cluster)])
  if (length(clusters) < 2L) stop("At least two clusters are required", call. = FALSE)
  lapply(seq_len(replicates), function(b) sample(clusters, length(clusters), replace = TRUE))
}

deterministic_group_folds <- function(group, k = 10L, seed = 1988L) {
  g <- sort(unique(group[!is.na(group)]))
  if (length(g) < k) stop("Fewer groups than folds", call. = FALSE)
  hashes <- vapply(g, function(z) digest::digest(paste(seed, z, sep = "::"), algo = "sha256", serialize = FALSE), character(1))
  ord <- order(hashes)
  fold <- rep(seq_len(k), length.out = length(g))
  data.table::data.table(group = g[ord], fold = fold)
}
