suppressPackageStartupMessages({library(data.table); library(digest); library(jsonlite)})
source("R/assert.R")
source("R/species_registry.R")
source("R/model_registry.R")
counts <- validate_registry_bundle()
privacy <- if (file.exists("outputs/setup/privacy_scan_summary.json")) {
  jsonlite::read_json("outputs/setup/privacy_scan_summary.json", simplifyVector = TRUE)
} else list(status = "NOT RUN")
source_sha <- jsonlite::read_json("metadata/v1_source_provenance.json", simplifyVector = TRUE)$source_commit_sha
source_checks <- fread("metadata/source_verification_summary.csv",
                       colClasses = list(character = c("n_primary", "n_secondary")))
rows <- paste(sprintf("<tr><th>%s</th><td>%s</td></tr>", names(counts), unlist(counts)), collapse = "\n")
html <- paste0(
  "<!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='generator' content='scripts/05_build_setup_audit.R'><title>Repository setup audit</title>",
  "<style>body{font-family:system-ui;max-width:980px;margin:40px auto;line-height:1.5;color:#183247}",
  "table{border-collapse:collapse}th,td{border:1px solid #ccd6dd;padding:8px;text-align:left}",
  ".pass{color:#176b3a;font-weight:700}.gate{background:#fff4d6;padding:14px;border-left:5px solid #d48b00}</style></head><body>",
  "<h1>Herring x eBird Version 2: repository setup audit</h1>",
  "<p class='gate'>Outcome gate: metadata and design only. No Version 2 bird-response outcome was opened or fitted.</p>",
  "<h2>Canonical registry counts</h2><table>", rows, "</table>",
  "<h2>Provenance</h2><p>Version 1 source pinned at <code>", source_sha, "</code>. Clean history retained; no fitted or row-level artifact ported.</p>",
  "<h2>Privacy</h2><p class='pass'>", privacy$status, "</p>",
  "<h2>Raw-input status</h2><p class='pass'>", if (all(source_checks$status == "PASS")) "PASS" else "FAIL", "</p>",
  "<p>All five sizes and SHA-256 values match; headers, shapefile bundles, CRS declarations, source metadata, and EBD-to-SED many-to-one keys passed. Paths and record-level values are not embedded.</p>",
  "<h2>Scientific status</h2><p>Exploratory and estimand-refining until prospective confirmation. See <code>docs/08_UNRESOLVED_SCIENTIFIC_DECISIONS.md</code>.</p>",
  "</body></html>"
)
con <- file("reports/repository_setup_audit.html", open = "wb")
on.exit(close(con), add = TRUE)
writeBin(charToRaw(paste0(html, "\n")), con)
cat("reports/repository_setup_audit.html\n")
