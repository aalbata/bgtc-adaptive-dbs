function exp_limits(resDir)
%EXP_LIMITS Attainability, persistent saturation and observation errors (E9).
%   Part 1: 120-s closed-loop runs for every combination of D in {0.05,
%   0.15, 0.35, 0.60}, stimulation gain G_DBS in {0.25, 0.5, 1.0},
%   saturation u_max in {0.3, 0.6} and reference TH_ref in {0.40, 0.45,
%   0.50}, and 120-s open-loop runs at the constant command u_max for each
%   (D, G_DBS, u_max). Writes limits_attain.csv.
%   Part 2: 120-s closed-loop runs at D = 0.35 with nominal gains
%   (Kp = 0.8, Ki = 0.15 1/s) and with fast gains (Kp = 1.6, Ki = 1.35 1/s),
%   varying one observation error at a time: bias in {-0.02, -0.01, 0,
%   0.01, 0.02}, noise standard deviation in {0, 0.01, 0.02, 0.05, 0.10},
%   and delay in {0, 0.1, 0.25, 0.5, 1, 2} s. Writes limits_sensor.csv.
%   Measures are taken against the reference of each run.

mf = metric_fields();
Ds = [0.05 0.15 0.35 0.60]; Gs = [0.25 0.5 1.0]; Um = [0.3 0.6]; Refs = [0.40 0.45 0.50];
rows = cell(0, 6 + numel(mf));
for i = 1:numel(Ds)
    for g = 1:numel(Gs)
        for m = 1:numel(Um)
            for q = 1:numel(Refs)
                P = set_scenario('closed_loop', Ds(i));
                P.DBS_effect_gain = Gs(g); P.DBS_max = Um(m); P.TH_ref = Refs(q); P.StopTime = 120;
                [~, v] = metric_fields(signal_metrics(simulate(P, 'dbs'), P, 120));
                rows(end+1, :) = [{Ds(i), Gs(g), Um(m), Refs(q), 'closed_loop', NaN}, num2cell(v)]; %#ok<AGROW>
            end
            P = set_scenario('open_loop', Ds(i));
            P.DBS_effect_gain = Gs(g); P.DBS_max = Um(m);
            [~, v] = metric_fields(run_fixed(P, Um(m), 120));
            rows(end+1, :) = [{Ds(i), Gs(g), Um(m), P.TH_ref, 'open_loop_umax', Um(m)}, num2cell(v)]; %#ok<AGROW>
        end
    end
    fprintf('  limits: D = %.2f\n', Ds(i));
end
write_csv(fullfile(resDir, 'limits_attain.csv'), ...
    [{'D', 'G_DBS', 'u_max', 'TH_ref', 'condition', 'u_fixed'}, mf], rows);

gains = [0.8 0.15; 1.6 1.35];
factors = {'bias', [-0.02 -0.01 0 0.01 0.02]; 'noise', [0 0.01 0.02 0.05 0.10]; ...
    'delay', [0 0.1 0.25 0.5 1 2]};
rows = cell(0, 5 + numel(mf));
for a = 1:size(gains, 1)
    for f = 1:size(factors, 1)
        for v0 = factors{f, 2}
            P = set_scenario('closed_loop', 0.35);
            P.Kp = gains(a, 1); P.Ki = gains(a, 2); P.StopTime = 120;
            switch factors{f, 1}
                case 'bias',  P.sensorBias = v0;
                case 'noise', P.sensorNoise = v0;
                case 'delay', P.sensorDelay = v0;
            end
            [~, v] = metric_fields(signal_metrics(simulate(P, 'dbs'), P, 120));
            rows(end+1, :) = [{0.35, gains(a, 1), gains(a, 2), factors{f, 1}, v0}, num2cell(v)]; %#ok<AGROW>
        end
    end
end
write_csv(fullfile(resDir, 'limits_sensor.csv'), [{'D', 'Kp', 'Ki', 'factor', 'value'}, mf], rows);
end
