# Native R empirical discrete and conditional transfer entropy

Independent Python-free plug-in transfer entropy, local information
histories, analyst-declared source-only circular shift nulls, Cartesian
specification sensitivity and transparent scientific reporting.

## Usage

``` r
etr_discrete_transfer_entropy(source, target, target_history, source_history,
  source_lag)
etr_transfer_entropy_local_frame(result)
etr_transfer_entropy_circular_shift_test(source, target, target_history,
  source_history, source_lag, shifts)
etr_conditional_transfer_entropy(source, target, condition, target_history,
  source_history, condition_history, source_lag, condition_lag)
etr_conditional_transfer_entropy_local_frame(result)
etr_conditional_transfer_entropy_circular_shift_test(source, target, condition,
  target_history, source_history, condition_history, source_lag, condition_lag,
  shifts)
etr_transfer_entropy_parameter_sensitivity(source, target, target_histories,
  source_histories, source_lags, shifts = NULL)
etr_transfer_entropy_reporting_text(result)
etr_transfer_entropy_circular_shift_reporting_text(result)
etr_conditional_transfer_entropy_reporting_text(result)
etr_conditional_transfer_entropy_circular_shift_reporting_text(result)
etr_transfer_entropy_parameter_sensitivity_reporting_text(result)
```

## Arguments

- source:

  Explicit one-dimensional finite integer-coded source states. No
  discretization is applied.

- target:

  Equally long one-dimensional finite integer-coded target states.

- condition:

  Equally long finite integer-coded conditioning-process states.

- target_history:

  Positive target history length in samples.

- source_history:

  Positive source history length in samples.

- condition_history:

  Positive conditioning history length in samples.

- source_lag:

  Positive declared source lag in samples.

- condition_lag:

  Positive declared conditioning-process lag in samples.

- shifts:

  Nonempty, unique integer circular offsets strictly between zero and
  series length; no shifts are generated.

- target_histories:

  Nonempty unique positive target-history grid.

- source_histories:

  Nonempty unique positive source-history grid.

- source_lags:

  Nonempty unique positive source-lag grid.

- result:

  Native discrete or conditional transfer-entropy result, shift-test
  result or sensitivity table.

## Value

A native empirical transfer-entropy result, fixed-surrogate null,
sensitivity result, exact-history data frame or transparent reporting
text.

## Details

All entropies are empirical plug-in conditional mutual information in
bits. No automatic discretization, history/lag tuning, support
filtering, shift generation or causal identification. Circular shifts
require an explicit defensible stationarity/wrap-around assumption. Test
p-values have plus-one Monte Carlo resolution; parameter sensitivity is
descriptive, not multiplicity-adjusted inference. The complete Python
public API certification gate remains closed.
