# Plot source participant functional random-effects scientific artists

Frozen Python eyetrajectoriespy 1.2.0 source-scientific plot geometry,
while preserving original native R scientific estimators and default
base R return values.

## Usage

``` r
etr_plot_functional_random_effects(result, effect = "intercept",
  max_participants = NULL, alpha = 0.35, strict_source_record = FALSE)
```

## Arguments

- result:

  Native realized participant mixed-model random-effect result,
  including source participant IDs and fitted random-intercept or
  random-slope functions.

- effect:

  Source participant functional intercept or slope.

- max_participants:

  Optional first number of participants. Strict source mode requires a
  positive R integer, matching Python's int requirement.

- alpha:

  Matplotlib source opacity between zero and one inclusive.

- strict_source_record:

  TRUE returns a typed native R Matplotlib scientific artist record,
  including per-participant source order, opacity, conditional legend
  and dashed zero line; default retains numeric source audit lines.

## Value

Default invisible original source-ordered R numerical line geometry.
Strict mode returns a typed native R scientific artist record with
source axes, original fitted participant BLUP functions, legend only for
at most 12 participants and zero reference. No Python Matplotlib Axes
identity, estimator refit or complete Python object domain.

## Details

Bounded native source-scientific artist parity only: no Python dataclass
or pandas runtime protocol, injected Axes identity, pixel rendering
equivalence, exception subclass identity, exact-head executable
qualification or independent full-source contract certification.
