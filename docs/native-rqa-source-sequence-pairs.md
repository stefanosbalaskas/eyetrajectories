# Frozen Python 1.2 windowed-RQA pair sequence domain — Batch 09

Source: `src/eyetrajectoriespy/functional_rqa.py::_validated_window_step_pairs`, frozen SHA `c1cd95ad718327550f7e55393ff38582872f7a94`.

The source accepts two-element Python `Sequence` pairs containing a mix of integer and floating-point values. It rejects booleans, strings, nonfinite numbers, empty specifications, and malformed pair lengths. Sample units must subsequently resolve to integer sample counts. The R source analogue now supports `list(list(5L, 2.0), list(7.0, 3L))` while retaining its existing numeric-vector and two-column matrix convenience representations.

This change does **not** choose an optimal RQA specification, estimate independent-information resolution, or modify recurrence calculations. It does not imply independent validation of the full scientific contract. Both resolved sample units and physical-time windows are explicitly tested in native R, with a direct pinned-Python source comparison for output tables.

The source-gap ledger's `windowed_rqa_sensitivity` row remains `unresolved_source_gap=TRUE`. Cross-language dataclass class identity, complete exceptional inputs, and independent full-contract review remain open; certificates remain 0/508.
