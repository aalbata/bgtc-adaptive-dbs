function exp_dopamine_sweep(resDir)
%EXP_DOPAMINE_SWEEP Deterministic baseline at six dopamine levels.
%   Writes dopamine_sweep.csv to RESDIR.

Ds = [1.0 0.8 0.6 0.4 0.2 0.1];
out = zeros(numel(Ds), 7);
for i = 1:numel(Ds)
    P = apply_dopamine(bgtc_params(), Ds(i));
    S = simulate(P, 'baseline');
    M = signal_metrics(S, P);
    out(i, :) = [Ds(i), P.betaDriveAmp, M.TH_peak, M.TH_mean, M.GPi_mean, M.TH_beta, M.GPi_beta];
end
write_csv(fullfile(resDir, 'dopamine_sweep.csv'), ...
    {'D', 'beta_amp', 'TH_peak', 'TH_mean', 'GPi_mean', 'TH_beta', 'GPi_beta'}, out);
end
