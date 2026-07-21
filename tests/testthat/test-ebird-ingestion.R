test_that("header inspection detects delimiter encoding and fields", {
  path <- tempfile(fileext = ".txt")
  writeLines("FIELD ONE\tFIELD TWO\nvalue\tvalue", path, useBytes = TRUE)
  got <- inspect_delimited_header(path)
  expect_identical(got$delimiter, "\t")
  expect_equal(got$field_count, 2L)
  expect_identical(got$source_fields[[1]], c("FIELD ONE", "FIELD TWO"))
})

test_that("EBD to SED is declared many to one", {
  ebd <- data.table(sampling_event_identifier = c("fixture_a", "fixture_a", "fixture_b"))
  sed <- data.table(sampling_event_identifier = c("fixture_a", "fixture_b"))
  got <- audit_ebd_sed_keys(ebd, sed)
  expect_identical(got$status, "PASS")
  expect_error(audit_ebd_sed_keys(ebd, rbind(sed, sed[1])), "JOIN_CARDINALITY")
})

test_that("shared checklists collapse once and retain disagreement audit", {
  sed <- data.table(sampling_event_identifier = c("fixture_b", "fixture_a", "fixture_c"),
                    group_identifier = c("group_1", "group_1", NA),
                    duration_minutes = c(10, 20, 30))
  got <- resolve_shared_checklists(sed)
  expect_equal(nrow(got$canonical_rows), 2L)
  expect_equal(nrow(got$primary_rows), 1L)
  expect_identical(got$canonical_rows[analysis_checklist_id == "group_1", observer_effect_treatment],
                   "shared_group_composite_cluster")
  expect_true(got$canonical_rows[analysis_checklist_id == "group_1", has_effort_disagreement])
  expect_false("group_1" %in% got$primary_rows$analysis_checklist_id)
  expect_equal(sum(got$private_crosswalk$canonical_effort_row), 2L)
  expect_equal(got$aggregate_audit$disagreement_groups, 1L)
})

test_that("numeric X lower-bound ambiguity and missing remain distinct", {
  got <- parse_ebird_count_state(c("12", "X", "5+", "uncertain", ""),
                                 ambiguous = c(FALSE, FALSE, FALSE, TRUE, FALSE))
  expect_identical(got$count_type, c("numeric", "X", "lower_bound", "ambiguity_affected", "missing"))
  expect_identical(got$detection, rep(1L, 5L))
  expect_true(is.na(got$numeric_count[2]))
  expect_identical(
    parse_ebird_count_state("", observation_record_present = FALSE)$detection,
    0L
  )
})

test_that("accepted-record predicate is APPROVED only", {
  expect_identical(
    accepted_ebird_record(c("1", "TRUE", "0", "FALSE", NA),
                          reviewed = c("0", "0", "1", "1", "1")),
    c(TRUE, TRUE, FALSE, FALSE, FALSE)
  )
})

test_that("stationary distance is normalized before effort handling", {
  got <- normalize_stationary_distance(
    c("Stationary", "stationary", "Traveling", "Traveling"),
    c(NA, 2.5, 1.25, NA)
  )
  expect_identical(got[1:3], c(0, 0, 1.25))
  expect_true(is.na(got[4]))
})

test_that("zero filling changes only absent eligible taxa", {
  checklists <- data.table(analysis_checklist_id = c("fixture_a", "fixture_b", "fixture_sed_only"),
                           zero_fill_eligible = c(TRUE, TRUE, FALSE))
  det <- data.table(analysis_checklist_id = c("fixture_a", "fixture_sed_only"),
                    analysis_taxon_id = c("taxon_a", "taxon_a"),
                    detection = 1L, numeric_count = NA_real_, lower_bound_count = NA_real_,
                    count_type = "X", ambiguity_flag = FALSE)
  got <- zero_fill_taxa(checklists, det, c("taxon_a", "taxon_b"))
  expect_identical(got[analysis_checklist_id == "fixture_a" & analysis_taxon_id == "taxon_a", count_type], "X")
  expect_equal(got[count_type == "zero_filled", .N], 3L)
  expect_false("fixture_sed_only" %in% got$analysis_checklist_id)
})

test_that("ambiguity masks are never zero filled", {
  checklists <- data.table(analysis_checklist_id = "fixture_a", zero_fill_eligible = TRUE)
  det <- data.table(
    analysis_checklist_id = "fixture_a", analysis_taxon_id = "taxon_a",
    detection = NA_integer_, numeric_count = NA_real_, lower_bound_count = NA_real_,
    count_type = "ambiguity_affected", ambiguity_flag = TRUE
  )
  got <- zero_fill_taxa(checklists, det, c("taxon_a", "taxon_b"))
  expect_true(is.na(got[analysis_taxon_id == "taxon_a", detection]))
  expect_identical(got[analysis_taxon_id == "taxon_a", count_type], "ambiguity_affected")
  expect_identical(got[analysis_taxon_id == "taxon_b", count_type], "zero_filled")
})

test_that("guild ambiguity changes only defensible upper bounds", {
  named <- data.table(analysis_checklist_id = "fixture_a", guild_id = "g1", detection = 1L,
                      numeric_count = NA_real_, lower_bound_count = 4)
  ambiguous <- data.table(analysis_checklist_id = c("fixture_a", "fixture_a"),
                          possible_guild_ids = c("g1", "g1;g2"), lower_bound_count = c(3, 9))
  got <- guild_count_bounds(named, ambiguous)
  expect_equal(got$guild_count_lower, 4)
  expect_equal(got$guild_count_upper, 7)
})

test_that("missing zero-fill eligibility column fails loud", {
  checklists <- data.table(analysis_checklist_id = c("fixture_a", "fixture_b"))
  det <- data.table(analysis_checklist_id = "fixture_a", analysis_taxon_id = "taxon_a",
                    detection = 1L, numeric_count = NA_real_, lower_bound_count = NA_real_,
                    count_type = "X", ambiguity_flag = FALSE)
  expect_error(zero_fill_taxa(checklists, det, c("taxon_a", "taxon_b")), "ZERO_FILL_ELIGIBILITY")
})
