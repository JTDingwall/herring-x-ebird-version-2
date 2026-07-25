## Laplace (nAGQ = 1) reporting sensitivity for the post-Stage 4A SoG
## event study.
##
## Motivation. The primary reporting models are fitted with nAGQ = 0, which
## replaces the Laplace approximation with a penalised-iteratively-reweighted-
## least-squares step. That approximation is least reliable for very sparse
## binary outcomes, and the strongest reporting contrasts in the release sit
## on gulls reported on roughly 1-2 per cent of checklists. This module
## refits the reporting outcome with nAGQ = 1 and reports the paired
## comparison.
##
## Scope of the upgrade. lme4 supports adaptive Gauss-Hermite quadrature
## (nAGQ > 1) only for models with a single scalar random effect. This model
## carries three crossed random intercepts (event block, observer cluster,
## location cluster), so Laplace is the highest order available. That is a
## genuine improvement over nAGQ = 0, not a workaround.
##
## This module never writes to the frozen v1 release directory, and never
## alters the primary path: it calls the same fitting function with the
## single argument nAGQ changed.

.post_stage4a_laplace_frozen_effects_v1 <- function() {
  path <- file.path(
    .post_stage4a_frozen_release_dir_v1, "effect_estimates_v1.csv"
  )
  manifest_path <- file.path(
    .post_stage4a_frozen_release_dir_v1, "output_hash_manifest_v1.csv"
  )
  if (!file.exists(path) || !file.exists(manifest_path)) {
    stop("POST_STAGE4A_LAPLACE_BASELINE_GATE: frozen v1 release not found",
         call. = FALSE)
  }
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
  expected <- manifest$sha256[
    gsub("\\\\", "/", manifest$file) ==
      gsub("\\\\", "/", file.path(
        .post_stage4a_frozen_release_dir_v1, "effect_estimates_v1.csv"
      ))
  ]
  observed <- .post_stage4a_sha256_v1(path)
  if (length(expected) != 1L || !identical(observed, expected)) {
    stop("POST_STAGE4A_LAPLACE_BASELINE_GATE: ",
         "frozen effect_estimates_v1.csv does not match its recorded hash",
         call. = FALSE)
  }
  utils::read.csv(path, stringsAsFactors = FALSE)
}

run_post_stage4a_laplace_reporting_sensitivity_v1 <- function(
    execution_code_commit,
    output_dir = "outputs/post_stage4a_sog_event_study_laplace_v1",
    model_summary_dir =
      "outputs/post_stage4a_sog_event_study_laplace_model_summaries_v1",
    scope = c("all_core", "adjusted_significant")) {
  scope <- match.arg(scope)
  .post_stage4a_guard_frozen_outputs_v1(output_dir)
  .post_stage4a_require_authorization_v1()

  primary <- .post_stage4a_laplace_frozen_effects_v1()
  prepared <- post_stage4a_prepare_event_study_inputs_v1()
  events <- prepared$events
  states <- prepared$states
  masks <- prepared$masks
  species_registry <- prepared$species_registry
  core_taxa <- prepared$core_taxa
  comparator_taxa <- prepared$comparator_taxa
  protected_hashes <- prepared$protected_hashes
  rm(prepared)

  ## The reporting species whose primary active-window contrast survives BH
  ## adjustment. Used only when scope = "adjusted_significant".
  significant_taxa <- unique(primary$analysis_taxon_id[
    primary$analysis_role == "core_species" &
      primary$outcome == "detection" &
      primary$contrast == "did_active_0_14_day" &
      is.finite(primary$q_value) & primary$q_value < 0.05
  ])
  selected_taxa <- if (identical(scope, "all_core")) {
    core_taxa
  } else {
    core_taxa[core_taxa %in% significant_taxa]
  }
  if (!length(selected_taxa)) {
    stop("POST_STAGE4A_LAPLACE_SCOPE_GATE: no taxa selected", call. = FALSE)
  }

  protected_dir <- "data/derived/post_stage4a_sog_event_study_laplace_v1"
  checkpoint_dir <- file.path(protected_dir, "checkpoints")
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!is.null(model_summary_dir)) {
    dir.create(model_summary_dir, recursive = TRUE, showWarnings = FALSE)
  }
  code_signature <- paste(
    execution_code_commit,
    protected_hashes,
    .post_stage4a_sha256_v1(
      "metadata/post_stage4a_sog_event_study_spec_v1.yml"
    ),
    "nAGQ=1",
    sep = "|",
    collapse = "|"
  )

  workers <- post_stage4a_worker_count_v1(length(selected_taxa))
  fit_one_taxon <- function(taxon_id) {
    unit_label <- species_registry$common_name[
      match(taxon_id, species_registry$analysis_taxon_id)
    ]
    if (length(unit_label) != 1L || is.na(unit_label) || !nzchar(unit_label)) {
      stop("POST_STAGE4A_EVENT_STUDY_TAXON_NAME_GATE: unresolved taxon",
           call. = FALSE)
    }
    denominator <- stage4a_materialize_taxon(events, states, masks, taxon_id)
    post_stage4a_fit_one_v1(
      denominator, taxon_id, unit_label, "core_species", "detection",
      file.path(checkpoint_dir, paste(taxon_id, "detection", "rds", sep = "_")),
      code_signature, model_summary_dir, nAGQ = 1L
    )
  }
  if (workers == 1L) {
    results <- lapply(selected_taxa, fit_one_taxon)
  } else {
    cluster <- parallel::makePSOCKcluster(workers)
    results <- tryCatch({
      parallel::clusterEvalQ(cluster, {
        Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
        source(file.path("R", "stage4a_core.R"), local = FALSE)
        source(file.path("R", "stage4a_production.R"), local = FALSE)
        source(file.path("R", "post_stage4a_sog_event_study_v1.R"),
               local = FALSE)
        NULL
      })
      parallel::clusterExport(
        cluster,
        c("events", "states", "masks", "species_registry", "checkpoint_dir",
          "code_signature", "model_summary_dir"),
        envir = environment()
      )
      parallel::parLapply(cluster, selected_taxa, function(taxon_id) {
        unit_label <- species_registry$common_name[
          match(taxon_id, species_registry$analysis_taxon_id)
        ]
        denominator <- stage4a_materialize_taxon(
          events, states, masks, taxon_id
        )
        post_stage4a_fit_one_v1(
          denominator, taxon_id, unit_label, "core_species", "detection",
          file.path(checkpoint_dir,
                    paste(taxon_id, "detection", "rds", sep = "_")),
          code_signature, model_summary_dir, nAGQ = 1L
        )
      })
    }, finally = {
      parallel::stopCluster(cluster)
    })
  }

  effects <- do.call(rbind, lapply(results, `[[`, "effect"))
  diagnostics <- do.call(rbind, lapply(results, `[[`, "diagnostic"))
  term_support <- do.call(rbind, lapply(results, `[[`, "term_support"))
  effects <- post_stage4a_adjust_multiplicity_v1(effects)
  effects$nAGQ <- 1L
  effects$multiplicity_family_size <- as.integer(
    table(effects$multiplicity_family)[effects$multiplicity_family]
  )

  ## Paired comparison against the frozen primary release.
  key <- function(x) paste(x$analysis_taxon_id, x$contrast, sep = "|")
  primary_reporting <- primary[
    primary$outcome == "detection" &
      primary$analysis_role == "core_species", , drop = FALSE
  ]
  match_index <- match(key(effects), key(primary_reporting))
  paired <- data.frame(
    analysis_taxon_id = effects$analysis_taxon_id,
    unit_label = effects$unit_label,
    outcome = effects$outcome,
    contrast = effects$contrast,
    contrast_type = effects$contrast_type,
    ecological_period = effects$ecological_period,
    primary_estimand = effects$primary_estimand,
    primary_ratio = primary_reporting$ratio[match_index],
    primary_ratio_conf_low = primary_reporting$ratio_conf_low[match_index],
    primary_ratio_conf_high = primary_reporting$ratio_conf_high[match_index],
    primary_p_value = primary_reporting$p_value[match_index],
    primary_q_value = primary_reporting$q_value[match_index],
    primary_status = primary_reporting$status[match_index],
    laplace_ratio = effects$ratio,
    laplace_ratio_conf_low = effects$ratio_conf_low,
    laplace_ratio_conf_high = effects$ratio_conf_high,
    laplace_p_value = effects$p_value,
    laplace_q_value = effects$q_value,
    laplace_status = effects$status,
    stringsAsFactors = FALSE
  )
  comparable <- is.finite(paired$primary_ratio) &
    is.finite(paired$laplace_ratio)
  paired$direction_preserved <- ifelse(
    comparable,
    sign(log(paired$primary_ratio)) == sign(log(paired$laplace_ratio)),
    NA
  )
  primary_significant <- is.finite(paired$primary_q_value) &
    paired$primary_q_value < 0.05
  laplace_significant <- is.finite(paired$laplace_q_value) &
    paired$laplace_q_value < 0.05
  paired$primary_significant <- primary_significant
  paired$laplace_significant <- laplace_significant
  paired$significance_preserved <- primary_significant == laplace_significant
  paired$log_ratio_shift <- ifelse(
    comparable, log(paired$laplace_ratio) - log(paired$primary_ratio), NA_real_
  )
  ## When the scope is reduced, the Laplace BH families are smaller than the
  ## 49-species primary families, so q-values are not directly comparable.
  paired$q_families_comparable <- identical(scope, "all_core")

  .post_stage4a_write_csv_v1(
    effects, file.path(output_dir, "laplace_reporting_effects_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    diagnostics, file.path(output_dir, "laplace_model_diagnostics_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    term_support, file.path(output_dir, "laplace_model_term_support_v1.csv")
  )
  .post_stage4a_write_csv_v1(
    paired, file.path(output_dir, "laplace_vs_primary_paired_v1.csv")
  )

  headline <- paired[
    paired$contrast %in% c("did_active_0_14_day", "active_minus_pre_14_day") &
      (paired$primary_significant | paired$laplace_significant), , drop = FALSE
  ]
  .post_stage4a_write_csv_v1(
    headline, file.path(output_dir, "laplace_headline_comparison_v1.csv")
  )

  overturned <- headline[
    is.finite(headline$log_ratio_shift) &
      (!headline$significance_preserved |
         !as.logical(headline$direction_preserved)), , drop = FALSE
  ]

  execution_record <- list(
    execution_version = "post_stage4a_sog_event_study_laplace_sensitivity_v1",
    executed_at_utc = format(
      as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"
    ),
    execution_code_commit = execution_code_commit,
    analysis_status = "labelled_sensitivity_not_primary",
    primary_path_modified = FALSE,
    nAGQ = 1L,
    nAGQ_ceiling_reason = paste(
      "lme4 supports nAGQ > 1 only for a single scalar random effect;",
      "this model has three crossed random intercepts"
    ),
    scope = scope,
    taxa_requested = length(selected_taxa),
    outcome = "detection",
    model_components = nrow(diagnostics),
    model_status_counts = as.list(table(diagnostics$status)),
    q_families_comparable_to_primary = identical(scope, "all_core"),
    headline_rows_compared = nrow(headline),
    headline_rows_overturned = nrow(overturned),
    overturned_taxa = if (nrow(overturned)) {
      as.list(unique(overturned$unit_label))
    } else {
      list()
    },
    protected_input_hashes = as.list(protected_hashes),
    final_gate = "PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW"
  )
  .post_stage4a_write_yaml_v1(
    execution_record, file.path(output_dir, "execution_record_v1.yml")
  )

  output_files <- file.path(
    output_dir,
    c(
      "laplace_reporting_effects_v1.csv",
      "laplace_model_diagnostics_v1.csv",
      "laplace_model_term_support_v1.csv",
      "laplace_vs_primary_paired_v1.csv",
      "laplace_headline_comparison_v1.csv",
      "execution_record_v1.yml"
    )
  )
  manifest <- data.frame(
    file = gsub("\\\\", "/", output_files),
    sha256 = vapply(output_files, .post_stage4a_sha256_v1, character(1L)),
    stringsAsFactors = FALSE
  )
  .post_stage4a_write_csv_v1(
    manifest, file.path(output_dir, "output_hash_manifest_v1.csv")
  )

  if (nrow(overturned)) {
    message(
      "POST_STAGE4A_LAPLACE_SENSITIVITY_ALERT=",
      "headline reporting results changed under Laplace: ",
      paste(unique(overturned$unit_label), collapse = ", ")
    )
  }
  message("POST_STAGE4A_LAPLACE_SENSITIVITY_GATE=",
          "PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW")
  invisible(list(
    effects = effects, diagnostics = diagnostics, paired = paired,
    headline = headline, overturned = overturned
  ))
}
