source(file.path("figures_ggplot2", "00_theme_mer.R"), local = TRUE)

x <- read_figure_csv("tableS_period_profiles_49x2_stage2.csv", 686L)
assert_unique_key(
  x, c("analysis_taxon_id", "outcome", "contrast"),
  "Stage 2 period-profile input"
)

focal_species <- c(
  "Surf Scoter", "White-winged Scoter", "Harlequin Duck",
  "Common Merganser", "Glaucous-winged Gull", "Short-billed Gull",
  "Bald Eagle", "American Wigeon"
)
profile_contrasts <- c(
  "did_pre_14_day", "did_spawn_start", "did_early_egg", "did_late_egg"
)
distribution_contrasts <- c(
  profile_contrasts, "did_active_0_14_day"
)

focal <- x[
  species %chin% focal_species & contrast %chin% profile_contrasts
]
if (nrow(focal) != 64L ||
    uniqueN(focal$species) != 8L ||
    uniqueN(focal$outcome) != 2L ||
    any(!grepl("^completed", focal$status))) {
  stop("FIGURE3_CARDINALITY_GATE: expected 8 x 2 x 4 estimable profiles",
       call. = FALSE)
}
if (any(!is.finite(focal$ratio)) ||
    any(!is.finite(focal$ratio_conf_low)) ||
    any(!is.finite(focal$ratio_conf_high)) ||
    any(focal$ratio_conf_low <= 0)) {
  stop("FIGURE3_INTERVAL_GATE: invalid ratio or interval", call. = FALSE)
}
focal[, period := factor(
  contrast, levels = profile_contrasts,
  labels = unname(period_labels[profile_contrasts])
)]
focal[, species := factor(species, levels = focal_species)]
focal[, outcome_label := outcome_labels[outcome]]
dodge <- position_dodge(width = 0.17)

p3 <- ggplot(
  focal,
  aes(
    x = period, y = ratio, group = outcome,
    colour = outcome, linetype = outcome, shape = outcome
  )
) +
  geom_hline(yintercept = 1, colour = muted, linewidth = 0.45,
             linetype = "dashed") +
  geom_errorbar(
    aes(ymin = ratio_conf_low, ymax = ratio_conf_high),
    width = 0.08, linewidth = 0.42, alpha = 0.60, position = dodge
  ) +
  geom_line(linewidth = 0.65, position = dodge) +
  geom_point(
    aes(fill = outcome), size = 2.15, stroke = 0.70, position = dodge
  ) +
  facet_wrap(vars(species), ncol = 2, scales = "free_y") +
  scale_y_log10() +
  scale_colour_manual(values = outcome_colours, labels = outcome_labels) +
  scale_fill_manual(
    values = c(
      checklist_reporting = "white",
      conditional_positive_numeric_count = gold
    ),
    labels = outcome_labels
  ) +
  scale_shape_manual(values = outcome_shapes, labels = outcome_labels) +
  scale_linetype_manual(values = outcome_linetypes, labels = outcome_labels) +
  labs(
    title = "Species-specific change through event time",
    subtitle = "Eight species span the prespecified feeding groups; intervals are 95% confidence intervals.",
    x = NULL,
    y = "Ratio to days -28 to -15 baseline (log scale)",
    caption = paste0(
      "Reporting is shown by blue dashed lines and open squares; reported number by ochre solid lines and circles. ",
      "These profiles describe timing; Figure 2 contains the formal active-minus-pre contrast."
    )
  ) +
  theme_mer(9.6) +
  theme(
    panel.grid.major.y = element_line(colour = grid, linewidth = 0.30),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 7.3, lineheight = 0.92),
    panel.spacing = grid::unit(0.9, "lines")
  )

save_figure(p3, "Figure_3_period_profiles_stage2", 10.8, 12.2)

count <- x[
  outcome == "conditional_positive_numeric_count" &
    contrast %chin% distribution_contrasts &
    grepl("^completed", status)
]
if (uniqueN(count$species) != 46L ||
    nrow(count) != 46L * length(distribution_contrasts)) {
  stop("FIGURE4_CARDINALITY_GATE: expected 46 x 5 estimable count rows",
       call. = FALSE)
}
if (any(!is.finite(count$ratio)) || any(count$ratio <= 0)) {
  stop("FIGURE4_RATIO_GATE: count ratios must be finite and positive",
       call. = FALSE)
}
count[, period := factor(
  contrast, levels = distribution_contrasts,
  labels = unname(period_labels[distribution_contrasts])
)]
means <- count[, .(ratio = mean(ratio)), by = period]

p4 <- ggplot(count, aes(x = period, y = ratio)) +
  geom_hline(yintercept = 1, colour = muted, linewidth = 0.5,
             linetype = "dashed") +
  geom_boxplot(
    width = 0.54, outlier.shape = NA, fill = "white",
    colour = marine, linewidth = 0.65
  ) +
  geom_point(
    colour = gold, fill = gold_light, shape = 21, stroke = 0.45,
    size = 1.75, alpha = 0.78,
    position = position_jitter(width = 0.12, height = 0, seed = 20260729)
  ) +
  geom_point(
    data = means, aes(x = period, y = ratio),
    inherit.aes = FALSE, shape = 23, size = 3.15,
    fill = gold, colour = ink, stroke = 0.65
  ) +
  scale_y_log10() +
  labs(
    title = "Reported-number ratios across event periods",
    subtitle = "One point per species for the 46 estimable count models; diamonds mark arithmetic means.",
    x = NULL,
    y = "Ratio to days -28 to -15 baseline (log scale)",
    caption = "The active-period box is the duration-weighted composite of spawn start and early egg availability, not a sixth period."
  ) +
  theme_mer(10.3) +
  theme(
    legend.position = "none",
    panel.grid.major.y = element_line(colour = grid, linewidth = 0.30),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 8.4, lineheight = 0.95)
  )

save_figure(p4, "Figure_4_count_period_distribution_stage2", 9.4, 6.1)
