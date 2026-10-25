#!/usr/bin/env python3
"""Independent Python Monte Carlo check of the analytic two-level variance.

Tests the *generating model mathematical identity*, not any R fitting code,
nor inferential coverage. Synthetic data and known truth only.
"""
import math
import numpy as np
rng = np.random.default_rng(20261025)
n_subjects, trials, n_time = 24, 3, 41
time = np.linspace(0.0, 1.0, n_time)
weights = np.empty(n_time)
weights[0] = (time[1] - time[0]) / 2
weights[-1] = (time[-1] - time[-2]) / 2
weights[1:-1] = (time[2:] - time[:-2]) / 2
subject_sd, trial_sd, noise_sd = .35, .15, .05
basis = np.stack((np.sin(np.pi*time), np.cos(np.pi*time)), axis=1)
theoretical = np.sum(weights * (
    (subject_sd**2 + trial_sd**2/trials) *
    (np.sin(np.pi*time)**2 + np.cos(np.pi*time)**2) +
    2*noise_sd**2/trials
))
estimates = []
for _ in range(1200):
    subject = rng.normal(scale=subject_sd,size=(n_subjects,1,1,2))
    trial = rng.normal(scale=trial_sd,size=(n_subjects,trials,1,2))
    measurement = rng.normal(scale=noise_sd,size=(n_subjects,trials,n_time,2))
    participants = ((subject + trial) * basis[None,None,:,:] + measurement).mean(axis=1)
    centered = participants-participants.mean(axis=0)
    integrated_trace = ((centered**2).sum(axis=0).sum(axis=1) /
                        (n_subjects-1) * weights).sum()
    estimates.append(float(integrated_trace))
sample_mean = float(np.mean(estimates))
mc_se = float(np.std(estimates,ddof=1)/math.sqrt(len(estimates)))
assert math.isfinite(sample_mean) and math.isfinite(mc_se) and mc_se > 0
assert abs(sample_mean-theoretical) < 5*mc_se, (
    f"analytic={theoretical}, MC mean={sample_mean}, MC SE={mc_se}")
print(f"Independent analytic variance audit: truth={theoretical:.8f}, "
      f"MC mean={sample_mean:.8f}, MC SE={mc_se:.8f}, draws={len(estimates)}")
