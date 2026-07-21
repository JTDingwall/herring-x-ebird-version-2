# Stage 4A aggregate pooling repair specification v2

Status: **specification only; numeric execution is prohibited in this change**.

## Controlling scope and discovered count discrepancy

The released `partial_pool_estimate` and `partial_pool_standard_error` fields are
invalid. They were constructed in families keyed only by region, outcome, and
contrast, so they mix models or unit classes and can count the M11/M12 component
representations twice. Individual estimates, standard errors, confidence intervals,
p-values, and model-specific BH q-values remain intact and are not superseded.

The merged audit reports 4,890 finite rows in 84 families. Re-reading the tracked CSV
while preserving the registered literal region code `NA` finds 6,562 finite rows in
112 families. The difference is exactly 1,672 rows and 28 families from the North
region: base `read.csv()` treated the text `NA` as a missing value, and `interaction()`
dropped those rows. The machine-readable files preserve both the authorized legacy
4,890/84 subset and the exact 6,562/112 tracked scope. All released finite v1 pooling
values are invalid. A later execution must fail closed until a human explicitly accepts
the expanded exact scope.

## Outcome-independent family identity

`pooling_family_id_v2` is a SHA-256-derived identifier built only from frozen metadata.
The only field allowed to vary inside a family is `stable_unit_id`—an
`analysis_taxon_id` for species or the registered `guild_id` for guilds. Every family
holds invariant the canonical model, architecture, component estimand, response state,
unit class, effect scale, exposure definition, temporal window, spatial buffer,
analysis population, adjustment set, component role, coefficient meaning, and variance
meaning. Region and contrast enter those frozen meanings and therefore cannot be pooled
across.

No outcome value, magnitude, sign, interval, p-value, q-value, status, or model-fit
result may create, split, merge, or otherwise alter a family. Missing or ambiguous
identity fails closed. Singletons remain explicit with `NON_ESTIMABLE_SINGLETON`; they
are never forced into another family.

Canonical serialization uses a fixed field order. Each trimmed UTF-8 scalar is encoded
as byte length plus lowercase hexadecimal bytes, fields are joined with a fixed
separator, and the identifier uses the first 24 hexadecimal characters of SHA-256 with
a typed prefix. Collision audits compare every identifier with its complete canonical
identity and fail on disagreement. This is independent of display labels and row order.

## Component evidence and M11/M12

`component_evidence_id` adds stable unit, registered region, and contrast to the family
identity. It identifies the underlying fitted component, not its displayed row.

The historical production code copies M01/M02 component rows and relabels them M11/M12.
The core methods document likewise says M11 detection and M12 positive-lognormal rows
are implementation components rather than independent evidence. The frozen precedence
rule therefore retains M01/M02 as the primary compound-model representation and excludes
the corresponding M11/M12 row with
`EXCLUDED_DUPLICATE_COMPONENT_REPRESENTATION`. Effect size, sign, significance, interval
width, and desirability play no role. The duplicate audit links every exclusion to its
selected representation and semantic source.

## Frozen future estimator contract

The later repair will use a normal-normal empirical-Bayes model separately within each
compatible family. For eligible component estimate `y_i` and standard error `s_i`, the
sampling variance is `v_i = s_i^2`. The method-of-moments between-component variance is
`tau^2 = max(0, sample_variance(y) - mean(v))`; family weights are
`1 / (v_i + tau^2)` and the family mean is their weighted mean. When `tau^2 > 0`, each
component posterior uses the ordinary normal-normal conjugate mean and reciprocal-sum
precision variance. At the zero boundary, all components receive the common
inverse-variance family mean and its variance `1 / sum(1/v_i)`. This boundary rule avoids
the historical artificial `1e-12` precision behavior.

At least two eligible components are required. Missing inputs, non-finite inputs, or a
nonpositive standard error exclude that row with a reason code and trigger a recount;
fewer than two remaining components yields an explicit NA singleton result. An
incompatible scale or compatibility violation fails the entire family. Duplicate
resolution occurs before estimation. Ninety-five-percent intervals use the standard
normal quantile `1.959963984540054`. The repair produces no pooled p-values or q-values.
It performs no rounding before serialization, writes decimal-point numerics at 17
significant digits, sorts by family then evidence ID, and requires no random seed because
the algorithm is closed form.

## Versioning, outputs, and later execution

Every v1 file remains immutable. Future outputs use new v2 filenames and supersede only
the two invalid pooling columns; every unaffected field must match the v1 source exactly,
including missingness and textual representation. No value is written back into v1.
The future execution record must capture all input and code hashes, validators, software
versions, and UTC time, followed by an output hash manifest.

The separate execution PR will consume tracked privacy-safe aggregates and frozen
metadata only. It will implement this contract, compare unaffected fields byte-for-byte
or by the declared typed serialization, regenerate aggregate-only reports, publish
hashes and a supersession manifest, and fail on any compatibility or scope violation.
It will not rerun the protected builder, response models, M27/M28, WCVI sensitivities,
M26, Stage 4B, or a holdout. This specification PR creates no repaired estimate,
standard error, interval, p-value, or q-value.

## Machine-readable artifacts

- `metadata/stage4a_pooling_repair_spec_v2.yml`: controlling contract.
- `metadata/stage4a_pooling_v1_invalidation_manifest.csv`: exact invalid columns,
  immutable input hash, unaffected columns, and both scope counts.
- `metadata/stage4a_pooling_family_registry_v2.csv`: compatible v2 families.
- `metadata/stage4a_component_evidence_registry_v2.csv`: selected evidence identities.
- `metadata/stage4a_pooling_v1_to_v2_crosswalk.csv`: complete row crosswalk.
- `metadata/stage4a_pooling_row_disposition_v2.csv`: inclusion/exclusion accounting.
- `metadata/stage4a_m11_m12_duplicate_resolution_v2.csv`: duplicate precedence audit.
- `metadata/stage4a_pooling_family_compatibility_audit_v2.csv`: invariant checks.
- `metadata/stage4a_pooling_v1_family_invalidation_audit.csv`: exact 112-family scope.
- `metadata/stage4a_pooling_legacy_4890_row_84_family_audit.csv`: legacy audit subset.
- `metadata/stage4a_pooling_artifact_schema_v2.csv`: schemas for current and required
  future artifacts.
- `metadata/stage4a_pooling_reason_codes_v2.csv`: closed reason-code vocabulary.

The only unresolved gate is explicit acceptance of the corrected 6,562-row/112-family
scope. No estimator or identity decision remains unresolved.
