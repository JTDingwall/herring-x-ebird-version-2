suppressPackageStartupMessages(library(data.table))
source("R/assert.R")
source("R/config.R")
source("R/join_assertions.R")
source("R/ebird_ingestion.R")

cfg <- read_project_config()
paths <- resolve_input_paths(cfg)
key <- "SAMPLING EVENT IDENTIFIER"
sed <- fread(paths[["ebird_sed"]], sep = "\t", select = key, quote = "", showProgress = TRUE)
if (anyNA(sed[[key]]) || any(!nzchar(sed[[key]])) || anyDuplicated(sed[[key]])) {
  stop("SED checklist key is missing, blank, or duplicated", call. = FALSE)
}
sed_keys <- unique(sed[[key]])
rm(sed); invisible(gc())
ebd <- fread(paths[["ebird_ebd"]], sep = "\t", select = key, quote = "", showProgress = TRUE)
ebd_keys <- unique(ebd[[key]])
result <- data.table(
  relationship = "EBD-to-SED checklist", expected_cardinality = "many-to-one",
  ebd_rows = nrow(ebd), ebd_unique_keys = length(ebd_keys), sed_unique_keys = length(sed_keys),
  ebd_keys_unmatched_to_sed = sum(!ebd_keys %chin% sed_keys),
  sed_keys_without_ebd = sum(!sed_keys %chin% ebd_keys)
)
result[, status := if (ebd_keys_unmatched_to_sed == 0L) "PASS" else "FAIL"]
dir.create("outputs/input_audit_local", recursive = TRUE, showWarnings = FALSE)
fwrite(result, "outputs/input_audit_local/ebd_sed_key_audit.csv")
if (result$status != "PASS") stop("EBD/SED key audit failed", call. = FALSE)
cat("EBD/SED many-to-one checklist-key audit passed; only aggregate counts were written.\n")
