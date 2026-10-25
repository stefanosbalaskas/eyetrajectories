#!/usr/bin/env python3
"""Verify frozen mathematical reference cases against *actual* eyetrajectoriespy==1.2.0.

The CSV contains analytically tractable, sign-invariant values frozen in Git.
They must not be refreshed to conceal discrepancies. This check executes the
upstream published backend and fails if any reference target disagrees.
"""
import csv
import math
from pathlib import Path
from importlib.metadata import version

import numpy as np

from eyetrajectoriespy import (
    TrajectorySet,
    fit_mfpca,
    functional_trapezoid_weights,
    functional_l2_distance,
    discrete_frechet_distance,
    dynamic_time_warping_distance,
    recurrence_matrix,
    rqa_metrics,
    speed_function,
    cumulative_path_length,
)

assert version("eyetrajectoriespy") == "1.2.0", "Scientific reference backend must be 1.2.0"
root = Path(__file__).resolve().parents[1]
with (root / "tests/testthat/fixtures/python_1_2_0_math_reference.csv").open() as handle:
    expected = {row["key"]: float(row["value"]) for row in csv.DictReader(handle)}

def check(key: str, actual: float, atol: float = 1e-9):
    assert math.isclose(float(actual), expected[key], abs_tol=atol, rel_tol=atol), (
        f"{key}: expected {expected[key]:.17g}, actual {actual:.17g}"
    )

time = np.asarray([0.0, 1.0, 2.0, 4.0])
values = np.zeros((3, 4, 2), dtype=float)
for i in range(3):
    values[i, :, 0] = float(i)
    values[i, :, 1] = float(2 * i)
gaze = TrajectorySet(time=time, values=values, curve_ids=("c1", "c2", "c3"),
                     dimension_names=("x", "y"), time_unit="s")
for i, w in enumerate(functional_trapezoid_weights(time)):
    check(f"trapezoid_w{i + 1}", w)
fit = fit_mfpca(gaze, n_components=1, scaling="none")
check("fpca_eigenvalue1", fit.explained_variance[0])
check("fpca_variance_ratio1", fit.explained_variance_ratio[0])
check("l2_curve1_curve2", functional_l2_distance(values[0], values[1], time=time))
check("frechet_curve1_curve2", discrete_frechet_distance(values[0], values[1]))
check("dtw_curve1_curve2", dynamic_time_warping_distance(values[0], values[1]))

regular = TrajectorySet(time=np.arange(4, dtype=float), values=values,
                        curve_ids=("c1", "c2", "c3"), dimension_names=("x", "y"), time_unit="s")
rec = recurrence_matrix(regular, curve="c1", radius=0.0)
qa = rqa_metrics(rec)
check("rqa_recurrence_rate", qa.recurrence_rate)
check("rqa_determinism", qa.determinism)
check("rqa_laminarity", qa.laminarity)

linear = np.zeros((1, 4, 2), dtype=float)
linear[0, :, 0] = time
linear[0, :, 1] = 2.0 * time
straight = TrajectorySet(time=time, values=linear, curve_ids=("linear",),
                         dimension_names=("x", "y"), time_unit="s")
check("velocity_x", 1.0)
check("velocity_y", 2.0)
check("speed", speed_function(straight).values[0, 0, 0])
check("path_length", cumulative_path_length(straight).values[0, -1, 0])
check("tortuosity", 1.0)
print(f"Verified {len(expected)} frozen targets against eyetrajectoriespy 1.2.0")
