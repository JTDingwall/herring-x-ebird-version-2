# Data governance and privacy

## eBird

The EBD and SED are restricted and may not be redistributed. Do not commit:

- raw or filtered EBD/SED rows;
- sampling event identifiers;
- source observer identifiers;
- exact locality identifiers or names;
- exact checklist coordinates;
- record-level review samples;
- row-level maps that permit reconstruction.

Use source identifiers in memory or ignored local files only. Public outputs use aggregate counts, generalized grids/shoreline units, and privacy-reviewed summaries.

## Herring

DFO herring records are open, but Version 2 still keeps raw source files immutable and records checksums. Derived event IDs may be public only after checking that they do not encode restricted eBird information.

## Repository checks

Tests scan tracked text and tabular files for known restricted field names and coordinate-like columns. A release is blocked if raw-data paths, exact IDs, or row-level coordinates are tracked.

## Reproducibility

The public repository should contain:

- code;
- configuration;
- source versions and checksums;
- taxonomy/guild metadata;
- aggregate QA;
- synthetic test fixtures;
- model summaries and figures that satisfy privacy rules.

A local authorized analyst can reproduce the analysis by setting environment variables to the protected source files.
