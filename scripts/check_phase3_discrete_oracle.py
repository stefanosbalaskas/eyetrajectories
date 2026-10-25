#!/usr/bin/env python3
"""Independent stdlib-only finite-sample Shannon CMI oracle for discrete TE.

No R code, no eyetrajectoriespy, and no TE library is imported. The reference
is fixed on a deterministically defined 31-bit integer LCG, with exact
multiplication below the IEEE-754 integer precision limit. Ref values are
not a claim of calibrated causal inference.
"""
from collections import Counter
from csv import DictReader
from math import isclose, log2
from pathlib import Path

def lcg_bits(n, seed):
    state = float(seed)
    sequence = []
    for _ in range(n):
        state = (48271 * state) % 2147483647
        sequence.append(int(state % 2))
    return sequence

def entropy(rows, columns):
    counts = Counter(tuple(row[i] for i in columns) for row in rows)
    size = len(rows)
    return -sum((count / size) * log2(count / size) for count in counts.values())

def discrete_te(source, target):
    # One lag of both target and source; source(t-1) -> target(t)
    rows = [(target[t], target[t-1], source[t-1])
            for t in range(1, len(target))]
    # H(Y_t,Y_t-1) + H(X_t-1,Y_t-1) - H(Y_t-1) - H(Y_t,Y_t-1,X_t-1)
    return (entropy(rows, (0,1)) + entropy(rows, (2,1)) -
            entropy(rows, (1,)) - entropy(rows, (0,1,2)))

source = lcg_bits(401,12345)
target = [0] + source[:-1]
independent = lcg_bits(401,987654)
actual = {
    "forward_coupled": discrete_te(source, target),
    "reverse_coupled": discrete_te(target, source),
    "independent_source": discrete_te(source, independent),
}
csv_path = Path(__file__).resolve().parents[1] / "tests/testthat/fixtures/phase3_discrete_te_oracle.csv"
with csv_path.open(encoding="utf8") as handle:
    reference = {row["scenario"]: float(row["expected_bits"])
                 for row in DictReader(handle)}
assert set(actual) == set(reference)
for name, value in actual.items():
    assert isclose(value, reference[name], rel_tol=0, abs_tol=1e-12), (
        name, value, reference[name])
assert actual["forward_coupled"] > actual["reverse_coupled"] + .5
print("Three finite-sample Shannon CMI oracles verified, independent of R.")
