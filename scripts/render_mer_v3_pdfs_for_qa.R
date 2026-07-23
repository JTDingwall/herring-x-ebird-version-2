#!/usr/bin/env Rscript

# Render the already-created MER v3 PDFs into page images and compact contact
# sheets for visual quality assurance. This script does not read analysis data.

suppressPackageStartupMessages({
  library(grid)
  library(pdftools)
  library(png)
})

args <- commandArgs(trailingOnly = TRUE)
input_dir <- if (length(args) >= 1L) args[[1L]] else
  file.path("manuscript", "journal_submission", "marine_environmental_research", "rendered_v3")
output_dir <- if (length(args) >= 2L) args[[2L]] else
  file.path("manuscript", "journal_submission", "marine_environmental_research", "rendered_v3_qa")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
pdfs <- list.files(input_dir, pattern = "[.]pdf$", full.names = TRUE)
stopifnot(length(pdfs) > 0L)

manifest <- list()
for (pdf in pdfs) {
  stem <- tools::file_path_sans_ext(basename(pdf))
  page_dir <- file.path(output_dir, stem)
  dir.create(page_dir, recursive = TRUE, showWarnings = FALSE)
  pages <- pdf_info(pdf)$pages
  page_files <- file.path(page_dir, sprintf("page-%03d.png", seq_len(pages)))
  pdf_convert(pdf, format = "png", dpi = 110, filenames = page_files, verbose = FALSE)

  sheet_ids <- split(seq_len(pages), ceiling(seq_len(pages) / 4))
  for (sheet_no in seq_along(sheet_ids)) {
    ids <- sheet_ids[[sheet_no]]
    sheet_file <- file.path(page_dir, sprintf("contact-%02d.png", sheet_no))
    png(sheet_file, width = 1800, height = 2400, res = 150, bg = "white")
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(2, 2)))
    for (slot in seq_along(ids)) {
      row <- ceiling(slot / 2)
      col <- if (slot %% 2 == 1) 1 else 2
      img <- readPNG(page_files[[ids[[slot]]]])
      pushViewport(viewport(layout.pos.row = row, layout.pos.col = col))
      grid.rect(gp = gpar(fill = "white", col = "grey70"))
      grid.raster(img, width = unit(0.96, "npc"), height = unit(0.91, "npc"), interpolate = TRUE)
      grid.text(sprintf("%s — page %d", stem, ids[[slot]]), y = unit(0.975, "npc"),
                gp = gpar(fontsize = 8, col = "grey20"))
      popViewport()
    }
    popViewport()
    dev.off()
  }

  manifest[[length(manifest) + 1L]] <- data.frame(
    file = basename(pdf), pages = pages, contact_sheets = length(sheet_ids),
    stringsAsFactors = FALSE
  )
}

manifest <- do.call(rbind, manifest)
write.csv(manifest, file.path(output_dir, "pdf_visual_qa_manifest_v3.csv"), row.names = FALSE)
print(manifest)
