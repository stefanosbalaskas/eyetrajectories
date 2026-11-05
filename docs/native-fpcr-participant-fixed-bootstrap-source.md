# Frozen Python 1.2 participant FPCR bootstrap — fixed whole-group replay

## Scope

`etr_bootstrap_fpca_regression_uncertainty()` now accepts externally supplied
zero-based **expanded source-curve index vectors** in `bootstrap_indices` for
`resample_unit="participant"` as well as `"curve"`. The `participant_column`
remains mandatory for participant resampling.

Python `regression_inference.py::_participant_bootstrap_indices` samples one
participant label per original independent participant, with replacement,
then expands each selected participant to **every original source curve in
original row order**. Thus index vectors can have different lengths if
participants contain unequal numbers of curves. Repeated whole groups are
allowed, and partial/scrambled groups are rejected. The validation enforces
exactly the original number of participant draws, not exactly the number of
source curves. Each paired response is indexed by the same expanded row order.

The R implementation fits FPCA/MFPCA and Gaussian scalar score regression
on each complete bootstrap sample, then reports original-unit slope and
fixed-target conditional-mean percentile intervals.

## Deterministic numerical evidence

`test-native-fpcr-bootstrap-uncertainty.R` tests (1) unequal-sized original
groups, duplicates and malformed partial-group rejections; (2) R RNG state
isolation; (3) **direct frozen Python 1.2 paired bootstrap under a pinned
fixed participant-index source helper**, comparing every bootstrap slope,
intercept, conditional-mean prediction, pointwise slope quantile/SE, and
target-prediction quantile/SE with native R under identical samples.

This is a scientific replay for a declared subset. It does **not** imply
cross-language NumPy seed equivalence, generic statsmodels/R-lm optimizer
identity, a matching typed return class, or independent full-contract
certification. Source gap remains unresolved.
