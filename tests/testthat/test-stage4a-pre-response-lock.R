testthat::test_that("Stage 4A disposition preserves all 45 registered models", {
  registry <- utils::read.csv(repo_file("metadata", "model_registry.csv"),
    stringsAsFactors = FALSE)
  disposition <- utils::read.csv(repo_file("metadata", "stage4a_model_disposition_v1.csv"),
    stringsAsFactors = FALSE)
  testthat::expect_equal(nrow(registry), 45L)
  testthat::expect_equal(nrow(disposition), 45L)
  testthat::expect_identical(registry$model_id, disposition$model_id)
  testthat::expect_setequal(disposition$model_id[grepl("^activated_",
    disposition$stage4a_disposition)],
    c("M01","M02","M05","M08","M11","M12","M26","M27","M28","M29","M32","M40"))
  testthat::expect_identical(disposition$stage4a_disposition[disposition$model_id == "M31"],
    "prospective_locked")
  testthat::expect_true(all(disposition$stage4a_disposition[!disposition$model_id %in%
    c("M01","M02","M05","M08","M11","M12","M26","M27","M28","M29","M31","M32","M40")] ==
    "deferred_pre_response"))
  testthat::expect_identical(digest::digest(repo_file("metadata", "model_registry.csv"),
    algo="sha256", file=TRUE, serialize=FALSE),
    "e9f28b1772ca8e5816abfe8e59c0286b495305725f2cfc9e08beb97cd211d311")
})

testthat::test_that("Stage 4A lock artifacts are hash-identical", {
  testthat::skip_if_not_installed("digest")
  pairs <- list(
    c("metadata/stage4a_human_scientific_authorization_v1.yml","metadata/stage4a_human_scientific_authorization_v1.sha256"),
    c("metadata/stage4a_model_disposition_v1.csv","metadata/stage4a_model_disposition_v1.csv.sha256"),
    c("metadata/stage4a_model_specification_matrix_v1.csv","metadata/stage4a_model_specification_matrix_v1.csv.sha256"),
    c("metadata/stage4a_core_spec_v1.yml","metadata/stage4a_core_spec_v1.sha256"),
    c("metadata/stage4a_pre_response_scope_lock_v1.yml","metadata/stage4a_pre_response_scope_lock_v1.sha256"),
    c("metadata/stage4a_pre_response_scope_lock_v2.yml","metadata/stage4a_pre_response_scope_lock_v2.sha256"),
    c("metadata/stage4a_pre_response_scope_lock_v3.yml","metadata/stage4a_pre_response_scope_lock_v3.sha256"),
    c("metadata/stage4a_pre_response_scope_lock_v4.yml","metadata/stage4a_pre_response_scope_lock_v4.sha256"),
    c("metadata/stage4a_execution_v1.yml","metadata/stage4a_execution_v1.sha256"),
    c("docs/14_STAGE4A_CORE_METHODS.md","docs/14_STAGE4A_CORE_METHODS.sha256"),
    c("docs/15_STAGE4A_RESULTS_TEMPLATE.md","docs/15_STAGE4A_RESULTS_TEMPLATE.sha256"),
    c("docs/15_STAGE4A_CORE_RESULTS.md","docs/15_STAGE4A_CORE_RESULTS.sha256"),
    c("outputs/stage4a_results/aggregate_artifact_hashes.csv",
      "outputs/stage4a_results/aggregate_artifact_hashes.csv.sha256"))
  for(pair in pairs) {
    sidecar <- do.call(repo_file,as.list(strsplit(pair[2],"/",fixed=TRUE)[[1]]))
    artifact <- do.call(repo_file,as.list(strsplit(pair[1],"/",fixed=TRUE)[[1]]))
    recorded <- strsplit(readLines(sidecar,warn=FALSE)[1],"[[:space:]]+")[[1]][1]
    actual <- digest::digest(artifact,
      algo="sha256",file=TRUE,serialize=FALSE)
    testthat::expect_identical(recorded,actual)
  }
})

testthat::test_that("Stage 4A specification freezes factorized scope and region rules", {
  testthat::skip_if_not_installed("yaml")
  spec <- yaml::read_yaml(repo_file("metadata", "stage4a_core_spec_v1.yml"))
  testthat::expect_equal(spec$taxon_registry$expected_rows, 58L)
  testthat::expect_true(spec$population$factorized_denominator)
  testthat::expect_identical(spec$population$full_logical_grid_materialization, "prohibited")
  testthat::expect_equal(spec$population$latest_year, 2025L)
  testthat::expect_equal(spec$population$primary_regions$SoG, 2005L)
  testthat::expect_equal(spec$population$primary_regions$WCVI, 2015L)
  testthat::expect_equal(spec$population$high_precision_sensitivity_km_maximum, 2L)
  testthat::expect_identical(spec$population$broad_10km_frame, "prohibited")
  testthat::expect_equal(spec$validation$folds, 4L)
  testthat::expect_identical(spec$validation$new_event_generalization_claim_source,
    "event_blocked_only")
  testthat::expect_identical(spec$validation$heldout_prediction_random_effects,
    "population_expectation")
  testthat::expect_identical(spec$validation$conditional_blups, "prohibited")
  testthat::expect_equal(spec$species_selector$expected_primary_taxa, 49L)
})

testthat::test_that("Stage 4A response builder has a narrow field allowlist", {
  code <- paste(readLines(repo_file("scripts", "Stage4AProtectedBuilder.cs"),
    warn = FALSE), collapse = "\n")
  testthat::expect_true(grepl("reported_count_states", code, fixed=TRUE))
  testthat::expect_true(grepl("ambiguity_masks", code, fixed=TRUE))
  testthat::expect_true(grepl("OBSERVATION DATE", code, fixed=TRUE))
  testthat::expect_false(grepl("LATITUDE|LONGITUDE|COMMENTS|BREEDING CODE|AGE.SEX|2026|2027|2028",
    code, ignore.case = TRUE))
  testthat::expect_false(grepl("83[ ,]?159[ ,]?588", code))
  testthat::expect_true(grepl("ConcurrentLinks", code, fixed=TRUE))
})

testthat::test_that("Stage 4A factorization keeps X, ambiguity and zero distinct", {
  source(repo_file("R", "stage4a_core.R"), local = TRUE)
  testthat::expect_silent(stage4a_fixture())
  events <- data.frame(analysis_event_token=c("a","b","c"), stringsAsFactors=FALSE)
  states <- data.frame(analysis_event_token="a", analysis_taxon_id="t", detection=1L,
    numeric_count=NA_real_, lower_bound_count=NA_real_, count_type="unquantified_X",
    ambiguity_flag=FALSE, stringsAsFactors=FALSE)
  masks <- data.frame(analysis_event_token="b", analysis_taxon_id="t",
    stringsAsFactors=FALSE)
  out <- stage4a_materialize_taxon(events,states,masks,"t")
  testthat::expect_identical(out$count_type, c("unquantified_X","structural_unknown","deterministic_zero"))
  testthat::expect_identical(out$detection, c(1L,NA_integer_,0L))
})

testthat::test_that("Stage 4A production code protects prediction and multiplicity rules", {
  code <- paste(readLines(repo_file("R", "stage4a_production.R"), warn=FALSE), collapse="\n")
  testthat::expect_true(grepl("exclude = random_terms", paste(readLines(
    repo_file("R", "stage4a_core.R"), warn=FALSE),collapse="\n"), fixed=TRUE))
  testthat::expect_true(grepl("event_fold", code, fixed=TRUE))
  testthat::expect_true(grepl("observer_fold", code, fixed=TRUE) ||
    grepl("observer_disjoint", code, fixed=TRUE))
  testthat::expect_true(grepl("dominant_observer", code, fixed=TRUE))
  core_code <- paste(readLines(repo_file("R", "stage4a_core.R"), warn=FALSE), collapse="\n")
  testthat::expect_true(grepl('method = "BH"', core_code, fixed=TRUE))
  testthat::expect_false(grepl("HERRING_EBIRD_V2_EBD|HERRING_EBIRD_V2_HERRING|LATITUDE|LONGITUDE|comments\\.tsv",
    code, ignore.case=TRUE))
})

testthat::test_that("zero-truncated NB2 analytic score matches the frozen likelihood", {
  env <- new.env(parent = baseenv())
  sys.source(repo_file("R", "stage4a_production.R"), envir = env)
  X <- cbind(`(Intercept)` = 1, active_near = c(0, 1, 0, 1, 1, 0))
  y <- c(1, 2, 4, 1, 7, 3)
  objective <- env$.stage4a_zt_nb2_objective(X, y)
  par <- c(log(2), 0.15, log(1.7))
  epsilon <- 1e-6
  numerical <- vapply(seq_along(par), function(i) {
    plus <- minus <- par
    plus[i] <- plus[i] + epsilon
    minus[i] <- minus[i] - epsilon
    (objective$fn(plus) - objective$fn(minus)) / (2 * epsilon)
  }, numeric(1))
  testthat::expect_equal(unname(objective$gr(par)), numerical, tolerance = 1e-5)
})

testthat::test_that("event-blocked validation excludes only unsupported fixed-factor levels", {
  env <- new.env(parent = baseenv())
  sys.source(repo_file("R", "stage4a_production.R"), envir = env)
  n <- 100L
  dat <- data.frame(
    detection = rep(c(0L, 1L), length.out = n),
    log_count = log(rep(1:5, length.out = n)),
    numeric_count = rep(1:5, length.out = n),
    active_near = rep(c(0L, 1L), length.out = n),
    contemporaneous_reference = rep(c(1L, 0L, 0L, 0L), length.out = n),
    checklist_year = rep(c(2019L, 2020L), n / 2),
    protocol = factor(rep(c("Stationary", "Traveling"), n / 2)),
    log_duration = log(rep(30, n)), log_effort_distance = log1p(rep(1, n)),
    observer_count = rep(1L, n), event_fold = rep(1:4, each = 25L),
    stringsAsFactors = FALSE)
  for (nm in paste0("time_", c("immediate_pre", "spawn_start", "early_egg", "late_egg", "post")))
    dat[[nm]] <- 0L
  for (nm in paste0("distance_", c("ring_0_0p5", "ring_0p5_1", "ring_1_2",
    "ring_2_3", "ring_3_4", "ring_4_5", "ring_5_10"))) dat[[nm]] <- 0L
  dat$checklist_year[1:5] <- 2021L
  dat$event_fold[100] <- NA_integer_
  out <- env$.stage4a_cv(dat, "detection", stats::binomial(), "M02", "SoG", "species")
  testthat::expect_equal(nrow(out), 4L)
  testthat::expect_equal(out$n_validation_unsupported_factor_levels[out$fold == 1L], 5L)
  testthat::expect_equal(out$n_validation_supported[out$fold == 1L], 20L)
  testthat::expect_true(all(is.finite(out$metric_1)))
  testthat::expect_false(any(out$privacy_suppressed))
  testthat::expect_equal(sum(out$n_validation), 99L)
})

testthat::test_that("matrix validation engine matches the registered formula fit", {
  env <- new.env(parent = baseenv())
  sys.source(repo_file("R", "stage4a_production.R"), envir = env)
  set.seed(412L)
  n <- 240L
  dat <- data.frame(
    active_near = stats::rbinom(n, 1, 0.35),
    contemporaneous_reference = stats::rbinom(n, 1, 0.25),
    checklist_year = sample(2019:2022, n, replace = TRUE),
    protocol = factor(sample(c("Stationary", "Traveling"), n, replace = TRUE)),
    log_duration = log(stats::runif(n, 5, 300)),
    log_effort_distance = log1p(stats::runif(n, 0, 5)),
    observer_count = sample(1:4, n, replace = TRUE),
    event_fold = rep(1:4, length.out = n))
  for (nm in paste0("time_", c("immediate_pre", "spawn_start", "early_egg", "late_egg", "post")))
    dat[[nm]] <- stats::rbinom(n, 1, 0.15)
  for (nm in paste0("distance_", c("ring_0_0p5", "ring_0p5_1", "ring_1_2",
    "ring_2_3", "ring_3_4", "ring_4_5", "ring_5_10"))) dat[[nm]] <- stats::rbinom(n, 1, 0.12)
  dat$detection <- stats::rbinom(n, 1, stats::plogis(-1 + 0.4 * dat$active_near))
  dat$numeric_count <- 1
  dat$log_count <- 0
  out <- env$.stage4a_cv(dat, "detection", stats::binomial(), "M02", "SoG", "species")
  train <- dat$event_fold != 1L; test <- !train
  reference <- stats::glm(env$.stage4a_fixed_formula("detection"),
    data = dat[train,], family = stats::binomial())
  pred <- stats::predict(reference, newdata = dat[test,], type = "response")
  expected <- env$.stage4a_metrics(dat$detection[test], pred, "detection")
  testthat::expect_equal(unname(out$metric_1[out$fold == 1L]), unname(expected[1]),
    tolerance = 1e-8)
  testthat::expect_equal(unname(out$metric_2[out$fold == 1L]), unname(expected[2]),
    tolerance = 1e-8)
})

testthat::test_that("regional selectors never materialize missing metadata rows", {
  env <- new.env(parent = baseenv())
  sys.source(repo_file("R", "stage4a_production.R"), envir = env)
  events <- data.frame(region = c("SoG", "WCVI", NA, "SoG"),
    checklist_year = c(2005L, 2015L, 2020L, NA_integer_))
  sog <- env$.stage4a_region_scope(events, "SoG", 2005L)
  wcvi <- env$.stage4a_region_scope(events, "WCVI", 2015L)
  testthat::expect_identical(sog, c(TRUE, FALSE, FALSE, FALSE))
  testthat::expect_identical(wcvi, c(FALSE, TRUE, FALSE, FALSE))
  testthat::expect_false(anyNA(c(sog, wcvi)))
})

testthat::test_that("protected cache reader preserves the registered NA region code", {
  env <- new.env(parent = baseenv())
  sys.source(repo_file("R", "stage4a_production.R"), envir = env)
  path <- tempfile(fileext = ".tsv.gz")
  con <- gzfile(path, "wt")
  writeLines(c("region\tvalue", "NA\t1", "\t2"), con)
  close(con)
  on.exit(unlink(path), add = TRUE)
  got <- env$.stage4a_read_gz(path)
  testthat::expect_identical(got$region[1], "NA")
  testthat::expect_true(is.na(got$region[2]))
})

testthat::test_that("Stage 4A released outputs preserve registry and validation gates", {
  out <- function(name) repo_file("outputs", "stage4a_results", name)
  status <- utils::read.csv(out("all_45_model_status.csv"), stringsAsFactors = FALSE, na.strings="")
  cv <- utils::read.csv(out("four_fold_predictive_performance.csv"), stringsAsFactors = FALSE, na.strings="")
  observer <- utils::read.csv(out("wcvi_observer_robustness.csv"), stringsAsFactors = FALSE, na.strings="")
  concentration <- utils::read.csv(out("wcvi_observer_concentration.csv"),
    stringsAsFactors = FALSE, na.strings="")
  effects <- utils::read.csv(out("effect_estimates.csv"), stringsAsFactors = FALSE, na.strings="")
  samples <- utils::read.csv(out("aggregate_sample_sizes.csv"), stringsAsFactors = FALSE, na.strings="")
  geometry <- utils::read.csv(out("model_geometry.csv"), stringsAsFactors = FALSE, na.strings="")
  testthat::expect_equal(nrow(status), 45L)
  testthat::expect_setequal(unique(cv$fold), 1:4)
  testthat::expect_true(all(cv$validation_view == "event_blocked_new_event_generalization"))
  testthat::expect_false(any(cv$conditional_observer_or_location_BLUP_used %in% TRUE))
  testthat::expect_true(all(observer$validation_view ==
    "observer_disjoint_composition_robustness_only"))
  testthat::expect_true(all(is.finite(observer$metric_1) & is.finite(observer$metric_2)))
  testthat::expect_false(any(observer$conditional_observer_or_location_BLUP_used %in% TRUE))
  testthat::expect_equal(concentration$dominant_observer_share, 0.356)
  testthat::expect_equal(concentration$effective_observer_replication, 7.4)
  testthat::expect_setequal(unique(effects$region[effects$model_id %in% c("M01","M02")]),
    c("SoG","WCVI","CC","NA"))
  testthat::expect_setequal(unique(effects$region[effects$model_id == "M29"]),
    c("SoG","WCVI"))
  testthat::expect_false(any(is.finite(effects$n) & effects$n > 0 & effects$n < 20))
  testthat::expect_false(any(geometry$model_id %in% c("M11","M12") &
    geometry$unit_label %in% c("Gadwall","Northern Shoveler")))
  count_values <- unlist(samples[c("n","detections","positive_numeric","structural_unknown")])
  testthat::expect_false(any(is.finite(count_values) & count_values > 0 & count_values < 20))
  testthat::expect_setequal(unique(samples$region), c("SoG","WCVI","CC","NA"))
  testthat::expect_identical(sort(unique(samples[c("region","n")]$n)),
    c(861L,8584L,9007L,217200L))
})

testthat::test_that("Stage 4A aggregate manifest is complete and reproducible", {
  testthat::skip_if_not_installed("digest")
  manifest <- utils::read.csv(repo_file("outputs", "stage4a_results",
    "aggregate_artifact_hashes.csv"), stringsAsFactors = FALSE)
  testthat::expect_equal(nrow(manifest), 13L)
  for (i in seq_len(nrow(manifest))) {
    path <- repo_file("outputs", "stage4a_results", manifest$artifact[i])
    testthat::expect_identical(digest::digest(path, algo="sha256", file=TRUE,
      serialize=FALSE), manifest$sha256[i])
  }
  released <- list.files(repo_file("outputs", "stage4a_results"), pattern="\\.csv$",
    full.names=TRUE)
  headers <- unlist(lapply(released, function(path) names(utils::read.csv(path,
    nrows=1, check.names=FALSE))))
  testthat::expect_false(any(grepl("identifier|coordinate|latitude|longitude|observer_cluster_token|location_cluster_token|analysis_event_token",
    headers, ignore.case=TRUE)))
})

testthat::test_that("Stage 4A pre-response report is empty of observed results", {
  x <- paste(readLines(repo_file("docs", "15_STAGE4A_RESULTS_TEMPLATE.md"), warn=FALSE),
    collapse="\n")
  testthat::expect_true(grepl("LOCKED_NO_OBSERVED_RESULTS", x, fixed=TRUE))
  testthat::expect_true(grepl("contains no observed", x, fixed=TRUE))
})
