function make_figures(resDir, figDir, which)
%MAKE_FIGURES Draw every figure of the article from the result files.
%   MAKE_FIGURES(RESDIR, FIGDIR) reads the CSV files in RESDIR and writes
%   Fig2.pdf to Fig10.pdf (vector) and PNG copies at 300 dpi to FIGDIR.
%   MAKE_FIGURES(RESDIR, FIGDIR, WHICH) draws only the figures whose
%   numbers are listed in WHICH. Fig. 1 is the model diagram drawn in the
%   manuscript source.

if ~exist(figDir, 'dir'), mkdir(figDir); end
if nargin < 3 || isempty(which), which = 2:10; end
st = style();
figs = {2, @fig_baseline; 3, @fig_nominal; 4, @fig_efficiency; 5, @fig_severity; ...
    6, @fig_step; 7, @fig_gains; 8, @fig_cohort; 9, @fig_change; 10, @fig_limits};
for k = 1:size(figs, 1)
    if ismember(figs{k, 1}, which), figs{k, 2}(resDir, figDir, st); end
end
close all;
end

% =====================================================================
function st = style()
st.font = 'Times New Roman';
st.fs = 8;
st.lw = 0.75;
st.W = 5.15;                                   % text width of the journal (in)
% conditions (colour-blind-safe palette; each also has its own line style)
st.col.no   = [0.43 0.43 0.43];                % no DBS
st.col.ol   = [0.84 0.37 0.00];                % open loop, u_OL = 0.12
st.col.cl   = [0.00 0.45 0.70];                % closed loop
st.col.lc   = [0.53 0.13 0.33];                % late-command-matched open loop
st.col.cc   = [0.34 0.71 0.91];                % cumulative-command-matched open loop
st.col.em   = [0.80 0.47 0.65];                % effort-matched open loop
st.col.pm   = [0.60 0.60 0.20];                % performance-matched open loop
st.col.olt  = [0.00 0.62 0.45];                % open loop, tuned command
st.col.oltl = [0.07 0.47 0.20];                % open loop, tuned to the low-dopamine state
st.col.olb  = [0.65 0.38 0.10];                % open loop, best constant for a schedule
st.col.olba = [0.90 0.62 0.00];                % open loop, best constant after the change
st.col.oli  = [0.67 0.27 0.60];                % open loop, individually optimized command
st.col.healthy = [0 0 0];
st.col.pd  = [0.78 0.12 0.12];
st.ref = [0.25 0.25 0.25];
% dopamine levels 0.15, 0.20, 0.35, 0.50, 0.60 from severe (dark) to mild (light)
st.Ds = [0.15 0.20 0.35 0.50 0.60];
st.ramp = [0.03 0.19 0.42; 0.03 0.32 0.61; 0.13 0.44 0.71; 0.26 0.57 0.78; 0.42 0.68 0.84];
end

function c = dcol(st, D)
c = st.ramp(abs(st.Ds - D) < 1e-9, :);
end

function f = new_fig(st, h)
f = figure('Units', 'inches', 'Position', [1 1 st.W h], 'Color', 'w', ...
    'PaperUnits', 'inches', 'PaperSize', [st.W h], 'PaperPosition', [0 0 st.W h], ...
    'Visible', 'off');
end

function ax = new_ax(f, pos, st)
ax = axes('Parent', f, 'Units', 'inches', 'Position', pos);
hold(ax, 'on');
set(ax, 'FontName', st.font, 'FontSize', st.fs, 'LabelFontSizeMultiplier', 1, ...
    'TitleFontSizeMultiplier', 1, 'LineWidth', 0.5, 'TickDir', 'out', ...
    'Box', 'off', 'TickLength', [0.015 0.015], 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
end

function label(ax, s, st, dx, dy)
if nargin < 4 || isempty(dx), dx = -0.45; end
if nargin < 5, dy = 0.05; end
p = get(ax, 'Position');
text(ax, dx / p(3), 1 + dy / p(4), s, 'Units', 'normalized', 'FontName', st.font, ...
    'FontSize', st.fs, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end

function lab(ax, xl, yl)
if ~isempty(xl), xlabel(ax, xl); end
if ~isempty(yl), ylabel(ax, yl); end
end

function save_fig(f, figDir, name)
exportgraphics(f, fullfile(figDir, [name '.pdf']), 'ContentType', 'vector');
exportgraphics(f, fullfile(figDir, [name '.png']), 'Resolution', 300);
end

function l = leg(ax, h, names, st, loc, ncol)
if nargin < 5, loc = 'best'; end
if nargin < 6, ncol = 1; end
l = legend(ax, h, names, 'Location', loc, 'Box', 'off', 'FontName', st.font, ...
    'FontSize', st.fs, 'NumColumns', ncol);
l.ItemTokenSize = [16 8];
end

function y = cumint(t, x)
y = [0; cumsum(0.5 * diff(t) .* (x(1:end-1) + x(2:end)))];
end

function refline(ax, x, st)
plot(ax, x, [0.45 0.45], ':', 'Color', st.ref, 'LineWidth', 0.8, 'HandleVisibility', 'off');
end

% =====================================================================
function fig_baseline(resDir, figDir, st)
T = readtable(fullfile(resDir, 'baseline_traces.csv'));
W = readtable(fullfile(resDir, 'dopamine_sweep.csv'));
f = new_fig(st, 3.60);
w = 1.05; h = 0.92; x0 = [0.58 2.28 3.98]; yTop = 2.22; yBot = 0.45;
sig = {'C', 'GPi', 'TH'};
yl = {'Motor cortex (a.u.)', 'GPi (a.u.)', 'Thalamus (a.u.)'};
labs = 'abcdef';
for k = 1:3
    ax = new_ax(f, [x0(k) yTop w h], st);
    h1 = plot(ax, T.t, T.([sig{k} '_healthy']), '-', 'Color', st.col.healthy, 'LineWidth', st.lw);
    h2 = plot(ax, T.t, T.([sig{k} '_pd']), '--', 'Color', st.col.pd, 'LineWidth', st.lw);
    xlim(ax, [0 15]); set(ax, 'XTick', 0:5:15);
    lab(ax, 'Time (s)', yl{k}); label(ax, ['(' labs(k) ')'], st, -0.55, 0.14);
    if k == 1
        l = leg(ax, [h1 h2], {'Healthy, D = 1.00', 'Moderate PD, D = 0.35'}, st, 'north', 2);
        l.Units = 'inches'; l.Position = [1.10 3.38 3.00 0.18];
    end
end
ax = new_ax(f, [x0(1) yBot w h], st);
plot(ax, W.D, W.TH_mean, '-o', 'Color', st.col.healthy, 'LineWidth', st.lw, 'MarkerSize', 3, 'MarkerFaceColor', 'w');
xlim(ax, [0 1.05]); lab(ax, 'Dopamine level D', 'Thalamic late mean (a.u.)'); label(ax, '(d)', st, -0.55, 0.14);
ax = new_ax(f, [x0(2) yBot w h], st);
plot(ax, W.D, W.GPi_mean, '-o', 'Color', st.col.healthy, 'LineWidth', st.lw, 'MarkerSize', 3, 'MarkerFaceColor', 'w');
xlim(ax, [0 1.05]); lab(ax, 'Dopamine level D', 'GPi late mean (a.u.)'); label(ax, '(e)', st, -0.55, 0.14);
ax = new_ax(f, [x0(3) yBot w h], st);
h1 = plot(ax, W.D, W.GPi_beta, '-o', 'Color', st.col.healthy, 'LineWidth', st.lw, 'MarkerSize', 3, 'MarkerFaceColor', 'w');
h2 = plot(ax, W.D, W.TH_beta, '--s', 'Color', st.col.healthy, 'LineWidth', st.lw, 'MarkerSize', 3, 'MarkerFaceColor', 'w');
set(ax, 'YScale', 'log', 'YTick', 10.^(-11:2:-3)); xlim(ax, [0 1.05]); ylim(ax, [1e-11 1e-4]);
lab(ax, 'Dopamine level D', ['13' char(8211) '30 Hz power ((a.u.)' char(178) ')']); label(ax, '(f)', st, -0.55, 0.14);
leg(ax, [h1 h2], {'GPi', 'Thalamus'}, st, 'southwest');
save_fig(f, figDir, 'Fig2');
end

% =====================================================================
function fig_nominal(resDir, figDir, st)
T = readtable(fullfile(resDir, 'nominal_traces.csv'));
conds = {'no_dbs', 'open_loop', 'closed_loop', 'late_command', 'effort', 'performance'};
cols = {st.col.no, st.col.ol, st.col.cl, st.col.lc, st.col.em, st.col.pm};
sty = {'-', '-', '-', '--', '-.', ':'};
lws = [0.6 0.6 0.8 0.9 0.9 1.0];
names = {'No DBS', 'Open loop, u_{OL} = 0.12', 'Closed loop', 'Late-command-matched', ...
    'Effort-matched', 'Performance-matched'};
f = new_fig(st, 3.85);
pos = {[0.58 1.98 1.92 1.15], [3.10 1.98 1.92 1.15], [0.58 0.42 1.92 1.05], [3.10 0.42 1.92 1.05]};
ax = gobjects(1, 4);
for a = 1:4, ax(a) = new_ax(f, pos{a}, st); end
hh = gobjects(1, numel(conds));
t = T.t;
for c = 1:numel(conds)
    th = T.(['TH_' conds{c}]); u = T.(['u_' conds{c}]);
    hh(c) = plot(ax(1), t, movmean(th, 51), sty{c}, 'Color', cols{c}, 'LineWidth', lws(c));
    plot(ax(2), t, u, sty{c}, 'Color', cols{c}, 'LineWidth', lws(c));
    plot(ax(3), t, cumint(t, (th - 0.45).^2), sty{c}, 'Color', cols{c}, 'LineWidth', lws(c));
    plot(ax(4), t, cumint(t, u.^2), sty{c}, 'Color', cols{c}, 'LineWidth', lws(c));
end
refline(ax(1), [0 15], st);
ylim(ax(1), [0.30 0.50]); ylim(ax(2), [0 0.40]); ylim(ax(3), [0 0.12]); ylim(ax(4), [0 0.35]);
for a = 1:4, xlim(ax(a), [0 15]); set(ax(a), 'XTick', 0:3:15); end
lab(ax(1), 'Time (s)', 'Thalamus, 0.25-s mean (a.u.)');
lab(ax(2), 'Time (s)', 'Command u_{DBS} (a.u.)');
lab(ax(3), 'Time (s)', ['J_e(t) ((a.u.)' char(178) ' s)']);
lab(ax(4), 'Time (s)', ['J_u(t) ((a.u.)' char(178) ' s)']);
for a = 1:4, label(ax(a), ['(' char('a' + a - 1) ')'], st, -0.55, 0.08); end
l = leg(ax(1), hh, names, st, 'north', 3);
l.Units = 'inches'; l.Position = [0.40 3.42 4.70 0.32];
save_fig(f, figDir, 'Fig3');
end

% =====================================================================
function fig_efficiency(resDir, figDir, st)
C = readtable(fullfile(resDir, 'command_map.csv'));
H = readtable(fullfile(resDir, 'horizon_metrics.csv'), 'TextType', 'char');
G = readtable(fullfile(resDir, 'gains.csv'));
Ts = [15 60 120]; Dsel = [0.15 0.35 0.60];
f = new_fig(st, 4.40);
mk = {'s', 'o', '^'};
for k = 1:3
    ax = new_ax(f, [0.58 + (k-1)*1.60 2.25 1.22 1.45], st);
    hh = gobjects(1, 2*numel(Dsel));
    for i = 1:numel(Dsel)
        x = C(abs(C.D - Dsel(i)) < 1e-9 & C.T == Ts(k), :);
        hh(i) = plot(ax, x.Ju, x.Je, '-', 'Color', dcol(st, Dsel(i)), 'LineWidth', st.lw);
        g = G(abs(G.D - Dsel(i)) < 1e-9 & G.T == Ts(k), :);
        plot(ax, g.Ju, g.Je, mk{i}, 'Color', dcol(st, Dsel(i)), 'MarkerSize', 3, 'LineWidth', 0.5);
        hc = H(abs(H.D - Dsel(i)) < 1e-9 & H.T == Ts(k) & strcmp(H.condition, 'closed_loop'), :);
        hh(numel(Dsel) + i) = plot(ax, hc.Ju, hc.Je, mk{i}, 'Color', 'k', 'MarkerFaceColor', dcol(st, Dsel(i)), ...
            'MarkerSize', 4.5, 'LineWidth', 0.5);
    end
    set(ax, 'YScale', 'log');
    yl = ylim(ax); ylim(ax, [1e-3 max(yl(2), 0.3)]);
    xm = max(G.Ju(G.T == Ts(k))) * 1.10;
    xlim(ax, [-0.03*xm xm]);
    text(ax, 0.97, 0.97, sprintf('T = %d s', Ts(k)), 'Units', 'normalized', 'FontName', st.font, ...
        'FontSize', st.fs, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
    xlabel(ax, ['J_u(T) ((a.u.)' char(178) ' s)']);
    if k == 1
        ylabel(ax, ['J_e(T) ((a.u.)' char(178) ' s)']);
        names = [arrayfun(@(d) sprintf('Open loop, D = %.2f', d), Dsel, 'UniformOutput', false), ...
            arrayfun(@(d) sprintf('Closed loop, D = %.2f', d), Dsel, 'UniformOutput', false)];
        ord = [1 4 2 5 3 6];
        l = leg(ax, hh(ord), names(ord), st, 'north', 3);
        l.Units = 'inches'; l.Position = [0.45 3.97 4.65 0.36];
    end
    label(ax, ['(' char('a' + k - 1) ')'], st, -0.45, 0.12);
end
% (d), (e) ratios of the matched comparators to the closed loop, nominal gains
names = {'Ju', 'Je'}; conds = {'performance', 'effort'};
yl = {'J_u(u_{PM}) / J_u(closed loop)', 'J_e(u_{EM}) / J_e(closed loop)'};
tsty = {'-', '--', ':'}; tmk = {'o', 's', '^'};
for p = 1:2
    ax = new_ax(f, [0.55 + (p-1)*2.45 0.42 1.85 1.25], st);
    hh = gobjects(1, 3); rAll = 1;
    for k = 1:3
        r = zeros(1, numel(st.Ds));
        for i = 1:numel(st.Ds)
            sel = abs(H.D - st.Ds(i)) < 1e-9 & H.T == Ts(k);
            m = H(sel & strcmp(H.condition, conds{p}), :);
            c = H(sel & strcmp(H.condition, 'closed_loop'), :);
            r(i) = m.(names{p}) / c.(names{p});
        end
        hh(k) = plot(ax, st.Ds, r, tsty{k}, 'Marker', tmk{k}, 'Color', st.col.cl, 'LineWidth', st.lw, ...
            'MarkerSize', 3.5, 'MarkerFaceColor', 'w');
        rAll = [rAll r]; %#ok<AGROW>
    end
    pad = 0.08 * (max(rAll) - min(rAll));
    ylim(ax, [min(rAll) - pad, max(rAll) + pad]);
    plot(ax, [0.1 0.65], [1 1], ':', 'Color', st.ref, 'LineWidth', 0.8);
    xlim(ax, [0.1 0.65]); set(ax, 'XTick', 0.15:0.15:0.6);
    lab(ax, 'Dopamine level D', yl{p});
    label(ax, ['(' char('d' + p - 1) ')'], st, -0.50, 0.10);
    if p == 1, leg(ax, hh, {'T = 15 s', 'T = 60 s', 'T = 120 s'}, st, 'east'); end
end
save_fig(f, figDir, 'Fig4');
end

% =====================================================================
function fig_severity(resDir, figDir, st)
T = readtable(fullfile(resDir, 'horizon_traces.csv'));
H = readtable(fullfile(resDir, 'horizon_metrics.csv'), 'TextType', 'char');
C = readtable(fullfile(resDir, 'command_map.csv'));
H = H(H.T == 120, :); C = C(C.T == 120, :);
Ds = st.Ds;
f = new_fig(st, 4.0);
ax = new_ax(f, [0.58 2.35 3.90 1.35], st);
yEnd = zeros(1, numel(Ds));
for i = 1:numel(Ds)
    tag = sprintf('closed_loop_D%03d', round(100*Ds(i)));
    plot(ax, T.t, T.(['u_' tag]), '-', 'Color', st.ramp(i, :), 'LineWidth', st.lw);
    yEnd(i) = mean(T.(['u_' tag])(T.t >= 118));
end
[ys, order] = sort(yEnd);
for k = 2:numel(ys), ys(k) = max(ys(k), ys(k-1) + 0.032); end
for k = 1:numel(ys)
    i = order(k);
    text(ax, 121.5, ys(k), sprintf('D = %.2f', Ds(i)), 'FontName', st.font, ...
        'FontSize', st.fs, 'Color', st.ramp(i, :), 'VerticalAlignment', 'middle');
end
plot(ax, [0 120], [0.12 0.12], '--', 'Color', st.col.ol, 'LineWidth', st.lw);
text(ax, 121.5, 0.13, 'u_{OL} = 0.12', 'FontName', st.font, 'FontSize', st.fs, 'Color', st.col.ol, ...
    'VerticalAlignment', 'middle');
xlim(ax, [0 120]); ylim(ax, [0 0.4]); set(ax, 'XTick', 0:20:120);
lab(ax, 'Time (s)', 'Closed-loop u_{DBS} (a.u.)'); label(ax, '(a)', st, -0.50, 0.05);
ax = new_ax(f, [0.58 0.42 1.85 1.35], st);
conds = {'no_dbs', 'open_loop', 'closed_loop'};
cols = {st.col.no, st.col.ol, st.col.cl}; mk = {'s', '^', 'o'}; ls = {':', '--', '-'};
names = {'No DBS', 'Open loop, u_{OL} = 0.12', 'Closed loop'};
hh = gobjects(1, 3);
for c = 1:3
    x = H(strcmp(H.condition, conds{c}), :);
    hh(c) = plot(ax, x.D, x.TH_mean, ls{c}, 'Marker', mk{c}, 'Color', cols{c}, 'LineWidth', st.lw, ...
        'MarkerSize', 3.5, 'MarkerFaceColor', cols{c}, 'MarkerEdgeColor', 'w');
end
refline(ax, [0.1 0.65], st);
xlim(ax, [0.1 0.65]); ylim(ax, [0.22 0.48]); set(ax, 'XTick', 0.15:0.15:0.6);
lab(ax, 'Dopamine level D', 'Thalamic late mean (a.u.)'); label(ax, '(b)', st, -0.50, 0.05);
leg(ax, hh, names, st, 'southeast');
ax = new_ax(f, [3.05 0.42 1.95 1.35], st);
hm = gobjects(1, numel(Ds));
for i = 1:numel(Ds)
    x = C(abs(C.D - Ds(i)) < 1e-9, :);
    hm(i) = plot(ax, x.u, x.TH_mean, '-', 'Color', st.ramp(i, :), 'LineWidth', st.lw);
    hc = H(abs(H.D - Ds(i)) < 1e-9 & strcmp(H.condition, 'closed_loop'), :);
    plot(ax, hc.u_late, hc.TH_mean, 'o', 'Color', st.ramp(i, :), 'MarkerSize', 4, 'LineWidth', 0.7);
end
refline(ax, [0 0.6], st);
xlim(ax, [0 0.6]); ylim(ax, [0.22 0.58]); set(ax, 'XTick', 0:0.1:0.6);
lab(ax, 'Fixed command u (a.u.)', 'Thalamic late mean (a.u.)'); label(ax, '(c)', st, -0.50, 0.05);
leg(ax, hm, arrayfun(@(d) sprintf('D = %.2f', d), Ds, 'UniformOutput', false), st, 'southeast');
save_fig(f, figDir, 'Fig5');
end

% =====================================================================
function fig_step(resDir, figDir, st)
T = readtable(fullfile(resDir, 'dopamine_step_traces.csv'));
conds = {'no_dbs', 'open_loop', 'open_loop_tuned', 'open_loop_tuned_low', 'open_loop_best', ...
    'open_loop_best_after', 'closed_loop'};
cols = {st.col.no, st.col.ol, st.col.olt, st.col.oltl, st.col.olb, st.col.olba, st.col.cl};
sty = {':', '-', '--', '-.', '--', '-.', '-'};
names = {'No DBS', 'Open loop, u_{OL} = 0.12', 'Open loop, tuned at D = 0.50', ...
    'Open loop, tuned at D = 0.20', 'Open loop, best for schedule', 'Open loop, best after change', ...
    'Closed loop'};
Tend = T.t(end); Tseg = Tend / 3;
f = new_fig(st, 4.98);
axs = [new_ax(f, [0.60 2.88 4.38 1.05], st), new_ax(f, [0.60 1.66 4.38 0.92], st), ...
    new_ax(f, [0.60 0.42 4.38 0.95], st)];
ylims = {[0.30 0.545], [0 0.42], [2e-3 4]};
for a = 1:3
    patch(axs(a), [Tseg 2*Tseg 2*Tseg Tseg], ylims{a}([1 1 2 2]), [0.93 0.93 0.93], 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
end
hh = gobjects(1, numel(conds));
for c = 1:numel(conds)
    th = T.(['TH_' conds{c}]); u = T.(['u_' conds{c}]);
    hh(c) = plot(axs(1), T.t, movmean(th, 21), sty{c}, 'Color', cols{c}, 'LineWidth', st.lw);
    plot(axs(2), T.t, u, sty{c}, 'Color', cols{c}, 'LineWidth', st.lw);
    J = T.(['Je_' conds{c}]);
    plot(axs(3), T.t(2:end), J(2:end), sty{c}, 'Color', cols{c}, 'LineWidth', st.lw);
end
refline(axs(1), [0 Tend], st);
set(axs(3), 'YScale', 'log', 'YTick', 10.^(-2:0), 'YMinorTick', 'off');
for a = 1:3, ylim(axs(a), ylims{a}); xlim(axs(a), [0 Tend]); set(axs(a), 'XTick', 0:30:Tend, 'Layer', 'top'); end
set(axs(1), 'XTickLabel', []); set(axs(2), 'XTickLabel', []);
ylabel(axs(1), 'Thalamus (a.u.)'); ylabel(axs(2), 'u_{DBS} (a.u.)');
lab(axs(3), 'Time (s)', ['J_e(t) ((a.u.)' char(178) ' s)']);
for a = 1:3, label(axs(a), ['(' char('a' + a - 1) ')'], st, -0.52, 0.06); end
Dseq = [0.50 0.20 0.50];
for s = 1:3
    text(axs(1), (s - 0.5)*Tseg, 0.543, sprintf('D = %.2f', Dseq(s)), 'FontName', st.font, ...
        'FontSize', st.fs, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
end
l = leg(axs(1), hh, names, st, 'north', 3);
l.Units = 'inches'; l.Position = [0.35 4.07 4.75 0.46];
save_fig(f, figDir, 'Fig6');
end

% =====================================================================
function fig_gains(resDir, figDir, st)
G = readtable(fullfile(resDir, 'gains.csv'));
G = G(G.T == 120, :);
Ds = unique(G.D)'; Kps = unique(G.Kp)'; Kis = unique(G.Ki)';
f = new_fig(st, 4.10);
kcol = [0.60 0.75 0.90; 0.13 0.44 0.71; 0.03 0.19 0.42];
mk = {'s', 'o', '^'}; ls = {':', '-', '--'};
fields = {'t_settle', 'Ju', 'Je'};
ylabs = {'Settling time (s)', ['J_u(120) ((a.u.)' char(178) ' s)'], ['J_e(120) ((a.u.)' char(178) ' s)']};
for i = 1:numel(Ds)
    x0 = 0.62 + (i-1)*1.55;
    axs = [new_ax(f, [x0 2.78 1.18 0.95], st), new_ax(f, [x0 1.60 1.18 0.95], st), ...
        new_ax(f, [x0 0.42 1.18 0.95], st)];
    hh = gobjects(1, numel(Kps));
    for a = 1:numel(Kps)
        x = G(abs(G.D - Ds(i)) < 1e-9 & abs(G.Kp - Kps(a)) < 1e-9, :);
        for r = 1:3
            h = plot(axs(r), x.Ki, x.(fields{r}), ls{a}, 'Marker', mk{a}, 'Color', kcol(a, :), ...
                'LineWidth', st.lw, 'MarkerSize', 3.5, 'MarkerFaceColor', kcol(a, :), 'MarkerEdgeColor', 'w');
            if r == 1, hh(a) = h; end
        end
        miss = isnan(x.t_settle);
        plot(axs(1), x.Ki(miss) * 1.12^(a - 2), 118*ones(sum(miss), 1), 'x', 'Color', kcol(a, :), 'MarkerSize', 4, 'LineWidth', 0.7);
    end
    for ax = axs
        set(ax, 'XScale', 'log', 'XTick', Kis, 'XTickLabel', {'0.05', '0.15', '0.45', '1.35'}); xlim(ax, [0.04 1.7]);
    end
    set(axs(1), 'XTickLabel', []); set(axs(2), 'XTickLabel', []);
    set(axs(3), 'YScale', 'log', 'YTick', [0.003 0.01 0.03 0.1 0.3 1], ...
        'YTickLabel', {'0.003', '0.01', '0.03', '0.1', '0.3', '1'});
    yl3 = ylim(axs(3)); ylim(axs(3), [min(yl3(1), 0.003) max(1.3*yl3(2), 0.03)]);
    title(axs(1), sprintf('D = %.2f', Ds(i)), 'FontName', st.font, 'FontSize', st.fs, 'FontWeight', 'normal');
    xlabel(axs(3), 'K_i (1/s)');
    ylim(axs(1), [0 122]); yl = ylim(axs(2)); ylim(axs(2), [0 1.1*yl(2)]);
    if i == 1
        for r = 1:3, ylabel(axs(r), ylabs{r}); label(axs(r), ['(' char('a' + r - 1) ')'], st, -0.55, 0.02); end
    end
    if i == numel(Ds)
        leg(axs(1), hh, arrayfun(@(k) sprintf('K_p = %.1f', k), Kps, 'UniformOutput', false), st, 'northeast');
    end
end
save_fig(f, figDir, 'Fig7');
end

% =====================================================================
function strip(ax, x0, y, col, mk, jit)
plot(ax, x0 + jit, y, mk, 'Color', col, 'MarkerSize', 2.2, 'MarkerFaceColor', col, 'LineWidth', 0.4);
end

function fig_cohort(resDir, figDir, st)
Q = readtable(fullfile(resDir, 'cohort_stationary.csv'), 'TextType', 'char');
U = readtable(fullfile(resDir, 'cohort_subjects.csv'));
conds = {'no_dbs', 'open_loop', 'open_loop_tuned', 'open_loop_individual', 'closed_loop'};
cols = {st.col.no, st.col.ol, st.col.olt, st.col.oli, st.col.cl};
mks = {'o', '^', 's', 'd', 'o'};
ticks = {'No DBS', 'OL 0.12', 'OL nominal', 'OL individual', 'CL'};
n = height(U);
rng(1, 'twister'); jit = 0.30*(rand(n, 1) - 0.5);
f = new_fig(st, 4.30);
% (a) thalamic late mean
ax = new_ax(f, [0.58 2.62 2.05 1.40], st);
patch(ax, [0.4 5.6 5.6 0.4], [0.44 0.44 0.46 0.46], [0.90 0.90 0.90], 'EdgeColor', 'none');
for c = 1:5
    x = Q(strcmp(Q.condition, conds{c}), :);
    strip(ax, c, x.TH_mean, cols{c}, mks{c}, jit);
end
refline(ax, [0.4 5.6], st);
xlim(ax, [0.4 5.6]);
set(ax, 'XTick', 1:5, 'XTickLabel', ticks, 'TickLabelInterpreter', 'tex', 'XTickLabelRotation', 25, 'Layer', 'top');
ylabel(ax, 'Thalamic late mean (a.u.)'); label(ax, '(a)', st, -0.55, 0.05);
% (b) full-horizon error
ax = new_ax(f, [3.25 2.62 1.75 1.40], st);
for c = 3:5
    x = Q(strcmp(Q.condition, conds{c}), :);
    strip(ax, c - 2, x.Je, cols{c}, mks{c}, jit);
end
set(ax, 'YScale', 'log'); xlim(ax, [0.4 3.6]);
set(ax, 'XTick', 1:3, 'XTickLabel', ticks(3:5), 'TickLabelInterpreter', 'tex', 'XTickLabelRotation', 25);
ylabel(ax, ['J_e(120) ((a.u.)' char(178) ' s)']); label(ax, '(b)', st, -0.55, 0.05);
% (c) stimulation use
ax = new_ax(f, [0.58 0.55 2.05 1.30], st);
for c = 2:5
    x = Q(strcmp(Q.condition, conds{c}), :);
    strip(ax, c - 1, x.Ju, cols{c}, mks{c}, jit);
end
xlim(ax, [0.4 4.6]);
set(ax, 'XTick', 1:4, 'XTickLabel', ticks(2:5), 'TickLabelInterpreter', 'tex', 'XTickLabelRotation', 25);
ylabel(ax, ['J_u(120) ((a.u.)' char(178) ' s)']); label(ax, '(c)', st, -0.55, 0.05);
% (d) settled closed-loop command against the individually optimized command
ax = new_ax(f, [3.25 0.55 1.75 1.30], st);
x = Q(strcmp(Q.condition, 'closed_loop'), :);
att = U.attainable == 1;
plot(ax, [0 0.6], [0 0.6], ':', 'Color', st.ref, 'LineWidth', 0.8);
h1 = plot(ax, U.u_star(att), x.u_late(att), 'o', 'Color', st.col.cl, 'MarkerSize', 2.5, 'MarkerFaceColor', st.col.cl);
h2 = plot(ax, U.u_star(~att), x.u_late(~att), 'x', 'Color', st.col.ol, 'MarkerSize', 4, 'LineWidth', 0.7);
xlim(ax, [0 0.62]); ylim(ax, [0 0.62]); set(ax, 'XTick', 0:0.2:0.6, 'YTick', 0:0.2:0.6);
lab(ax, 'Individually optimized command (a.u.)', 'Closed-loop u_{late} (a.u.)'); label(ax, '(d)', st, -0.55, 0.05);
if any(~att)
    leg(ax, [h1 h2], {'Reference attainable', 'Not attainable'}, st, 'southeast');
end
save_fig(f, figDir, 'Fig8');
end

% =====================================================================
function fig_change(resDir, figDir, st)
Z = readtable(fullfile(resDir, 'cohort_change.csv'), 'TextType', 'char');
U = readtable(fullfile(resDir, 'cohort_subjects.csv'));
conds = {'open_loop_individual', 'open_loop_individual_low', 'open_loop_best', 'open_loop_best_after', 'closed_loop'};
cols = {st.col.oli, st.col.oltl, st.col.olb, st.col.olba, st.col.cl};
mks = {'d', 'v', 's', '^', 'o'};
ticks = {'OL\newlineu_i^*(D)', 'OL\newlineu_i^*(D_{low})', 'OL\newlineu_{i,best}', 'OL\newlineu_{i,post}', 'CL'};
nc = numel(conds);
n = height(U);
rng(2, 'twister'); jit = 0.30*(rand(n, 1) - 0.5);
seg = @(c, s) Z(strcmp(Z.condition, c) & Z.segment == s, :);
f = new_fig(st, 4.10);
% (a) error after the first change (90-270 s)
ax = new_ax(f, [0.58 2.40 1.95 1.40], st);
for c = 1:nc
    J = seg(conds{c}, 2).Je_segment + seg(conds{c}, 3).Je_segment;
    strip(ax, c, J, cols{c}, mks{c}, jit);
end
set(ax, 'YScale', 'log'); xlim(ax, [0.5 nc + 0.5]);
set(ax, 'XTick', 1:nc, 'XTickLabel', ticks, 'TickLabelInterpreter', 'tex', 'XTickLabelRotation', 0);
ylabel(ax, ['J_e over 90' char(8211) '270 s ((a.u.)' char(178) ' s)']); label(ax, '(a)', st, -0.55, 0.05);
% (b) closed loop against the best constant, per subject
ax = new_ax(f, [3.40 2.40 1.38 1.40], st);
Jb = seg('open_loop_best_after', 2).Je_segment + seg('open_loop_best_after', 3).Je_segment;
Jc = seg('closed_loop', 2).Je_segment + seg('closed_loop', 3).Je_segment;
scatter(ax, Jb, Jc, 6, U.dD, 'filled');
lims = [min([Jb; Jc]) max([Jb; Jc])] .* [0.8 1.25];
plot(ax, lims, lims, ':', 'Color', st.ref, 'LineWidth', 0.8);
set(ax, 'XScale', 'log', 'YScale', 'log'); xlim(ax, lims); ylim(ax, lims);
set(ax, 'XTick', [0.01 0.1], 'YTick', [0.01 0.1], 'XTickLabel', {'10^{-2}', '10^{-1}'}, ...
    'YTickLabel', {'10^{-2}', '10^{-1}'}, 'TickLabelInterpreter', 'tex', 'FontSize', st.fs);
cmap = interp1(linspace(0, 1, size(st.ramp, 1)), flipud(st.ramp), linspace(0, 1, 64));
colormap(ax, cmap); clim(ax, [0.10 0.30]);
cb = colorbar(ax, 'Units', 'inches', 'Position', [4.86 2.40 0.05 1.40], 'FontName', st.font, ...
    'FontSize', st.fs, 'TickDirection', 'out', 'Ticks', 0.1:0.1:0.3);
cb.Title.String = '\DeltaD'; cb.Title.FontName = st.font; cb.Title.FontSize = st.fs; cb.LineWidth = 0.5;
lab(ax, ['J_e, OL u_{i,post} ((a.u.)' char(178) ' s)'], ['J_e, CL ((a.u.)' char(178) ' s)']); label(ax, '(b)', st, -0.55, 0.05);
% (c) time off target after the first change
ax = new_ax(f, [0.58 0.45 1.95 1.30], st);
for c = 1:nc
    t = (seg(conds{c}, 2).time_off + seg(conds{c}, 3).time_off) / 2;
    strip(ax, c, 100*t, cols{c}, mks{c}, jit);
end
xlim(ax, [0.5 nc + 0.5]); ylim(ax, [0 105]);
set(ax, 'XTick', 1:nc, 'XTickLabel', ticks, 'TickLabelInterpreter', 'tex', 'XTickLabelRotation', 0);
ylabel(ax, ['Time off target, 90' char(8211) '270 s (%)']); label(ax, '(c)', st, -0.55, 0.05);
% (d) stimulation use over 270 s
ax = new_ax(f, [3.08 0.45 2.02 1.30], st);
for c = 1:nc
    J = seg(conds{c}, 1).Ju_segment + seg(conds{c}, 2).Ju_segment + seg(conds{c}, 3).Ju_segment;
    strip(ax, c, J, cols{c}, mks{c}, jit);
end
xlim(ax, [0.5 nc + 0.5]);
set(ax, 'XTick', 1:nc, 'XTickLabel', ticks, 'TickLabelInterpreter', 'tex', 'XTickLabelRotation', 0);
ylabel(ax, ['J_u(270) ((a.u.)' char(178) ' s)']); label(ax, '(d)', st, -0.55, 0.05);
save_fig(f, figDir, 'Fig9');
end

% =====================================================================
function fig_limits(resDir, figDir, st)
A = readtable(fullfile(resDir, 'limits_attain.csv'), 'TextType', 'char');
O = readtable(fullfile(resDir, 'limits_sensor.csv'), 'TextType', 'char');
f = new_fig(st, 3.75);
% (a) closed-loop late mean against the open loop at u_max, by reference
ax = new_ax(f, [0.58 2.15 1.85 1.35], st);
cl = A(strcmp(A.condition, 'closed_loop'), :);
ol = A(strcmp(A.condition, 'open_loop_umax'), :);
refs = unique(cl.TH_ref)'; rmk = {'v', 'o', '^'};
rcol = [0.42 0.68 0.84; 0.13 0.44 0.71; 0.03 0.19 0.42];
hh = gobjects(1, numel(refs));
for q = 1:numel(refs)
    x = cl(abs(cl.TH_ref - refs(q)) < 1e-9, :);
    thMax = zeros(height(x), 1);
    for k = 1:height(x)
        o = ol(abs(ol.D - x.D(k)) < 1e-9 & abs(ol.G_DBS - x.G_DBS(k)) < 1e-9 & abs(ol.u_max - x.u_max(k)) < 1e-9, :);
        thMax(k) = o.TH_mean;
    end
    sat = x.sat_late >= 0.5;
    hh(q) = plot(ax, thMax(~sat) - refs(q), x.TH_mean(~sat) - refs(q), rmk{q}, 'Color', rcol(q, :), ...
        'MarkerSize', 3.5, 'MarkerFaceColor', rcol(q, :), 'MarkerEdgeColor', 'w');
    plot(ax, thMax(sat) - refs(q), x.TH_mean(sat) - refs(q), rmk{q}, 'Color', rcol(q, :), ...
        'MarkerSize', 3.5, 'MarkerFaceColor', 'w', 'LineWidth', 0.6);
end
plot(ax, [-0.25 0.2], [-0.25 0.2], ':', 'Color', st.ref, 'LineWidth', 0.8);
plot(ax, [-0.25 0.2], [0 0], '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
xlim(ax, [-0.25 0.2]); ylim(ax, [-0.25 0.1]);
lab(ax, ['Open loop at u_{max} ' char(8722) ' TH_{ref} (a.u.)'], ['Closed loop ' char(8722) ' TH_{ref} (a.u.)']);
label(ax, '(a)', st, -0.55, 0.05);
leg(ax, hh, arrayfun(@(r) sprintf('TH_{ref} = %.2f', r), refs, 'UniformOutput', false), st, 'southeast');
% (b) observation bias, (c) observation noise, (d) observation delay
gk = {[0.8 0.15], [1.6 1.35]}; gname = {'Nominal gains', 'Fast gains'};
gcol = {st.col.cl, st.col.lc}; gls = {'-', '--'}; gmk = {'o', 's'};
specs = {'bias', 'TH_mean', 'Observation bias b_y (a.u.)', 'Thalamic late mean (a.u.)', [3.10 2.15 1.85 1.35]; ...
    'noise', 'Ju', 'Observation noise \sigma_y (a.u.)', ['J_u(120) ((a.u.)' char(178) ' s)'], [0.58 0.42 1.85 1.25]; ...
    'delay', 'Je', 'Observation delay d_y (s)', ['J_e(120) ((a.u.)' char(178) ' s)'], [3.10 0.42 1.85 1.25]};
for p = 1:3
    ax = new_ax(f, specs{p, 5}, st);
    hh = gobjects(1, 2);
    for a = 1:2
        x = O(strcmp(O.factor, specs{p, 1}) & abs(O.Kp - gk{a}(1)) < 1e-9 & abs(O.Ki - gk{a}(2)) < 1e-9, :);
        hh(a) = plot(ax, x.value, x.(specs{p, 2}), gls{a}, 'Marker', gmk{a}, 'Color', gcol{a}, ...
            'LineWidth', st.lw, 'MarkerSize', 3.5, 'MarkerFaceColor', 'w');
    end
    if p == 1
        plot(ax, [-0.02 0.02], 0.45 - [-0.02 0.02], ':', 'Color', st.ref, 'LineWidth', 0.8);
        leg(ax, hh, gname, st, 'northeast');
    end
    if p == 3, set(ax, 'YScale', 'log'); end
    xv = O.value(strcmp(O.factor, specs{p, 1})); dx = 0.04 * (max(xv) - min(xv));
    xlim(ax, [min(xv) - dx, max(xv) + dx]);
    yl = ylim(ax);
    if p == 3, ylim(ax, yl .* [0.85 1.15]); else, ylim(ax, yl + [-1 1] * 0.03 * diff(yl)); end
    lab(ax, specs{p, 3}, specs{p, 4});
    label(ax, ['(' char('a' + p) ')'], st, -0.55, 0.05);
end
save_fig(f, figDir, 'Fig10');
end
