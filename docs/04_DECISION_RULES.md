# Decision rules: less conservative without becoming result-seeking

## 1. Why Version 1 was too conservative

Version 1 sometimes treated any diagnostic warning as a universal stop: many correlated residual tests, fold-specific range exceedance, exact deletion of every event, and thousands of full model refits. These requirements were not always aligned with the scientific contrast and could prevent any conclusion.

Version 2 distinguishes hard failures from interpretable limitations.

## 2. Hard stops

Stop a stage when there is:

- source checksum/version mismatch without approval;
- duplicate or inflated keys after a join;
- leakage of restricted eBird identifiers or exact coordinates;
- impossible exposure classification or unit error;
- deterministic separation or empty comparison support;
- non-identifiability demonstrated by simulation or posterior geometry;
- persistent nonconvergence after a prespecified simpler reparameterization;
- predictions required outside the support of the estimand;
- invalid count coercion, including treating `X` or missing components as zero.

## 3. Warnings that do not automatically stop all analysis

Continue, report, and run targeted sensitivity when there is:

- one residual envelope breach among many correlated checks;
- imperfect absolute calibration while relative contrasts remain stable;
- moderate imbalance that is adjusted and disclosed;
- a single influential event below the material-shift threshold;
- disagreement in one geometry, radius, or timing sensitivity;
- sparse support for one species while its guild remains supported;
- spatial structure in baseline prevalence that disappears in the target within-event contrast.

## 4. Multiplicity

The principal hypotheses are guild- and mechanism-level, not 45 unrelated null tests. Primary inference uses hierarchical partial pooling and prespecified guild contrasts. Species estimates remain visible. For frequentist species tables, use Benjamini–Hochberg FDR within coherent families rather than a single Holm family-wise correction across every exploratory species and model. Unadjusted estimates and intervals are also shown.

This does not authorize selective claims. All species and all model families remain in the results registry.

## 5. Model-family selection

Count families are selected by simulation, predictive performance, residual checks, and ecological realism. AIC, LOO, or cross-validation may compare compatible likelihoods. The herring coefficient's sign or p-value is never a selection criterion.

## 6. Evidence synthesis

A conclusion is classified as:

- **strongly supported:** consistent direction and biologically meaningful magnitude across at least two independent design families, with no decisive placebo or observation-process contradiction;
- **supported with qualifications:** coherent primary family plus partial support elsewhere, with identified limitations;
- **mixed:** signs or magnitudes differ materially among defensible designs;
- **not supported:** estimates center near null across designs with adequate precision;
- **contradicted:** robust effects oppose the prespecified prediction;
- **not estimable:** support or identification is inadequate.

## 7. Clustered uncertainty

The default uncertainty unit is the herring event, with observer/location/year sensitivity. Use at least 999 event-cluster bootstrap replicates for frequentist core contrasts when feasible, or a hierarchical Bayesian model with explicit event dependence and posterior predictive checks. Row-wise iid standard errors are not sufficient.

## 8. Post-result status

The old outcomes have been inspected. Version 2 analyses on the same 2015–2025 data are exploratory or estimand-refining. The first confirmatory test must use frozen models on new 2026+ data or an independently frozen region.
