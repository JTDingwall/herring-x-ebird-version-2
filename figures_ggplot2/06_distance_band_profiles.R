source(file.path("figures_ggplot2", "00_theme_mer.R"), local = TRUE)

x <- read_figure_csv("tableS_distance_bands_3species_stage2.csv", 468L)
assert_unique_key(
  x, c("analysis_taxon_id", "outcome", "band", "period"),
  "Stage 2 distance-band input"
)
plot_periods <- c(
  "early_pre", "immediate_pre", "spawn_start", "early_egg", "late_egg"
)
d <- x[period %chin% plot_periods]
if (nrow(d) != 390L ||
    uniqueN(d$analysis_taxon_id) != 3L ||
    uniqueN(d$outcome) != 2L ||
    uniqueN(d$band) != 13L) {
  stop("FIGURE5_CARDINALITY_GATE: expected 3 x 2 x 13 x 5 rows",
       call. = FALSE)
}
cell_counts <- d[, .N, by = .(analysis_taxon_id, outcome, period)]
if (any(cell_counts$N != 13L)) {
  stop("FIGURE5_BAND_GATE: every species-outcome-period needs 13 bands",
       call. = FALSE)
}
if (any(!grepl("^completed", d$status)) ||
    any(!is.finite(d$ratio)) ||
    any(!is.finite(d$ratio_conf_low)) ||
    any(!is.finite(d$ratio_conf_high)) ||
    any(d$ratio_conf_low <= 0)) {
  stop("FIGURE5_INTERVAL_GATE: all plotted rows require completed positive intervals",
       call. = FALSE)
}
robin_roles <- unique(d[unit_label == "American Robin", species_role])
if (!identical(robin_roles, "comparison_species")) {
  stop("FIGURE5_ROLE_GATE: American Robin must be comparison_species",
       call. = FALSE)
}

d[, band_midpoint := (minimum_day * 0) +
    as.numeric(sub("^band_([0-9]+)_([0-9]+)$", "\\1", band)) + 1]
d[, period_factor := factor(
  period, levels = plot_periods,
  labels = c(
    "Early pre (-14 to -8 d)",
    "Immediate pre (-7 to -1 d)",
    "Spawn start (0 to 3 d)",
    "Early egg (4 to 14 d)",
    "Late egg (15 to 28 d)"
  )
)]
d[, outcome_label := factor(
  outcome_labels[outcome], levels = unname(outcome_labels)
)]
d[, species_label := fifelse(
  unit_label == "American Robin",
  "American Robin - comparison species", unit_label
)]
d[, species_label := factor(
  species_label,
  levels = c(
    "Bald Eagle", "Glaucous-winged Gull",
    "American Robin - comparison species"
  )
)]

period_colours <- c(
  "Early pre (-14 to -8 d)" = muted,
  "Immediate pre (-7 to -1 d)" = warm_grey,
  "Spawn start (0 to 3 d)" = gold,
  "Early egg (4 to 14 d)" = marine,
  "Late egg (15 to 28 d)" = ink
)
period_linetypes <- c("33", "13", "solid", "solid", "longdash")
names(period_linetypes) <- names(period_colours)

p5 <- ggplot(
  d,
  aes(
    x = band_midpoint, y = ratio, group = period_factor,
    colour = period_factor, fill = period_factor, linetype = period_factor
  )
) +
  geom_hline(yintercept = 1, colour = muted, linewidth = 0.42,
             linetype = "dashed") +
  geom_ribbon(
    aes(ymin = ratio_conf_low, ymax = ratio_conf_high),
    colour = NA, alpha = 0.055
  ) +
  geom_line(linewidth = 0.68) +
  geom_point(size = 1.35, stroke = 0) +
  facet_grid(
    rows = vars(species_label), cols = vars(outcome_label),
    scales = "free_y"
  ) +
  scale_x_continuous(
    breaks = seq(1, 25, by = 2),
    labels = paste0(seq(0, 24, by = 2), "-", seq(2, 26, by = 2))
  ) +
  scale_y_log10() +
  scale_colour_manual(values = period_colours) +
  scale_fill_manual(values = period_colours) +
  scale_linetype_manual(values = period_linetypes) +
  labs(
    title = "Event-time profiles across 2-km distance bands",
    subtitle = "Bald Eagle and Glaucous-winged Gull are focal waterbirds; American Robin is a comparison species, not a negative control.",
    x = "Distance band (km)",
    y = "Same-band ratio to baseline (log scale)",
    caption = paste0(
      "Each band has its own days -28 to -15 reference, so comparisons are within band rather than between bands. ",
      "Translucent ribbons are 95% confidence intervals."
    )
  ) +
  theme_mer(9.2) +
  theme(
    panel.grid.major.y = element_line(colour = grid, linewidth = 0.28),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 6.7),
    legend.position = "top",
    panel.spacing = grid::unit(0.85, "lines")
  )

save_figure(p5, "Figure_5_distance_band_profiles_stage2", 12.2, 10.4)
