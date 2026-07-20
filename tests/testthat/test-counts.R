source("R/assert.R")
source("R/outcomes.R")

test_that("X remains a detection and not a numeric count", {
  x <- parse_ebird_count(c("12", "X", "", NA))
  expect_equal(x$detection, c(1L,1L,0L,0L))
  expect_equal(x$numeric_count[[1]], 12)
  expect_true(is.na(x$numeric_count[[2]]))
  expect_equal(x$count_type, c("numeric","X","missing","missing"))
})
