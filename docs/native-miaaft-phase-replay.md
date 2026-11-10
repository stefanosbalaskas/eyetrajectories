# Periodic MIAAFT phase replay

The 96-sample, three-channel periodic witness uses reference channel $y$,
seed 17, three surrogates, and a two-sided Lyapunov test. The source oracle
is EyeTrajectories Python 1.2.0 at
`c1cd95ad718327550f7e55393ff38582872f7a94`. Both runtimes receive the same
time and value arrays.

## First numerical difference

The seeded initial permutations agree exactly. The first target FFTs
differ by at most $1.28\times10^{-14}$ in complex magnitude. The reference
channel has signal at Fourier bins 5 and 11. At bins 4, 9, and 13 the
reference has roundoff-scale amplitude, while another selected channel
has a signal. Computing an angle for the small reference coefficient
amplifies the FFT difference and rotates the strong channel's coefficient.
The first phase offsets differ by up to 5.97 radians before wrapping.
The adjusted spectra differ by 7.18, the inverse transforms differ by
0.198, and 148 of the 288 rank positions then differ. The same mechanism
can occur in the current reference spectrum on later iterations.

## Replay

`etr_generate_multivariate_iaaft_surrogates()` and
`etr_multivariate_surrogate_nonlinearity_test()` accept `phase_replay`.
The optional `target` matrix contains half-spectrum phases for the
original selected channels. The optional `reference` list contains one
iteration-by-frequency matrix per surrogate. Radians replace phases
only at locally unresolved coefficients. An `NA_real_` entry keeps the
native phase. DC and the even-length Nyquist bin retain the original real
coefficients. Native R still computes FFT amplitudes, projected signals,
stable ranks, stopping decisions, and test statistics. By default it
uses native FFT phases.

Run the witness with the pinned Python oracle available.

```sh
Rscript --vanilla scripts/trace_miaaft_source_witness.R
```

The script writes a per-iteration trace, a replay RDS, strict comparisons,
and backend diagnostics under `artifacts/native_batch_numeric_diff/<first 12 characters of R SHA>`.
The saved replay can be supplied to the native function with the same
input, seed, selected channels, and convergence controls.

## Observed scope

| Quantity | Native R default | Frozen Python with NumPy 2.3.5 | Native R with replay |
| --- | ---: | ---: | ---: |
| Two-sided p-value | 1 | 0.5 | 0.5 |
| Observed Lyapunov statistic | 12.1079185278 | 12.1079185278 | 12.1079185278 |
| First surrogate statistic | 14.4552578132 | 15.4453829561 | 15.4453829561 |
| Second surrogate statistic | 11.3022383181 | 12.3858675797 | 12.3858675797 |
| Third surrogate statistic | 15.5703527245 | 13.0320403737 | 13.0320403737 |

All replayed surrogate values, rank orders, and iteration counts
(12, 5, and 9) agree on this Linux run. The maximum replayed inverse FFT
difference across all 26 iterations is about $3.2\times10^{-14}$.
The supported $x,y$ cross-spectral error agrees within $1.5\times10^{-16}$.
The other two channel pairs have no shared signal harmonics. Their
cross-spectral norms are effectively zero and their native relative
error diagnostics remain backend-sensitive even for identical surrogates.
The largest absolute discrepancy is about $5.91\times10^{11}$
against a source relative error of $1.19\times10^{13}$.
The trace reports this sensitivity separately from the replay checks.
The result is bounded to the tested fixture and numerical backends.
