function exp_gains(resDir)
%EXP_GAINS Closed-loop behavior for a grid of PI gains (E7).
%   Runs 120-s closed-loop simulations for Kp in {0.4, 0.8, 1.6} and Ki in
%   {0.05, 0.15, 0.45, 1.35} 1/s at D = 0.15, 0.35 and 0.60, with the
%   nominal noise seeds, and evaluates them over the horizons T = 15, 60
%   and 120 s. TH_smooth_max is the largest 1-s moving mean of TH after
%   5 s. Writes gains.csv to RESDIR.

Ds = [0.15 0.35 0.60];
Kps = [0.4 0.8 1.6];
Kis = [0.05 0.15 0.45 1.35];
Ts = [15 60 120];
mf = metric_fields();
rows = zeros(numel(Ds)*numel(Kps)*numel(Kis)*numel(Ts), 4 + numel(mf)); r = 0;
for i = 1:numel(Ds)
    for a = 1:numel(Kps)
        for b = 1:numel(Kis)
            P = set_scenario('closed_loop', Ds(i));
            P.Kp = Kps(a); P.Ki = Kis(b); P.StopTime = 120;
            S = simulate(P, 'dbs');
            for k = 1:numel(Ts)
                [~, v] = metric_fields(signal_metrics(S, P, Ts(k)));
                r = r + 1;
                rows(r, :) = [Ds(i), Kps(a), Kis(b), Ts(k), v];
            end
        end
    end
    fprintf('  gains: D = %.2f\n', Ds(i));
end
write_csv(fullfile(resDir, 'gains.csv'), [{'D', 'Kp', 'Ki', 'T'}, mf], rows);
end
