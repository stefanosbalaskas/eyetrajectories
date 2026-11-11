# Two new complete native-language semantic catalog closures

**Frozen oracle:** `eyetrajectoriespy==1.2.0`, Python Git commit
`c1cd95ad718327550f7e55393ff38582872f7a94`.

**Scope:** developer-side, *native R scientific semantics*, not exact Python
object-identity emulation or independent certification.

## Reviewed policy decision

For an API whose entire accepted argument domain consists of **zero
arguments** and whose result is a **finite immutable-source metadata
catalog**, the native R representation is an ordered, **named list of
language-native S3 records**. It is deemed scientifically equivalent to
an ordered Python tuple of frozen dataclasses when every source record
and scalar or tuple field is identical in name, position, content, value
order and UTF-8 bytes, and neither an extra positional nor an extra
named argument is accepted. A second native call returns the same
canonical values, and mutations of caller-owned returned copies do not
alter the canonical catalog.

This policy does **not** claim `isinstance(..., tuple)`, Python
`dataclass` class identity, tuple hashability, shared Python object
identity or assignment raising `FrozenInstanceError` in R. These
language-specific properties are deliberately represented using native
R structures with copy-isolated behavior. We treat them separately
from scientific metadata equivalence.

This is the same explicit cross-language principle previously applied
to Python pandas `DataFrame` and native R `data.frame` in two source
table closures.

## Exhaustive closed contract register

| Frozen Python function | Native R function | Records | Fields | Function input domain | Source result |
| --- | --- | ---: | --- | --- | --- |
| `list_mathematical_contracts()` | `etr_list_mathematical_contracts()` | 41 | `key, title, public_api, equations, site_anchor, scope` | No parameters | All ordered frozen records and nested ordered public API/equations values |
| `functional_recovery_metric_catalog()` | `etr_functional_recovery_metric_catalog()` | 27 | `name, quantity, direction, units, scope, description` | No parameters | All 27 ordered frozen metric definitions |

There is no numerical tolerance, resampling stream, fitting estimator
or scientific prediction in either function. Every record is a frozen
reference value; therefore *complete* value-domain comparison is finite.

The Python-side source is
`src/eyetrajectoriespy/mathematical_contracts.py` and
`src/eyetrajectoriespy/recovery.py` at the frozen commit. The native
R implementations are `R/native-math-contracts-diagnostics.R` and
the recovery metric catalog exposed as
`etr_functional_recovery_metric_catalog`.

## Source evidence and review protocol

The new gate is
`tests/testthat/test-native-zeroarg-catalog-source-semantic-closures.R`.

It validates: zero-formal-argument native signatures; each R record's
exact six field names and order; `41` or `27` records and stable ordered
names; repeated call determinism; caller-copy isolation; rejection of
extra positional and keyword arguments; direct Python 1.2 tuple and
frozen-dataclass identification; all six source fields for all records,
including nested tuple values, using exact UTF-8 bytes; and the frozen
source's own rejection of extra arguments.

Existing supplementary source checks include
`test-native-catalog-contract-boundaries.R` and
`test-native-math-contracts-diagnostics.R`. The source-gap record
`inst/extdata/native_source_contract_gaps_stage22.csv` retains each
historical row and its source witness but changes
`unresolved_source_gap` to `FALSE` for **these two names only**.

This is a developer semantic gap closure, subject to CI and independent
scientific audit. The separate `one_to_one_native_contract_complete`
and `independent_numeric_parity_pass` flags remain **FALSE** until
independent review. A CI pass must not be misreported as independent
certification.

## Exact inventory reconciliation

Before this change (PR #79 at `d5a9b287a841b8a17091f92e08dc4b8130991568`):
- gap-free: **306/508**
- unresolved callables: **201**
- unresolved noncallables: **1**
- independent certifications: **0**

After the two explicit semantic closures, provided the exact-head
source gate passes:
- gap-free: **308/508** (60.63%)
- unresolved callables: **199**
- unresolved noncallables: **1**
- independent certifications: **0**

The next `get_mathematical_contract(name)` record is **not** closed:
its open argument coercion, shaped NumPy objects, arbitrary Python
equality protocols and error-type boundaries do not meet the same
finite-domain condition. Similarly, no estimator, plotting, MIAAFT or
mixed-effects gap is closed by these metadata decisions.
