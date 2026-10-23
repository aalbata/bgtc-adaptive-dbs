function summarize_results(resDir)
%SUMMARIZE_RESULTS Derived quantities reported in the article.
%   SUMMARIZE_RESULTS(RESDIR) reads the result files in RESDIR and writes
%   summary.csv, a list of named values (key, value) from which every
%   number in the text and tables of the article is filled. Percentage
%   changes use the paired no-DBS value as reference. A thalamic late mean
%   is on target when it lies within 0.01 of the reference 0.45. The 5th
%   and 95th values of a sample of size N are the round(0.05 N)-th and
%   round(0.95 N)-th sorted observations. Spearman rank correlations give
%   tied values their average rank.

ref = 0.45; tol = 0.01;
K = {}; V = [];
    function put(k, v)
        if ~isscalar(v), error('Value for %s is not scalar.', k); end
        if any(strcmp(K, k)), error('Duplicate key %s.', k); end
        K{end+1, 1} = k; V(end+1, 1) = v;
    end

% ---- E1 baselines and dopamine sweep
B = readtable(fullfile(resDir, 'baseline_metrics.csv'), 'TextType', 'char');
for k = 1:height(B)
    put(['base_' B.condition{k} '_TH'], B.TH_mean(k));
    put(['base_' B.condition{k} '_GPi'], B.GPi_mean(k));
    put(['base_' B.condition{k} '_C'], B.C_mean(k));
end
W = readtable(fullfile(resDir, 'dopamine_sweep.csv'));
put('sweep_TH_min', min(W.TH_mean)); put('sweep_TH_max', max(W.TH_mean));
put('sweep_GPi_min', min(W.GPi_mean)); put('sweep_GPi_max', max(W.GPi_mean));
put('sweep_GPibeta_ratio', W.GPi_beta(W.D == 0.1) / W.GPi_beta(W.D == 1.0));
put('sweep_THbeta_ratio', W.TH_beta(W.D == 0.1) / W.TH_beta(W.D == 1.0));
put('beta_amp_D035', 0.002 + 0.10 * (1 - 0.35)^1.5);

% ---- E2 nominal 15-s comparison with matched open loops
N = readtable(fullfile(resDir, 'nominal_metrics.csv'), 'TextType', 'char');
conds = {'no_dbs', 'open_loop', 'closed_loop', 'late_command', 'mean_command', 'effort', 'performance'};
tags  = {'no', 'ol', 'cl', 'lc', 'cc', 'em', 'pm'};
n0 = N(strcmp(N.condition, 'no_dbs'), :);
ncl = N(strcmp(N.condition, 'closed_loop'), :);
for c = 1:numel(conds)
    r = N(strcmp(N.condition, conds{c}), :);
    t = ['nom_' tags{c} '_'];
    put([t 'u'], r.u_fixed); put([t 'TH'], r.TH_mean); put([t 'GPi'], r.GPi_mean);
    put([t 'RMSE'], r.TH_RMSE); put([t 'ulate'], r.u_late);
    put([t 'Je'], r.Je); put([t 'Je_start'], r.Je_start); put([t 'Je_late'], r.Je_late);
    put([t 'Ju'], r.Ju); put([t 'Ju_start'], r.Ju_start); put([t 'Ju_late'], r.Ju_late);
    put([t 'U1'], r.U1); put([t 'GPibeta'], r.GPi_beta);
    put([t 'GPibeta_e6'], 1e6 * r.GPi_beta);
    if c > 1
        put([t 'THimp'], 100*(r.TH_mean - n0.TH_mean)/n0.TH_mean);
        put([t 'GPired'], 100*(n0.GPi_mean - r.GPi_mean)/n0.GPi_mean);
        put([t 'betared'], 100*(n0.GPi_beta - r.GPi_beta)/n0.GPi_beta);
    end
    if c ~= 3
        put([t 'Ju_ratio'], r.Ju / ncl.Ju);
        put([t 'Je_ratio'], r.Je / ncl.Je);
    end
end
lc = N(strcmp(N.condition, 'late_command'), :);
put('nom_lc_maxdiff', max(abs([lc.TH_mean - ncl.TH_mean, lc.GPi_mean - ncl.GPi_mean, lc.TH_RMSE - ncl.TH_RMSE])));
put('nom_cl_gap', ref - ncl.TH_mean);
put('nom_cl_Je_start_share', ncl.Je_start / ncl.Je);
put('nom_cl_Ju_start_share', ncl.Ju_start / ncl.Ju);
% averaging methods (time-weighted against unweighted samples and a uniform grid)
d = [N.TH_mean - N.TH_mean_s; N.GPi_mean - N.GPi_mean_s; N.TH_RMSE - N.TH_RMSE_s; N.u_late - N.u_late_s];
put('nom_avg_maxdiff_sample', max(abs(d)));
d = [N.TH_mean - N.TH_mean_g; N.GPi_mean - N.GPi_mean_g; N.TH_RMSE - N.TH_RMSE_g; N.u_late - N.u_late_g];
put('nom_avg_maxdiff_grid', max(abs(d)));

% Proposition 1 on the nominal closed loop: late mean error from the command drift
Tr = readtable(fullfile(resDir, 'nominal_traces.csv'));
[lhs, rhs] = window_identity(Tr.t, Tr.TH_closed_loop, Tr.u_closed_loop, 12, 15, 0.8, 0.15, ref);
put('nom_prop1_lhs', lhs); put('nom_prop1_rhs', rhs);
put('nom_cl_udrift_window', on_grid(Tr.t, Tr.u_closed_loop, 15, 'previous') - on_grid(Tr.t, Tr.u_closed_loop, 12, 'previous'));

% ---- E3 independent noise sequences
S = readtable(fullfile(resDir, 'noise_seeds.csv'), 'TextType', 'char');
pick = @(c) S(strcmp(S.condition, c), :);
sc = pick('closed_loop'); so = pick('open_loop'); s0 = pick('no_dbs');
put('seed_n', height(sc));
sds = [];
for c = 1:numel(conds)
    x = pick(conds{c});
    t = ['seed_' tags{c} '_'];
    put([t 'TH_mean'], mean(x.TH_mean)); put([t 'TH_sd'], std(x.TH_mean));
    put([t 'Je_mean'], mean(x.Je)); put([t 'Je_sd'], std(x.Je));
    put([t 'Ju_mean'], mean(x.Ju)); put([t 'Ju_sd'], std(x.Ju));
    if c > 3, put([t 'u_mean'], mean(x.u_fixed)); put([t 'u_sd'], std(x.u_fixed)); end
    sds = [sds, std(x.TH_mean), std(x.GPi_mean)]; %#ok<AGROW>
end
put('seed_sd_max', max(sds));
sl = pick('late_command'); se = pick('effort'); sp = pick('performance');
put('seed_lc_maxdiff', max(max(abs([sl.TH_mean - sc.TH_mean, sl.GPi_mean - sc.GPi_mean, sl.TH_RMSE - sc.TH_RMSE]))));
put('seed_cl_gt_ol_TH', sum(sc.TH_mean > so.TH_mean));
put('seed_cl_lt_ol_Ju', sum(sc.Ju < so.Ju));
put('seed_ol_lt_cl_Je', sum(so.Je < sc.Je));
put('seed_lc_gt_cl_Ju', sum(sl.Ju > sc.Ju));
put('seed_em_le_cl_Je', sum(se.Je <= sc.Je));
put('seed_pm_le_cl_Ju', sum(sp.Ju <= sc.Ju));
put('seed_pm_Ju_ratio_min', min(sp.Ju ./ sc.Ju)); put('seed_pm_Ju_ratio_max', max(sp.Ju ./ sc.Ju));
put('seed_em_Je_ratio_min', min(se.Je ./ sc.Je)); put('seed_em_Je_ratio_max', max(se.Je ./ sc.Je));
d = [S.TH_mean - S.TH_mean_s; S.GPi_mean - S.GPi_mean_s; S.TH_RMSE - S.TH_RMSE_s; S.u_late - S.u_late_s];
put('seed_avg_maxdiff_sample', max(abs(d)));
d = [S.TH_mean - S.TH_mean_g; S.GPi_mean - S.GPi_mean_g; S.TH_RMSE - S.TH_RMSE_g; S.u_late - S.u_late_g];
put('seed_avg_maxdiff_grid', max(abs(d)));
put('seed_cl_betared_mean', mean(100*(s0.GPi_beta - sc.GPi_beta)./s0.GPi_beta));
put('seed_ol_betared_mean', mean(100*(s0.GPi_beta - so.GPi_beta)./s0.GPi_beta));

% ---- E5 fixed-command map: u*, static response, convexity of phi (Proposition 2)
C = readtable(fullfile(resDir, 'command_map.csv'));
Dmap = unique(C.D)';
Ds = [0.15 0.20 0.35 0.50 0.60];
phiViol = 0; phiChecks = 0; phiWorst = 0;
for i = 1:numel(Dmap)
    tag = sprintf('D%03d', round(100*Dmap(i)));
    x = C(abs(C.D - Dmap(i)) < 1e-9 & C.T == 120, :);
    put(['map_h0_' tag], x.TH_mean(x.u == 0));
    put(['map_hmax_' tag], x.TH_mean(end));
    k = find(x.TH_mean(1:end-1) < ref & x.TH_mean(2:end) >= ref, 1);
    if isempty(k)
        put(['map_ustar_' tag], NaN);
    else
        put(['map_ustar_' tag], x.u(k) + (ref - x.TH_mean(k)) * (x.u(k+1) - x.u(k)) / (x.TH_mean(k+1) - x.TH_mean(k)));
    end
    put(['map_monotone_' tag], double(all(diff(x.TH_mean) > 0)));
    % phi(v) = (TH_ref - h(sqrt v))^2 on v = u^2 is convex on [0, cmax^2] when the
    % slopes of consecutive grid segments do not decrease up to cmax
    v = x.u.^2; phi = (ref - x.TH_mean).^2;
    s = diff(phi) ./ diff(v);
    ds = diff(s);
    kBad = find(ds < 0, 1);
    if isempty(kBad), kc = numel(x.u); else, kc = kBad + 1; end
    put(['phi_cmax_' tag], x.u(kc)); put(['phi_hcmax_' tag], x.TH_mean(kc));
    put(['phi_hcmax_above_' tag], x.TH_mean(kc) - ref);
    phiChecks = phiChecks + numel(ds); phiViol = phiViol + sum(ds < 0);
end
put('phi_checks', phiChecks); put('phi_violations', phiViol);
cm = V(startsWith(K, 'phi_cmax_')); ha = V(startsWith(K, 'phi_hcmax_above_'));
put('phi_cmax_min', min(cm)); put('phi_hcmax_above_min', min(ha));

% ---- E4 five dopamine levels over 15, 60, 120 s, with matched open loops
H = readtable(fullfile(resDir, 'horizon_metrics.csv'), 'TextType', 'char');
Ts = [15 60 120];
hsel = @(D, T, c) H(abs(H.D - D) < 1e-9 & H.T == T & strcmp(H.condition, c), :);
cnt = struct('em_le', 0, 'pm_le', 0, 'lc_reprod', 0, 'n', 0);
cntStart = 0; cntLate = 0;
emR = []; pmR = []; lcR = []; ccR = []; lcJu = []; pmNaN = 0;
for i = 1:numel(Ds)
    tag = sprintf('D%03d', round(100*Ds(i)));
    for T = Ts
        cl = hsel(Ds(i), T, 'closed_loop'); ol = hsel(Ds(i), T, 'open_loop');
        em = hsel(Ds(i), T, 'effort'); pm = hsel(Ds(i), T, 'performance');
        lc = hsel(Ds(i), T, 'late_command'); cc = hsel(Ds(i), T, 'mean_command');
        tt = sprintf('hz_%s_T%03d_', tag, T);
        put([tt 'cl_TH'], cl.TH_mean); put([tt 'ol_TH'], ol.TH_mean);
        put([tt 'cl_Je'], cl.Je); put([tt 'ol_Je'], ol.Je); put([tt 'cl_Ju'], cl.Ju); put([tt 'ol_Ju'], ol.Ju);
        put([tt 'cl_Je_start'], cl.Je_start); put([tt 'cl_Je_late'], cl.Je_late);
        put([tt 'em_u'], em.u_fixed); put([tt 'em_Je'], em.Je); put([tt 'em_TH'], em.TH_mean);
        put([tt 'em_Je_start'], em.Je_start); put([tt 'em_Je_late'], em.Je_late);
        put([tt 'pm_u'], pm.u_fixed); put([tt 'pm_Ju'], pm.Ju);
        put([tt 'lc_u'], lc.u_fixed); put([tt 'lc_Je'], lc.Je); put([tt 'lc_Ju'], lc.Ju);
        put([tt 'cc_u'], cc.u_fixed); put([tt 'cc_Je'], cc.Je); put([tt 'cc_Ju'], cc.Ju);
        put([tt 'em_Je_ratio'], em.Je / cl.Je); put([tt 'pm_Ju_ratio'], pm.Ju / cl.Ju);
        put([tt 'lc_Ju_ratio'], lc.Ju / cl.Ju); put([tt 'lc_Je_ratio'], lc.Je / cl.Je);
        put([tt 'cc_Je_ratio'], cc.Je / cl.Je);
        put([tt 'cl_tsettle'], cl.t_settle); put([tt 'cl_Ju_settle'], cl.Ju_settle);
        cnt.n = cnt.n + 1;
        cnt.em_le = cnt.em_le + (em.Je <= cl.Je);
        cntStart = cntStart + (cl.Je_start > em.Je_start); cntLate = cntLate + (cl.Je_late < em.Je_late);
        if isnan(pm.u_fixed), pmNaN = pmNaN + 1; else, cnt.pm_le = cnt.pm_le + (pm.Ju <= cl.Ju); end
        emR(end+1) = em.Je / cl.Je; pmR(end+1) = pm.Ju / cl.Ju; %#ok<AGROW>
        lcR(end+1) = max(abs([lc.TH_mean - cl.TH_mean, lc.GPi_mean - cl.GPi_mean, lc.TH_RMSE - cl.TH_RMSE])); %#ok<AGROW>
        lcJu(end+1) = lc.Ju / cl.Ju; ccR(end+1) = cc.Je / cl.Je; %#ok<AGROW>
    end
    cl = hsel(Ds(i), 120, 'closed_loop');
    put(['hz_ustar_diff_' tag], cl.u_late - V(strcmp(K, ['map_ustar_' tag])));
    put(['hz_cl_ulate_' tag], cl.u_late); put(['hz_cl_TH_' tag], cl.TH_mean);
    put(['hz_cl_RMSE_' tag], cl.TH_RMSE); put(['hz_cl_tsettle_' tag], cl.t_settle);
    put(['hz_cl_Ju120_' tag], cl.Ju); put(['hz_ol_Ju120_' tag], hsel(Ds(i), 120, 'open_loop').Ju);
    put(['hz_no_TH_' tag], hsel(Ds(i), 120, 'no_dbs').TH_mean);
    put(['hz_ol_TH_' tag], hsel(Ds(i), 120, 'open_loop').TH_mean);
    put(['hz_cl_udrift_' tag], cl.u_end - cl.u_late);
end
put('hz_n', cnt.n); put('hz_em_le_cl_Je', cnt.em_le);
put('hz_cl_start_gt_em', cntStart); put('hz_cl_late_lt_em', cntLate); put('hz_pm_le_cl_Ju', cnt.pm_le); put('hz_pm_undefined', pmNaN);
put('hz_em_Je_ratio_min', min(emR)); put('hz_em_Je_ratio_max', max(emR));
put('hz_pm_Ju_ratio_min', min(pmR)); put('hz_pm_Ju_ratio_max', max(pmR));
put('hz_lc_maxdiff', max(lcR)); put('hz_lc_Ju_ratio_min', min(lcJu)); put('hz_lc_Ju_ratio_max', max(lcJu));
put('hz_cc_Je_ratio_min', min(ccR)); put('hz_cc_Je_ratio_max', max(ccR));
h120 = H(H.T == 120, :);
hc = h120(strcmp(h120.condition, 'closed_loop'), :); ho = h120(strcmp(h120.condition, 'open_loop'), :);
put('hz_cl_TH_min', min(hc.TH_mean)); put('hz_cl_TH_max', max(hc.TH_mean));
put('hz_cl_RMSE_max', max(hc.TH_RMSE));
put('hz_cl_settle_min', min(hc.t_settle)); put('hz_cl_settle_max', max(hc.t_settle));
put('hz_cl_u_min', min(hc.u_late)); put('hz_cl_u_max', max(hc.u_late));
put('hz_cl_udrift_max', max(abs(hc.u_end - hc.u_late)));
put('hz_ol_TH_min', min(ho.TH_mean)); put('hz_ol_TH_max', max(ho.TH_mean));
put('map_absdiff_max', max(abs(V(startsWith(K, 'hz_ustar_diff_')))));
% Proposition 1 on the 120-s closed loops at T = 15, 60, 120: the left side is the
% time-weighted late mean error of horizon_metrics.csv, and the right side is
% evaluated from the recorded command and error at the window ends (0.05-s grid)
Tr = readtable(fullfile(resDir, 'horizon_traces.csv'));
p1 = [];
for i = 1:numel(Ds)
    tag = sprintf('closed_loop_D%03d', round(100*Ds(i)));
    for T = Ts
        [~, rhs] = window_identity(Tr.t, Tr.(['TH_' tag]), Tr.(['u_' tag]), 0.8*T, T, 0.8, 0.15, ref);
        hc = H(abs(H.D - Ds(i)) < 1e-9 & H.T == T & strcmp(H.condition, 'closed_loop'), :);
        p1(end+1) = abs((ref - hc.TH_mean) - rhs); %#ok<AGROW>
    end
end
put('prop1_maxdiff_horizon', max(p1));
% time that each 120-s closed-loop command spends above the convex range of phi
above = []; umaxAfter = [];
for i = 1:numel(Ds)
    tag = sprintf('D%03d', round(100*Ds(i)));
    u = Tr.(['u_closed_loop_' tag]); t = Tr.t;
    cmax = V(strcmp(K, ['phi_cmax_' tag]));
    above(end+1) = sum(u > cmax) * 0.05; %#ok<AGROW>
    umaxAfter(end+1) = max(u(t >= 1)) - cmax; %#ok<AGROW>
end
put('cl_time_above_cmax_max', max(above)); put('cl_umax_after1s_minus_cmax_max', max(umaxAfter));
put('cl_time_above_cmax_bound', max(above) + 0.05);
% averaging methods over every E4 row
d = [H.TH_mean - H.TH_mean_s; H.GPi_mean - H.GPi_mean_s; H.TH_RMSE - H.TH_RMSE_s; H.u_late - H.u_late_s];
put('hz_avg_maxdiff_sample', max(abs(d)));
d = [H.TH_mean - H.TH_mean_g; H.GPi_mean - H.GPi_mean_g; H.TH_RMSE - H.TH_RMSE_g; H.u_late - H.u_late_g];
put('hz_avg_maxdiff_grid', max(abs(d)));
put('hz_avg_ontarget_changes', sum(abs(H.TH_mean - ref) < tol ~= (abs(H.TH_mean_s - ref) < tol)));
put('hz_avg_ontarget_changes_g', sum(abs(H.TH_mean - ref) < tol ~= (abs(H.TH_mean_g - ref) < tol)));
% error of the performance-matched command (midpoint of the final bisection bracket)
% relative to the closed-loop error, over E2, E3 and E4
pr = abs(N.Je(strcmp(N.condition, 'performance')) / N.Je(strcmp(N.condition, 'closed_loop')) - 1);
pr = [pr; abs(S.Je(strcmp(S.condition, 'performance')) ./ S.Je(strcmp(S.condition, 'closed_loop')) - 1)];
hp = H(strcmp(H.condition, 'performance') & ~isnan(H.u_fixed), :);
for k = 1:height(hp)
    hc = H(strcmp(H.condition, 'closed_loop') & abs(H.D - hp.D(k)) < 1e-9 & H.T == hp.T(k), :);
    pr(end+1, 1) = abs(hp.Je(k) / hc.Je - 1); %#ok<AGROW>
end
put('pm_Je_reldiff_max', max(pr));

% ---- E7 controller gains (120 s), and Proposition 2 across the gain grid via the map
G = readtable(fullfile(resDir, 'gains.csv'));
G120 = G(G.T == 120, :);
fast = G120(abs(G120.Ki - 0.45) < 1e-9, :); nom = G120(abs(G120.Ki - 0.15) < 1e-9, :);
slow = G120(abs(G120.Ki - 0.05) < 1e-9, :); vfast = G120(abs(G120.Ki - 1.35) < 1e-9, :);
put('gain_vfast_settle_min', min(vfast.t_settle)); put('gain_vfast_settle_max', max(vfast.t_settle));
put('gain_vfast_unsettled', sum(isnan(vfast.t_settle)));
put('gain_fast_settle_min', min(fast.t_settle)); put('gain_fast_settle_max', max(fast.t_settle));
put('gain_nom_settle_min', min(nom.t_settle)); put('gain_nom_settle_max', max(nom.t_settle));
put('gain_slow_unsettled', sum(isnan(slow.t_settle))); put('gain_slow_n', height(slow));
[~, ia] = ismember([fast.D fast.Kp], [nom.D nom.Kp], 'rows');
r = fast.Ju ./ nom.Ju(ia);
put('gain_fast_Ju_ratio_min', min(r)); put('gain_fast_Ju_ratio_max', max(r));
[~, ia] = ismember([vfast.D vfast.Kp], [nom.D nom.Kp], 'rows');
r = vfast.Ju ./ nom.Ju(ia);
put('gain_vfast_Ju_ratio_min', min(r)); put('gain_vfast_Ju_ratio_max', max(r));
r = vfast.Je ./ nom.Je(ia);
put('gain_vfast_Je_ratio_min', min(r)); put('gain_vfast_Je_ratio_max', max(r));
put('gain_peak_max', max(G120.TH_smooth_max));
put('gain_sat_late_max', max(G120.sat_late));
put('gain_usd_kp16_min', min(G120.u_sd_late(abs(G120.Kp - 1.6) < 1e-9 & G120.Ki > 0.1)));
put('gain_usd_kp16_max', max(G120.u_sd_late(abs(G120.Kp - 1.6) < 1e-9 & G120.Ki > 0.1)));
put('gain_usd_kp04_max', max(G120.u_sd_late(abs(G120.Kp - 0.4) < 1e-9 & G120.Ki > 0.1)));
settled = G120(~isnan(G120.t_settle), :);
put('gain_settled_absdev_max', max(abs(settled.TH_mean - ref)));
% effort-matched comparison for every gain-grid run and horizon, by interpolation on the map
nG = 0; leG = 0; rG = []; pmG = []; nPm = 0; excD = []; excKi = []; pmExcD = []; pmExcKi = [];
excInit = []; nInit = 0; excT = [];
for k = 1:height(G)
    m = C(abs(C.D - G.D(k)) < 1e-9 & C.T == G.T(k), :);
    uEM = sqrt(G.Ju(k) / G.T(k));
    if uEM > max(m.u), continue; end
    JeEM = interp1(m.u, m.Je, uEM, 'pchip');
    % initial command K_p TH_ref, saturated at 0.6, above the convex range of Proposition 2
    init = min(G.Kp(k) * ref, 0.6) > V(strcmp(K, sprintf('phi_cmax_D%03d', round(100*G.D(k))))) + 1e-12;
    nInit = nInit + init;
    nG = nG + 1; leG = leG + (JeEM <= G.Je(k)); rG(end+1) = JeEM / G.Je(k); %#ok<AGROW>
    if JeEM > G.Je(k)
        excD(end+1) = G.D(k); excKi(end+1) = G.Ki(k); excInit(end+1) = init; excT(end+1) = G.T(k); %#ok<AGROW>
    end
    [JeMin, im] = min(m.Je);
    if JeMin <= G.Je(k)
        j = find(m.Je(1:im) <= G.Je(k), 1);
        if j == 1, c = 0; else
            c = fzero(@(c) interp1(m.u, m.Je, c, 'pchip') - G.Je(k), [m.u(j-1) m.u(j)]);
        end
        nPm = nPm + 1; pmG(end+1) = c^2 * G.T(k) / G.Ju(k); %#ok<AGROW>
        if pmG(end) > 1, pmExcD(end+1) = G.D(k); pmExcKi(end+1) = G.Ki(k); end %#ok<AGROW>
    end
end
put('gaingrid_exc_n', numel(excD)); put('gaingrid_pm_exc_n', numel(pmExcD));
put('gaingrid_exc_ki135', sum(abs(excKi - 1.35) < 1e-9));
otherKi = excKi(abs(excKi - 1.35) >= 1e-9);
put('gaingrid_exc_other_n', numel(otherKi));
if ~isempty(otherKi)
    % ratio of the exception that is not at Ki = 1.35 (exceptions are listed in grid order)
    kk = find(rG > 1); kk = kk(abs(excKi - 1.35) >= 1e-9);
    put('gaingrid_exc_other_ratio', max(rG(kk))); put('gaingrid_exc_other_ki', otherKi(1));
    put('gaingrid_exc_other_T', excT(find(abs(excKi - 1.35) >= 1e-9, 1)));
else
    put('gaingrid_exc_other_ratio', NaN); put('gaingrid_exc_other_ki', NaN); put('gaingrid_exc_other_T', NaN);
end
put('gaingrid_exc_all_D060', double(all(abs([excD pmExcD] - 0.60) < 1e-9)));
put('gaingrid_exc_all_Ki135', double(all(abs([excKi pmExcKi] - 1.35) < 1e-9)));
put('gaingrid_exc_cl_adv_max', 1 - 1/max(rG));
put('gaingrid_init_above_cmax_n', nInit); put('gaingrid_exc_init_above_cmax', sum(excInit));
put('gaingrid_ki135_n', sum(abs(G.Ki - 1.35) < 1e-9));
put('gaingrid_n', nG); put('gaingrid_em_le', leG);
put('gaingrid_em_ratio_min', min(rG)); put('gaingrid_em_ratio_max', max(rG));
put('gaingrid_pm_n', nPm); put('gaingrid_pm_le', sum(pmG <= 1));
put('gaingrid_pm_ratio_min', min(pmG)); put('gaingrid_pm_ratio_max', max(pmG));
% interpolation check against the simulated effort-matched runs of E4
ie = [];
for i = 1:numel(Ds)
    for T = Ts
        em = hsel(Ds(i), T, 'effort');
        m = C(abs(C.D - Ds(i)) < 1e-9 & C.T == T, :);
        ie(end+1) = abs(interp1(m.u, m.Je, em.u_fixed, 'pchip') - em.Je) / em.Je; %#ok<AGROW>
    end
end
put('gaingrid_interp_relerr_max', max(ie));

% ---- E6 dopamine changes within a run
Z = readtable(fullfile(resDir, 'dopamine_step_metrics.csv'), 'TextType', 'char');
zc = {'no_dbs', 'open_loop', 'open_loop_tuned', 'open_loop_tuned_low', 'open_loop_best', ...
    'open_loop_best_after', 'closed_loop'};
zt = {'no', 'ol', 'olt', 'oltl', 'olb', 'olba', 'cl'};
for c = 1:numel(zc)
    z = Z(strcmp(Z.condition, zc{c}), :);
    t = ['step_' zt{c} '_'];
    put([t 'u'], z.u_fixed(1));
    for s = 1:3
        put(sprintf('%sTH_seg%d', t, s), z.TH_last10(z.segment == s));
        put(sprintf('%sJe_seg%d', t, s), z.Je_segment(z.segment == s));
        put(sprintf('%soff_seg%d', t, s), z.time_off(z.segment == s));
    end
    put([t 'Je_total'], sum(z.Je_segment)); put([t 'Je_after'], sum(z.Je_segment(z.segment > 1)));
    put([t 'Ju_total'], sum(z.Ju_segment));
    put([t 'off_after'], mean(z.time_off(z.segment > 1)));
end
z = Z(strcmp(Z.condition, 'closed_loop'), :);
put('step_cl_settle_seg2', z.t_settle(z.segment == 2)); put('step_cl_settle_seg3', z.t_settle(z.segment == 3));
put('step_cl_peak_seg3', z.TH_smooth_max(z.segment == 3));
put('step_cl_u_seg1', z.u_last10(z.segment == 1)); put('step_cl_u_seg2', z.u_last10(z.segment == 2));
put('step_cl_u_seg3', z.u_last10(z.segment == 3));
put('step_cl_vs_best_Je_after', V(strcmp(K, 'step_cl_Je_after')) / V(strcmp(K, 'step_olb_Je_after')));
put('step_cl_vs_bestafter_Je_after', V(strcmp(K, 'step_cl_Je_after')) / V(strcmp(K, 'step_olba_Je_after')));
put('step_cl_vs_best_Je_total', V(strcmp(K, 'step_cl_Je_total')) / V(strcmp(K, 'step_olb_Je_total')));
sel = startsWith(K, 'step_o') & ~startsWith(K, 'step_cl_');
ltT = double(V(strcmp(K, 'step_cl_Je_total')) < min(V(sel & endsWith(K, '_Je_total'))));
ltA = double(V(strcmp(K, 'step_cl_Je_after')) < min(V(sel & endsWith(K, '_Je_after'))));
put('step_cl_lt_all_total', ltT); put('step_cl_lt_all_after', ltA);

% ---- E8 virtual cohort
if exist(fullfile(resDir, 'cohort_stationary.csv'), 'file')
    U = readtable(fullfile(resDir, 'cohort_subjects.csv'));
    Q = readtable(fullfile(resDir, 'cohort_stationary.csv'), 'TextType', 'char');
    n = height(U);
    put('coh_n', n);
    qc = {'no_dbs', 'open_loop', 'open_loop_tuned', 'open_loop_individual', 'closed_loop'};
    qt = {'no', 'ol', 'olt', 'oli', 'cl'};
    q0 = Q(strcmp(Q.condition, 'no_dbs'), :);
    for c = 1:numel(qc)
        x = Q(strcmp(Q.condition, qc{c}), :);
        if height(x) ~= n || any(x.subject ~= U.subject), error('Cohort rows out of order.'); end
        t = ['coh_' qt{c} '_'];
        th = sort(x.TH_mean); dev = abs(x.TH_mean - ref);
        put([t 'TH_mean'], mean(x.TH_mean));
        put([t 'TH_p05'], th(round(0.05*n))); put([t 'TH_p95'], th(round(0.95*n)));
        put([t 'TH_min'], th(1)); put([t 'TH_max'], th(end));
        put([t 'ontarget'], sum(dev < tol)); put([t 'below'], sum(x.TH_mean <= ref - tol));
        put([t 'above'], sum(x.TH_mean >= ref + tol));
        put([t 'absdev_mean'], mean(dev)); put([t 'absdev_max'], max(dev));
        put([t 'Je_mean'], mean(x.Je)); put([t 'Je_median'], median(x.Je));
        put([t 'Ju_mean'], mean(x.Ju)); put([t 'Ju_median'], median(x.Ju));
        if c > 1
            put([t 'GPired_mean'], mean(100*(q0.GPi_mean - x.GPi_mean)./q0.GPi_mean));
            put([t 'betared_median'], median(100*(q0.GPi_beta - x.GPi_beta)./q0.GPi_beta));
        end
    end
    cl = Q(strcmp(Q.condition, 'closed_loop'), :);
    oi = Q(strcmp(Q.condition, 'open_loop_individual'), :);
    put('coh_tuned_u', Q.u_fixed(find(strcmp(Q.condition, 'open_loop_tuned'), 1)));
    att = U.attainable == 1;
    put('coh_attainable', sum(att)); put('coh_unattainable', sum(~att));
    put('coh_unattainable_low', sum(U.attainable_low == 0));
    put('coh_n_minus_unatt_low', sum(U.attainable_low == 1));
    put('coh_no_needed', sum(U.u_star == 0));
    put('coh_ustar_min', min(U.u_star(att))); put('coh_ustar_max', max(U.u_star(att)));
    put('coh_cl_sat', sum(cl.sat_late >= 0.5));
    put('coh_cl_sat_unatt', sum(cl.sat_late >= 0.5 & ~att));
    put('coh_cl_ontarget_att', sum(abs(cl.TH_mean(att) - ref) < tol));
    off = abs(cl.TH_mean - ref) >= tol;
    put('coh_cl_offcount', sum(off));
    put('coh_noneed_above', sum(U.u_star == 0 & q0.TH_mean >= ref + tol));
    put('coh_cl_off_noneed', sum(off & U.u_star == 0)); put('coh_cl_off_unatt', sum(off & ~att));
    put('coh_unatt_on', sum(~off & ~att));
    ud = abs(cl.u_late - U.u_star);
    big = att & ud > 0.03;
    put('coh_udiff_big_n', sum(big)); put('coh_udiff_big_Gmax', max(U.G_DBS(big)));
    put('coh_udiff_big_settle_min', min(cl.t_settle(big)));
    put('coh_oi_ontarget_att', sum(abs(oi.TH_mean(att) - ref) < tol));
    put('coh_cl_u_vs_ustar_max', max(abs(cl.u_late(att) - U.u_star(att))));
    put('coh_cl_u_vs_ustar_median', median(abs(cl.u_late(att) - U.u_star(att))));
    put('coh_cl_lt_oi_Je', sum(cl.Je < oi.Je)); put('coh_oi_lt_cl_Je', sum(oi.Je < cl.Je));
    put('coh_oi_Je_ratio_median', median(oi.Je ./ cl.Je));
    put('coh_cl_lt_oi_Ju', sum(cl.Ju < oi.Ju)); put('coh_cl_Ju_ratio_median', median(cl.Ju ./ oi.Ju));
    put('coh_cl_Je_late_median', median(cl.Je_late)); put('coh_oi_Je_late_median', median(oi.Je_late));
    put('coh_cl_Je_start_share_median', median(cl.Je_start ./ cl.Je));
    put('coh_cl_settle_median', median(cl.t_settle, 'omitnan')); put('coh_cl_settle_max', max(cl.t_settle));
    put('coh_cl_unsettled', sum(isnan(cl.t_settle))); put('coh_cl_settled_n', sum(~isnan(cl.t_settle)));
    put('coh_cl_usd_median', median(cl.u_sd_late)); put('coh_cl_usd_max', max(cl.u_sd_late));
    % rank correlations with the design parameters
    pn = {'D', 'g', 'a_n', 'G_DBS', 'sensor_delay', 'sensor_noise'};
    for p = 1:numel(pn)
        put(['coh_rho_ustar_' pn{p}], spearman(U.u_star(att), U.(pn{p})(att)));
        put(['coh_rho_settle_' pn{p}], spearman(cl.t_settle(att & ~isnan(cl.t_settle)), U.(pn{p})(att & ~isnan(cl.t_settle))));
    end
    put('coh_rho_ustar_h0', spearman(U.u_star(att), U.h0(att)));
    put('coh_rho_h0_D', spearman(U.h0(att), U.D(att))); put('coh_rho_h0_g', spearman(U.h0(att), U.g(att)));
    put('coh_rho_h0_G_DBS', spearman(U.h0(att), U.G_DBS(att)));
    pp = {'D', 'g', 'G_DBS'};
    for p = 1:numel(pp)
        put(['coh_prho_ustar_' pp{p} '_h0'], partial_spearman(U.u_star(att), U.(pp{p})(att), U.h0(att)));
    end
    taus = {'tau_C', 'tau_D1', 'tau_D2', 'tau_GPe', 'tau_STN', 'tau_GPi', 'tau_TH', 'd_TC', 'd_CSTN', ...
        'd_GPeSTN', 'd_STNGPe', 'd_STNGPi', 'd_GPiTH'};
    rmax = 0; rmaxs = 0;
    for p = 1:numel(taus)
        rmax = max(rmax, abs(spearman(U.u_star(att), U.(taus{p})(att))));
        ok = att & ~isnan(cl.t_settle);
        rmaxs = max(rmaxs, abs(spearman(cl.t_settle(ok), U.(taus{p})(ok))));
    end
    put('coh_rho_ustar_tau_absmax', rmax); put('coh_rho_settle_tau_absmax', rmaxs);
    d = [Q.TH_mean - Q.TH_mean_s; Q.GPi_mean - Q.GPi_mean_s; Q.TH_RMSE - Q.TH_RMSE_s; Q.u_late - Q.u_late_s];
    put('coh_avg_maxdiff_sample', max(abs(d)));
    d = [Q.TH_mean - Q.TH_mean_g; Q.GPi_mean - Q.GPi_mean_g; Q.TH_RMSE - Q.TH_RMSE_g; Q.u_late - Q.u_late_g];
    put('coh_avg_maxdiff_grid', max(abs(d)));
    put('coh_avg_ontarget_changes', sum((abs(Q.TH_mean - ref) < tol) ~= (abs(Q.TH_mean_s - ref) < tol)));
    put('coh_avg_ontarget_changes_g', sum((abs(Q.TH_mean - ref) < tol) ~= (abs(Q.TH_mean_g - ref) < tol)));
    % state-change protocol
    Zc = readtable(fullfile(resDir, 'cohort_change.csv'), 'TextType', 'char');
    zc = {'no_dbs', 'open_loop_individual', 'open_loop_individual_low', 'open_loop_best', ...
        'open_loop_best_after', 'closed_loop'};
    zt = {'no', 'oi', 'oil', 'ob', 'oba', 'cl'};
    JeA = zeros(n, numel(zc)); offA = JeA; JuT = JeA; Je1 = JeA; JeT = JeA;
    for c = 1:numel(zc)
        g1 = Zc(strcmp(Zc.condition, zc{c}) & Zc.segment == 1, :);
        g2 = Zc(strcmp(Zc.condition, zc{c}) & Zc.segment == 2, :);
        g3 = Zc(strcmp(Zc.condition, zc{c}) & Zc.segment == 3, :);
        if any(g1.subject ~= U.subject) || any(g2.subject ~= U.subject) || any(g3.subject ~= U.subject)
            error('Cohort change rows out of order.');
        end
        JeA(:, c) = g2.Je_segment + g3.Je_segment;
        JeT(:, c) = g1.Je_segment + JeA(:, c);
        offA(:, c) = (g2.time_off + g3.time_off) / 2;
        JuT(:, c) = g1.Ju_segment + g2.Ju_segment + g3.Ju_segment;
        Je1(:, c) = g1.Je_segment;
        t = ['chg_' zt{c} '_'];
        put([t 'JeA_median'], median(JeA(:, c))); put([t 'JeA_mean'], mean(JeA(:, c)));
        put([t 'offA_median'], median(offA(:, c))); put([t 'JuT_mean'], mean(JuT(:, c)));
        put([t 'Je1_median'], median(Je1(:, c))); put([t 'JeT_median'], median(JeT(:, c)));
    end
    ic = 6; iba = 5; ib = 4; ii = 2; il = 3; consts = [ii il ib iba];
    % 90-270 s, after the first change
    put('chg_cl_lt_ob', sum(JeA(:, ic) < JeA(:, ib))); put('chg_cl_lt_oba', sum(JeA(:, ic) < JeA(:, iba)));
    put('chg_cl_lt_oi', sum(JeA(:, ic) < JeA(:, ii))); put('chg_cl_lt_oil', sum(JeA(:, ic) < JeA(:, il)));
    put('chg_cl_lt_all', sum(JeA(:, ic) < min(JeA(:, consts), [], 2)));
    put('chg_cl_ob_ratio_median', median(JeA(:, ic) ./ JeA(:, ib)));
    put('chg_cl_oba_ratio_median', median(JeA(:, ic) ./ JeA(:, iba)));
    put('chg_cl_oi_ratio_median', median(JeA(:, ic) ./ JeA(:, ii)));
    put('chg_oba_lt_ob', sum(JeA(:, iba) < JeA(:, ib)));
    % constants off target over 90-270 s
    z0 = offA(:, iba) == 0;
    put('chg_oba_off0_n', sum(z0));
    if any(z0), put('chg_oba_off0_dDmax', max(U.dD(z0))); else, put('chg_oba_off0_dDmax', NaN); end
    put('chg_oba_off0_cl_lt', sum(z0 & JeA(:, ic) < JeA(:, iba)));
    put('chg_oi_oil_offA_min', min(min(offA(:, [ii il]))));
    % whole run, 0-270 s, including the start-up of the closed loop
    put('chg_cl_lt_ob_total', sum(JeT(:, ic) < JeT(:, ib)));
    put('chg_cl_lt_oba_total', sum(JeT(:, ic) < JeT(:, iba)));
    put('chg_cl_lt_all_total', sum(JeT(:, ic) < min(JeT(:, consts), [], 2)));
    put('chg_cl_ob_ratio_total_median', median(JeT(:, ic) ./ JeT(:, ib)));
    ge = JeT(:, ic) >= JeT(:, ib);
    put('chg_cl_ge_ob_total', sum(ge));
    put('chg_ge_total_Je1_gt_ob', sum(ge & Je1(:, ic) > Je1(:, ib)));
    put('chg_ge_total_A_lt_ob', sum(ge & JeA(:, ic) < JeA(:, ib)));
    put('chg_rho_total_dD', spearman(JeT(:, ib) ./ JeT(:, ic), U.dD));
    % first segment, before the change
    put('chg_cl_Je1_gt_oi', sum(Je1(:, ic) > Je1(:, ii))); put('chg_cl_Je1_gt_ob', sum(Je1(:, ic) > Je1(:, ib)));
    put('chg_cl_Je1_ob_ratio_median', median(Je1(:, ic) ./ Je1(:, ib)));
    % subjects in which the best constant after the change does at least as well over 90-270 s
    exc = JeA(:, ic) >= JeA(:, iba);
    noneed = U.u_star == 0 & U.u_star_low == 0;
    lowwind = U.attainable_low == 1 & U.u_star == 0 & U.u_star_low > 0;
    put('chg_exc_n', sum(exc)); put('chg_exc_unatt_low', sum(exc & U.attainable_low == 0));
    put('chg_exc_noneed', sum(exc & U.attainable_low == 1 & noneed));
    put('chg_exc_lowwind', sum(exc & lowwind));
    rest = exc & U.attainable_low == 1 & ~noneed & ~lowwind;
    put('chg_exc_rest', sum(rest));
    if any(rest)
        put('chg_exc_rest_dDmax', max(U.dD(rest)));
        put('chg_exc_rest_ratio_max', max(JeA(rest, ic) ./ JeA(rest, iba)));
    else
        put('chg_exc_rest_dDmax', NaN); put('chg_exc_rest_ratio_max', NaN);
    end
    put('coh_dD_min', min(U.dD));
    put('chg_cl_Ju_ratio_ob_median', median(JuT(:, ic) ./ JuT(:, ib)));
    put('chg_cl_Ju_ratio_oba_median', median(JuT(:, ic) ./ JuT(:, iba)));
    put('chg_rho_gain_dD', spearman(JeA(:, iba) ./ JeA(:, ic), U.dD));
    s2 = Zc(strcmp(Zc.condition, 'closed_loop') & Zc.segment == 2, :);
    s3 = Zc(strcmp(Zc.condition, 'closed_loop') & Zc.segment == 3, :);
    put('chg_cl_settle2_median', median(s2.t_settle, 'omitnan')); put('chg_cl_unsettled2', sum(isnan(s2.t_settle)));
    put('chg_cl_settle3_median', median(s3.t_settle, 'omitnan')); put('chg_cl_unsettled3', sum(isnan(s3.t_settle)));
    put('chg_cl_settled2_n', sum(~isnan(s2.t_settle))); put('chg_cl_settled3_n', sum(~isnan(s3.t_settle)));
    put('chg_cl_overshoot3_median', median(s3.TH_smooth_max - ref)); put('chg_cl_overshoot3_max', max(s3.TH_smooth_max - ref));
    put('chg_cl_sat2', sum(s2.u_max_seg >= bgtc_params().DBS_max - 1e-9));
    uns = isnan(s2.t_settle);
    put('chg_unsettled2_sat', sum(uns & s2.u_max_seg >= bgtc_params().DBS_max - 1e-9));
    put('chg_unsettled2_unatt', sum(uns & U.attainable_low == 0));
    put('chg_unsettled2_lowwind', sum(uns & lowwind & s2.u_max_seg < 0.05));
    % no return within 90 s after the recovery: output above the reference without
    % stimulation at D, unattainable reference at D, or an integrator charged while the
    % command was saturated at D_low
    uns3 = isnan(s3.t_settle);
    put('chg_unsettled3_noneed', sum(uns3 & U.u_star == 0));
    put('chg_unsettled3_unatt', sum(uns3 & U.attainable == 0));
    w3 = uns3 & U.u_star > 0 & U.attainable == 1;
    put('chg_unsettled3_windup', sum(w3 & s2.u_max_seg >= bgtc_params().DBS_max - 1e-9 & s3.TH_last10 >= ref + tol));
    put('chg_unsettled3_other', sum(w3) - V(strcmp(K, 'chg_unsettled3_windup')));
end

% ---- E9 attainability and observation errors
A = readtable(fullfile(resDir, 'limits_attain.csv'), 'TextType', 'char');
acl = A(strcmp(A.condition, 'closed_loop'), :); aol = A(strcmp(A.condition, 'open_loop_umax'), :);
sat = acl.sat_late >= 0.5;
low = acl.u_late < 1e-6 & acl.sat_late < 0.5;
thMax = zeros(height(acl), 1);
for k = 1:height(acl)
    o = aol(abs(aol.D - acl.D(k)) < 1e-9 & abs(aol.G_DBS - acl.G_DBS(k)) < 1e-9 & abs(aol.u_max - acl.u_max(k)) < 1e-9, :);
    thMax(k) = o.TH_mean;
end
put('lim_n', height(acl)); put('lim_sat', sum(sat));
put('lim_unattainable', sum(thMax < acl.TH_ref));
put('lim_sat_unatt_agree', sum(sat == (thMax < acl.TH_ref)));
put('lim_sat_maxdiff_olumax', max(abs(acl.TH_mean(sat) - thMax(sat))));
on = abs(acl.TH_mean - acl.TH_ref) < tol;
put('lim_ontarget', sum(on)); put('lim_ontarget_att', sum(on & thMax >= acl.TH_ref));
put('lim_att', sum(thMax >= acl.TH_ref));
put('lim_lowsat', sum(acl.u_late < 1e-4));
put('lim_lowsat_above', sum(acl.u_late < 1e-4 & acl.TH_mean >= acl.TH_ref + tol));
notOn = ~on & thMax >= acl.TH_ref & acl.u_late >= 1e-4;
put('lim_att_not_on', sum(notOn));
put('lim_att_not_on_settle_min', min(acl.t_settle(notOn)));
put('lim_att_not_on_rising', sum(notOn & acl.u_end > acl.u_late));
put('lim_att_not_on_lowG', sum(notOn & acl.G_DBS < 0.25 + 1e-9));
put('lim_att_not_on_settle_max', max(acl.t_settle(notOn)));
put('lim_att_not_on_near', sum(notOn & thMax - acl.TH_ref < tol));
put('lim_att_not_on_near_lowG', sum(notOn & acl.G_DBS < 0.25 + 1e-9 & thMax - acl.TH_ref < tol));
put('lim_sat_n_mismatch', sum(sat ~= (thMax < acl.TH_ref)));
O = readtable(fullfile(resDir, 'limits_sensor.csv'), 'TextType', 'char');
ob = O(strcmp(O.factor, 'bias'), :);
put('obs_bias_offset_maxerr', max(abs(ob.TH_mean - (ref - ob.value))));
obf = ob(abs(ob.Kp - 1.6) < 1e-9, :); obn = ob(abs(ob.Kp - 0.8) < 1e-9, :);
put('obs_bias_fast_offset_maxerr', max(abs(obf.TH_mean - (ref - obf.value))));
put('obs_bias_nom_offset_maxerr', max(abs(obn.TH_mean - (ref - obn.value))));
on_ = O(strcmp(O.factor, 'noise') & abs(O.Kp - 0.8) < 1e-9, :);
put('obs_noise_Ju_ratio_max', on_.Ju(on_.value == max(on_.value)) / on_.Ju(on_.value == 0));
put('obs_noise_TH_absdev_max', max(abs(on_.TH_mean - ref)));
put('obs_noise_usd_max', max(on_.u_sd_late));
onf = O(strcmp(O.factor, 'noise') & abs(O.Kp - 1.6) < 1e-9, :);
put('obs_noise_fast_Ju_ratio_max', onf.Ju(onf.value == max(onf.value)) / onf.Ju(onf.value == 0));
od = O(strcmp(O.factor, 'delay') & abs(O.Kp - 0.8) < 1e-9, :);
odf = O(strcmp(O.factor, 'delay') & abs(O.Kp - 1.6) < 1e-9, :);
put('obs_delay_nom_TH_absdev_max', max(abs(od.TH_mean - ref)));
put('obs_delay_nom_Je_ratio', od.Je(od.value == max(od.value)) / od.Je(od.value == 0));
put('obs_delay_fast_Je_ratio', odf.Je(odf.value == max(odf.value)) / odf.Je(odf.value == 0));
put('obs_delay_fast_RMSE_max', max(odf.TH_RMSE)); put('obs_delay_fast_usd_max', max(odf.u_sd_late));
put('obs_delay_fast_unsettled', sum(isnan(odf.t_settle)));
put('obs_delay_fast_first_unsettled', min([odf.value(isnan(odf.t_settle)); Inf]));

% ---- solver settings
Nm = readtable(fullfile(resDir, 'numerics.csv'), 'TextType', 'char');
ref6 = Nm(Nm.RelTol == 1e-6 & Nm.MaxStep == 2.5e-4, :);
dmax = struct('TH', 0, 'u', 0, 'Je', 0, 'Ju', 0);
for k = 1:height(Nm)
    r0 = ref6(strcmp(ref6.condition, Nm.condition{k}) & abs(ref6.D - Nm.D(k)) < 1e-9 & ref6.T == Nm.T(k), :);
    dmax.TH = max(dmax.TH, abs(Nm.TH_mean(k) - r0.TH_mean));
    dmax.u = max(dmax.u, abs(Nm.u_late(k) - r0.u_late));
    dmax.Je = max(dmax.Je, abs(Nm.Je(k) - r0.Je) / r0.Je);
    if r0.Ju > 0, dmax.Ju = max(dmax.Ju, abs(Nm.Ju(k) - r0.Ju) / r0.Ju); end
end
put('num_TH_maxdiff', dmax.TH); put('num_u_maxdiff', dmax.u);
put('num_Je_relmax', dmax.Je); put('num_Ju_relmax', dmax.Ju);

write_csv(fullfile(resDir, 'summary.csv'), {'key', 'value'}, [K, num2cell(V)]);
end

function r = spearman(x, y)
% Spearman rank correlation, with tied values given their average rank
rx = ranks(x(:)); ry = ranks(y(:));
r = sum((rx - mean(rx)) .* (ry - mean(ry))) / sqrt(sum((rx - mean(rx)).^2) * sum((ry - mean(ry)).^2));
end

function r = partial_spearman(x, y, z)
% Spearman rank correlation of x and y given z: correlation of the residuals of the
% ranks of x and y after linear regression on the ranks of z
rx = ranks(x(:)); ry = ranks(y(:)); rz = ranks(z(:));
A = [ones(size(rz)) rz];
ex = rx - A * (A \ rx); ey = ry - A * (A \ ry);
r = sum(ex .* ey) / sqrt(sum(ex.^2) * sum(ey.^2));
end

function r = ranks(x)
[xs, order] = sort(x);
r = zeros(size(x));
i = 1; n = numel(x);
while i <= n
    j = i;
    while j < n && xs(j+1) == xs(i), j = j + 1; end
    r(order(i:j)) = (i + j) / 2;
    i = j + 1;
end
end

function [lhs, rhs] = window_identity(t, TH, u, ta, tb, Kp, Ki, ref)
% Mean tracking error over [ta, tb] and the right-hand side of Proposition 1,
% (u(tb) - u(ta) - Kp (e(tb) - e(ta))) / (Ki (tb - ta)), from recorded traces.
e = ref - TH;
lhs = win_int(t, e, ta, tb) / (tb - ta);
ua = on_grid(t, u, ta, 'previous'); ub = on_grid(t, u, tb, 'previous');
ea = on_grid(t, e, ta); eb = on_grid(t, e, tb);
rhs = (ub - ua - Kp*(eb - ea)) / (Ki*(tb - ta));
end
