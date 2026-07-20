test_that("tracked files do not contain restricted raw-data extensions", {
  files <- system2("git", c("ls-files"), stdout = TRUE)
  forbidden <- grepl("(ebd_CA-BC|sampling_event_identifier.*csv|observer_id.*csv|data/raw/.+\\.(txt|csv|shp|dbf)$)", files, ignore.case = TRUE)
  expect_false(any(forbidden))
})
