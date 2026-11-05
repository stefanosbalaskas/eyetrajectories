# Batch 18: fractional physical-time W4 recurrence workflow source domain

Frozen Python 1.2 `RecurrenceWorkflowConfig` accepts finite positive fractional physical-time durations for `delay` and finite nonnegative fractional physical-time durations for `theiler_window`. Its execution converts those durations to exact integral sample offsets on the actual regular trajectory grid, and rejects conversions not close to integers. It also supports `cityblock`, `euclidean` and `chebyshev` metrics.

The pre-existing native R executor already implements the time-unit conversions and three recurrence metrics. However, `etr_frozen_recurrence_workflow_config()` previously required an integer numeric delay and Theiler window even for physical-time units. This batch corrects the **constructor's accepted numeric domain** without rounding, truncation or introducing hidden interpolation. Values in `samples` units remain integral.

Existing `test-native-source-time-units.R` adds a 21-point two-channel fixture with 37.5 ms delay and 12.5 ms Theiler window on a 12.5 ms grid. It checks three metrics, equivalent seconds/samples representations, invalid fractional sample lags and direct frozen Python 1.2 workflow embedding and binary recurrence matrix outputs. This is a developer source comparison, not full-domain independent certification.

The 203 callable source-gap records and one nonfunction gap remain open. The previous `run_recurrence_workflow` ledger description mistakenly said native R omitted L1/L-infinity and physical time; that statement was stale. This batch updates the descriptive gap without clearing the unresolved flag. Native records are not Python frozen dataclasses and measured R elapsed timings cannot be Python elapsed timings.
