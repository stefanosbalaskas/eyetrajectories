# Workflow 03 — Sparse and irregular FDA

Known truth: 1 + sin(pi*t) + latent_i*cos(2*pi*t); latent_i ~ N(0,0.75^2).
Irregular observed times and additive Gaussian measurement noise SD=0.08.
Estimation: optional fdapace::FPCA via etr_fit_sparse_pace adapter.
Synthetic reconstruction RMSE: 0.11856; mean-only RMSE: 0.53071.
Sign-invariant correlation of first score with latent: 0.99488.
One-factor synthetic recovery only. NOT an independent PACE implementation.
A missingness process dependent on unobserved gaze is NOT simulated here.
No human data, inference coverage, eye-tracker calibration or raw event truth.
