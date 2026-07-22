# Minimum external DFO survey-coverage data request

Request data at the finest defensible survey-operation or coverage-unit grain, subject
to DFO disclosure controls. Each delivery should include a stable survey/event and
source-record identifier; survey date; start and end time where available; section,
location, and stock-assessment region; searched shoreline or survey geometry (or a
secure versioned geometry reference); method; completion status; effort and unit;
searched extent and unit; proportion of expected area covered; detection threshold or
minimum detectable spawn; quality and confidence fields; reason for incomplete,
cancelled, or absent adequate coverage; positive-spawn evidence; explicit negative-
survey evidence; and complete source, release, revision, and revision-time provenance.

Every registered coverage cell must have exactly one mutually exclusive state:
`surveyed_positive`, `surveyed_negative`, or `unmonitored_unknown`. A positive requires
a completed search, a detection, and positive evidence. A negative requires a completed
search, adequate recorded effort/extent/coverage, a documented threshold, no detection,
and explicit negative-survey evidence. A missing record is not a surveyed negative.
Incomplete coverage cannot silently become a surveyed negative. Unknown coverage stays
unknown unless the completion, search, effort, threshold, and detection requirements are
met. Planned, cancelled, or incomplete events may retain stable provenance identifiers,
but must state the incomplete-coverage reason and may not carry a completed-survey or
detection claim.

The delivery contract is defined in `metadata/dfo_survey_effort_schema.csv` and enforced
by `validate_dfo_survey_effort()`. Exact operational geometry and sensitive identifiers
should remain in an authorized environment; tracked derivatives use generalized or
hashed references only. This document is a request specification: it does not contact
DFO, download data, or authorize synthetic records to be treated as production data.
