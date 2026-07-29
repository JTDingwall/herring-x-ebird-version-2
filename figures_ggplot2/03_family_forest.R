source(file.path("figures_ggplot2", "00_theme_mer.R"), local = TRUE)

x <- read_figure_csv("tableS_primary_contrast_49x2_stage2.csv", 98L)
required <- c(
  "species", "outcome", "ratio", "ratio_conf_low", "ratio_conf_high",
  "q_value", "n", "status"
)
if (!all(required %in% names(x))) {
  stop("FIGURE2_SCHEMA_GATE: missing required columns", call. = FALSE)
}
assert_unique_key(x, c("species", "outcome"), "Figure 2 input")
if (uniqueN(x$species) != 49L ||
    !setequal(unique(x$outcome), names(outcome_labels))) {
  stop("FIGURE2_FAMILY_GATE: expected 49 species x two outcomes",
       call. = FALSE)
}

x[, estimable := grepl("^completed", status)]
x[, positive_bh_survivor :=
    estimable & !is.na(q_value) & q_value < 0.05 & ratio > 1]
survivors <- x[, .(survivors = sum(positive_bh_survivor)), by = outcome]
expected <- data.table(
  outcome = c(
    "checklist_reporting", "conditional_positive_numeric_count"
  ),
  survivors = c(13L, 20L)
)
setkey(survivors, outcome)
setkey(expected, outcome)
if (!identical(survivors[expected]$survivors, expected$survivors)) {
  stop(
    "FIGURE2_SURVIVOR_GATE: required 13 reporting and 20 count survivors; ",
    paste(survivors$outcome, survivors$survivors, sep = "=", collapse = ", "),
    call. = FALSE
  )
}

x[, species_factor := factor(species, levels = rev(sort(unique(species))))]
x[, outcome_label := factor(
  outcome_labels[outcome],
  levels = unname(outcome_labels)
)]
finite <- x[
  estimable & is.finite(ratio) & is.finite(ratio_conf_low) &
    is.finite(ratio_conf_high) & ratio > 0 & ratio_conf_low > 0 &
    ratio_conf_high > 0
]
if (nrow(finite) != sum(x$estimable)) {
  stop("FIGURE2_INTERVAL_GATE: estimable rows require finite positive intervals",
       call. = FALSE)
}
labels <- survivors[, .(
  outcome_label = factor(outcome_labels[outcome], levels = unname(outcome_labels)),
  label = paste0(survivors, " positive BH survivors")
)]

p <- ggplot(finite, aes(y = species_factor, colour = outcome)) +
  geom_vline(xintercept = 1, colour = muted, linewidth = 0.5, linetype = "dashed") +
  geom_segment(
    aes(x = ratio_conf_low, xend = ratio_conf_high,
        yend = species_factor),
    linewidth = 0.52, alpha = 0.72
  ) +
  geom_point(
    aes(x = ratio, shape = outcome),
    fill = "white", size = 2.15, stroke = 0.75
  ) +
  geom_point(
    data = finite[positive_bh_survivor == TRUE],
    aes(x = ratio, shape = outcome, fill = outcome),
    size = 2.45, stroke = 0.75
  ) +
  geom_text(
    data = labels,
    aes(x = Inf, y = Inf, label = label),
    inherit.aes = FALSE, hjust = 1.08, vjust = 1.25,
    colour = muted, family = "sans", size = 3.0
  ) +
  facet_grid(cols = vars(outcome_label)) +
  scale_x_log10() +
  scale_colour_manual(values = outcome_colours, guide = "none") +
  scale_fill_manual(values = outcome_colours, guide = "none") +
  scale_shape_manual(values = outcome_shapes, guide = "none") +
  labs(
    title = "Active-period change for all 49 species",
    subtitle = paste0(
      "Duration-weighted days 0-14 versus the preceding 14 days, per additional recorded event link.\n",
      "Filled points are positive BH survivors (q < 0.05); open points include non-survivors and adjusted decreases."
    ),
    x = "Ratio (95% confidence interval; log scale)",
    y = NULL,
    caption = paste0(
      "No point is drawn for a non-estimable component. The fixed Stage 2 family contains 49 species per outcome.\n",
      "Two negative checklist-reporting estimates have q < 0.05 but remain open under the requested positive-survivor convention."
    )
  ) +
  theme_mer(9.2) +
  theme(
    axis.text.y = element_text(size = 7.1),
    panel.spacing.x = grid::unit(1.0, "lines"),
    panel.grid.major.y = element_line(colour = light_grey, linewidth = 0.25),
    legend.position = "none"
  )

save_figure(p, "Figure_2_family_forest_stage2", 11.2, 13.2)
message(
  "FIGURE2_SURVIVORS=checklist_reporting:13,",
  "conditional_positive_numeric_count:20"
)
