.stage4a_report_escape <- function(x) {
  x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

.stage4a_report_table <- function(x, digits = 4L) {
  if (!nrow(x)) return("<p>No rows.</p>")
  y <- data.frame(lapply(x, function(value) {
    if (is.numeric(value)) format(value, digits = digits, scientific = FALSE,
                                  trim = TRUE, na.encode = FALSE) else as.character(value)
  }), check.names = FALSE, stringsAsFactors = FALSE)
  header <- paste0("<th>", .stage4a_report_escape(names(y)), "</th>", collapse = "")
  body <- paste(apply(y, 1L, function(row) paste0(
    "<tr>", paste0("<td>", .stage4a_report_escape(row), "</td>", collapse = ""), "</tr>"
  )), collapse = "")
  paste0("<div class='table-wrap'><table><thead><tr>", header,
         "</tr></thead><tbody>", body, "</tbody></table></div>")
}

.stage4a_report_svg_document <- function(path, width, height, body) {
  svg <- c(
    sprintf("<svg xmlns='http://www.w3.org/2000/svg' width='%d' height='%d' viewBox='0 0 %d %d' role='img'>",
            width, height, width, height),
    "<rect width='100%' height='100%' fill='white'/>",
    "<style>text{font-family:Arial,sans-serif;fill:#17212b}.axis{stroke:#6b7280;stroke-width:1}.zero{stroke:#6b7280;stroke-width:1;stroke-dasharray:5 4}.individual{stroke:#1f5a7a;fill:white;stroke-width:2}.posterior{stroke:#b7791f;fill:#b7791f;stroke-width:2}.muted{fill:#596674}</style>",
    body, "</svg>"
  )
  .stage4a_pooling_v2_write_text_lf(svg, path)
  paste(svg, collapse = "\n")
}

.stage4a_report_scale_x <- function(value, minimum, maximum, left, right) {
  if (!is.finite(minimum) || !is.finite(maximum) || maximum <= minimum) {
    return(rep(as.integer(round((left + right) / 2)), length(value)))
  }
  as.integer(round(left + (value - minimum) / (maximum - minimum) * (right - left)))
}

.stage4a_report_text <- function(x, y, label, size = 13L, anchor = "start",
                                 weight = "normal", class = "") {
  sprintf("<text x='%d' y='%d' font-size='%d' text-anchor='%s' font-weight='%s' class='%s'>%s</text>",
          as.integer(x), as.integer(y), as.integer(size), anchor, weight, class,
          .stage4a_report_escape(label))
}

.stage4a_report_forest <- function(x, path, title, width = 11, height = 10) {
  panels <- split(x, interaction(x$region, x$outcome, drop = TRUE))
  panel_rows <- max(vapply(panels, nrow, integer(1L)))
  svg_width <- 1100L
  panel_height <- max(260L, 105L + panel_rows * 27L)
  svg_height <- 55L + 2L * panel_height
  body <- .stage4a_report_text(svg_width / 2, 28, title, 18, "middle", "bold")
  for (index in seq_along(panels)) {
    d <- panels[[index]][order(panels[[index]]$unit_label), ]
    column <- (index - 1L) %% 2L
    row <- (index - 1L) %/% 2L
    x0 <- column * 550L
    y0 <- 48L + row * panel_height
    left <- x0 + 185L
    right <- x0 + 530L
    top <- y0 + 48L
    bottom <- top + max(1L, nrow(d) - 1L) * 27L
    xr <- range(c(0, d$conf_low, d$conf_high, d$partial_pool_conf_low_v2,
                  d$partial_pool_conf_high_v2), finite = TRUE)
    pad <- max(diff(xr) * 0.06, 0.05)
    xr <- xr + c(-pad, pad)
    body <- c(body,
      .stage4a_report_text(x0 + 275L, y0 + 20L,
        paste(unique(d$region), ifelse(unique(d$outcome) == "detection",
          "detection", "positive count")), 15, "middle", "bold"),
      sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='axis'/>",
              left, bottom + 18L, right, bottom + 18L),
      .stage4a_report_text(left, bottom + 38L, format(xr[1L], digits = 3), 11, "middle", class = "muted"),
      .stage4a_report_text(right, bottom + 38L, format(xr[2L], digits = 3), 11, "middle", class = "muted"))
    zero <- .stage4a_report_scale_x(0, xr[1L], xr[2L], left, right)
    if (0 >= xr[1L] && 0 <= xr[2L]) body <- c(body,
      sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='zero'/>", zero, top - 12L, zero, bottom + 10L))
    for (i in seq_len(nrow(d))) {
      y <- top + (i - 1L) * 27L
      xi <- .stage4a_report_scale_x(c(d$conf_low[i], d$estimate[i], d$conf_high[i]),
                                    xr[1L], xr[2L], left, right)
      xp <- .stage4a_report_scale_x(c(d$partial_pool_conf_low_v2[i],
        d$partial_pool_estimate_v2[i], d$partial_pool_conf_high_v2[i]),
        xr[1L], xr[2L], left, right)
      body <- c(body,
        .stage4a_report_text(left - 10L, y + 4L, d$unit_label[i], 11, "end"),
        sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='individual'/>", xi[1L], y - 4L, xi[3L], y - 4L),
        sprintf("<circle cx='%d' cy='%d' r='4' class='individual'/>", xi[2L], y - 4L),
        sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='posterior'/>", xp[1L], y + 5L, xp[3L], y + 5L),
        sprintf("<circle cx='%d' cy='%d' r='4' class='posterior'/>", xp[2L], y + 5L))
    }
  }
  .stage4a_report_svg_document(path, svg_width, svg_height, body)
}

.stage4a_report_event_time <- function(x, path) {
  window_order <- c("time_immediate_pre", "time_spawn_start", "time_early_egg",
                    "time_late_egg", "time_post")
  labels <- c("Immediate pre", "Spawn start", "Early egg", "Late egg", "Post")
  width <- 1000L
  height <- 430L
  body <- character()
  outcomes <- c("detection", "positive_numeric_count_given_detection")
  for (panel in seq_along(outcomes)) {
    outcome <- outcomes[panel]
    d <- x[x$response_state == outcome, ]
    x0 <- (panel - 1L) * 500L
    left <- x0 + 70L
    right <- x0 + 470L
    top <- 60L
    bottom <- 315L
    yr <- range(c(0, d$family_conf_low, d$family_conf_high), finite = TRUE)
    pad <- max(diff(yr) * 0.08, 0.05)
    yr <- yr + c(-pad, pad)
    scale_y <- function(value) as.integer(round(bottom - (value - yr[1L]) /
      (yr[2L] - yr[1L]) * (bottom - top)))
    xpos <- as.integer(round(seq(left + 25L, right - 25L, length.out = 5L)))
    body <- c(body,
      .stage4a_report_text(x0 + 250L, 28L,
        if (outcome == "detection") "Detection" else "Positive count", 16, "middle", "bold"),
      sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='axis'/>", left, bottom, right, bottom),
      sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='zero'/>", left, scale_y(0), right, scale_y(0)),
      .stage4a_report_text(left, top - 8L, format(yr[2L], digits = 3), 11, "start", class = "muted"),
      .stage4a_report_text(left, bottom + 16L, format(yr[1L], digits = 3), 11, "start", class = "muted"))
    for (i in seq_along(labels)) body <- c(body,
      .stage4a_report_text(xpos[i], bottom + 34L + (i %% 2L) * 15L, labels[i], 10, "middle"))
    for (region_name in c("SoG", "WCVI")) {
      z <- as.data.frame(d[d$region == region_name, , drop = FALSE])
      z <- z[match(window_order, z$temporal_window), , drop = FALSE]
      offset <- if (region_name == "SoG") -7L else 7L
      class <- if (region_name == "SoG") "individual" else "posterior"
      for (i in seq_len(nrow(z))) body <- c(body,
        sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='%s'/>",
          xpos[i] + offset, scale_y(z$family_conf_low[i]), xpos[i] + offset,
          scale_y(z$family_conf_high[i]), class),
        sprintf("<circle cx='%d' cy='%d' r='5' class='%s'/>",
          xpos[i] + offset, scale_y(z$family_mean[i]), class))
    }
    body <- c(body,
      sprintf("<circle cx='%d' cy='55' r='5' class='individual'/>", right - 115L),
      .stage4a_report_text(right - 103L, 59L, "SoG", 11),
      sprintf("<circle cx='%d' cy='55' r='5' class='posterior'/>", right - 55L),
      .stage4a_report_text(right - 43L, 59L, "WCVI", 11))
  }
  .stage4a_report_svg_document(path, width, height, body)
}

build_stage4a_pooling_report_v2 <- function(repo_root = ".") {
  root <- normalizePath(repo_root, winslash = "/", mustWork = TRUE)
  path <- function(...) file.path(root, ...)
  report_output <- path("outputs", "stage4a_pooling_report_v2")
  report_dir <- path("reports")
  figure_dir <- path("reports", "figures")
  dir.create(report_output, recursive = TRUE, showWarnings = FALSE)
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

  effects <- data.table::fread(path("outputs", "stage4a_pooling_repair_v2",
                                    "effect_estimates_v2.csv"))
  families <- data.table::fread(path("outputs", "stage4a_pooling_repair_v2",
                                     "pooling_family_estimates_v2.csv"))
  registry <- data.table::fread(path("outputs", "stage4a_pooling_repair_v2",
                                     "pooling_family_registry_v2.csv"))
  family <- registry[families, on = "pooling_family_id_v2"]
  data.table::setnames(
    family,
    c("estimability_status", "i.estimability_status"),
    c("registry_eligibility_status", "estimability_status")
  )
  family[, region := sub("_.*$", "", analysis_population)]
  species <- data.table::fread(path("metadata", "canonical_species_registry.csv"))
  priority_a <- species[priority_tier == "A", common_name]

  guild <- effects[model_id == "M01" & region %in% c("SoG", "WCVI") &
    contrast == "active_near" & status == "completed" &
    pooling_reason_code_v2 == "INCLUDED_PRIMARY_REPRESENTATION"]
  focal <- effects[model_id == "M02" & region %in% c("SoG", "WCVI") &
    unit_label %in% priority_a & contrast == "active_near" & status == "completed" &
    pooling_reason_code_v2 == "INCLUDED_PRIMARY_REPRESENTATION"]
  event <- family[canonical_model_id == "M05" & unit_class == "guild" &
    region %in% c("SoG", "WCVI") & grepl("^time_", temporal_window)]
  data.table::setorder(guild, region, outcome, unit_label)
  data.table::setorder(focal, region, outcome, unit_label)
  data.table::setorder(event, response_state, region, temporal_window)
  data.table::setorder(family, canonical_model_id, region, unit_class, response_state,
                       temporal_window, spatial_buffer)

  .stage4a_pooling_v2_write_csv(guild, file.path(report_output, "primary_guild_results_v2.csv"))
  .stage4a_pooling_v2_write_csv(focal, file.path(report_output, "priority_a_species_results_v2.csv"))
  .stage4a_pooling_v2_write_csv(event, file.path(report_output, "event_time_family_results_v2.csv"))
  .stage4a_pooling_v2_write_csv(family, file.path(report_output, "family_diagnostics_v2.csv"))

  reason <- effects[, .N, by = pooling_reason_code_v2][order(-N)]
  fig_reason <- file.path(figure_dir, "stage4a_pooling_v2_row_disposition.svg")
  reason_labels <- c(INCLUDED_PRIMARY_REPRESENTATION = "Estimated primary",
    NON_ESTIMABLE_MODEL_STATUS = "Failed-fit NA",
    EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION = "Duplicate NA")
  reason_data <- reason[match(names(reason_labels), pooling_reason_code_v2)]
  reason_x <- c(180L, 400L, 620L)
  reason_base <- 340L
  reason_top <- 65L
  reason_height <- as.integer(round(reason_data$N / max(reason_data$N) *
                                      (reason_base - reason_top)))
  reason_colors <- c("#1f5a7a", "#d1d5db", "#d6a54b")
  reason_body <- c(.stage4a_report_text(400L, 28L, "V2 row disposition", 18L,
                                        "middle", "bold"))
  for (i in seq_along(reason_x)) reason_body <- c(reason_body,
    sprintf("<rect x='%d' y='%d' width='120' height='%d' fill='%s' stroke='#374151'/>",
      reason_x[i] - 60L, reason_base - reason_height[i], reason_height[i], reason_colors[i]),
    .stage4a_report_text(reason_x[i], reason_base - reason_height[i] - 10L,
      format(reason_data$N[i], big.mark = ","), 13L, "middle", "bold"),
    .stage4a_report_text(reason_x[i], reason_base + 25L,
      reason_labels[reason_data$pooling_reason_code_v2[i]], 12L, "middle"))
  reason_body <- c(reason_body,
    sprintf("<line x1='80' y1='%d' x2='720' y2='%d' class='axis'/>", reason_base, reason_base),
    .stage4a_report_text(28L, 205L, "Affected rows", 13L, "middle"))
  inline_reason <- .stage4a_report_svg_document(fig_reason, 800L, 400L, reason_body)
  fig_guild <- file.path(figure_dir, "stage4a_pooling_v2_primary_guild.svg")
  inline_guild <- .stage4a_report_forest(
    guild, fig_guild, "Primary guild results: individual (open blue) and v2 posterior (gold)"
  )
  fig_species <- file.path(figure_dir, "stage4a_pooling_v2_priority_a_species.svg")
  inline_species <- .stage4a_report_forest(
    focal, fig_species, "Priority-A species: individual (open blue) and v2 posterior (gold)",
    height = 8
  )
  fig_event <- file.path(figure_dir, "stage4a_pooling_v2_event_time.svg")
  inline_event <- .stage4a_report_event_time(event, fig_event)
  fig_tau <- file.path(figure_dir, "stage4a_pooling_v2_tau_distribution.svg")
  tau_hist <- graphics::hist(log10(family$tau2 + 1e-12), breaks = 24L, plot = FALSE)
  tau_left <- 75L
  tau_right <- 765L
  tau_top <- 55L
  tau_base <- 335L
  tau_x <- as.integer(round(seq(tau_left, tau_right, length.out = length(tau_hist$counts) + 1L)))
  tau_h <- as.integer(round(tau_hist$counts / max(tau_hist$counts) * (tau_base - tau_top)))
  tau_body <- c(.stage4a_report_text(420L, 28L,
    "Between-component variance distribution", 18L, "middle", "bold"))
  for (i in seq_along(tau_h)) tau_body <- c(tau_body,
    sprintf("<rect x='%d' y='%d' width='%d' height='%d' fill='#b9d6e5' stroke='#1f5a7a'/>",
      tau_x[i], tau_base - tau_h[i], max(1L, tau_x[i + 1L] - tau_x[i]), tau_h[i]))
  tau_body <- c(tau_body,
    sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' class='axis'/>", tau_left, tau_base, tau_right, tau_base),
    .stage4a_report_text(tau_left, tau_base + 24L, format(min(tau_hist$breaks), digits = 3), 11L, "middle", class = "muted"),
    .stage4a_report_text(tau_right, tau_base + 24L, format(max(tau_hist$breaks), digits = 3), 11L, "middle", class = "muted"),
    .stage4a_report_text(420L, 382L, "log10(tau^2 + 1e-12)", 13L, "middle"),
    .stage4a_report_text(25L, 195L, "V2 families", 13L, "middle"))
  inline_tau <- .stage4a_report_svg_document(fig_tau, 840L, 410L, tau_body)

  chart_map <- data.table::data.table(
    segment = c("Repair accounting", "Guild evidence", "Priority species",
                "Event timing", "Estimator diagnostics"),
    analytical_question = c(
      "How were all invalid v1 rows disposed?",
      "How do individual and v2 posterior guild coefficients compare?",
      "How do registered Priority-A species coefficients compare?",
      "How do pooled event-time coefficients vary across registered windows?",
      "How heterogeneous are the compatible v2 families?"
    ),
    chart_family = c("bar", "faceted dot and interval", "faceted dot and interval",
                     "categorical point and interval", "histogram"),
    fields = c("reason,count", "estimate,CI,posterior,posterior_CI",
               "estimate,CI,posterior,posterior_CI", "family_mean,family_CI,window,region",
               "tau2"),
    supported_claim = c("Complete 6,562-row accounting",
      "Posterior estimates are distinct from individual-model inference",
      "Priority species are shown without outcome-based selection",
      "Event-time comparisons are discrete registered contrasts",
      "Family heterogeneity is explicit rather than hidden"),
    palette = "blue_gold_neutral_noncolor_markers",
    artifact = c(basename(fig_reason), basename(fig_guild), basename(fig_species),
                 basename(fig_event), basename(fig_tau)),
    source = c("outputs/stage4a_pooling_repair_v2/effect_estimates_v2.csv",
               "outputs/stage4a_pooling_repair_v2/effect_estimates_v2.csv",
               "outputs/stage4a_pooling_repair_v2/effect_estimates_v2.csv",
               "outputs/stage4a_pooling_repair_v2/pooling_family_estimates_v2.csv",
               "outputs/stage4a_pooling_repair_v2/pooling_family_estimates_v2.csv")
  )
  .stage4a_pooling_v2_write_csv(chart_map, file.path(report_output, "chart_map_v2.csv"))

  summary_table <- data.table::data.table(
    metric = c("Invalid v1 finite rows", "Invalid v1 families", "Compatible v2 families",
               "Estimable v2 families", "Rows with v2 posterior", "Noncompleted rows as NA",
               "Duplicate representations as NA"),
    value = c(6562L, 112L, nrow(family), sum(family$estimability_status == "ESTIMABLE"),
              sum(effects$pooling_reason_code_v2 == "INCLUDED_PRIMARY_REPRESENTATION"),
              sum(effects$pooling_reason_code_v2 == "NON_ESTIMABLE_MODEL_STATUS"),
              sum(effects$pooling_reason_code_v2 ==
                    "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION"))
  )
  diagnostic_table <- family[, .(
    model = canonical_model_id, population = analysis_population, unit_class,
    response = response_state, registered = component_count_registered,
    eligible = component_count_eligible, tau2, status = estimability_status
  )][order(model, population, unit_class, response)]
  diagnostic_table <- utils::head(diagnostic_table, 30L)
  html <- paste0(
    "<!doctype html><html><head><meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width,initial-scale=1'>",
    "<meta name='color-scheme' content='light dark'>",
    "<title>Stage 4A Aggregate Pooling Repair v2</title><style>",
    ":root{color-scheme:light dark;--ink:#17212b;--muted:#596674;--paper:#fff;--panel:#f5f7f8;--line:#ccd4db;--blue:#1f5a7a;--gold:#b7791f}",
    "@media(prefers-color-scheme:dark){:root{--ink:#edf2f5;--muted:#bdc8d0;--paper:#12181e;--panel:#1c252d;--line:#46545f;--blue:#79b8d8;--gold:#e0b45f}}",
    "body{font-family:system-ui,-apple-system,sans-serif;max-width:1120px;margin:0 auto;padding:28px 22px;color:var(--ink);background:var(--paper);line-height:1.55}",
    "h1,h2{line-height:1.2}h1{color:var(--blue)}h2{margin-top:2.2rem;border-bottom:1px solid var(--line);padding-bottom:.35rem}",
    ".summary{background:var(--panel);border-left:5px solid var(--blue);padding:14px 18px}.caution{background:var(--panel);border-left:5px solid var(--gold);padding:12px 16px}",
    ".figure{margin:22px 0;padding:12px;background:white;border:1px solid #d5dde3;overflow:auto}.figure svg{width:100%;height:auto;min-width:680px}",
    ".caption{font-size:.9rem;color:var(--muted);margin-top:8px}.table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:.86rem}th,td{border:1px solid var(--line);padding:6px 8px;text-align:left}th{background:var(--panel)}code{font-size:.9em}",
    "</style></head><body>",
    "<h1>Stage 4A Aggregate Pooling Repair v2</h1>",
    "<h2>Technical summary</h2><div class='summary'><p><strong>The aggregate-only repair is complete and deterministic.</strong> The accepted scope is 6,562 finite v1 pooling rows in 112 invalid historical families. Metadata-compatible reconstruction creates 162 v2 families; all remain estimable after 38 noncompleted rows and 439 duplicate M11/M12 representations are retained as explicit NA exclusions. The remaining 6,085 primary rows receive versioned posterior estimates.</p><p>Every unaffected individual estimate, standard error, confidence interval, p-value, model-specific BH q-value, sample size, status, and identity is exactly preserved at source serialization. No protected record was used.</p></div>",
    "<h2>Every invalid v1 row has an explicit v2 disposition</h2><p>The bar chart accounts for the complete authoritative scope. Duplicate component representations and noncompleted fits remain visible; neither can contribute to a family estimate.</p>",
    "<div class='figure'>", inline_reason, "<p class='caption'>Counts from the versioned v2 aggregate. The earlier 4,890/84 audit was a parser undercount of the registered North code <code>NA</code>, not a protected-data recovery.</p></div>",
    .stage4a_report_table(summary_table, 8L),
    "<h2>Registered guild coefficients remain checklist-conditional associations</h2><p>Open blue intervals are the unchanged individual-model estimates; filled gold intervals are the new compatible-family posterior estimates. Panels include all registered guild rows for the SoG and WCVI primary frames, without selection by sign or significance.</p>",
    "<div class='figure'>", inline_guild, "<p class='caption'>M01 active-near contrasts. Detection is on the log-odds scale; positive counts are on the registered positive-lognormal coefficient scale.</p></div>",
    "<h2>Priority-A species are shown without outcome-based selection</h2><p>The five registry-defined Priority-A taxa are displayed for both response components and both primary regions. Shrinkage changes synthesis, not the unchanged individual-model inference.</p>",
    "<div class='figure'>", inline_species, "<p class='caption'>M02 active-near contrasts for the frozen Priority-A metadata subset.</p></div>",
    "<h2>Event-time summaries use discrete registered contrasts</h2><p>Each point is a compatible M05 guild-family mean for a registered event-time contrast. These are categorical event-window comparisons, not a continuous trajectory and not a causal event-study estimate.</p>",
    "<div class='figure'>", inline_event, "<p class='caption'>SoG and WCVI pooled guild families; normal 95% intervals. Response scales remain separate.</p></div>",
    "<h2>Scope, data, and metric definitions</h2><p>The source population is eligible submitted complete eBird checklists from the registered Stage 4A frames. The repair reads only <code>outputs/stage4a_results/effect_estimates.csv</code> and frozen metadata. The literal North code <code>NA</code> is a registered categorical value. Individual coefficients retain their original model scale; families never mix response states, unit classes, models, estimands, scales, exposures, time windows, buffers, populations, adjustment sets, or coefficient/variance meanings.</p>",
    "<h2>The estimator is closed form and versioned</h2><p>Within each compatible family, v2 uses the frozen normal-normal empirical-Bayes method-of-moments contract. Sampling variance is squared individual standard error; between-component variance is <code>max(0, var(y) - mean(v))</code>; family weights are <code>1/(v + tau²)</code>. Zero between-family variance uses the exact common-effect boundary rather than the historical artificial precision floor. No pooled p-values or q-values are created.</p>",
    "<div class='figure'>", inline_tau, "<p class='caption'>All 162 v2 families. The logarithmic diagnostic axis exposes both near-zero and highly heterogeneous families without implying comparable biological scales.</p></div>",
    .stage4a_report_table(diagnostic_table, 5L),
    "<h2>Limitations, uncertainty, and robustness</h2><div class='caution'><p><strong>Interpretation boundary.</strong> These are associations among eligible submitted checklists after registered adjustment. They do not identify population abundance, biomass, occupancy, movement, or causal effects. Checklist submission and observer behavior, residual spatial-temporal confounding, interference among nearby spawn events, and incomplete DFO negative-survey coverage remain limitations. Missing DFO records are not surveyed negatives; unmonitored coverage remains unknown.</p></div><p>CC and North remain hierarchical/descriptive. Extreme but finite completed-fit coefficients are retained visibly and should be read with their uncertainty and model diagnostics; no result was removed for magnitude, direction, or significance.</p>",
    "<h2>Recommended next steps</h2><p>The next authorized step is the matched-model publication sensitivity PR: corrected region-year exposure-bundle placebos, WCVI 2-km sensitivity, dominant-observer sensitivity, and retirement of M26 v1 from the inferential publication set. Publication claims should be finalized only after those matched sensitivity diagnostics are available.</p>",
    "<h2>Further questions</h2><p>How stable are the registered associations under matched placebos and observer/spatial sensitivity? Which region-specific estimates remain interpretable after failed-geometry and extreme-coefficient diagnostics? Complete DFO negative-survey coverage would improve exposure interpretation, but its absence does not convert unknown cells to negatives or invalidate the aggregate repair.</p>",
    "</body></html>"
  )
  report_file <- file.path(report_dir, "stage4a_pooling_repair_v2.html")
  .stage4a_pooling_v2_write_text_lf(html, report_file)

  artifact_files <- c(
    report_file, fig_reason, fig_guild, fig_species, fig_event, fig_tau,
    file.path(report_output, c("primary_guild_results_v2.csv",
      "priority_a_species_results_v2.csv", "event_time_family_results_v2.csv",
      "family_diagnostics_v2.csv", "chart_map_v2.csv"))
  )
  normalized_artifacts <- normalizePath(artifact_files, winslash = "/", mustWork = TRUE)
  hashes <- data.table::data.table(
    artifact_path = substring(normalized_artifacts, nchar(root) + 2L),
    sha256 = vapply(artifact_files, .stage4a_pooling_v2_file_hash, character(1L)),
    bytes = as.numeric(file.info(artifact_files)$size)
  )
  .stage4a_pooling_v2_write_csv(hashes, file.path(report_output, "report_artifact_hashes_v2.csv"))
  invisible(list(report = report_file, hashes = hashes, chart_map = chart_map))
}
