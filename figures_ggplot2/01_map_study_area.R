source(file.path("figures_ggplot2", "00_theme_mer.R"), local = TRUE)

p <- ggplot() +
  annotate(
    "rect", xmin = 0, xmax = 10, ymin = 0, ymax = 6,
    fill = "white", colour = marine, linewidth = 0.9
  ) +
  annotate(
    "rect", xmin = 0.35, xmax = 9.65, ymin = 0.35, ymax = 5.65,
    fill = marine_light, colour = NA, alpha = 0.28
  ) +
  annotate(
    "text", x = 5, y = 3.55, label = "AUTHOR-SUPPLIED STUDY-AREA MAP",
    family = "sans", fontface = "bold", colour = ink, size = 5
  ) +
  annotate(
    "text", x = 5, y = 2.55,
    label = paste(
      "Placeholder only - no locality or coordinate data are rendered.",
      "Replace with the approved publication map before submission.",
      sep = "\n"
    ),
    family = "sans", colour = muted, size = 3.7, lineheight = 1.2
  ) +
  coord_cartesian(xlim = c(0, 10), ylim = c(0, 6), expand = FALSE) +
  theme_void(base_family = "sans") +
  theme(
    plot.background = element_rect(fill = "white", colour = NA),
    plot.margin = margin(14, 14, 14, 14)
  )

save_figure(p, "Study_area_map_author_placeholder", 8.5, 5.2)
