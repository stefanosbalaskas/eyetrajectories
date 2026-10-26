#!/usr/bin/env python3
"""Independent combinatorial rank oracle for frozen score split conformal.

Standard-library Python only. Does not import or exercise R or estimate
FPCA/anomaly performance. Its target is the finite-sample rank calculation.
"""
from __future__ import annotations
from math import ceil


def rank_threshold(calibration: list[float], alpha: float) -> tuple[int, float]:
    n = len(calibration)
    if not (0 < alpha < 1) or n < 1:
        raise ValueError("invalid rank design")
    k = ceil((n + 1) * (1 - alpha))
    return k, sorted(calibration)[k - 1] if k <= n else float("inf")


def enumerate_future_rank(n_calibration: int, alpha: float) -> tuple[int, int]:
    # Use every one of n+1 possible distinct score ranks as a future value.
    scores = list(range(1, n_calibration + 2))
    flags = 0
    for position, value in enumerate(scores):
        calibration = scores[:position] + scores[position + 1 :]
        k, cutoff = rank_threshold(calibration, alpha)
        flags += int(value > cutoff)
    return flags, len(scores)


def main() -> None:
    for alpha, flagged in ((0.05, 1), (0.10, 2), (0.20, 4)):
        count, n = enumerate_future_rank(19, alpha)
        assert (count, n) == (flagged, 20), (alpha, count, n)
        rank, _ = rank_threshold(list(range(1, 20)), alpha)
        theory = (20 - rank) / 20
        assert count / n == theory, (alpha, count, theory)
        assert count / n <= alpha + 1e-12
        print(
            f"PASS: n_cal=19, alpha={alpha:.2f}, "
            f"rank={rank}, false alarms={count}/{n} ({theory:.2%})"
        )

    rank, cutoff = rank_threshold(list(range(1, 9)), 0.10)
    assert rank == 9 and cutoff == float("inf")
    tie_k, tie_cutoff = rank_threshold([0.5] * 19, 0.10)
    assert tie_k == 18 and tie_cutoff == 0.5
    assert not (0.5 > tie_cutoff)
    print("PASS: finite-sample infinite cutoff and conservative tie handling")
    print("This does NOT test the native R FPCA score, its calibration under")
    print("observed gaze data, participant dependence, or any confidence bands.")


if __name__ == "__main__":
    main()
