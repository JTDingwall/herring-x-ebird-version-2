read_docx_entry <- function(path, entry) {
  connection <- unz(path, entry, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste(readLines(connection, warn = FALSE, encoding = "UTF-8"),
        collapse = "")
}

docx_plain_text <- function(path) {
  xml <- read_docx_entry(path, "word/document.xml")
  text_nodes <- regmatches(
    xml,
    gregexpr("<w:t[^>]*>.*?</w:t>", xml, perl = TRUE)
  )[[1L]]
  text <- gsub("^<w:t[^>]*>|</w:t>$", "", text_nodes, perl = TRUE)
  text <- gsub("&lt;", "<", text, fixed = TRUE)
  text <- gsub("&gt;", ">", text, fixed = TRUE)
  text <- gsub("&amp;", "&", text, fixed = TRUE)
  paste(text, collapse = " ")
}

testthat::test_that("revised v9 manuscript is valid and submission-ready", {
  root <- repo_file(
    "manuscript", "journal_submission",
    "marine_environmental_research"
  )
  manuscript <- file.path(
    root, "rendered_v9",
    "mer_manuscript_unblinded_v9_revised_clean.docx"
  )

  testthat::expect_true(file.exists(manuscript))
  entries <- utils::unzip(manuscript, list = TRUE)$Name
  testthat::expect_true(all(c(
    "[Content_Types].xml", "word/document.xml",
    "word/settings.xml", "word/media/rId30.png",
    "word/media/rId34.png", "word/media/rId38.png"
  ) %in% entries))
  text <- docx_plain_text(manuscript)
  testthat::expect_match(text, "deterministic nearest-event", fixed = TRUE)
  testthat::expect_match(
    text,
    "conditional positive numeric reported count",
    fixed = TRUE
  )
  testthat::expect_false(grepl(
    "full stationary, nearest-event", text, fixed = TRUE
  ))
  testthat::expect_false(grepl("flock size", text, fixed = TRUE))
  testthat::expect_gte(
    lengths(regmatches(
      text,
      gregexpr("AUTHOR INPUT REQUIRED", text, fixed = TRUE)
    )),
    6L
  )

  document_xml <- read_docx_entry(manuscript, "word/document.xml")
  testthat::expect_match(document_xml, "<w:lnNumType", fixed = TRUE)
  footer_entries <- entries[grepl("^word/footer[0-9]+\\.xml$", entries)]
  testthat::expect_gte(length(footer_entries), 1L)
  footer_xml <- paste(
    vapply(
      footer_entries,
      function(entry) read_docx_entry(manuscript, entry),
      character(1L)
    ),
    collapse = ""
  )
  testthat::expect_match(footer_xml, "PAGE", fixed = TRUE)

  paragraphs <- regmatches(
    document_xml,
    gregexpr("<w:p(?: [^>]*)?>.*?</w:p>", document_xml, perl = TRUE)
  )[[1L]]
  abstract_xml <- paragraphs[
    grepl("Pacific herring \\(Clupea pallasii\\) spawning creates",
          paragraphs)
  ]
  testthat::expect_length(abstract_xml, 1L)
  abstract_nodes <- regmatches(
    abstract_xml,
    gregexpr("<w:t[^>]*>.*?</w:t>", abstract_xml, perl = TRUE)
  )[[1L]]
  abstract <- paste(
    gsub("^<w:t[^>]*>|</w:t>$", "", abstract_nodes, perl = TRUE),
    collapse = " "
  )
  words <- regmatches(
    abstract,
    gregexpr("\\b[[:alnum:]][[:alnum:]'-]*\\b", abstract, perl = TRUE)
  )[[1L]]
  testthat::expect_lte(length(words), 250L)
})

testthat::test_that("v9 supplement and highlights are synchronized", {
  root <- repo_file(
    "manuscript", "journal_submission",
    "marine_environmental_research"
  )
  supplement <- file.path(root, "rendered_v9", "mer_supplement_v9.docx")
  highlights <- file.path(root, "rendered_v9", "mer_highlights_v9.docx")

  testthat::expect_true(file.exists(supplement))
  testthat::expect_true(file.exists(highlights))
  supplement_text <- docx_plain_text(supplement)
  testthat::expect_match(
    supplement_text, "Complete primary and nearest-event A14 results",
    fixed = TRUE
  )
  testthat::expect_match(
    supplement_text, "245", fixed = TRUE
  )
  testthat::expect_match(
    supplement_text, "Surfbird", fixed = TRUE
  )
  testthat::expect_match(
    supplement_text, "Western Grebe", fixed = TRUE
  )

  highlight_source <- readLines(
    file.path(root, "source_v9", "mer_highlights_v9.qmd"),
    warn = FALSE, encoding = "UTF-8"
  )
  bullets <- highlight_source[grepl("^- ", highlight_source)]
  testthat::expect_equal(length(bullets), 5L)
  testthat::expect_true(all(nchar(sub("^- ", "", bullets)) <= 85L))
  testthat::expect_false(any(grepl(
    "detection|flock size", bullets, ignore.case = TRUE
  )))
})
