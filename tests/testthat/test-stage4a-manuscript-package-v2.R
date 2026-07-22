test_that("manuscript claim, singular-fit, and falsification audits are complete", {
  claim <- fread(repo_file("metadata", "stage4a_publication_claim_evidence_matrix_v2.csv"))
  singular <- fread(repo_file("outputs", "stage4a_publication_v2", "singular_fit_claim_audit_v2.csv"))
  fals <- fread(repo_file("outputs", "stage4a_publication_v2", "sog_falsification_claim_audit_v2.csv"))

  expect_equal(nrow(claim), 20L)
  expect_equal(claim[, .N, by = robustness_classification][
    robustness_classification == "robust", N], 11L)
  expect_equal(claim[, .N, by = robustness_classification][
    robustness_classification == "supported with qualification", N], 7L)
  expect_equal(nrow(singular), 43L)
  expect_equal(anyDuplicated(singular[, .(model_version_id, region, species_or_guild, outcome)]), 0L)
  expect_true(all(is.finite(singular$coefficient_estimate)))
  expect_true(all(is.finite(singular$conf_low)))
  expect_true(all(is.finite(singular$conf_high)))
  expect_false(any(singular$headline_claim_depends_on_component))
  expect_equal(nrow(fals), 2L)
  expect_true(all(fals$bh_q_value < 0.05))
})

test_that("manuscript tables preserve authoritative rows and readable pairing", {
  authoritative <- fread(repo_file("manuscript", "tables", "table2_priority_species_v2.csv"))
  display <- readLines(repo_file("manuscript", "generated", "table2_priority_species_v2.md"), warn = FALSE)

  expect_equal(nrow(authoritative), 20L)
  expect_setequal(unique(authoritative$outcome),
                  c("detection", "positive numeric count given detection"))
  expect_equal(length(grep("^\\| (SoG|WCVI) \\|", display)), 10L)
  expect_match(display[1], "Positive numeric count \\(detected\\)")
})

test_that("publication citations, provenance, and rendered artifacts are auditable", {
  citations <- fread(repo_file("metadata", "stage4a_publication_citation_audit_v2.csv"))
  provenance <- fread(repo_file("metadata", "stage4a_publication_table_figure_provenance_v2.csv"))

  expect_equal(nrow(citations), 20L)
  expect_equal(anyDuplicated(citations$citation_key), 0L)
  expect_true(all(citations$missing_information_status == "none"))
  expect_equal(nrow(provenance[manuscript_location == "main" & grepl("^Figure", artifact_id)]), 5L)
  expect_equal(nrow(provenance[manuscript_location == "main" & grepl("^Table", artifact_id)]), 3L)
  expect_equal(nrow(provenance[manuscript_location == "supplement" & grepl("^Figure", artifact_id)]), 4L)
  expect_equal(nrow(provenance[manuscript_location == "supplement" & grepl("^Table", artifact_id)]), 9L)
  for (i in seq_len(nrow(provenance))) {
    source <- file.path(project_root, provenance$source_file[i])
    expect_true(file.exists(source), info = provenance$source_file[i])
    expect_identical(digest::digest(source, algo = "sha256", file = TRUE,
                                    serialize = FALSE), provenance$source_hash[i],
                     info = provenance$artifact_id[i])
  }

  rendered <- c("stage4a_manuscript_v2.html", "stage4a_manuscript_v2.docx",
                "stage4a_manuscript_v2.pdf", "stage4a_supplement_v2.html",
                "stage4a_supplement_v2.docx", "stage4a_supplement_v2.pdf",
                "stage4a_cover_letter_template_v2.docx",
                "stage4a_cover_letter_template_v2.pdf")
  sizes <- file.info(file.path(repo_file("manuscript", "rendered"), rendered))$size
  expect_true(all(is.finite(sizes) & sizes > 0))
})

test_that("manuscript sources retain accessibility and claim boundaries", {
  main <- paste(readLines(repo_file("manuscript", "stage4a_manuscript_v2.qmd"),
                          warn = FALSE), collapse = "\n")
  supp <- paste(readLines(repo_file("manuscript", "stage4a_supplement_v2.qmd"),
                          warn = FALSE), collapse = "\n")
  text <- paste(main, supp, sep = "\n")

  expect_equal(length(gregexpr("fig-alt=", text, fixed = TRUE)[[1]]), 9L)
  expect_match(main, "checklist-conditional", fixed = TRUE)
  expect_match(main, "specificity panel was non-null", fixed = TRUE)
  expect_match(main, "M26 v1 was retired without replacement", fixed = TRUE)
  expect_match(main, "zero 2026-or-later rows read", fixed = TRUE)
  expect_false(grepl("sampling_event_identifier|locality_id|observer_id", text,
                     ignore.case = TRUE))
})
