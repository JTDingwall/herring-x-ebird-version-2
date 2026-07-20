options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore(prompt = FALSE)
cat("Project library restored. Configure protected input environment variables only for local metadata audits.\n")
