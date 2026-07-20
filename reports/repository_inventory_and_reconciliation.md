# Repository inventory and reconciliation

## Pre-implementation inventory

The initial clean Version 2 scaffold contained a useful scientific blueprint but conflicting machine-readable assets:

- a 58-row broad candidate species file and a 47-row legacy-derived support file;
- nine guild rows, one of which represented an exclusion status rather than a biological guild;
- a 33-row CSV model registry, a separate YAML model registry, and 12 proposed additions;
- a 50-row analysis-module registry with a distinct identifier system;
- stale 47/45-species test assertions and fixed 1 km through 50 km distance rings;
- no lockfile, CI workflow, canonical estimand registry, co-occurrence registry, or value-aware privacy scanner;
- several superseded setup prompts and stale paths in the README.

No Version 2 bird-response values were inspected while making this inventory.

## Reconciliation decisions

| Concept | Canonical count | Decision |
|---|---:|---|
| Species | 58 | Keep every broad candidate visible; 45 legacy-supported taxa are design-registered, two legacy exclusions require reassessment, and 11 additions require taxonomy and support review. |
| Guilds | 8 | Normalize identifiers to the legacy-reviewed mechanisms; represent exclusion as species status rather than a ninth guild. |
| Estimands | 15 | Separate ecological quantities from their statistical implementations. |
| Models | 45 | Merge the 33 original entries with 12 prespecified additions and map every model to one approved estimand and module. |
| Co-occurrence | 9 | Register raw, null-adjusted, latent-factor, network, stability, diversity, and privacy-safe supporting architectures without selecting pairs from outcomes. |
| Analysis modules | 50 | Preserve the comprehensive blueprint and normalize columns, IDs, foreign keys, and status values. |

## Retired conflicts

The provisional species, guild, model-addition, and YAML model registries were removed after their content was reconciled. Superseded setup prompts were removed; `prompts/02_CODEX_BUILD_REPO_AND_PORT_V1_ASSETS.md` remains the canonical construction specification. The master prompt remains as a broader future-work instruction, not a competing setup prompt.

## Outcome-blind boundary

Registry support states were reconciled from previously audited metadata and scientific mechanism fields only. No Version 2 focal bird response, fitted estimate, coefficient, weight, model object, or outcome-dependent output was opened or created.
