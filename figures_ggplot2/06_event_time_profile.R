#!/usr/bin/env Rscript
# Exploratory event-time figure: day-resolved active-minus-baseline contrast
# for one species, days -5 to +5. Reads only committed aggregate CSVs.
#
# Colour comes from 00_theme_mer.R and is not restyled. Line type and
# open/filled symbols carry the same information as colour so the figure
# survives greyscale reproduction. Vector PDF plus 600 dpi PNG.

Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE")
analysis_library <- file.path(
  ".analysis-library", "blockaware_v1", "R-4.5", "x86_64-w64-mingw32"
)
frozen_library <- file.path(
  "renv", "library", "windows", "R-4.5", "x86_64-w64-mingw32"
)
.libPaths(c(
  if (dir.exists(analysis_library)) normalizePath(analysis_library, winslash = "/") else character(),
  if (dir.exists(frozen_library)) normalizePath(frozen_library, winslash = "/") else character(),
  .libPaths()
))

source(file.path("figures_ggplot2", "00_theme_mer.R"))

root <- file.path("outputs", "post_stage4a_event_time_v1")
profile <- fread(
  file.path(root, "event_time_profile.csv"), na.strings = c("", "NA")
)
pooled <- fread(
  file.path(root, "event_time_pooled_check.csv"), na.strings = c("", "NA")
)
assert_unique_key(profile, c("outcome", "event_day"), "event-time profile")
stopifnot(
  nrow(profile) == 22L,
  length(unique(profile$species)) == 1L,
  all(range(profile$event_day) == c(-5L, 5L))
)
species <- unique(profile$species)

profile[, outcome_label := factor(
  outcome_labels[outcome], levels = unname(outcome_labels)
)]
# Filled marker where the day interval excludes 1, open where it does not.
# This duplicates the colour information for greyscale readers.
profile[, marker_fill := ifelse(
  interval_excludes_one, outcome_colours[outcome], "white"
)]

reporting_n <- unique(profile[outcome == "checklist_reporting", n])
count_n <- unique(
  profile[outcome == "conditional_positive_numeric_count", n]
)
pooled_reporting <- pooled[outcome == "checklist_reporting", ratio]
pooled_count <- pooled[outcome == "conditional_positive_numeric_count", ratio]

dodge <- position_dodge(width = 0.45)

plot <- ggplot(
  profile,
  aes(
    x = event_day, y = ratio,
    colour = outcome_label, shape = outcome_label,
    linetype = outcome_label, group = outcome_label
  )
) +
  annotate(
    "rect", xmin = -0.5, xmax = 3.5, ymin = -Inf, ymax = Inf,
    fill = light_grey, alpha = 0.55
  ) +
  annotate(
    "text", x = 1.5, y = 1.40, label = "registered spawn-start window\n0 to 3 d",
    colour = muted, size = 2.9, lineheight = 1.05, vjust = 1
  ) +
  geom_hline(yintercept = 1, colour = ink, linewidth = 0.4) +
  geom_vline(xintercept = -0.5, colour = muted, linewidth = 0.3,
             linetype = "31") +
  geom_line(position = dodge, linewidth = 0.55) +
  geom_errorbar(
    aes(ymin = ratio_conf_low, ymax = ratio_conf_high),
    position = dodge, width = 0.28, linewidth = 0.45, linetype = "solid"
  ) +
  geom_point(
    aes(fill = marker_fill), position = dodge, size = 2.5, stroke = 0.7
  ) +
  scale_fill_identity(guide = "none") +
  scale_colour_manual(values = unname(outcome_colours[names(outcome_labels)])) +
  scale_shape_manual(values = unname(outcome_shapes[names(outcome_labels)])) +
  scale_linetype_manual(
    values = unname(outcome_linetypes[names(outcome_labels)])
  ) +
  scale_x_continuous(breaks = -5:5, minor_breaks = NULL) +
  scale_y_continuous(
    breaks = seq(0.9, 1.5, by = 0.1),
    labels = function(x) formatC(x, format = "f", digits = 1)
  ) +
  coord_cartesian(ylim = c(0.88, 1.45)) +
  labs(
    title = paste0(species, ": day-resolved response around spawn onset"),
    subtitle = paste0(
      "Each point is (near - reference) on that day minus the same difference ",
      "in the registered baseline,\ndays -28 to -15. Near is within 5 km. ",
      "Filled markers mark intervals excluding 1. The pooled\nregistered ",
      "contrast gives ", formatC(pooled_count, format = "f", digits = 3),
      " for reported number and ",
      formatC(pooled_reporting, format = "f", digits = 3),
      " for reporting, because it weights\ndays 4 to 14 at eleven fifteenths ",
      "against days 0 to 3 at four fifteenths."
    ),
    x = "Days from first recorded spawn date at the location",
    y = "Ratio against the pre-spawn baseline",
    caption = paste0(
      "Exploratory. One species, chosen after the family results were known. ",
      "No Benjamini-Hochberg family, and no\nmultiplicity adjustment across ",
      "the eleven days, which are not independent. Event-block random ",
      "intercept\nonly, so these intervals are Stage 2 width: narrower than a ",
      "block-aware interval by roughly the 16 to 18 per\ncent median widening ",
      "measured in post_stage4a_blockaware_v1. Reporting n = ",
      format(reporting_n, big.mark = ","), " (Wald), reported\nnumber n = ",
      format(count_n, big.mark = ","), " (Satterthwaite denominator). ",
      "Source: outputs/post_stage4a_event_time_v1/."
    )
  ) +
  theme_mer() +
  theme(
    panel.grid.major.y = element_line(colour = grid, linewidth = 0.3),
    panel.grid.major.x = element_blank(),
    legend.key.width = unit(1.5, "lines")
  )

save_figure(plot, "figure_event_time_bald_eagle", width = 8.2, height = 6.1)
