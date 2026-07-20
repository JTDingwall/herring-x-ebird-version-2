suppressPackageStartupMessages({library(data.table); library(jsonlite)})
source("R/privacy_scan.R")
scan <- scan_privacy()
write_privacy_summary(scan)
if (scan$status != "PASS") {
  print(unique(scan$violations))
  stop("Privacy scan failed; matching text was not persisted", call. = FALSE)
}
cat("Privacy scan passed across ", scan$files_scanned, " text files.\n", sep = "")
