# bgtc-adaptive-dbs

MATLAB/Simulink code, result files and figure scripts for the article "Feedback as automatic dose selection in a basal ganglia-thalamocortical model of adaptive deep brain stimulation" (Cognitive Neurodynamics).

The model is a seven-population firing-rate model of the basal ganglia-thalamocortical (BGTC) loop (motor cortex, D1 and D2 striatum, GPe, STN, GPi, thalamus) with dopamine-dependent pathway gains, transmission delays, a prescribed 20-Hz beta-band input, and deep brain stimulation (DBS) represented as an effective suppressive input to the STN. Stimulation is either a fixed command (open loop) or the output of a saturated proportional-integral (PI) controller acting on the error between a thalamic reference and the observed thalamic output (closed loop); the observation may include a delay, a bias and noise. The experiments separate the effect of feedback from the effect of the amount of stimulation with four open-loop commands matched to the closed loop (late command, cumulative command, stimulation use, full-horizon error), and test the separation across horizons, dopamine levels, controller gains, a 200-subject virtual cohort with stationary and state-change protocols, and attainability and observation-error conditions.

## Requirements

MATLAB and Simulink. The results were produced with MATLAB R2026b (26.2) and Simulink on Windows 11 (Intel Core Ultra 7 155U). No other toolbox is used; the Welch spectrum is implemented in `src/beta_power.m` and the Latin hypercube design in `src/cohort_design.m`.

## Quick start

```matlab
reproduce          % redraw figures and recompute results/summary.csv from the shipped results
reproduce('full')  % rerun every simulation first
```

`reproduce('full')` rebuilds the two Simulink models from `src/build_models.m` in a temporary folder, runs the experiments below, and overwrites the files in `results/`. The simulations use fixed noise seeds and write numbers with 12 significant digits; on the machine above, rerunning E1, E2 and E6 and cohort subjects 1 and 2 from this release with MATLAB R2026b reproduced the shipped files of E1, E2 and E6 and the shipped rows of subjects 1 and 2 byte for byte. On the same machine, E1 to E7, E9 and the solver check take about 3 h and the virtual cohort (E8) about 4 min per subject, so the full run in one MATLAB process takes about 16 h; with the cohort split over five concurrent processes as below, it takes about 7 h. To split the cohort, first run every other experiment from the repository root (E4 writes `results/horizon_metrics.csv`, which the cohort reads):

```matlab
addpath('src'); run_all_simulations('results', 1:10)      % all steps except E8
```

Then start five MATLAB processes, k = 1, ..., 5, each in the repository root with its own model and cache folder; process k runs subjects 40(k-1)+1 to 40k, so that together they cover subjects 1 to 200:

```matlab
k = 1;                                                     % process number
addpath('src');
w = fullfile(tempdir, sprintf('bgtc_part_%d', k)); mkdir(w);
Simulink.fileGenControl('set', 'CacheFolder', w, 'CodeGenFolder', w);
build_models(fullfile(w, 'models'));                       % builds and loads the two models
exp_cohort('results', 40*(k-1)+1:40*k, fullfile('results', 'parts'))
```

When all five parts are written, join them in one process (merge_cohort stops with an error unless the parts hold subjects 1 to 200 exactly once):

```matlab
addpath('src'); merge_cohort('results', fullfile('results', 'parts'))   % identical to a single run
reproduce                                                                % recomputes summary.csv and the figures
```

## Main results

| Quantity | Value |
|---|---|
| 15 s, D = 0.35: thalamic late mean, no DBS / open loop (u = 0.12) / closed loop | 0.3612 / 0.3995 / 0.4072 |
| 15 s: Je(15), open loop (u = 0.12) / closed loop | 0.0392 / 0.0455 |
| 15 s: late-command-matched open loop (u = 0.1439), largest difference from closed loop (TH, GPi, RMSE) | 0.000145 |
| 15 s: effort-matched open loop (u = 0.1106), Je relative to closed loop at equal Ju | 0.961 |
| 15 s: performance-matched open loop (u = 0.1071), Ju relative to closed loop at equal Je | 0.937 |
| 15 s, D = 0.35, 20 independent noise pairs: effort-matched Je not above closed loop | 20 of 20 pairs |
| Five dopamine levels x 15/60/120 s: effort-matched Je below closed loop (Je ratio) | 15 of 15 (0.312 to 0.998) |
| Five dopamine levels x 15/60/120 s: Ju of performance-matched open loop relative to closed loop | 0.75 to 0.99 |
| Gain grid (108 combinations): effort-matched Je not above closed loop | 104 of 108 |
| 120 s, D = 0.15 to 0.60: closed-loop thalamic late mean | 0.4489 to 0.4493 |
| 120 s: closed-loop settled command / largest difference from u* | 0.085 to 0.360 / 0.0037 |
| Dopamine changes (E6): Je over 90-270 s, closed loop / best constant after the change / best constant for the schedule | 0.048 / 0.116 / 0.131 |
| Dopamine changes (E6): Je over 0-270 s, closed loop / best constant for the schedule | 0.076 / 0.176 |
| Cohort (200), stationary: on target, closed loop / individually optimized constant | 193 / 193 |
| Cohort, stationary: individually optimized constant has lower Je than closed loop | 200 of 200 |
| Cohort, state change: closed loop has lower Je over 90-270 s than the best constant after the change | 185 of 200 |
| Cohort, state change: closed loop has lower Je over 0-270 s than the best constant for the schedule | 96 of 200 |
| Attainability grid (72 runs): persistently saturated / unattainable reference | 38 / 39 |

"On target" means a thalamic late mean within 0.01 of the reference 0.45. Late means are time averages over the final fifth of the run. u* is the fixed command at which the 120-s late mean of the fixed-command map equals the reference.

## Repository layout

```
reproduce.m              entry point
src/
  bgtc_params.m          nominal parameters
  apply_dopamine.m       dopamine-dependent gains and beta-input amplitude
  set_scenario.m         named conditions (healthy, moderate_pd, no_dbs, open_loop, closed_loop, ...)
  build_models.m         builds the baseline and DBS Simulink models
  simulate.m             runs one simulation and returns the recorded signals
  simulate_schedule.m    runs consecutive segments that continue from the saved state
  signal_metrics.m       time-weighted late means, RMSE, Je, Ju, settling, beta power
  segment_metrics.m      measures of one segment of a scheduled run
  win_int.m, settling.m  time integral over a window; settling time and smoothed peak
  matched_commands.m     late-command, cumulative-command and effort-matched commands
  perf_match.m, perf_match_grid.m   performance-matched command by bisection
  run_fixed.m            open-loop run at a constant command
  best_constant.m        best constant command for a dopamine schedule or window
  cohort_design.m        Latin hypercube design of the virtual cohort
  subject_params.m       parameters and noise seeds of one virtual subject
  calibrate_subject.m    individually optimized constant commands of one subject
  psd_signal.m, beta_power.m   post-transient resampling and Welch PSD
  on_grid.m, write_csv.m, metric_fields.m   interpolation, CSV output, column list
  exp_*.m                the experiments (E1 to E9 in the article) and the solver check
  merge_cohort.m         joins cohort parts written by separate processes
  run_all_simulations.m  runs every experiment
  summarize_results.m    derived values reported in the article -> results/summary.csv
  make_figures.m         Figs. 2 to 10 -> figures/
results/                 result files (CSV)
figures/                 Figs. 2 to 10 (PDF and PNG); Fig. 1 is the model diagram in the article
```

## Experiments and result files

| Experiment | Function | Result file(s) |
|---|---|---|
| E1 baselines, D = 1.00 and 0.35 | `exp_baseline` | `baseline_metrics.csv`, `baseline_traces.csv` |
| E1 dopamine sweep | `exp_dopamine_sweep` | `dopamine_sweep.csv` |
| E2 nominal 15-s comparison and matched open loops | `exp_nominal` | `nominal_metrics.csv`, `nominal_traces.csv` |
| E3 20 independent noise pairs | `exp_noise_seeds` | `noise_seeds.csv` |
| E4 five dopamine levels over 15, 60 and 120 s, with matched open loops | `exp_horizon` | `horizon_metrics.csv`, `horizon_traces.csv` |
| E5 fixed-command map | `exp_command_map` | `command_map.csv` |
| E6 dopamine changes within a run | `exp_dopamine_step` | `dopamine_step_metrics.csv`, `dopamine_step_traces.csv` |
| E7 controller-gain grid | `exp_gains` | `gains.csv` |
| E8 virtual cohort, 200 subjects | `exp_cohort` | `cohort_subjects.csv`, `cohort_stationary.csv`, `cohort_change.csv` |
| E9 attainability, saturation and observation errors | `exp_limits` | `limits_attain.csv`, `limits_sensor.csv` |
| solver tolerance and maximum step | `exp_numerics` | `numerics.csv` |
| derived values | `summarize_results` | `summary.csv` |

E5 must run before E4, and E4 before E6 and E8, because they read its result files; `run_all_simulations` uses this order.

## Column definitions

All activities, gains and commands are normalized (a.u.). Time is in s; `Je` and `Ju` are in (a.u.)^2 s.

- `t`: time (s). `TH`, `GPi`, `STN`, `C`: thalamic, GPi, STN and motor-cortex outputs; `u`: stimulation command, bounded by the saturation bound u_max (0.60 unless the file lists another).
- `D`: dopamine level (1 = healthy reference). `T`: horizon of the measures (the first T seconds of the run).
- `condition`: `healthy` and `moderate_pd` (baseline model without noise or stimulation at D = 1.00 and D = 0.35); `no_dbs`; `open_loop` (fixed command u_OL = 0.12); `closed_loop` (PI control); matched open loops `late_command` (closed-loop late mean command), `mean_command` (equal cumulative command, int u dt), `effort` (equal Ju), `performance` (smallest constant command with Je not above the closed loop); `open_loop_tuned` (closed-loop settled command at D = 0.50 in E6 or at D = 0.35 in E8); `open_loop_tuned_low` (settled command at D = 0.20); `open_loop_best` (best constant for the dopamine schedule, weights 2/3 and 1/3); `open_loop_best_after` (best constant after the change, weights 1/2 and 1/2 of the 90-270-s window); `open_loop_individual`, `open_loop_individual_low` (individually optimized command at D and at D_low); `open_loop_umax` (constant command u_max).
- `u_fixed`: constant open-loop command (NaN for the closed loop). `u` (`command_map.csv`): fixed open-loop command of the map.
- `C_mean`: time-weighted mean cortical output over the late window. `beta_amp`: amplitude of the prescribed 20-Hz beta input at D. `pair`, `seedC`, `seedSTN`: noise pair k = 1, ..., 20 with cortical seed 1000 + k and STN seed 2000 + k. `subject`: subject index i (row of the design, 1 to 200). `segment`: 1, 2, 3 for 0-90, 90-180 and 180-270 s.
- `TH_mean`, `GPi_mean`, `u_late`: time-weighted means over the late window [0.8 T, T]. `TH_RMSE`: root-mean-square deviation of TH from the reference over the same window.
- `*_s`: the same four measures as unweighted means of the recorded samples j0..Nt with j0 = max(1, round(0.8 Nt)); `*_g`: as means over a uniform 1-kHz grid of the late window.
- `Je`, `Je_start`, `Je_late`: int (TH - TH_ref)^2 dt over [0, T], [0, 0.8 T] and [0.8 T, T]. `Ju`, `Ju_start`, `Ju_late`: int u^2 dt over the same intervals. `U1`: int u dt over [0, T].
- `u_end`: command at T; `u_sd_late`: time-weighted standard deviation of the command in the late window; `sat_late`: fraction of the late window with the command at u_max.
- `t_settle`: time, measured from the start of the run or segment, after which the centered 1-s moving mean of TH stays within 0.01 of the reference until its end (0 if the moving mean never leaves this band, NaN if it is outside the band at the end); `TH_smooth_max`: largest 1-s moving mean of TH after 5 s; `Ju_settle`: Ju up to t_settle; `TH_peak`: largest recorded TH.
- `TH_beta`, `GPi_beta`: 13-30 Hz power of the post-transient (t >= 3 s) Welch PSD, (a.u.)^2. `on_target`: 1 if |TH_mean - TH_ref| < 0.01, with TH_ref the reference of the run (0.45 unless the file lists another).
- `TH_last10`, `u_last10`, `TH_RMSE_last10`: time-weighted means and RMSE over the last 10 s of a segment; `Ju_segment`, `Je_segment`: integrals over the segment; `TH_smooth_max`, `TH_smooth_min`: extremes of the 1-s moving mean within the segment; `time_off`: fraction of the segment with the moving mean at least 0.01 from the reference; `u_max_seg`: largest command in the segment.
- Cohort design (`cohort_subjects.csv`): `g` pathway multiplier, `a_n` noise multiplier, `tau_*` time-constant multipliers, `d_*` delay multipliers, `G_DBS` stimulation gain, `sensor_delay`, `sensor_noise` observation delay and noise, `dD` dopamine decrease, `D_low`; calibration results `u_star`, `u_star_low` (individually optimized commands), `u_best` (best constant for the schedule), `u_best_after` (best constant after the change), `h0`, `h0_low`, `hmax`, `hmax_low` (thalamic late means of the 30-s calibration runs, with the calibration noise seeds, at u = 0 and at u = u_max, at D and at D_low), `attainable`, `attainable_low` (1 if the calibration late mean at u = 0 or at u = u_max reaches TH_ref, otherwise 0), `n_cal_runs` (number of 30-s calibration runs at the two dopamine levels).
- `limits_attain.csv`: `G_DBS`, `u_max`, `TH_ref` of each run. `limits_sensor.csv`: `Kp`, `Ki`, `factor` (bias, noise, delay) and its `value`. `numerics.csv`: `RelTol`, `MaxStep`, `n_samples` (number of recorded solver steps).
- `*_traces.csv`: time courses interpolated on a uniform grid (5 ms or 50 ms); commands use the last recorded value. Trace columns are named signal_condition; in `baseline_traces.csv` the suffix `pd` denotes `moderate_pd`, and in `horizon_traces.csv` the suffixes `D015` to `D060` give the dopamine level (0.15 to 0.60). The `Je_*` columns of `dopamine_step_traces.csv` hold the accumulated tracking error int (TH - TH_ref)^2 dt, integrated by the trapezoidal rule over the solver steps and sampled on the grid.

## License

MIT, see LICENSE. Citation metadata is in CITATION.cff.
