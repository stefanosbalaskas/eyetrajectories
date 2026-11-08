# Frozen Python 1.2 mixed-scalar simplex boundaries — local Batch 08

Frozen source: `eyetrajectoriespy==1.2.0`, commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.

| Export | Native entry point | Newly supported, explicit Python boundary mode | Still unresolved |
|---|---|---|---|
| `alr_transform` | `etr_alr_transform` | Rectangular three-level lists containing mixed `logical`, numeric, numeric-text scalar leaves; elementwise dtype=float conversion | Arbitrary Python object protocols and exact exception classes |
| `inverse_alr` | `etr_inverse_alr` | The same scalar-leaf domain, plus bounded NumPy-compatible `NaN`/`Inf` inverse-logratio arithmetic | Full source accepted domain and cross-language result/error classes |
| `validate_simplex` | `etr_validate_simplex` | Source-mode Boolean/text/complex ndarray, fully nested mixed scalar leaves, empty curve/time axes | Other NumPy object classes and exact Python errors |

The default native scientific validation remains unchanged. No Python
interpreter is called by these R functions. The direct source oracles live in
`tests/testthat/test-native-alr-mixed-nested-source.R`.

The qualified R/Python test modes are **developer evidence**, not independent
scientific review. The 203 callable plus 1 nonfunction source-gap inventory is
**not reduced or certified by this batch**. The `alr_transform` and `inverse_alr`
CSV descriptions are refreshed to avoid incorrectly describing already resolved
subdomains, while `unresolved_source_gap` remains `TRUE` for both.

Prior qualified baseline: native R commit `6cf586a` (the user's archive).
This batch must be retested in RStudio against a new exact local HEAD.
