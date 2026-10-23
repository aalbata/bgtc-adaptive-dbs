function run_all_simulations(resDir, steps)
%RUN_ALL_SIMULATIONS Build the models and run every experiment of the article.
%   RUN_ALL_SIMULATIONS(RESDIR) writes all result files to RESDIR.
%   RUN_ALL_SIMULATIONS(RESDIR, STEPS) runs only the listed steps (indices
%   into the list below); later steps read files written by earlier ones.

if ~exist(resDir, 'dir'), mkdir(resDir); end
buildDir = fullfile(tempdir, 'bgtc_models');
build_models(buildDir);
list = {
    'E1 baselines (D = 1.00 and 0.35)',               @() exp_baseline(resDir)
    'E1 dopamine sweep',                               @() exp_dopamine_sweep(resDir)
    'E2 nominal comparison and matched open loops',    @() exp_nominal(resDir)
    'E3 independent noise sequences',                  @() exp_noise_seeds(resDir)
    'E5 fixed-command map',                            @() exp_command_map(resDir)
    'E4 five dopamine levels, 15/60/120 s',            @() exp_horizon(resDir)
    'E6 dopamine changes within a run',                @() exp_dopamine_step(resDir)
    'E7 controller gain grid',                         @() exp_gains(resDir)
    'E9 attainability and observation errors',         @() exp_limits(resDir)
    'solver settings',                                 @() exp_numerics(resDir)
    'E8 virtual cohort, 200 subjects',                 @() exp_cohort(resDir)};
if nargin < 2 || isempty(steps), steps = 1:size(list, 1); end
for k = steps
    fprintf('[%d/%d] %s\n', k, size(list, 1), list{k, 1});
    tic; list{k, 2}(); fprintf('      %.0f s\n', toc);
end
bdclose('all');
end
