# Phase 1 — Source metadata audit

## Objective

Recompute and verify the Version 2 metadata audit directly from the configured local source files before constructing any bird response.

## Required actions

1. Verify file existence, size, SHA-256, EBD/SED release compatibility, and shapefile sidecars.
2. Confirm exact EBD, SED, and herring headers against `R/metadata_audit.R`.
3. Reproduce raw SED protocol, complete-list, county, group-list, and effort missingness/range summaries.
4. Reproduce herring missingness, ranges, Method levels, component-observation patterns, date anomalies, and event-key uniqueness.
5. Compare all values with `docs/00_METADATA_AUDIT.md`. Differences are reported, not silently forced to match.
6. Produce aggregate CSV/JSON and a Quarto report. Do not write row-level eBird records.
7. Add tests for all source key and unit assumptions.
8. Stop for human review after the metadata report. No zero filling, exposure assignment, or bird-response model is authorized in Phase 1.
