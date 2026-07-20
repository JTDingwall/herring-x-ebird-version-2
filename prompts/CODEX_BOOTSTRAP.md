# Codex bootstrap instruction

Work only in `herring-x-ebird-version-2`. Do not edit or rerun the Version 1 repository.

1. Read `README.md` and every file under `docs/`.
2. Run the test suite.
3. Do not read bird outcomes until Phase 1 metadata and source checks pass and their report is committed.
4. Never commit EBD/SED rows, checklist IDs, observer IDs, locality IDs, or exact checklist coordinates.
5. Implement one bounded phase at a time. Every stage writes row accounting, schema checks, key/cardinality checks, missingness, units, and provenance.
6. Do not choose filters, count families, radii, timing windows, or model variants based on the sign or significance of herring effects.
7. Retain all prespecified model results in a machine-readable registry.
