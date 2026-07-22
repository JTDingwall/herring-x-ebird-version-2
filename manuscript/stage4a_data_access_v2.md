# Data-access and code-availability statements

## Data availability

Open DFO-derived inputs are available from the Government of Canada Open Government Portal under the source licence and with the documented monitoring and relative-index caveats. Redistributable aggregate products in this repository include model coefficients, intervals, multiplicity results, pooling-family summaries, diagnostic status, sensitivity outputs, claim audits, provenance records, and publication figures.

The eBird Basic Dataset and Sampling Event Data require access under eBird terms. Raw EBD/SED, source checklist rows, observer identities, exact localities, exact coordinates, event tokens, transformation mappings, and protected row-level derivatives are not redistributed. Privacy-safe publication outputs are sufficient to audit the reported aggregate results but not to reconstruct protected rows.

Missing herring components are not zeros. Surveyed-positive, surveyed-negative, and unmonitored-unknown states remain distinct. The DFO spawn index is a relative index of spawning biomass and is not absolute biomass.

## Code availability

Analysis and manuscript-generation code are available at `https://github.com/JTDingwall/herring-x-ebird-version-2`. The frozen analysis is commit `c54b8e7f95a2fe3573e2e38633079cd223c5a783`, tag `stage4a-publication-v2-analysis-freeze`. The manuscript package is built from privacy-safe aggregate artifacts and does not rerun production response models or protected sensitivities.
