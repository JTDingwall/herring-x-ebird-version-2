#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[[1L]] else "."
root <- normalizePath(root, winslash = "/", mustWork = TRUE)
path <- function(...) file.path(root, ...)

journal_root <- path("manuscript", "journal_submission", "marine_environmental_research")
figure_dir <- file.path(journal_root, "figures")
source_dir <- file.path(journal_root, "source_artwork")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)

ink <- "#26343D"
muted <- "#66747D"
grid <- "#D9E0E3"
marine <- "#2B6F8A"
marine_light <- "#C7DEE7"
gold <- "#C58B2A"
gold_light <- "#F1DFB5"
warm_grey <- "#8A8178"
light_grey <- "#E8ECEE"

theme_mer <- function(base_size = 10.5) {
  theme_minimal(base_family = "sans", base_size = base_size) +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      plot.title = element_text(colour = ink, face = "bold", size = rel(1.35),
                                hjust = 0, margin = margin(b = 5)),
      plot.subtitle = element_text(colour = muted, size = rel(0.95), hjust = 0,
                                   margin = margin(b = 12), lineheight = 1.08),
      plot.caption = element_text(colour = muted, size = rel(0.80), hjust = 0,
                                  margin = margin(t = 10)),
      axis.title = element_text(colour = ink, face = "plain"),
      axis.text = element_text(colour = ink),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_line(colour = grid, linewidth = 0.35),
      strip.text = element_text(colour = ink, face = "bold", size = rel(1.03),
                                hjust = 0),
      strip.background = element_blank(),
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_blank(),
      legend.text = element_text(colour = ink),
      plot.margin = margin(14, 18, 14, 14)
    )
}

guild_labels <- c(
  alcid_piscivore = "Alcid piscivores",
  falsification = "Specificity guild",
  gull_roe = "Gulls associated with roe",
  intertidal_roe_shorebird = "Intertidal shorebirds",
  piscivore_active_spawn = "Active-spawn piscivores",
  roe_diving_seaduck = "Roe-feeding diving seaducks",
  shoreline_scavenger = "Shoreline scavengers",
  surface_vegetation_roe = "Surface/vegetation roe feeders"
)
guild_order <- names(guild_labels)

outcome_labels <- c(
  detection = "Detection",
  positive_count = "Conditional positive count",
  positive_numeric_count_given_detection = "Conditional positive count"
)

model_labels <- c(
  M01_PRIMARY_v2 = "Matched primary",
  S4A12_WCVI_2KM_v2 = "2-km cohort",
  S4A11_WCVI_DOMINANT_OBSERVER_v2 = "Observer holdout",
  M27_v2 = "Date-shift placebo",
  M28_v2 = "Location-shift placebo"
)

read_checked <- function(rel, expected_rows = NULL) {
  x <- fread(path(rel))
  if (!is.null(expected_rows) && nrow(x) != expected_rows) {
    stop(rel, ": expected ", expected_rows, " rows, found ", nrow(x))
  }
  x
}

save_figure <- function(plot, stem, width, height, dpi = 400) {
  png_path <- file.path(figure_dir, paste0(stem, ".png"))
  svg_path <- file.path(source_dir, paste0(stem, ".svg"))
  ggsave(png_path, plot = plot, width = width, height = height, units = "in",
         dpi = dpi, bg = "white", limitsize = FALSE)
  ggsave(svg_path, plot = plot, width = width, height = height, units = "in",
         device = grDevices::svg, bg = "white", limitsize = FALSE)
  if (!file.exists(png_path) || file.info(png_path)$size <= 0L ||
      !file.exists(svg_path) || file.info(svg_path)$size <= 0L) {
    stop("Figure export failed: ", stem)
  }
}

primary <- read_checked("outputs/stage4a_publication_v2/primary_guild_table_v2.csv", 32L)
species <- read_checked("outputs/stage4a_publication_v2/priority_a_species_table_v2.csv", 20L)
all_species <- read_checked("outputs/stage4a_results/effect_estimates.csv")
all_species <- all_species[
  model_id == "M02" & region %in% c("SoG", "WCVI") &
    contrast == "active_near" & unit_class == "species"
]
if (nrow(all_species) != 196L || uniqueN(all_species$unit_label) != 49L) {
  stop("M02 species accounting failed: expected 196 rows for 49 taxa")
}
if (all_species[, anyDuplicated(.SD), .SDcols = c("region", "unit_label", "outcome")]) {
  stop("M02 species keys are not unique")
}
event <- read_checked("outputs/stage4a_publication_v2/event_time_table_v2.csv", 160L)
sensitivity <- read_checked("outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv", 128L)
exclusion <- read_checked("outputs/stage4a_publication_v2/supplementary_exclusion_summary_v2.csv", 3L)
families <- read_checked("outputs/stage4a_publication_v2/supplementary_family_table_v2.csv", 162L)
diagnostics <- read_checked("outputs/stage4a_publication_v2/model_diagnostic_summary_v2.csv")
m29 <- read_checked(paste0(
  "manuscript/journal_submission/marine_environmental_research/audits/",
  "sog_m29_audit_v2.csv"), 2L)

# Figure 1: a science-first conceptual design built entirely with ggplot2.
windows <- data.table(
  xmin = 0:4, xmax = 1:5,
  label = c("Immediate\npre", "Spawn\nstart", "Early\negg", "Late\negg", "Post"),
  fill = c(light_grey, gold, gold_light, "#E7D8A1", light_grey)
)
coast <- data.table(x = seq(0.35, 3.65, length.out = 100))
coast[, y := 6.45 + 0.18 * sin((x - 0.25) * 2.1)]
pulse <- data.table(x = seq(0.15, 4.85, length.out = 180))
pulse[, y := 2.40 + 0.48 * exp(-0.5 * ((x - 2.25) / 0.72)^2)]

p1 <- ggplot() +
  annotate("text", x = 0.10, y = 7.60, label = "A", family = "sans", fontface = "bold",
           size = 5.0, colour = marine, hjust = 0) +
  annotate("text", x = 0.42, y = 7.60, label = "A short, local resource pulse",
           family = "sans", fontface = "bold", size = 5.0, colour = ink, hjust = 0) +
  annotate("rect", xmin = 0.35, xmax = 3.65, ymin = 5.55, ymax = 6.30,
           fill = marine_light, colour = NA) +
  geom_line(data = coast, aes(x, y), colour = ink, linewidth = 1.1) +
  annotate("point", x = c(1.45, 1.85, 2.25, 2.65), y = c(6.57, 6.66, 6.59, 6.70),
           shape = 21, size = 4.2, stroke = 0.6, fill = gold, colour = "white") +
  annotate("text", x = 2.00, y = 5.90, label = "recorded spawn and deposited eggs",
           family = "sans", size = 3.4, colour = ink) +
  annotate("text", x = 2.00, y = 5.43,
           label = "spatially patchy | short-lived | incompletely monitored",
           family = "sans", size = 3.0, colour = muted) +
  annotate("segment", x = 3.95, xend = 4.75, y = 6.28, yend = 6.28,
           colour = muted, linewidth = 0.8,
           arrow = grid::arrow(length = grid::unit(0.13, "in"), type = "closed")) +
  annotate("text", x = 5.00, y = 7.60, label = "B", family = "sans", fontface = "bold",
           size = 5.0, colour = marine, hjust = 0) +
  annotate("text", x = 5.32, y = 7.60, label = "Event-linked complete checklists",
           family = "sans", fontface = "bold", size = 4.6, colour = ink, hjust = 0) +
  annotate("rect", xmin = 5.10, xmax = 6.75, ymin = 6.00, ymax = 6.72,
           fill = marine_light, colour = marine, linewidth = 0.55) +
  annotate("rect", xmin = 7.05, xmax = 8.70, ymin = 6.00, ymax = 6.72,
           fill = "white", colour = warm_grey, linewidth = 0.55) +
  annotate("text", x = 5.925, y = 6.46, label = "NEAR",
           family = "sans", fontface = "bold", size = 4.0, colour = ink) +
  annotate("text", x = 5.925, y = 6.20, label = "recorded spawn",
           family = "sans", size = 3.0, colour = muted) +
  annotate("text", x = 7.875, y = 6.46, label = "REFERENCE",
           family = "sans", fontface = "bold", size = 4.0, colour = ink) +
  annotate("text", x = 7.875, y = 6.20, label = "shoreline context",
           family = "sans", size = 3.0, colour = muted) +
  annotate("text", x = 6.90, y = 5.65,
           label = "Detection: was the taxon reported?\nConditional count: how many, given detection?",
           family = "sans", size = 3.15, lineheight = 1.20, colour = ink) +
  annotate("text", x = 6.90, y = 5.17,
           label = "Estimand: eligible submitted complete checklists",
           family = "sans", size = 2.9, colour = muted) +
  annotate("text", x = 9.48, y = 7.60, label = "C", family = "sans", fontface = "bold",
           size = 5.0, colour = marine, hjust = 0) +
  annotate("text", x = 9.80, y = 7.60, label = "Four biological predictions",
           family = "sans", fontface = "bold", size = 4.6, colour = ink, hjust = 0) +
  annotate("text", x = 9.58, y = 6.75,
           label = "H1  support-qualified species respond near spawn\nH2  responses concentrate in biological windows\nH3  focal patterns exceed the specificity panel\nH4  strongest directions recur across regions",
           family = "sans", size = 3.35, lineheight = 1.55, colour = ink, hjust = 0, vjust = 1) +
  annotate("text", x = 9.58, y = 5.18,
           label = "Predictions evaluated with registered analyses",
           family = "sans", size = 2.9, colour = muted, hjust = 0) +
  geom_rect(data = windows, aes(xmin = xmin + 0.35, xmax = xmax + 0.31,
                                ymin = 3.25, ymax = 3.70, fill = fill),
            colour = "white", linewidth = 0.35, show.legend = FALSE) +
  scale_fill_identity() +
  geom_line(data = pulse, aes(x = x + 0.35, y = y), colour = marine, linewidth = 1.05) +
  annotate("text", x = 0.35, y = 4.18, label = "Five registered biological windows",
           family = "sans", fontface = "bold", size = 4.0, colour = ink, hjust = 0) +
  geom_text(data = windows, aes(x = (xmin + xmax) / 2 + 0.33, y = 3.04, label = label),
            family = "sans", size = 2.85, lineheight = 0.95, colour = ink) +
  annotate("text", x = 6.25, y = 4.18, label = "Interpret the pattern, then test its specificity",
           family = "sans", fontface = "bold", size = 4.0, colour = ink, hjust = 0) +
  annotate("segment", x = 6.30, xend = 8.55, y = 3.48, yend = 3.48,
           colour = marine, linewidth = 1.1,
           arrow = grid::arrow(length = grid::unit(0.12, "in"), type = "closed")) +
  annotate("text", x = 6.30, y = 3.76, label = "49 species + guild synthesis",
           family = "sans", size = 3.35, colour = marine, hjust = 0) +
  annotate("text", x = 9.00, y = 3.48, label = "versus",
           family = "sans", size = 3.0, colour = muted) +
  annotate("segment", x = 9.45, xend = 11.70, y = 3.48, yend = 3.48,
           colour = gold, linewidth = 1.1,
           arrow = grid::arrow(length = grid::unit(0.12, "in"), type = "closed")) +
  annotate("text", x = 9.45, y = 3.76,
           label = "Gadwall + Northern Shoveler",
           family = "sans", size = 3.35, colour = gold, hjust = 0) +
  annotate("text", x = 6.25, y = 2.80,
           label = "A detectable local signature can coexist with\nheterogeneity and a broader shared checklist signal.",
           family = "sans", size = 3.2, lineheight = 1.15, colour = ink, hjust = 0) +
  coord_cartesian(xlim = c(0, 12.6), ylim = c(2.25, 7.92), clip = "off") +
  theme_void(base_family = "sans") +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(20, 24, 18, 20))
save_figure(p1, "Figure_1", 12, 7)

make_synthesis_forest <- function(x, title, subtitle, species_plot = FALSE) {
  d <- copy(x)
  d[, outcome_label := factor(outcome_labels[outcome],
                              levels = c("Detection", "Conditional positive count"))]
  d[, region := factor(region, levels = c("SoG", "WCVI"))]
  if (species_plot) {
    units <- sort(unique(d$unit_label))
    labels <- setNames(units, units)
  } else {
    units <- guild_order
    labels <- guild_labels
  }
  d[, unit_factor := factor(unit_label, levels = rev(units))]
  long <- rbindlist(list(
    d[, .(region, outcome_label, unit_factor, series = "Individual estimate",
          estimate, low = conf_low, high = conf_high)],
    d[, .(region, outcome_label, unit_factor, series = "Compatible-family synthesis",
          estimate = partial_pool_estimate_v2, low = partial_pool_conf_low_v2,
          high = partial_pool_conf_high_v2)]
  ))
  dodge <- position_dodge(width = 0.52)
  ggplot(long, aes(x = estimate, y = unit_factor, colour = series, shape = series)) +
    geom_vline(xintercept = 0, colour = muted, linewidth = 0.45, linetype = "dashed") +
    geom_errorbar(aes(xmin = low, xmax = high), orientation = "y", width = 0,
                  linewidth = 0.65, position = dodge) +
    geom_point(size = 2.35, stroke = 0.75, position = dodge) +
    facet_grid(rows = vars(outcome_label), cols = vars(region), scales = "free_x") +
    scale_colour_manual(values = c("Individual estimate" = marine,
                                   "Compatible-family synthesis" = gold)) +
    scale_shape_manual(values = c("Individual estimate" = 21,
                                  "Compatible-family synthesis" = 18)) +
    scale_y_discrete(labels = labels) +
    labs(title = title, subtitle = subtitle, x = "Adjusted coefficient (95% interval)", y = NULL) +
    theme_mer(if (species_plot) 9.4 else 10.2) +
    theme(legend.position = "top", panel.spacing = grid::unit(1.0, "lines"),
          axis.text.y = element_text(size = rel(if (species_plot) 0.88 else 0.95)))
}

# Figure 2: complete, outcome-blind display of every support-qualified M02 taxon.
# Alphabetical ordering prevents the figure hierarchy from being selected by effect size,
# significance, or prior literature prominence.
all_species[, `:=`(
  taxon = factor(unit_label, levels = rev(sort(unique(unit_label)))),
  column = factor(
    paste(region, outcome, sep = "__"),
    levels = c("SoG__detection", "SoG__positive_count",
               "WCVI__detection", "WCVI__positive_count"),
    labels = c("SoG\nDetection", "SoG\nConditional count",
               "WCVI\nDetection", "WCVI\nConditional count")
  ),
  completed = status %chin% c("completed", "completed_with_singular_warning"),
  significant = !is.na(q_value) & q_value < 0.05
)]
all_species[, tile_label := fifelse(
  completed,
  sprintf("%+.2f%s", estimate, fifelse(significant, "*", "")),
  "NA"
)]
p2 <- ggplot(all_species, aes(x = column, y = taxon, fill = estimate)) +
  geom_tile(aes(colour = significant), linewidth = 0.62, na.rm = FALSE) +
  geom_text(aes(label = tile_label), family = "sans", size = 2.15,
            colour = ink, fontface = ifelse(all_species$significant, "bold", "plain")) +
  scale_fill_gradient2(low = gold_light, mid = "white", high = marine_light,
                       midpoint = 0, limits = c(-1.5, 1.5), oob = scales::squish,
                       na.value = light_grey, name = "Coefficient") +
  scale_colour_manual(values = c(`TRUE` = ink, `FALSE` = "white"), guide = "none") +
  labs(
    title = "Individual-species associations near recorded active spawn",
    subtitle = paste0(
      "All 49 support-qualified species are shown in alphabetical order; values are adjusted coefficients.\n",
      "An asterisk and dark tile border denote BH q < 0.05; NA is retained for a non-estimable component."
    ),
    x = NULL, y = NULL
  ) +
  theme_mer(9.6) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(face = "bold", size = 8.5, lineheight = 0.95),
    axis.text.y = element_text(size = 7.5),
    legend.position = "top",
    legend.key.width = grid::unit(1.5, "cm"),
    plot.margin = margin(12, 16, 12, 12)
  )
save_figure(p2, "Figure_2", 11, 13.2)

# Figure 3: all event-window components plus a descriptive window median.
window_order <- c("time_immediate_pre", "time_spawn_start", "time_early_egg",
                  "time_late_egg", "time_post")
window_labels <- c("Immediate pre", "Spawn start", "Early egg", "Late egg", "Post")
event[, `:=`(
  window = factor(contrast, levels = window_order, labels = window_labels),
  outcome_label = factor(outcome_labels[outcome],
                         levels = c("Detection", "Conditional positive count")),
  region = factor(region, levels = c("SoG", "WCVI")),
  guild_index = match(unit_label, guild_order)
)]
event[, x_position := as.numeric(window) + (guild_index - 4.5) * 0.047]
event_median <- event[, .(estimate = median(partial_pool_estimate_v2, na.rm = TRUE)),
                      by = .(region, outcome_label, window)]
event_median[, x_position := as.numeric(window)]
p3 <- ggplot(event, aes(x = x_position, y = partial_pool_estimate_v2)) +
  geom_hline(yintercept = 0, colour = muted, linewidth = 0.45, linetype = "dashed") +
  geom_segment(aes(xend = x_position, y = partial_pool_conf_low_v2,
                   yend = partial_pool_conf_high_v2),
               colour = marine, alpha = 0.35, linewidth = 0.42) +
  geom_point(colour = marine, fill = "white", shape = 21, size = 1.55,
             stroke = 0.55, alpha = 0.88) +
  geom_line(data = event_median, aes(x = x_position, y = estimate, group = 1),
            inherit.aes = FALSE, colour = gold, linewidth = 0.72) +
  geom_point(data = event_median, aes(x = x_position, y = estimate),
             inherit.aes = FALSE, shape = 18, size = 2.8, colour = gold) +
  facet_grid(rows = vars(region), cols = vars(outcome_label), scales = "free_y") +
  scale_x_continuous(breaks = seq_along(window_labels), labels = window_labels,
                     expand = expansion(mult = c(0.05, 0.05))) +
  labs(title = "Registered associations varied across biological event windows",
       subtitle = "Each open point is one guild coefficient with a 95% interval; the gold line connects descriptive window medians, not a fitted trajectory.",
       x = NULL, y = "Adjusted coefficient") +
  theme_mer(10.0) +
  theme(legend.position = "none", panel.spacing = grid::unit(1.0, "lines"),
        axis.text.x = element_text(size = rel(0.86)))
save_figure(p3, "Figure_3", 11, 7.8)

# Figure 4: the prespecified SoG specificity panel in the context of the complete
# individual-species detection distribution.
species_context <- all_species[region == "SoG" & outcome == "detection" & completed, .(
  species = unit_label,
  estimate,
  low = conf_low,
  high = conf_high,
  evidence = "M02 species"
)]
specificity <- m29[, .(
  species,
  estimate = estimate_log_odds,
  low = conf_low,
  high = conf_high,
  evidence = "Specificity panel"
)]
species_context[, y := 1]
specificity[, y := c(2.05, 2.55)]
p4 <- ggplot() +
  geom_vline(xintercept = 0, colour = muted, linewidth = 0.5, linetype = "dashed") +
  geom_rug(data = species_context, aes(x = estimate), sides = "b",
           colour = marine, alpha = 0.55, linewidth = 0.65) +
  geom_point(data = species_context, aes(x = estimate, y = y), shape = 21,
             size = 2.5, stroke = 0.55, fill = "white", colour = marine,
             position = position_jitter(height = 0.13, width = 0, seed = 842)) +
  geom_errorbar(data = specificity, aes(x = estimate, y = y, xmin = low, xmax = high),
                orientation = "y", width = 0, linewidth = 0.9, colour = gold) +
  geom_point(data = specificity, aes(x = estimate, y = y), shape = 18,
             size = 4.1, colour = gold) +
  geom_text(data = specificity, aes(x = high, y = y, label = species),
            hjust = -0.08, family = "sans", fontface = "bold", size = 3.55,
            colour = ink) +
  annotate("text", x = min(species_context$estimate), y = 1.38,
           label = "49 support-qualified M02 species", hjust = 0,
           family = "sans", size = 3.5, colour = marine) +
  coord_cartesian(ylim = c(0.65, 2.85), clip = "off") +
  scale_y_continuous(breaks = c(1, 2.30),
                     labels = c("M02 species", "M29 specificity"),
                     limits = c(0.65, 2.85)) +
  labs(
    title = "The SoG specificity panel was non-null in a broader species-level signal",
    subtitle = paste0(
      "Open circles show all registered M02 detection coefficients; gold diamonds and 95% confidence intervals\n",
      "show the prespecified Gadwall and Northern Shoveler panel."
    ),
    x = "Adjusted detection log-odds coefficient", y = NULL
  ) +
  theme_mer(10.5) +
  theme(panel.grid.major.y = element_blank(), legend.position = "none",
        plot.margin = margin(14, 95, 14, 14))
save_figure(p4, "Figure_4", 11, 5.6)

make_sensitivity_forest <- function(models, regions, title, subtitle) {
  d <- sensitivity[model_version_id %in% models & region %in% regions]
  expected <- length(models) * length(regions) * 16L
  if (nrow(d) != expected) stop("Sensitivity plot accounting failed: expected ", expected,
                                " rows, found ", nrow(d))
  d[, `:=`(
    model = factor(model_labels[model_version_id], levels = model_labels[models]),
    outcome_label = factor(outcome_labels[outcome],
                           levels = c("Detection", "Conditional positive count")),
    unit_factor = factor(unit_label, levels = rev(guild_order)),
    region = factor(region, levels = regions)
  )]
  dodge <- position_dodge(width = 0.64)
  values <- setNames(c(marine, gold, warm_grey)[seq_along(models)], model_labels[models])
  shapes <- setNames(c(16, 17, 4)[seq_along(models)], model_labels[models])
  ggplot(d, aes(x = estimate, y = unit_factor, colour = model, shape = model)) +
    geom_vline(xintercept = 0, colour = muted, linewidth = 0.45, linetype = "dashed") +
    geom_errorbar(aes(xmin = conf_low, xmax = conf_high), orientation = "y", width = 0,
                  linewidth = 0.60, position = dodge) +
    geom_point(size = 2.25, stroke = 0.85, position = dodge) +
    facet_grid(rows = vars(region), cols = vars(outcome_label), scales = "free_x") +
    scale_colour_manual(values = values) +
    scale_shape_manual(values = shapes) +
    scale_y_discrete(labels = guild_labels) +
    labs(title = title, subtitle = subtitle,
         x = "Adjusted coefficient (95% interval)", y = NULL) +
    theme_mer(9.8) +
    theme(panel.spacing = grid::unit(1.0, "lines"), axis.text.y = element_text(size = rel(0.90)))
}

p5 <- make_sensitivity_forest(
  c("M01_PRIMARY_v2", "S4A12_WCVI_2KM_v2", "S4A11_WCVI_DOMINANT_OBSERVER_v2"),
  "WCVI",
  "WCVI spatial and observer sensitivities",
  "Each sensitivity changes one registered design dimension while retaining the matched sparse model architecture."
)
save_figure(p5, "Figure_5", 12, 5.2)

species_forest <- copy(all_species[completed == TRUE])
species_forest[, `:=`(
  taxon = factor(unit_label, levels = rev(sort(unique(unit_label)))),
  outcome_label = factor(outcome_labels[outcome],
                         levels = c("Detection", "Conditional positive count")),
  region = factor(region, levels = c("SoG", "WCVI"))
)]
pS1 <- ggplot(species_forest, aes(x = estimate, y = taxon)) +
  geom_vline(xintercept = 0, colour = muted, linewidth = 0.42, linetype = "dashed") +
  geom_errorbar(aes(xmin = conf_low, xmax = conf_high, colour = q_value < 0.05),
                orientation = "y", width = 0, linewidth = 0.58) +
  geom_point(aes(fill = q_value < 0.05), shape = 21, size = 1.75,
             stroke = 0.55, colour = ink) +
  facet_grid(rows = vars(outcome_label), cols = vars(region), scales = "free_x") +
  scale_x_continuous(trans = scales::pseudo_log_trans(sigma = 0.35)) +
  scale_colour_manual(values = c(`TRUE` = marine, `FALSE` = warm_grey), guide = "none") +
  scale_fill_manual(values = c(`TRUE` = marine, `FALSE` = "white"), guide = "none") +
  labs(
    title = "Confidence intervals for all 49 support-qualified species",
    subtitle = paste0(
      "Filled points denote BH q < 0.05. The symmetric pseudo-log axis preserves sign while accommodating the full interval range.\n",
      "One non-estimable WCVI count component is retained as NA in Figure 2 and Table S2."
    ),
    x = "Adjusted coefficient (95% confidence interval; symmetric pseudo-log scale)", y = NULL
  ) +
  theme_mer(9.2) +
  theme(axis.text.y = element_text(size = 7.1), panel.spacing = grid::unit(1.0, "lines"),
        legend.position = "none")
save_figure(pS1, "Figure_S1", 11, 13.2)

disposition_labels <- c(
  INCLUDED_PRIMARY_REPRESENTATION = "Estimated primary representation",
  EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION = "Duplicate representation retained as NA",
  NON_ESTIMABLE_MODEL_STATUS = "Non-estimable model retained as NA"
)
exclusion[, label := factor(disposition_labels[release_category],
                            levels = rev(disposition_labels[c(
                              "INCLUDED_PRIMARY_REPRESENTATION",
                              "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION",
                              "NON_ESTIMABLE_MODEL_STATUS")]))]
exclusion[, colour_group := fifelse(
  release_category == "INCLUDED_PRIMARY_REPRESENTATION", "Estimated",
  fifelse(release_category == "EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION",
          "Duplicate", "Non-estimable"))]
pS2 <- ggplot(exclusion, aes(x = rows, y = label, fill = colour_group)) +
  geom_col(width = 0.62, colour = ink, linewidth = 0.35) +
  geom_text(aes(label = format(rows, big.mark = ",")), hjust = -0.15,
            family = "sans", colour = ink, size = 3.6) +
  scale_fill_manual(values = c(Estimated = marine, Duplicate = gold,
                               `Non-estimable` = light_grey)) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Disposition of all 6,562 repaired pooling rows",
       subtitle = "Duplicate and non-estimable representations remain explicit NA rows rather than zero effects.",
       x = "Rows", y = NULL) +
  theme_mer(10.4) +
  theme(legend.position = "none")
save_figure(pS2, "Figure_S2", 8, 4)

families[, log_tau2 := log10(tau2 + 1e-12)]
tau_median <- median(families$log_tau2[is.finite(families$log_tau2)], na.rm = TRUE)
pS3 <- ggplot(families[is.finite(log_tau2)], aes(x = log_tau2)) +
  geom_histogram(bins = 24, fill = marine_light, colour = marine, linewidth = 0.45) +
  geom_vline(xintercept = tau_median, colour = gold, linewidth = 0.85) +
  annotate("text", x = tau_median, y = Inf, label = "median", vjust = 1.5,
           hjust = -0.12, family = "sans", colour = gold, size = 3.2) +
  labs(title = "Between-component heterogeneity across compatible families",
       subtitle = "Distribution among 162 estimable pooling families; the horizontal scale is log10(tau-squared + 1e-12).",
       x = expression(log[10](tau^2 + 10^{-12})), y = "Families") +
  theme_mer(10.4)
save_figure(pS3, "Figure_S3", 8.4, 4.1)

diag <- diagnostics[, .(components = sum(components)),
                    by = .(model_version_id, status)]
all_diag <- CJ(model_version_id = names(model_labels),
               status = c("completed", "completed_with_singular_warning",
                          "failed_convergence"), unique = TRUE)
diag <- diag[all_diag, on = c("model_version_id", "status")]
diag[is.na(components), components := 0L]
diag[, `:=`(
  model = factor(model_labels[model_version_id], levels = rev(model_labels)),
  status_label = factor(status,
    levels = c("failed_convergence", "completed_with_singular_warning", "completed"),
    labels = c("Failed convergence", "Singular warning", "Ordinary fit"))
)]
pS4 <- ggplot(diag, aes(x = components, y = model, fill = status_label)) +
  geom_col(width = 0.64, colour = "white", linewidth = 0.35) +
  geom_text(data = diag[components > 0], aes(label = components),
            position = position_stack(vjust = 0.5), family = "sans",
            colour = ink, size = 3.3) +
  scale_fill_manual(values = c("Ordinary fit" = marine_light,
                               "Singular warning" = gold_light,
                               "Failed convergence" = light_grey)) +
  scale_x_continuous(breaks = seq(0, 32, 8), expand = expansion(mult = c(0, 0.04))) +
  labs(title = "Matched sensitivity model diagnostics",
       subtitle = "All 128 components completed; singularity is retained as a warning about variance-structure support.",
       x = "Components", y = NULL) +
  theme_mer(10.2)
save_figure(pS4, "Figure_S4", 9.8, 5.0)

pS5 <- make_sensitivity_forest(
  c("M01_PRIMARY_v2", "M27_v2", "M28_v2"),
  c("SoG", "WCVI"),
  "Matched whole-bundle placebo diagnostics",
  "Date- and location-shift placebos are compared with the matched primary reference; no placebo component had BH q below 0.05."
)
save_figure(pS5, "Figure_S5", 12, 7.12)

figure_audit <- data.table(
  figure = c("Figure 1", "Figure 2", "Figure 3", "Figure 4", "Figure 5",
             "Figure S1", "Figure S2", "Figure S3", "Figure S4", "Figure S5"),
  source_artifact = c(
    "metadata/stage4a_core_spec_v1.yml",
    "outputs/stage4a_results/effect_estimates.csv (M02; all 49 support-qualified taxa)",
    "outputs/stage4a_publication_v2/event_time_table_v2.csv",
    "effect_estimates.csv (M02 SoG detection) + sog_m29_audit_v2.csv",
    "outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv",
    "outputs/stage4a_results/effect_estimates.csv (M02; all 49 support-qualified taxa)",
    "outputs/stage4a_publication_v2/supplementary_exclusion_summary_v2.csv",
    "outputs/stage4a_publication_v2/supplementary_family_table_v2.csv",
    "outputs/stage4a_publication_v2/model_diagnostic_summary_v2.csv",
    "outputs/stage4a_publication_v2/matched_sensitivity_table_v2.csv"
  ),
  plotted_rows_or_components = c(4L, nrow(all_species), nrow(event),
                                 nrow(species_context) + nrow(specificity),
                                 sensitivity[model_version_id %in% c(
                                   "M01_PRIMARY_v2", "S4A12_WCVI_2KM_v2",
                                   "S4A11_WCVI_DOMINANT_OBSERVER_v2") &
                                   region == "WCVI", .N],
                                 nrow(all_species), nrow(exclusion), nrow(families),
                                 sum(diag$components),
                                 sensitivity[model_version_id %in% c(
                                   "M01_PRIMARY_v2", "M27_v2", "M28_v2"), .N]),
  expected_rows_or_components = c(4L, 196L, 160L, 51L, 48L, 196L, 3L, 162L, 128L, 96L)
)
figure_audit[, status := ifelse(plotted_rows_or_components == expected_rows_or_components,
                                "PASS", "FAIL")]
if (any(figure_audit$status != "PASS")) stop("Figure data accounting audit failed")
fwrite(figure_audit,
       file.path(journal_root, "audits", "figure_data_rebuild_audit_v2.csv"),
       quote = TRUE, na = "NA", eol = "\n")

cat("Rebuilt 10 Marine Environmental Research figures with ggplot2 ",
    as.character(packageVersion("ggplot2")), ".\n", sep = "")
