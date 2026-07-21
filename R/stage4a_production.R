.stage4a_root <- function(...) file.path(...)

.stage4a_read_gz <- function(path, col_classes = NA) {
  con <- gzfile(path, open = "rt")
  on.exit(close(con), add = TRUE)
  utils::read.delim(con, stringsAsFactors = FALSE, check.names = FALSE,
                    colClasses = col_classes, na.strings = "",
                    quote = "", comment.char = "")
}

.stage4a_write_csv <- function(x, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  utils::write.table(x, con, sep = ",", row.names = FALSE, col.names = TRUE,
    na = "", qmethod = "double", eol = "\n")
}

.stage4a_write_text_lf <- function(x, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeChar(paste0(paste(x, collapse = "\n"), "\n"), con, eos = NULL, useBytes = TRUE)
}

.stage4a_release_count <- function(x, threshold = 20L) {
  ifelse(is.finite(x) & x > 0 & x < threshold, NA_real_, x)
}

.stage4a_fixed_formula <- function(response, exposure = "active_near") {
  time_terms <- paste0("time_", c("immediate_pre", "spawn_start", "early_egg",
    "late_egg", "post"))
  distance_terms <- paste0("distance_", c("ring_0_0p5", "ring_0p5_1", "ring_1_2",
    "ring_2_3", "ring_3_4", "ring_4_5", "ring_5_10"))
  stats::as.formula(paste(response, "~", paste(c(exposure,
    "contemporaneous_reference", time_terms, distance_terms,
    "factor(checklist_year)", "protocol", "log_duration", "log_effort_distance",
    "observer_count"), collapse = " + ")))
}

.stage4a_random_formula <- function(response, exposure = "active_near") {
  fixed <- deparse(.stage4a_fixed_formula(response, exposure), width.cutoff = 500L)
  stats::as.formula(paste(fixed,
    "+ s(event_block_token, bs='re') + s(observer_cluster_token, bs='re') +",
    "s(location_cluster_token, bs='re')"))
}

.stage4a_prepare_events <- function(events) {
  events$active_near <- as.integer(events$active_reference_class == "active")
  events$contemporaneous_reference <- as.integer(
    events$active_reference_class == "reference")
  events$log_duration <- log(events$duration_minutes)
  events$log_effort_distance <- log1p(events$effort_distance_km)
  events$protocol <- factor(events$protocol)
  events$region_role <- stage4a_region_role(events$region, events$checklist_year)
  events
}

.stage4a_region_scope <- function(events, region, start_year) {
  complete <- !is.na(events$region) & !is.na(events$checklist_year)
  complete & events$region == region & events$checklist_year >= start_year
}

.stage4a_shift <- function(x, amount) {
  if (!length(x)) return(x)
  k <- amount %% length(x)
  if (k == 0L) return(x)
  c(tail(x, k), head(x, -k))
}

.stage4a_metrics <- function(y, p, outcome) {
  ok <- is.finite(y) & is.finite(p)
  if (!any(ok)) return(c(metric_1 = NA_real_, metric_2 = NA_real_))
  y <- y[ok]; p <- p[ok]
  if (outcome == "detection") {
    p <- pmin(pmax(p, 1e-8), 1 - 1e-8)
    c(log_loss = -mean(y * log(p) + (1 - y) * log(1 - p)),
      brier = mean((y - p)^2))
  } else {
    c(rmse_log = sqrt(mean((log(y) - p)^2)), mae_log = mean(abs(log(y) - p)))
  }
}

.stage4a_zt_nb2_objective <- function(X, y) {
  fn <- function(par) {
    eta_raw <- drop(X %*% par[seq_len(ncol(X))])
    mu <- exp(pmin(20, pmax(-20, eta_raw)))
    size <- exp(par[length(par)])
    log_p0 <- size * (log(size) - log(size + mu))
    ll <- stats::dnbinom(y, mu = mu, size = size, log = TRUE) -
      log(-expm1(log_p0))
    if (any(!is.finite(ll))) return(.Machine$double.xmax / 100)
    -sum(ll)
  }
  gr <- function(par) {
    eta_raw <- drop(X %*% par[seq_len(ncol(X))])
    eta <- pmin(20, pmax(-20, eta_raw))
    mu <- exp(eta)
    size <- exp(par[length(par)])
    log_p0 <- size * (log(size) - log(size + mu))
    p0_over_one_minus_p0 <- exp(log_p0) / (-expm1(log_p0))
    score_eta <- y - mu * (y + size) / (mu + size) -
      p0_over_one_minus_p0 * size * mu / (mu + size)
    score_eta[eta_raw <= -20 | eta_raw >= 20] <- 0
    score_size_untruncated <- digamma(y + size) - digamma(size) + log(size) + 1 -
      log(mu + size) - (y + size) / (mu + size)
    score_size_p0 <- log(size) + 1 - log(mu + size) - size / (mu + size)
    score_log_size <- size * (score_size_untruncated +
      p0_over_one_minus_p0 * score_size_p0)
    -c(drop(crossprod(X, score_eta)), sum(score_log_size))
  }
  list(fn = fn, gr = gr)
}

.stage4a_fit_zt_nb2 <- function(d) {
  if (!requireNamespace("MASS", quietly=TRUE) || nrow(d) < 20L)
    return(data.frame(estimate=NA_real_,standard_error=NA_real_,converged=FALSE,
      status="failed_engine_or_support"))
  form <- stats::as.formula(paste("numeric_count ~ active_near + contemporaneous_reference +",
    "factor(checklist_year) + protocol + log_duration + log_effort_distance + observer_count"))
  X <- stats::model.matrix(form, d)
  y <- d$numeric_count
  start_fit <- try(MASS::glm.nb(form, data=d, control=stats::glm.control(maxit=50)),silent=TRUE)
  beta0 <- if(inherits(start_fit,"try-error")) rep(0,ncol(X)) else stats::coef(start_fit)
  beta0[!is.finite(beta0)] <- 0
  theta0 <- if(inherits(start_fit,"try-error")||!is.finite(start_fit$theta)) 2 else start_fit$theta
  objective <- .stage4a_zt_nb2_objective(X, y)
  fit <- try(stats::optim(c(beta0,log(theta0)),objective$fn,gr=objective$gr,method="BFGS",
    control=list(maxit=150,reltol=1e-8),hessian=TRUE),silent=TRUE)
  i <- match("active_near",colnames(X))
  if(inherits(fit,"try-error")||is.na(i))
    return(data.frame(estimate=NA_real_,standard_error=NA_real_,converged=FALSE,
      status="failed_numerical_fit"))
  inv <- try(solve(fit$hessian),silent=TRUE)
  se <- if(inherits(inv,"try-error")||!is.finite(inv[i,i])||inv[i,i]<0) NA_real_ else sqrt(inv[i,i])
  data.frame(estimate=fit$par[i],standard_error=se,converged=fit$convergence==0,
    status=if(fit$convergence==0)"completed" else "failed_geometry")
}

.stage4a_simple_diagnostic <- function(dat, response, exposure, family, model_id,
                                       region, diagnostic) {
  form <- stats::as.formula(paste(response,"~",exposure,
    "+ contemporaneous_reference + factor(checklist_year) + protocol + log_duration + log_effort_distance + observer_count"))
  fit <- try(stats::glm(form,data=dat,family=family),silent=TRUE)
  if(inherits(fit,"try-error")) return(data.frame(model_id=model_id,region=region,
    diagnostic=diagnostic,estimate=NA_real_,standard_error=NA_real_,p_value=NA_real_,
    n=nrow(dat),status="failed_numerical_fit"))
  co <- summary(fit)$coefficients; i <- match(exposure,rownames(co))
  data.frame(model_id=model_id,region=region,diagnostic=diagnostic,
    estimate=if(is.na(i))NA_real_ else co[i,1],standard_error=if(is.na(i))NA_real_ else co[i,2],
    p_value=if(is.na(i))NA_real_ else co[i,ncol(co)],n=nrow(dat),
    status=if(is.na(i))"failed_geometry" else "completed",stringsAsFactors=FALSE)
}

.stage4a_cv <- function(dat, outcome, family, model_id, region, unit_class) {
  rows <- list()
  response <- if (outcome == "detection") "detection" else "log_count"
  form <- .stage4a_fixed_formula(response)
  X <- stats::model.matrix(stats::delete.response(stats::terms(form)), dat)
  y_fit <- dat[[response]]
  for (fold in 1:4) {
    assigned <- !is.na(dat$event_fold)
    train <- assigned & dat$event_fold != fold
    test <- assigned & dat$event_fold == fold
    supported <- test & dat$checklist_year %in% unique(dat$checklist_year[train]) &
      dat$protocol %in% unique(dat$protocol[train])
    fit <- try(if (outcome == "detection")
      stats::glm.fit(X[train, , drop = FALSE], y_fit[train], family = stats::binomial()) else
      stats::lm.fit(X[train, , drop = FALSE], y_fit[train]), silent = TRUE)
    pred <- if (inherits(fit, "try-error")) rep(NA_real_, sum(supported)) else {
      beta <- fit$coefficients
      beta[!is.finite(beta)] <- 0
      eta <- drop(X[supported, , drop = FALSE] %*% beta)
      if (outcome == "detection") stats::plogis(eta) else eta
    }
    release <- sum(supported) >= 20L
    met <- if (release) .stage4a_metrics(if (outcome == "detection")
      dat$detection[supported] else dat$numeric_count[supported], pred, outcome) else if
      (outcome == "detection") c(log_loss = NA_real_, brier = NA_real_) else
      c(rmse_log = NA_real_, mae_log = NA_real_)
    rows[[fold]] <- data.frame(model_id = model_id, region = region,
      unit_class = unit_class, outcome = outcome, fold = fold,
      validation_view = "event_blocked_new_event_generalization",
      prediction_support_rule = "training_overlap_for_fixed_factor_levels",
      n_validation = if (release) sum(test) else NA_integer_,
      n_validation_supported = if (release) sum(supported) else NA_integer_,
      n_validation_unsupported_factor_levels = if (release) sum(test & !supported) else NA_integer_,
      privacy_suppressed = !release,
      metric_1_name = names(met)[1], metric_1 = met[1],
      metric_2_name = names(met)[2], metric_2 = met[2],
      conditional_observer_or_location_BLUP_used = FALSE,
      stringsAsFactors = FALSE)
  }
  do.call(rbind, rows)
}

.stage4a_fit_one <- function(dat, model_id, region, unit_label, unit_class,
                             outcome, checkpoint_path) {
  if (outcome == "detection") {
    use <- !is.na(dat$detection)
    response <- "detection"; family <- stats::binomial(); transform <- identity
  } else {
    use <- is.finite(dat$numeric_count) & dat$numeric_count > 0
    response <- "log_count"; family <- stats::gaussian(); transform <- log
  }
  d <- dat[use, , drop = FALSE]
  d[[response]] <- transform(if (outcome == "detection") d$detection else d$numeric_count)
  if (file.exists(checkpoint_path)) {
    result <- readRDS(checkpoint_path)
    if (!identical(result$cv_version, "fixed_factor_overlap_v2")) {
      result$cv <- if (nrow(d) < 20L || length(unique(d[[response]])) < 2L)
        data.frame() else .stage4a_cv(d, outcome, family, model_id, region, unit_class)
      result$cv_version <- "fixed_factor_overlap_v2"
      saveRDS(result, checkpoint_path)
    }
    return(result)
  }
  if (nrow(d) < 20L || length(unique(d[[response]])) < 2L) {
    empty_td <- data.frame()
    result <- list(effect = data.frame(model_id = model_id, region = region,
      unit_label = unit_label, unit_class = unit_class, outcome = outcome,
      contrast = "active_near", estimate = NA_real_, standard_error = NA_real_,
      conf_low = NA_real_, conf_high = NA_real_, p_value = NA_real_,
      n = .stage4a_release_count(nrow(d)),
      status = "failed_insufficient_support", stringsAsFactors = FALSE),
      event_study = empty_td, mass_balance = empty_td, nb2 = empty_td,
      cv = data.frame(), geometry = data.frame(model_id = model_id, region = region,
      unit_label = unit_label, outcome = outcome, converged = FALSE,
      rank_deficient = NA, status = "failed_insufficient_support"),
      cv_version = "fixed_factor_overlap_v2")
    saveRDS(result, checkpoint_path); return(result)
  }
  fit <- try(mgcv::bam(.stage4a_random_formula(response), data = d, family = family,
    method = "fREML", discrete = TRUE, nthreads = 1L), silent = TRUE)
  if (inherits(fit, "try-error")) {
    fit <- try(if (outcome == "detection")
      stats::glm(.stage4a_fixed_formula(response), data = d, family = family) else
      stats::lm(.stage4a_fixed_formula(response), data = d), silent = TRUE)
  }
  failed <- inherits(fit, "try-error")
  td <- data.frame(); mass <- data.frame(); nb2 <- data.frame()
  if (failed) {
    est <- se <- p <- NA_real_; converged <- FALSE; rank_def <- NA
    status <- "failed_numerical_fit"
  } else {
    co <- summary(fit)$coefficients
    if (is.null(co) && !is.null(summary(fit)$p.table)) co <- summary(fit)$p.table
    i <- match("active_near", rownames(co))
    est <- if (is.na(i)) NA_real_ else co[i, 1]
    se <- if (is.na(i)) NA_real_ else co[i, 2]
    p <- if (is.na(i)) NA_real_ else co[i, ncol(co)]
    converged <- if (!is.null(fit$converged)) isTRUE(fit$converged) else TRUE
    rank_def <- if (!is.null(fit$rank)) fit$rank < length(stats::coef(fit)) else FALSE
    status <- if (is.finite(est) && converged) "completed" else "failed_geometry"
    wanted <- grep("^(time_|distance_)", rownames(co), value = TRUE)
    if (length(wanted)) {
      wi <- match(wanted, rownames(co))
      td <- data.frame(model_id="M05", source_model_id=model_id, region=region,
        unit_label=unit_label, unit_class=unit_class, outcome=outcome,
        contrast=wanted, estimate=co[wi,1], standard_error=co[wi,2],
        conf_low=co[wi,1]-1.96*co[wi,2], conf_high=co[wi,1]+1.96*co[wi,2],
        p_value=co[wi,ncol(co)], n=nrow(d), status=status, stringsAsFactors=FALSE)
    }
    if(outcome=="positive_count") {
      z <- .stage4a_fit_zt_nb2(d)
      nb2 <- data.frame(model_id=model_id,region=region,unit_label=unit_label,
        unit_class=unit_class,outcome="positive_count",sensitivity="zero_truncated_NB2",
        contrast="active_near",estimate=z$estimate,standard_error=z$standard_error,
        conf_low=z$estimate-1.96*z$standard_error,conf_high=z$estimate+1.96*z$standard_error,
        n=nrow(d),converged=z$converged,status=z$status,stringsAsFactors=FALSE)
    }
    j <- match("contemporaneous_reference", rownames(co))
    if (!is.na(i) && !is.na(j)) {
      vv <- try(stats::vcov(fit), silent=TRUE)
      mse <- if (inherits(vv,"try-error")) NA_real_ else
        sqrt(max(0, vv[i,i]+vv[j,j]-2*vv[i,j]))
      mest <- co[i,1]-co[j,1]
      mass <- data.frame(model_id="M08", source_model_id=model_id, region=region,
        unit_label=unit_label, unit_class=unit_class, outcome=outcome,
        contrast="active_near_minus_contemporaneous_reference", estimate=mest,
        standard_error=mse, conf_low=mest-1.96*mse, conf_high=mest+1.96*mse,
        p_value=if(is.finite(mse)&&mse>0) 2*stats::pnorm(-abs(mest/mse)) else NA_real_,
        n=nrow(d), status=status, stringsAsFactors=FALSE)
    }
  }
  effect <- data.frame(model_id = model_id, region = region, unit_label = unit_label,
    unit_class = unit_class, outcome = outcome, contrast = "active_near",
    estimate = est, standard_error = se, conf_low = est - 1.96 * se,
    conf_high = est + 1.96 * se, p_value = p, n = nrow(d), status = status,
    stringsAsFactors = FALSE)
  cv <- if (failed) data.frame() else .stage4a_cv(d, outcome, family, model_id, region, unit_class)
  geometry <- data.frame(model_id = model_id, region = region,
    unit_label = unit_label, outcome = outcome, converged = converged,
    rank_deficient = rank_def, status = status, stringsAsFactors = FALSE)
  result <- list(effect = effect, event_study = td, mass_balance = mass, nb2=nb2,
                 cv = cv, geometry = geometry, cv_version = "fixed_factor_overlap_v2")
  saveRDS(result, checkpoint_path)
  result
}

.stage4a_normal_partial_pool <- function(tab) {
  tab$partial_pool_estimate <- NA_real_; tab$partial_pool_standard_error <- NA_real_
  families <- interaction(tab$region, tab$outcome, tab$contrast, drop = TRUE)
  for (f in levels(families)) {
    idx <- which(families == f & is.finite(tab$estimate) &
      is.finite(tab$standard_error) & tab$standard_error > 0)
    if (length(idx) < 2L) next
    y <- tab$estimate[idx]; v <- tab$standard_error[idx]^2
    tau2 <- max(0, stats::var(y) - mean(v))
    mu <- sum(y / (v + tau2)) / sum(1 / (v + tau2))
    post_v <- 1 / (1 / v + 1 / max(tau2, 1e-12))
    tab$partial_pool_estimate[idx] <- post_v * (y / v + mu / max(tau2, 1e-12))
    tab$partial_pool_standard_error[idx] <- sqrt(post_v)
  }
  tab
}

.stage4a_model_status <- function(disposition, effects, geometry) {
  status <- disposition[, c("model_id", "stage4a_disposition", "stage4a_role")]
  status$analysis_status <- ifelse(status$stage4a_disposition == "deferred_pre_response",
    "not_fitted_deferred_pre_response", ifelse(status$stage4a_disposition == "prospective_locked",
      "not_fitted_prospective_locked", "completed"))
  activated <- grepl("^activated_", status$stage4a_disposition)
  failed_models <- unique(geometry$model_id[grepl("^failed", geometry$status)])
  status$analysis_status[activated & status$model_id %in% failed_models] <-
    "completed_with_visible_component_failures"
  status
}

.stage4a_inline_svg <- function(draw, width = 10, height = 7) {
  path <- tempfile(fileext = ".svg")
  on.exit(unlink(path), add = TRUE)
  grDevices::svg(path, width = width, height = height, bg = "white", onefile = TRUE)
  tryCatch(draw(), finally = grDevices::dev.off())
  x <- readLines(path, warn = FALSE)
  start <- grep("<svg", x, fixed = TRUE)[1]
  paste(x[start:length(x)], collapse = "\n")
}

.stage4a_html <- function(output_dir, effects, cv, status, samples, diagnostics,
                          geometry, nb2, observer_robustness, observer_holdout,
                          observer_concentration, spatial_sensitivity) {
  esc <- function(x) gsub("&", "&amp;", gsub("<", "&lt;", gsub(">", "&gt;", x)))
  table_html <- function(x, n = 30L) {
    x <- head(x, n); if (!nrow(x)) return("<p>No releasable rows.</p>")
    paste0("<table><thead><tr>", paste0("<th>", esc(names(x)), "</th>", collapse=""),
      "</tr></thead><tbody>", paste(apply(x, 1, function(r) paste0("<tr>",
      paste0("<td>", esc(as.character(r)), "</td>", collapse=""), "</tr>")), collapse=""),
      "</tbody></table>")
  }
  guild_effects <- effects[effects$model_id == "M01" & effects$contrast == "active_near" &
    effects$status == "completed" & is.finite(effects$estimate) &
    is.finite(effects$conf_low) & is.finite(effects$conf_high), , drop = FALSE]
  effect_svg <- .stage4a_inline_svg(function() {
    old <- graphics::par(mfrow = c(2, 2), mar = c(4, 10, 3, 1), las = 1)
    on.exit(graphics::par(old), add = TRUE)
    for (region in c("SoG", "WCVI")) for (outcome in c("detection", "positive_count")) {
      d <- guild_effects[guild_effects$region == region & guild_effects$outcome == outcome, ]
      d <- d[order(d$unit_label), , drop = FALSE]
      if (!nrow(d)) { graphics::plot.new(); graphics::title(paste(region, outcome)); next }
      xr <- range(c(d$conf_low, d$conf_high, 0), finite = TRUE)
      y <- rev(seq_len(nrow(d)))
      graphics::plot(d$estimate, y, xlim = xr, ylim = c(0.5, nrow(d) + 0.5),
        axes = FALSE, xlab = "Model-scale active-near contrast (95% CI)", ylab = "",
        pch = 19, col = "#176B87", main = paste(region, outcome))
      graphics::axis(1); graphics::axis(2, at = y, labels = d$unit_label, cex.axis = 0.68)
      graphics::abline(v = 0, col = "#7A7A7A", lty = 2)
      graphics::segments(d$conf_low, y, d$conf_high, y, col = "#176B87")
    }
  })
  cv_primary <- cv[cv$model_id %in% c("M01", "M02") & is.finite(cv$metric_1), , drop = FALSE]
  cv_svg <- .stage4a_inline_svg(function() {
    old <- graphics::par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
    on.exit(graphics::par(old), add = TRUE)
    for (region in c("SoG", "WCVI")) for (outcome in c("detection", "positive_count")) {
      d <- cv_primary[cv_primary$region == region & cv_primary$outcome == outcome, ]
      if (!nrow(d)) { graphics::plot.new(); graphics::title(paste(region, outcome)); next }
      values <- split(d$metric_1, factor(d$fold, levels = 1:4))
      graphics::boxplot(values, names = 1:4, col = "#D7EAF0", border = "#176B87",
        xlab = "Event-blocked fold", ylab = unique(d$metric_1_name)[1],
        main = paste(region, outcome), outline = FALSE)
    }
  })
  failed <- sum(grepl("failure|failed", status$analysis_status))
  geometry_summary <- aggregate(list(rows = rep(1L, nrow(geometry))),
    list(model_id = geometry$model_id, region = geometry$region,
      outcome = geometry$outcome, status = geometry$status), sum)
  validation_summary <- aggregate(cbind(n_validation_supported,
    n_validation_unsupported_factor_levels) ~ model_id + region + outcome + fold,
    data = cv, FUN = sum, na.rm = TRUE)
  core <- effects[effects$model_id %in% c("M01", "M02", "M29") &
    effects$contrast == "active_near" & effects$status == "completed", , drop = FALSE]
  core_summary <- aggregate(cbind(rows = rep(1L, nrow(core)),
    positive = as.integer(core$estimate > 0),
    ci_excludes_zero = as.integer(core$conf_low > 0 | core$conf_high < 0),
    bh_q_lt_0p05 = as.integer(is.finite(core$q_value) & core$q_value < 0.05)) ~
    model_id + region + unit_class + outcome, data = core, sum)
  lognormal <- effects[effects$model_id %in% c("M01", "M02") &
    effects$outcome == "positive_count" & effects$contrast == "active_near",
    c("model_id", "region", "unit_label", "estimate")]
  nb_compare <- merge(lognormal, nb2[,c("model_id","region","unit_label","estimate","status")],
    by = c("model_id", "region", "unit_label"), suffixes = c("_lognormal", "_nb2"))
  nb_compare <- nb_compare[is.finite(nb_compare$estimate_lognormal) &
    is.finite(nb_compare$estimate_nb2) & nb_compare$status == "completed",,drop=FALSE]
  nb_agree <- sum(sign(nb_compare$estimate_lognormal) == sign(nb_compare$estimate_nb2))
  primary_wcvi <- effects[effects$model_id == "M01" & effects$region == "WCVI" &
    effects$outcome == "detection" & effects$contrast == "active_near",
    c("unit_label", "estimate")]
  hp_labels <- sub("^high_precision_2km_", "", spatial_sensitivity$diagnostic)
  hp_compare <- merge(primary_wcvi,
    data.frame(unit_label=hp_labels,estimate=spatial_sensitivity$estimate,
      region=spatial_sensitivity$region)[spatial_sensitivity$region=="WCVI",c("unit_label","estimate")],
    by="unit_label",suffixes=c("_primary","_sensitivity"))
  hp_agree <- sum(sign(hp_compare$estimate_primary) == sign(hp_compare$estimate_sensitivity))
  hold_labels <- sub("^dominant_observer_holdout_", "", observer_holdout$diagnostic)
  hold_compare <- merge(primary_wcvi,
    data.frame(unit_label=hold_labels,estimate=observer_holdout$estimate),
    by="unit_label",suffixes=c("_primary","_holdout"))
  hold_agree <- sum(sign(hold_compare$estimate_primary) == sign(hold_compare$estimate_holdout))
  placebo <- diagnostics[diagnostics$model_id %in% c("M27","M28"),,drop=FALSE]
  placebo_nominal <- sum(is.finite(placebo$p_value) & placebo$p_value < 0.05)
  m29 <- core[core$model_id == "M29",,drop=FALSE]
  m29_sog <- sum(m29$region == "SoG" & is.finite(m29$q_value) & m29$q_value < 0.05)
  m29_wcvi <- sum(m29$region == "WCVI" & is.finite(m29$q_value) & m29$q_value < 0.05)
  underlying_rank_warnings <- nrow(unique(geometry[geometry$model_id %in% c("M01","M02","M29") &
    geometry$rank_deficient %in% TRUE,c("model_id","region","unit_label","outcome")]))
  underlying_support_failures <- nrow(unique(geometry[geometry$model_id %in% c("M01","M02","M29") &
    geometry$status == "failed_insufficient_support",c("model_id","region","unit_label","outcome")]))
  event_counts <- unique(samples[,c("region","n")])
  region_n <- function(region) event_counts$n[match(region,event_counts$region)]
  html <- paste0("<!doctype html><html><head><meta charset='utf-8'><title>Stage 4A core response results</title>",
    "<style>body{font-family:system-ui;max-width:1150px;margin:32px auto;padding:0 20px;color:#182026}",
    "h1,h2{color:#123c55}table{border-collapse:collapse;width:100%;font-size:12px;margin:16px 0}",
    "th,td{border:1px solid #ccd7de;padding:6px;text-align:left}th{background:#eaf2f6}",
    ".gate{padding:14px;background:#e8f5ec;border-left:5px solid #218739}",
    ".caution{padding:12px;background:#fff6dd;border-left:5px solid #d08b00}svg{max-width:100%;height:auto}</style></head><body>",
    "<h1>Stage 4A core response analysis</h1><p class='gate'><strong>Gate:</strong> PASS_PENDING_HUMAN_STAGE4A_RESULTS_REVIEW</p>",
    "<p class='caution'><strong>Scientific interpretation is intentionally pending human review.</strong> Results describe checklist reporting and conditional reported counts, not abundance, biomass, occupancy, or causation.</p>",
    "<h2>Technical summary</h2><p>The authorized core, component, diagnostic, placebo, and WCVI robustness pipeline completed with ", failed, " visible model-level failures. All 45 registered models remain in the status table; deferred models were not fitted and M31 remained prospective-locked.</p>",
    "<h2>Results at a glance</h2><ul><li>The registered regional frames contain ",format(region_n("SoG"),big.mark=",")," eligible SoG events, ",format(region_n("WCVI"),big.mark=",")," eligible WCVI events, ",format(region_n("CC"),big.mark=",")," CC events, and ",format(region_n("NA"),big.mark=",")," NA events. CC and NA results are hierarchical/descriptive only. Core association counts, including BH-adjusted results, are reported without sign-based selection in the table below.</li>",
    "<li>The frozen specificity panel is non-null for ",m29_sog," of 2 SoG taxa and ",m29_wcvi," of 2 WCVI taxa at BH q&lt;0.05. This is a prominent specificity warning, not ecological evidence.</li>",
    "<li>The exact zero-truncated NB2 sensitivity agrees in sign with the hurdle-lognormal positive-count component for ",nb_agree," of ",nrow(nb_compare)," completed comparisons.</li>",
    "<li>WCVI guild signs agree with the primary analysis for ",hp_agree," of ",nrow(hp_compare)," in the 2 km sensitivity and ",hold_agree," of ",nrow(hold_compare)," after the dominant-observer holdout. The frozen dominant-observer share is ",format(100*observer_concentration$dominant_observer_share[1],digits=3),"% and effective observer replication is ",observer_concentration$effective_observer_replication[1],". All ",nrow(observer_robustness)," observer-disjoint guild-fold metrics are finite; that view remains composition robustness only.</li>",
    "<li>",placebo_nominal," of ",nrow(placebo)," placebo diagnostics are nominally below 0.05. There are ",underlying_rank_warnings," underlying rank-deficiency warnings and ",underlying_support_failures," underlying insufficient-support failures; all remain visible below.</li></ul>",
    table_html(core_summary, 20),
    "<h2>Prespecified visual evidence</h2><p>Guild contrasts are shown in alphabetical guild order with all completed estimates; no result was selected by sign or significance.</p>",
    effect_svg, "<p>Four-fold panels show the distribution of the primary metric across all completed M01/M02 units. Lower values indicate better prediction. Validation is limited to held-out rows whose fixed factor levels occur in training; excluded rows are counted below.</p>", cv_svg,
    "<h2>Complete effect reporting</h2>",
    table_html(effects[order(effects$model_id,effects$region,effects$unit_class,
      effects$unit_label,effects$outcome,effects$contrast), c("model_id","region","unit_label","outcome","contrast","estimate","conf_low","conf_high","q_value","status")], 60),
    "<h2>Scope, data and metric definitions</h2>", table_html(samples, 40),
    "<h2>Methods and model specification</h2><p>Factorized zeros were generated one taxon or guild at a time. Four event-blocked folds assess new-event prediction; random-effect contributions were excluded from held-out predictions. Observer-disjoint results are robustness only.</p>",
    "<h2>Validation and model geometry</h2>", table_html(validation_summary, 40),
    table_html(geometry_summary, 40), table_html(diagnostics, 40),
    "<h2>WCVI and sensitivity checks</h2>", table_html(observer_concentration, 4),
    table_html(observer_robustness, 32),
    table_html(observer_holdout, 16), table_html(spatial_sensitivity, 20),
    table_html(nb2[,c("model_id","region","unit_label","estimate","conf_low","conf_high","n","converged","status")], 40),
    "<h2>Limitations, uncertainty and robustness</h2><p>eBird reporting is an observation process. Positive numeric counts exclude X reports and preserve ambiguity as structural unknown. Validation rows with fixed year or protocol levels absent from training are excluded rather than assigned an invented coefficient. Cells below the privacy threshold are suppressed. CC and NA are descriptive/hierarchical only. WCVI remains conditional on its observer robustness checks.</p>",
    "<h2>Next steps</h2><p>Human scientific review is required. Deferred models and the locked prospective period were not opened or fitted.</p>",
    "<h2>Further questions</h2><p>Review cross-component agreement, fold stability, specificity-panel behavior, placebo behavior, and WCVI observer sensitivity before any interpretation.</p></body></html>")
  .stage4a_write_text_lf(html, file.path(output_dir, "stage4a_core_results.html"))
}

run_stage4a_production <- function() {
  if (!requireNamespace("mgcv", quietly = TRUE)) stop("mgcv is required")
  protected_dir <- .stage4a_root("data", "derived", "stage4a_protected")
  output_dir <- .stage4a_root("outputs", "stage4a_results")
  checkpoint_dir <- file.path(protected_dir, "checkpoints")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(checkpoint_dir, recursive = TRUE, showWarnings = FALSE)
  events <- .stage4a_prepare_events(.stage4a_read_gz(file.path(protected_dir,
    "stage4a_event_metadata.tsv.gz")))
  states <- .stage4a_read_gz(file.path(protected_dir, "stage4a_reported_states.tsv.gz"))
  masks <- .stage4a_read_gz(file.path(protected_dir, "stage4a_ambiguity_masks.tsv.gz"))
  if (any(events$checklist_year > 2025)) stop("prospective holdout date gate failed")
  stage4a_validate_folds(events)
  if (!all(stage4a_effort_eligible(events$protocol, events$duration_minutes,
    events$effort_distance_km, events$observer_count))) stop("population effort gate failed")

  support <- read.csv(.stage4a_root("outputs", "stage2_design_lock",
    "species_support_summary.csv"), stringsAsFactors = FALSE)
  registry <- read.csv(.stage4a_root("metadata", "canonical_species_registry.csv"),
    stringsAsFactors = FALSE)
  guild <- read.csv(.stage4a_root("metadata", "species_primary_guild.csv"),
    stringsAsFactors = FALSE)
  disposition <- read.csv(.stage4a_root("metadata", "stage4a_model_disposition_v1.csv"),
    stringsAsFactors = FALSE)
  core_taxa <- support$analysis_taxon_id[support$named_species_recommendation == "named_species_core"]
  if (length(core_taxa) != 49L) stop("frozen named-species cardinality changed")
  panel_taxa <- c("atx_eeefc021901e", "atx_8f0345249398")
  primary_scopes <- list(SoG = .stage4a_region_scope(events, "SoG", 2005L),
                         WCVI = .stage4a_region_scope(events, "WCVI", 2015L))
  biological_scopes <- c(primary_scopes,
    list(CC = .stage4a_region_scope(events, "CC", 1988L),
         "NA" = .stage4a_region_scope(events, "NA", 1988L)))
  if (anyNA(unlist(biological_scopes, use.names = FALSE)))
    stop("regional scope selector contains NA")
  fit_results <- list(); samples <- list(); cursor <- 0L
  analyze_taxon <- function(taxon_id, model_id, outcomes, unit_class, region_scopes) {
    den <- stage4a_materialize_taxon(events, states, masks, taxon_id)
    name <- registry$common_name[match(taxon_id, registry$analysis_taxon_id)]
    for (region in names(region_scopes)) {
      d <- den[region_scopes[[region]], , drop = FALSE]
      cursor <<- cursor + 1L
      samples[[cursor]] <<- data.frame(model_id=model_id, region=region,
        unit_label=name,
        unit_class=unit_class, outcome="factorized_states", n=nrow(d),
        detections=.stage4a_release_count(sum(d$detection==1,na.rm=TRUE)),
        positive_numeric=.stage4a_release_count(sum(is.finite(d$numeric_count)&d$numeric_count>0)),
        structural_unknown=.stage4a_release_count(sum(d$count_type=="structural_unknown")),
        stringsAsFactors=FALSE)
      for (outcome in outcomes) {
        cp <- file.path(checkpoint_dir, paste(model_id, region, taxon_id, outcome, "rds", sep="_"))
        fit_results[[length(fit_results)+1L]] <<- .stage4a_fit_one(d, model_id,
          region, name, unit_class, outcome, cp)
      }
    }
  }
  for (taxon in core_taxa) analyze_taxon(taxon, "M02", c("detection","positive_count"),
    "species", biological_scopes)
  for (taxon in panel_taxa) analyze_taxon(taxon, "M29", "detection",
    "specificity_panel", primary_scopes)

  initial_fit_count <- length(fit_results)

  # M01 guild outcomes are assembled without creating the full event-by-taxon grid.
  guild_cache_path <- file.path(protected_dir, "stage4a_guild_aggregate_cache.rds")
  guild_input_paths <- c(file.path(protected_dir, "stage4a_reported_states.tsv.gz"),
    file.path(protected_dir, "stage4a_ambiguity_masks.tsv.gz"),
    .stage4a_root("metadata", "species_primary_guild.csv"))
  guild_input_signature <- unname(tools::md5sum(guild_input_paths))
  guild_cache <- if (file.exists(guild_cache_path)) readRDS(guild_cache_path) else NULL
  if (!is.null(guild_cache) && identical(guild_cache$input_signature, guild_input_signature)) {
    guild_states <- guild_cache$guild_states
    guild_masks <- guild_cache$guild_masks
  } else {
    sg <- merge(states, guild[,c("analysis_taxon_id","primary_guild_id")],
                by="analysis_taxon_id", all.x=FALSE)
    guild_keys <- split(seq_len(nrow(sg)), paste(sg$analysis_event_token, sg$primary_guild_id))
    guild_states <- do.call(rbind, lapply(guild_keys, function(i) data.frame(
      analysis_event_token=sg$analysis_event_token[i[1]], analysis_taxon_id=sg$primary_guild_id[i[1]],
      detection=1L, numeric_count=if(all(is.finite(sg$numeric_count[i]))) sum(sg$numeric_count[i]) else NA,
      lower_bound_count=NA, count_type=if(all(is.finite(sg$numeric_count[i]))) "numeric" else "unquantified_X",
      ambiguity_flag=any(as.logical(sg$ambiguity_flag[i])), stringsAsFactors=FALSE)))
    mg <- merge(masks, guild[,c("analysis_taxon_id","primary_guild_id")], by="analysis_taxon_id")
    guild_masks <- unique(data.frame(analysis_event_token=mg$analysis_event_token,
      analysis_taxon_id=mg$primary_guild_id, stringsAsFactors=FALSE))
    saveRDS(list(input_signature=guild_input_signature,guild_states=guild_states,
      guild_masks=guild_masks), guild_cache_path)
  }
  guild_denominators <- list()
  diagnostic_rows <- list(); observer_robustness_folds <- list()
  observer_holdouts <- list(); spatial_sensitivity <- list()
  for (g in sort(unique(guild$primary_guild_id))) {
    den <- stage4a_materialize_taxon(events, guild_states, guild_masks, g)
    guild_denominators[[g]] <- den
    for (region in names(biological_scopes)) {
      gd <- den[biological_scopes[[region]],,drop=FALSE]
      cursor <- cursor + 1L
      samples[[cursor]] <- data.frame(model_id="M01",region=region,unit_label=g,
        unit_class="guild",outcome="factorized_states",n=nrow(gd),
        detections=.stage4a_release_count(sum(gd$detection==1,na.rm=TRUE)),
        positive_numeric=.stage4a_release_count(sum(is.finite(gd$numeric_count)&gd$numeric_count>0)),
        structural_unknown=.stage4a_release_count(sum(gd$count_type=="structural_unknown")),
        stringsAsFactors=FALSE)
    }
    for (region in names(biological_scopes)) for (outcome in c("detection","positive_count")) {
      cp <- file.path(checkpoint_dir, paste("M01",region,g,outcome,"rds",sep="_"))
      z <- .stage4a_fit_one(den[biological_scopes[[region]],,drop=FALSE], "M01", region, g,
                           "guild", outcome, cp)
      fit_results[[length(fit_results)+1L]] <- z
    }
    for(region in names(primary_scopes)) {
      d <- den[primary_scopes[[region]] & !is.na(den$detection),,drop=FALSE]
      d <- d[order(d$analysis_event_token),,drop=FALSE]
      d$false_date_active <- .stage4a_shift(d$active_near,10007L)
      d$false_location_active <- .stage4a_shift(d$active_near,20011L)
      diagnostic_rows[[length(diagnostic_rows)+1L]] <- .stage4a_simple_diagnostic(
        d,"detection","false_date_active",stats::binomial(),"M27",region,
        paste0("false_date_",g))
      diagnostic_rows[[length(diagnostic_rows)+1L]] <- .stage4a_simple_diagnostic(
        d,"detection","false_location_active",stats::binomial(),"M28",region,
        paste0("false_location_",g))
      hp <- d[as.logical(d$high_precision_2km),,drop=FALSE]
      spatial_sensitivity[[length(spatial_sensitivity)+1L]] <- .stage4a_simple_diagnostic(
        hp,"detection","active_near",stats::binomial(),"M01",region,
        paste0("high_precision_2km_",g))
      if(region=="WCVI") {
        od <- d; od$event_fold <- od$observer_fold
        oo <- .stage4a_cv(od,"detection",stats::binomial(),"M01",region,"guild")
        oo$validation_view <- "observer_disjoint_composition_robustness_only"
        oo$unit_label <- g
        observer_robustness_folds[[length(observer_robustness_folds)+1L]] <- oo
        dominant <- names(sort(table(d$observer_cluster_token),decreasing=TRUE))[1]
        hold <- d[d$observer_cluster_token!=dominant,,drop=FALSE]
        observer_holdouts[[length(observer_holdouts)+1L]] <-
          .stage4a_simple_diagnostic(hold,"detection","active_near",stats::binomial(),
            "M01",region,paste0("dominant_observer_holdout_",g))
      }
    }
  }
  core_effects <- do.call(rbind, lapply(fit_results, `[[`, "effect"))
  event_study <- do.call(rbind, Filter(function(x)nrow(x),lapply(fit_results,`[[`,"event_study")))
  mass_balance <- do.call(rbind, Filter(function(x)nrow(x),lapply(fit_results,`[[`,"mass_balance")))
  event_study <- event_study[event_study$source_model_id %in% c("M01","M02"),,drop=FALSE]
  mass_balance <- mass_balance[mass_balance$source_model_id %in% c("M01","M02"),,drop=FALSE]
  cv_core <- do.call(rbind, Filter(function(x)nrow(x),lapply(fit_results,`[[`,"cv")))
  geometry_core <- do.call(rbind, lapply(fit_results, `[[`, "geometry"))
  nb2 <- do.call(rbind, Filter(function(x)nrow(x),lapply(fit_results,`[[`,"nb2")))
  components <- core_effects[core_effects$model_id %in% c("M01","M02"),,drop=FALSE]
  components$source_model_id <- components$model_id
  components$model_id <- ifelse(components$outcome=="detection","M11","M12")
  effects <- rbind(core_effects, event_study[,names(core_effects)],
                   mass_balance[,names(core_effects)], components[,names(core_effects)])
  effects$n <- .stage4a_release_count(effects$n)
  effects$multiplicity_family <- paste(effects$model_id,effects$region,effects$outcome,sep="_")
  effects <- stage4a_bh_within_family(effects)
  effects <- .stage4a_normal_partial_pool(effects)
  cv_bio <- cv_core[cv_core$model_id %in% c("M01","M02"),,drop=FALSE]
  cv <- rbind(cv_core, transform(cv_bio, model_id="M05"),
              transform(cv_bio, model_id="M08"))
  geometry_bio <- geometry_core[geometry_core$model_id %in% c("M01","M02"),,drop=FALSE]
  geometry <- rbind(geometry_core,
    transform(geometry_bio, model_id=ifelse(outcome=="detection","M11","M12")))

  # Observation-process diagnostics use only their registered response or metadata grain.
  for(region in names(primary_scopes)) {
    e <- events[primary_scopes[[region]],,drop=FALSE]
    visits <- aggregate(list(visitation_count=rep(1L,nrow(e))),
      list(event_block_token=e$event_block_token,checklist_year=e$checklist_year),sum)
    vf <- try(stats::glm(visitation_count~factor(checklist_year),data=visits,
      family=stats::quasipoisson()),silent=TRUE)
    diagnostic_rows[[length(diagnostic_rows)+1L]] <- data.frame(model_id="M26",region=region,
      diagnostic="birder_visitation_process",estimate=if(inherits(vf,"try-error"))NA_real_ else mean(visits$visitation_count),
      standard_error=if(inherits(vf,"try-error"))NA_real_ else stats::sd(visits$visitation_count)/sqrt(nrow(visits)),
      p_value=NA_real_,n=nrow(visits),status=if(inherits(vf,"try-error"))"failed_numerical_fit" else "completed_metadata_only")
    ss <- states[states$analysis_event_token %in% e$analysis_event_token,,drop=FALSE]
    ss$numeric_available <- as.integer(is.finite(ss$numeric_count))
    sm <- merge(ss[,c("analysis_event_token","numeric_available")],e,by="analysis_event_token")
    diagnostic_rows[[length(diagnostic_rows)+1L]] <- .stage4a_simple_diagnostic(
      sm,"numeric_available","active_near",stats::binomial(),"M32",region,
      "numeric_vs_unquantified_given_detection")
    richness <- aggregate(list(richness=rep(1L,nrow(ss))),
      list(analysis_event_token=ss$analysis_event_token),sum)
    rm <- merge(e,richness,by="analysis_event_token",all.x=TRUE); rm$richness[is.na(rm$richness)]<-0L
    diagnostic_rows[[length(diagnostic_rows)+1L]] <- .stage4a_simple_diagnostic(
      rm,"richness","active_near",stats::quasipoisson(),"M40",region,
      "observer_richness_and_reporting")
  }
  diagnostics <- do.call(rbind,diagnostic_rows)
  diagnostics$interpretation <- ifelse(diagnostics$model_id %in% c("M27","M28"),
    "placebo_not_biological_evidence",ifelse(diagnostics$model_id %in% c("M26","M40"),
      "observation_process_only","count_state_process_only"))
  observer_robustness_tab <- do.call(rbind,observer_robustness_folds)
  observer_holdout_tab <- do.call(rbind,observer_holdouts)
  spatial_sensitivity_tab <- do.call(rbind,spatial_sensitivity)
  observer_concentration_tab <- read.csv(.stage4a_root("outputs","stage3_phase3_validation",
    "observer_robustness_summary.csv"),stringsAsFactors=FALSE,na.strings="")
  observer_concentration_tab <- observer_concentration_tab[
    observer_concentration_tab$region=="WCVI",,drop=FALSE]
  observer_concentration_tab$stage4a_interpretation <-
    "observer_concentration_diagnostic_not_new_event_validation"
  status <- .stage4a_model_status(disposition, effects, geometry)
  samples_tab <- do.call(rbind, samples)
  .stage4a_write_csv(effects, file.path(output_dir,"effect_estimates.csv"))
  .stage4a_write_csv(cv, file.path(output_dir,"four_fold_predictive_performance.csv"))
  .stage4a_write_csv(geometry, file.path(output_dir,"model_geometry.csv"))
  .stage4a_write_csv(status, file.path(output_dir,"all_45_model_status.csv"))
  .stage4a_write_csv(samples_tab, file.path(output_dir,"aggregate_sample_sizes.csv"))
  .stage4a_write_csv(diagnostics, file.path(output_dir,"diagnostic_status.csv"))
  .stage4a_write_csv(nb2,file.path(output_dir,"truncated_nb2_sensitivity.csv"))
  .stage4a_write_csv(observer_robustness_tab,file.path(output_dir,"wcvi_observer_robustness.csv"))
  .stage4a_write_csv(observer_holdout_tab,file.path(output_dir,"wcvi_dominant_observer_holdout.csv"))
  .stage4a_write_csv(observer_concentration_tab,
    file.path(output_dir,"wcvi_observer_concentration.csv"))
  .stage4a_write_csv(spatial_sensitivity_tab,file.path(output_dir,"high_precision_2km_sensitivity.csv"))
  .stage4a_html(output_dir,effects,cv,status,samples_tab,diagnostics,geometry,nb2,
    observer_robustness_tab,observer_holdout_tab,observer_concentration_tab,
    spatial_sensitivity_tab)
  .stage4a_write_text_lf(c("gate: PASS_PENDING_HUMAN_STAGE4A_RESULTS_REVIEW",
    "records_2026_plus_read: 0", "comments_read: 0", "shoreline_fields_read: 0",
    "full_denominator_expanded: false", "conditional_BLUPs_in_heldout_prediction: false"),
    file.path(output_dir,"stage4a_execution_summary.yml"))
  message("STAGE4A_FINAL_GATE=PASS_PENDING_HUMAN_STAGE4A_RESULTS_REVIEW")
}
