# D10 — Confidence interval method

Read from `R/post_stage4a_sog_event_study_v1.R` (lines 460-495), for both
outcomes:

- A contrast is a fixed linear combination `L` of the fixed-effect vector.
- Estimate `= sum(L * beta)`; variance `= t(L) vcov(fit) L` using `vcov(fit)`
  (the fixed-effect covariance); `SE = sqrt(variance)`.
- **Interval: Wald z on the link scale,** `estimate +/- 1.959963984540054 * SE`.
- p-value: two-sided Wald z, `2 * pnorm(-abs(estimate / SE))`.
- Reported ratio and its limits are the exponentiated link-scale estimate and
  limits.

So all reported intervals are exponentiated Wald z intervals; none is a profile
or bootstrap interval. For the binomial detection models fitted with `nAGQ = 0`,
the fixed-effect covariance is the adaptive Gauss-Hermite order-0 (Laplace-style)
approximation. State this in Methods (Phase 3 item 5), with the `nAGQ = 0` caveat
addressed by the S2 sensitivity if Phase 2 is authorised.
