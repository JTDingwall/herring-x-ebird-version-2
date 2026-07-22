# Stage 4A v2 manuscript reproducibility

## Frozen analysis

- Repository: `https://github.com/JTDingwall/herring-x-ebird-version-2`
- Analysis-freeze commit: `c54b8e7f95a2fe3573e2e38633079cd223c5a783`
- Analysis-freeze tag: `stage4a-publication-v2-analysis-freeze`
- Manuscript branch: `codex/stage4a-manuscript-submission-v2`
- Maximum response year read by protected execution: 2025
- 2026-or-later response rows read: 0

## Rebuild the aggregate manuscript package

The build consumes only tracked privacy-safe aggregate CSV, Markdown, YAML, and SVG artifacts. It does not fit a response model.

```powershell
$env:RENV_CONFIG_AUTOLOADER_ENABLED = "FALSE"
Rscript --no-init-file scripts/build_stage4a_manuscript_package_v2.R .
```

Render the manuscript and supplement with the pinned Quarto executable available in RStudio or another compatible Quarto installation:

```powershell
./scripts/render_stage4a_manuscript_v2.ps1
```

The Windows renderer uses Quarto for HTML and DOCX. When Microsoft Word is available, it exports the final DOCX files to PDF. On Linux CI, Quarto plus LibreOffice provide the corresponding render path. PDF bytes can differ by office renderer, so source and numerical audits are authoritative; each released PDF is nevertheless recorded by SHA-256 and visually checked.

## Validation

```powershell
./scripts/validate_stage4a_manuscript_v2.ps1
```

The validator checks source counts, claim keys, percentages and denominators, citations, table/figure numbering, prohibited v1 and M26 claims, causal wording in the conclusion, absence of 2026-or-later results, singular-fit disclosure, specificity-panel wording, privacy-sensitive tokens, provenance hashes, and immutable frozen artifacts. The repository test suite, registry validation, privacy scan, and historical hash tests are run separately and in GitHub Actions.

## Authorized reconstruction of protected analysis

Raw eBird EBD/SED and row-level derivatives are not distributed. An authorized researcher must obtain the applicable EBD/SED release under eBird terms, obtain the official DFO inputs, reproduce the input hashes recorded by the protected execution, and use the frozen code and specifications at the analysis tag. The public repository is intentionally not self-contained with respect to restricted checklist rows.
