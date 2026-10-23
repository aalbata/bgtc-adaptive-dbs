function reproduce(mode)
%REPRODUCE Regenerate the results, summary values and figures of the article.
%   reproduce          redraws the figures and recomputes results/summary.csv
%                      from the result files shipped in results/
%   reproduce('full')  first reruns every simulation, overwriting the files in
%                      results/ (about 16 h in one MATLAB process on an Intel
%                      Core Ultra 7 155U laptop, most of it in the 200-subject
%                      virtual cohort; see README.md for running the cohort in
%                      parallel MATLAB processes)
%
%   Requires MATLAB and Simulink (developed with R2026b). No other toolbox
%   is used.

if nargin < 1, mode = 'fast'; end
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
resDir = fullfile(root, 'results');
figDir = fullfile(root, 'figures');

switch lower(mode)
    case 'full'
        t0 = tic;
        run_all_simulations(resDir);
        fprintf('Simulations finished in %.1f min\n', toc(t0)/60);
    case 'fast'
    otherwise
        error('Unknown mode "%s"; use ''fast'' or ''full''.', mode);
end

summarize_results(resDir);
make_figures(resDir, figDir);

S = readtable(fullfile(resDir, 'summary.csv'), 'TextType', 'char');
v = @(k) S.value(strcmp(S.key, k));
fprintf('\nKey results\n');
fprintf('  15 s, D = 0.35: Je closed loop %.4f, effort-matched open loop %.4f (equal Ju)\n', ...
    v('nom_cl_Je'), v('nom_em_Je'));
fprintf('  five dopamine levels x three horizons: effort-matched Je below closed loop in %d of %d\n', ...
    v('hz_em_le_cl_Je'), v('hz_n'));
fprintf('  120 s: settled closed-loop command within %.4f of the fixed command u*\n', v('map_absdiff_max'));
fprintf('  cohort, fixed state: individually optimized constant has lower Je in %d of %d subjects\n', ...
    v('coh_oi_lt_cl_Je'), v('coh_n'));
fprintf('  cohort, state change: closed loop has lower Je over 90-270 s than the best constant after the change in %d of %d subjects\n', ...
    v('chg_cl_lt_oba'), v('coh_n'));
fprintf('  cohort, state change: closed loop has lower Je over 0-270 s than the best constant for the schedule in %d of %d subjects\n', ...
    v('chg_cl_lt_ob_total'), v('coh_n'));
fprintf('Figures written to %s\n', figDir);
end
