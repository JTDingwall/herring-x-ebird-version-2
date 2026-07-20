required <- c("data.table", "digest", "jsonlite", "targets", "testthat", "yaml")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
source("tests/testthat.R")
cat("Core setup complete. Configure .Renviron before running the metadata targets.\n")
