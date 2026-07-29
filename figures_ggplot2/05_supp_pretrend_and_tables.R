source(file.path("figures_ggplot2", "00_theme_mer.R"), local = TRUE)

x <- read_figure_csv("tableS_period_profiles_49x2_stage2.csv", 686L)
assert_unique_key(
  x, c("analysis_taxon_id", "outcome", "contrast"),
  "Stage 2 period-profile input"
)

pre_contrasts <- c("did_early_pre", "did_immediate_pre")
pre <- x[contrast %chin% pre_contrasts & grepl("^completed", status)]
expected_rows <- 2L * (49L + 46L)
if (nrow(pre) != expected_rows) {
  stop("FIGURES1_CARDINALITY_GATE: expected 190 estimable pretrend rows; found ",
       nrow(pre), call. = FALSE)
}
if (any(!is.finite(pre$ratio)) || any(pre$ratio <= 0)) {
  stop("FIGURES1_RATIO_GATE: pretrend ratios must be finite and positive",
       call. = FALSE)
}
pre[, period := factor(
  contrast, levels = pre_contrasts,
  labels = unname(period_labels[pre_contrasts])
)]
pre[, outcome_label := factor(
  outcome_labels[outcome], levels = unname(outcome_labels)
)]
pre[, bh_survivor := !is.na(q_value) & q_value < 0.05]

summary <- pre[, .(
  estimable_species = .N,
  median_ratio = median(ratio),
  minimum_ratio = min(ratio),
  maximum_ratio = max(ratio),
  bh_survivors = sum(bh_survivor)
), by = .(outcome, contrast)]
summary[, outcome_label := outcome_labels[outcome]]
summary[, period := factor(
  contrast, levels = pre_contrasts,
  labels = unname(period_labels[pre_contrasts])
)]
summary[, annotation := sprintf(
  "median %.3f\nBH %d", median_ratio, bh_survivors
)]

pS1 <- ggplot(pre, aes(x = period, y = ratio, colour = outcome)) +
  geom_hline(yintercept = 1, colour = muted, linewidth = 0.5,
             linetype = "dashed") +
  geom_point(
    aes(shape = outcome), fill = "white", size = 2.0, stroke = 0.70,
    alpha = 0.82,
    position = position_jitter(width = 0.13, height = 0, seed = 20260729)
  ) +
  geom_point(
    data = pre[bh_survivor == TRUE],
    aes(shape = outcome, fill = outcome), size = 2.25, stroke = 0.70,
    position = position_jitter(width = 0.13, height = 0, seed = 20260729)
  ) +
  geom_point(
    data = summary, aes(x = period, y = median_ratio),
    inherit.aes = FALSE, shape = 23, size = 3.3,
    fill = ink, colour = "white", stroke = 0.55
  ) +
  geom_text(
    data = summary,
    aes(x = period, y = Inf, label = annotation),
    inherit.aes = FALSE, vjust = 1.15, colour = muted,
    family = "sans", size = 3.0, lineheight = 0.95
  ) +
  facet_grid(cols = vars(outcome_label), scales = "free_y") +
  scale_y_log10() +
  scale_colour_manual(values = outcome_colours, guide = "none") +
  scale_fill_manual(values = outcome_colours, guide = "none") +
  scale_shape_manual(values = outcome_shapes, guide = "none") +
  labs(
    title = "Pre-onset windows against the baseline",
    subtitle = "Each point is one estimable species; diamonds are medians and filled points have BH q < 0.05.",
    x = NULL,
    y = "Ratio to days -28 to -15 baseline (log scale)",
    caption = "The reference line at one means no drift in the near/reference gap before recorded onset."
  ) +
  theme_mer(10.0) +
  theme(
    legend.position = "none",
    panel.grid.major.y = element_line(colour = grid, linewidth = 0.30),
    panel.grid.major.x = element_blank()
  )

save_figure(pS1, "Figure_S1_pretrend_stage2", 9.4, 5.7)

profile_contrasts <- c(
  "did_pre_14_day", "did_spawn_start", "did_early_egg",
  "did_late_egg", "did_active_0_14_day"
)
count <- x[
  outcome == "conditional_positive_numeric_count" &
    contrast %chin% profile_contrasts &
    grepl("^completed", status)
]
if (nrow(count) != 46L * 5L || uniqueN(count$species) != 46L) {
  stop("FIGURES2_CARDINALITY_GATE: expected 46 x 5 count profile rows",
       call. = FALSE)
}
wide <- dcast(count, species ~ contrast, value.var = "ratio")
if (anyNA(wide[, ..profile_contrasts])) {
  stop("FIGURES2_MATRIX_GATE: incomplete species-period matrix",
       call. = FALSE)
}
matrix_values <- as.matrix(wide[, ..profile_contrasts])
rownames(matrix_values) <- wide$species
cluster <- hclust(dist(log(matrix_values)), method = "ward.D2")
species_order <- rownames(matrix_values)[cluster$order]
count[, species_factor := factor(species, levels = rev(species_order))]
count[, period := factor(
  contrast, levels = profile_contrasts,
  labels = unname(period_labels[profile_contrasts])
)]
count[, log_ratio := log(ratio)]
limit <- max(abs(count$log_ratio), na.rm = TRUE)

pS2 <- ggplot(count, aes(x = period, y = species_factor, fill = log_ratio)) +
  geom_tile(colour = "white", linewidth = 0.28) +
  scale_fill_steps2(
    low = gold_light, mid = "white", high = marine,
    midpoint = 0, limits = c(-limit, limit),
    n.breaks = 7, name = "Log ratio"
  ) +
  labs(
    title = "Complete reported-number response profiles",
    subtitle = "All 46 species with an estimable count model across four event periods and the active composite.",
    x = NULL,
    y = NULL,
    caption = "Row order is a display aid from Ward.D2 linkage on log ratios; no clusters were cut, selected, or tested."
  ) +
  theme_mer(9.0) +
  theme(
    panel.grid = element_blank(),
    axis.text.y = element_text(size = 7.0),
    axis.text.x = element_text(size = 7.8, lineheight = 0.92),
    legend.position = "top",
    legend.key.width = grid::unit(1.6, "cm")
  )

save_figure(pS2, "Figure_S2_count_profiles_stage2", 8.8, 12.5)

summary_out <- summary[, .(
  outcome, contrast, estimable_species, median_ratio,
  minimum_ratio, maximum_ratio, bh_survivors
)]
fwrite(
  summary_out,
  mer_path("figures_out", "tableS_pretrend_summary_stage2.csv"),
  na = ""
)
message("SUPPLEMENTARY_PRETREND_TABLE=PASS ROWS=", nrow(summary_out))
