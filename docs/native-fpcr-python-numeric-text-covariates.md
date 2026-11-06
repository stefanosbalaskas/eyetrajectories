# Optional native numeric-text covariates: Python 1.2 end-to-end boundary

Baseline: `fa210f9`. Python frozen source `c1cd95ad718327550f7e55393ff38582872f7a94`.

A source audit identified a subtle distinction: Python `prediction.py::_validate_covariates` calls `covariates.to_numpy(dtype=float)`, which accepts finite numeric text and Boolean columns. But the Python validator then returns the **original** DataFrame, and its downstream `statsmodels.OLS` rejects object-dtyped columns (`Pandas data cast to numpy dtype of object`). Consequently, a successful standalone validator conversion does **not** imply that the full Python 1.2 CV estimator accepts these inputs.

To preserve source-safe native defaults, `coerce_numeric_text_covariates=FALSE` remains the default in both `etr_cross_validate_fpca_regression()` and `etr_nested_cross_validate_fpca_regression()`. This batch implements **explicit opt-in** `TRUE` as a useful native R extension: finite decimal text, exponents and interdigit underscores are parsed per column, alongside numeric and logical columns, with invalid or nonfinite values rejected.

Tests verify the default rejection, opt-in-vs-numeric equivalent R results, explicit frozen Python object-type rejection, and comparison with Python after the *original* DataFrame is explicitly converted to numeric (`astype(float)`). The nested CV test confirms the same numerical predictions using opted-in text and numeric inputs. None of these tests supports full-domain Python source parity or independent certification. The 204 unresolved strict source flags are unchanged.
