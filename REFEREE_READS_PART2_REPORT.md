# Referee reads Part 2 execution report

Execution code commit: `ef5e3e5176e1b36c51323943af63b873d890deed`

Human authorization was supplied on 2026-07-25 as: “Run Part 2 now.” The
repository's exact through-2025 post-result-refinement acknowledgement was set
only in the execution process. The work was run in the isolated
`codex/referee-part2-run` worktree so the dirty manuscript branch and Part 1
artifacts were not changed.

The analyses remain post-result, exploratory estimand refinement. No claim in
this report is prospective or causal.

## Primary refit

Both fixture modes passed before production:

- `POST_STAGE4A_SOG_EVENT_STUDY_FIXTURE=PASS`
- `POST_STAGE4A_LAPLACE_SENSITIVITY_FIXTURE=PASS`

The full primary production refit then returned:

`POST_STAGE4A_SOG_EVENT_STUDY_GATE=PASS_PENDING_HUMAN_POST_STAGE4A_EVENT_STUDY_REVIEW`

The execution used all concurrent event links additively. The source-link hash,
event/link join cardinality, concurrent-link pairing, year, registered-taxon,
and frozen-output gates passed. It attempted all 100 registered components and
wrote 100 component summaries: 96 contain dimensionally valid fixed-effect and
covariance matrices, while four preserve the explicit failure status. The
eight-file output manifest recomputes exactly (8/8 SHA-256 matches).

### Active minus pre-onset result

The archived contrast is:

`did_active_0_14_day - did_pre_14_day`

BH adjustment was performed within each complete 49-species core family.

| Outcome | Registered core species | Estimable | Adjusted-significant positive | Adjusted-significant negative |
|---|---:|---:|---:|---:|
| Checklist reporting | 49 | 48 | 13 | 0 |
| Reported number conditional on a positive numeric report | 49 | 46 | 18 | 0 |

These are the prespecified acceptance counts. The absence of
adjusted-significant negatives is an observed result, not an execution gate.

### Component status

| Status | Components |
|---|---:|
| Completed | 95 |
| Completed with singular warning | 1 |
| Failed prespecified support | 3 |
| Failed numerical fit, no fallback | 1 |

The three support failures are the reported-number components for Surfbird,
Rhinoceros Auklet, and Glaucous Gull. The numerical failure is Glaucous Gull
reporting. They remain visible in the diagnostics; no fallback model was
silently substituted.

### Gradient limitation

The locked local R library did not contain `numDeriv`. The runner therefore
recorded `gradient_check_status = numDeriv_unavailable` for all 96 fitted
components and `not_fitted` for the other four. `max_abs_gradient` is `NA`, as
designed. No gradient distribution can be reported from this execution, and
the completed status must not be interpreted as a successful gradient check.

## Laplace sensitivity

The exact full-family `nAGQ = 1` reporting sensitivity was attempted with four
workers for one hour. All four workers remained responsive and CPU-bound, but
none of the first four fits completed. The attempt produced 0/49 checkpoints
and 0/49 model summaries before the process ceiling.

Status:

`COMPUTATIONALLY_INFEASIBLE_NO_COMPLETED_FIT_WITHIN_ONE_HOUR`

No smaller adjusted-significant-only family was substituted because its BH
q-values would not be comparable with the 49-species primary family. The
Laplace attempt yields no effect estimate and no evidence for or against
robustness.

## Artifacts

Primary versioned outputs:

- `outputs/post_stage4a_sog_event_study_v1_1/`
- `outputs/post_stage4a_sog_event_study_model_summaries_v1/`

Laplace feasibility record:

- `outputs/post_stage4a_sog_event_study_laplace_v1/infeasibility_record.yml`

## Governance checks

- The hash-locked `outputs/post_stage4a_sog_event_study_v1/` release was not
  modified or regenerated.
- No 2026-2028 response record was read.
- No M31 fit or interim holdout look was performed.
- No raw checklist, observer, locality, event, block, or coordinate identifier
  was released.
- The official repository privacy scanner passed across 775 text files when
  run inside the isolated Part 2 worktree.
- The primary execution record reports `records_2026_plus_read: 0`,
  `comments_read: 0`, `shoreline_fields_read: 0`, source-link hash gate `PASS`,
  and concurrent-link pairing gate `PASS`.
- Scientific interpretation remains pending human review.
