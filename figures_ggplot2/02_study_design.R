source(file.path("figures_ggplot2", "00_theme_mer.R"), local = TRUE)

boxes <- data.table(
  x = c(1.0, 3.2, 5.4, 7.6, 9.8, 9.8),
  y = c(4.2, 4.2, 4.2, 4.2, 5.15, 3.25),
  label = c(
    "Recorded herring\nspawn onset",
    "Complete eBird\nchecklists",
    "Concurrent additive\nexposure links",
    "Event-anchored\nnear/reference model",
    "Checklist\nreporting",
    "Reported\nnumber"
  ),
  fill = c(marine_light, "white", marine_light, "white", marine_light, gold_light)
)

arrows <- data.table(
  x = c(1.65, 3.85, 6.05, 8.25, 8.25),
  xend = c(2.55, 4.75, 6.95, 9.10, 9.10),
  y = c(4.2, 4.2, 4.2, 4.2, 4.2),
  yend = c(4.2, 4.2, 4.2, 5.15, 3.25)
)

p <- ggplot() +
  geom_segment(
    data = arrows,
    aes(x = x, xend = xend, y = y, yend = yend),
    colour = muted, linewidth = 0.75,
    arrow = grid::arrow(length = grid::unit(0.14, "inches"), type = "closed")
  ) +
  geom_label(
    data = boxes, aes(x = x, y = y, label = label, fill = fill),
    colour = ink, linewidth = 0.45, label.padding = grid::unit(0.18, "lines"),
    label.r = grid::unit(0.10, "lines"), family = "sans", fontface = "bold",
    size = 3.5
  ) +
  scale_fill_identity() +
  annotate(
    "text", x = 5.4, y = 2.2,
    label = "Baseline: days -28 to -15     |     Pre-onset: days -14 to -1     |     Active: days 0 to 14",
    colour = muted, family = "sans", size = 3.4
  ) +
  annotate(
    "segment", x = 5.4, xend = 5.4, y = 3.35, yend = 2.65,
    colour = muted, linewidth = 0.55,
    arrow = grid::arrow(length = grid::unit(0.11, "inches"), type = "closed")
  ) +
  annotate(
    "label", x = 5.4, y = 1.25,
    label = "Primary Stage 2 estimand:\nduration-weighted active period minus the preceding 14 days",
    fill = "white", colour = ink, linewidth = 0.45, family = "sans",
    fontface = "bold", size = 3.55
  ) +
  coord_cartesian(xlim = c(0.15, 10.65), ylim = c(0.35, 6.1), clip = "off") +
  labs(
    title = "Event-anchored study design",
    subtitle = "The same exposure design feeds separate reporting and reported-number models; no estimates are shown."
  ) +
  theme_void(base_family = "sans") +
  theme(
    plot.background = element_rect(fill = "white", colour = NA),
    plot.title = element_text(
      colour = ink, face = "bold", size = 15, hjust = 0,
      margin = margin(b = 5)
    ),
    plot.subtitle = element_text(
      colour = muted, size = 10.5, hjust = 0, margin = margin(b = 10)
    ),
    plot.margin = margin(18, 18, 18, 18)
  )

save_figure(p, "Figure_1_study_design_stage2", 11.5, 6.8)
