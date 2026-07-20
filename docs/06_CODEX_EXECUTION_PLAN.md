# Codex execution plan

## Phase 1 — Re-audit metadata from source files

1. Verify all five checksums and shapefile sidecars.
2. Read headers and compare exact field sets.
3. Reproduce SED protocol, completeness, effort, group, date, and geography profiles.
4. Reproduce herring field missingness, ranges, method values, component patterns, and date anomalies.
5. Freeze a Version 2 input manifest and metadata report before reading bird outcomes.

## Phase 2 — Rebuild the complete-checklist universe

1. Process 1988–2025 January–June without applying the 2015 cutoff.
2. Preserve transparent exclusion flags rather than only a final eligible flag.
3. Deduplicate group checklists with a local source crosswalk.
4. Harmonize all registry taxa to pinned taxonomy.
5. Keep detection, numeric count, `X`, lower bound, and ambiguity as distinct fields.

## Phase 3 — Re-engineer herring exposure

1. Preserve the 13,332-row source master and multiple eligibility definitions.
2. Build start, midpoint, interval, and decay timing representations.
3. Build point, shoreline-projected, location-unit, and uncertainty-kernel geometry.
4. Construct all checklist–event candidate links through 50 km and −60:+90 days.
5. Build non-overlapping rings, additive binary exposure, and intensity-weighted exposure.
6. Audit multi-event membership without duplicating rows as independent observations.

## Phase 4 — Outcome-blind support and simulation

1. Calculate support by species, guild, ring, event day, year, event, observer, and location.
2. Simulate count families using observed zero rates, overdispersion, heaping, and cluster sizes.
3. Select model families and computational strategy without examining herring-effect estimates.
4. Freeze validation folds and model registry hashes.

## Phase 5 — Core analyses

Run M10, M11, M12, M20, M23, M30, M40, M41, and M50. Fit species models in parallel, then the hierarchical guild model. Save every model outcome to a registry.

## Phase 6 — Supporting analyses

Run same-location, same-observer, community, regional allocation, BACI-style, distributed-lag, phenology, and visitation models.

## Phase 7 — Validation and synthesis

Run event/year/section/spatial/observer holdouts, clustered uncertainty, date/location placebos, geometry/date sensitivities, and dominance checks. Classify evidence using `docs/04_DECISION_RULES.md`.

## Phase 8 — Freeze prospective test

Before adding 2026+ data, freeze code, parameters, species/guild registry, and claims. Use new events/checklists as prospective confirmation.
