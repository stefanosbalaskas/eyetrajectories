#!/usr/bin/env python3
"""Independent standard-library oracles for native R parity stage 1.

This script does not import R or eyetrajectoriespy. Its checks are limited
to deterministic mathematical cases; it is NOT a scientific coverage audit.
Run: python scripts/check_native_parity_stage1_oracles.py
"""
from __future__ import annotations

import math


def recurrence_graph(radius: float):
    # The first native demo curve has offset=-0.06; only its common phase
    # changes. Pairwise planar distances are invariant to that shift.
    n = 41
    points = [
        (
            math.sin(2 * math.pi * (i / 40 + 0.06)),
            math.cos(2 * math.pi * (i / 40 + 0.06)),
        )
        for i in range(n)
    ]
    graph = [[False] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            if j - i <= 1:  # exclude main diagonal and Theiler lag=1
                continue
            distance = math.dist(points[i], points[j])
            graph[i][j] = graph[j][i] = distance <= radius

    degrees = [sum(row) for row in graph]
    edges = sum(degrees) // 2
    triangles = sum(
        1
        for i in range(n)
        for j in range(i + 1, n)
        for k in range(j + 1, n)
        if graph[i][j] and graph[i][k] and graph[j][k]
    )
    triples = sum(d * (d - 1) // 2 for d in degrees)
    transitivity = 3 * triangles / triples if triples else float("nan")
    seen = set()
    components = 0
    for vertex in range(n):
        if vertex in seen:
            continue
        components += 1
        seen.add(vertex)
        stack = [vertex]
        while stack:
            index = stack.pop()
            for other in range(n):
                if graph[index][other] and other not in seen:
                    seen.add(other)
                    stack.append(other)
    return edges, triangles, triples, transitivity, components


def test_graphs():
    small = recurrence_graph(0.30)
    large = recurrence_graph(0.70)
    assert small == (3, 0, 2, 0.0, 38), small
    assert large[0:3] == (129, 57, 689), large
    assert math.isclose(large[3], 171 / 689, abs_tol=1e-14), large
    assert large[4] == 1, large
    return small, large


def test_landmark_inverse():
    # Piecewise-linear inverse warp; x(target landmark) = source landmark.
    n = 12
    offsets = [-0.06 + (0.12 * i) / (n - 1) for i in range(n)]
    sources = [0.25 + shift for shift in offsets]
    target = 0.25
    assert math.isclose(min(sources), 0.19, abs_tol=1e-14)
    assert math.isclose(max(sources), 0.31, abs_tol=1e-14)
    for s in sources:
        knots_target = [0.0, target, 1.0]
        knots_source = [0.0, s, 1.0]
        assert knots_source[0] < knots_source[1] < knots_source[2]
        assert all(b > a for a, b in zip(knots_target, knots_target[1:]))
    return min(sources), max(sources)


def test_delay_and_return_map():
    series = list(range(1, 7))
    dimension, lag = 3, 2
    rows = [
        tuple(series[t - j * lag] for j in range(dimension))
        for t in range((dimension - 1) * lag, len(series))
    ]
    assert rows == [(5, 3, 1), (6, 4, 2)], rows
    t = list(range(1, 7))
    vals = [-1, 1, -1, 1, -1, 1]
    crossings = [
        t[i] + (-vals[i]) / (vals[i + 1] - vals[i]) * (t[i + 1] - t[i])
        for i in range(len(vals) - 1)
        if vals[i] < 0 <= vals[i + 1]
    ]
    assert crossings == [1.5, 3.5, 5.5], crossings
    assert [b - a for a, b in zip(crossings, crossings[1:])] == [2, 2]
    return len(rows), crossings


def test_split_conformal_ranks():
    def threshold(scores, alpha):
        rank = math.ceil((len(scores) + 1) * (1 - alpha))
        return rank, float("inf") if rank > len(scores) else sorted(scores)[rank - 1]

    assert threshold(list(range(1, 10)), 0.1) == (9, 9)
    assert threshold(list(range(1, 9)), 0.1) == (9, float("inf"))
    assert threshold(list(range(1, 10)), 0.2) == (8, 8)
    rank, value = threshold(list(range(1, 20)), 0.1)
    assert (rank, value) == (18, 18), (rank, value)
    # Under continuous iid calibration + one future score, the rank of
    # the future score among 20 is uniform. Only ranks 19 and 20 are
    # above the eighteenth calibration order statistic: 2/20 = alpha.
    assert (20 - rank) / 20 == 0.1
    return rank, value


def main():
    sparse, dense = test_graphs()
    bounds = test_landmark_inverse()
    nrows, events = test_delay_and_return_map()
    rank, value = test_split_conformal_ranks()
    print("PASS: independent Python-standard-library mathematical oracles")
    print("  0.30 graph edges/triangles/components:", sparse[0], sparse[1], sparse[4])
    print(
        "  0.70 graph edges/triangles/triples/transitivity/components:",
        dense,
    )
    print("  Prespecified landmark source range:", bounds)
    print("  Exact delay-embedding rows:", nrows, "threshold crossings:", events)
    print("  n=19, alpha=.10 split-conformal rank and sample cutoff:", rank, value)
    print("  This does NOT test the R code, empirical anomaly detection,")
    print("  small-cluster confidence-band calibration, or Python API parity.")


if __name__ == "__main__":
    main()
