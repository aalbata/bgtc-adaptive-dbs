function [names, values] = metric_fields(M)
%METRIC_FIELDS Names and values of the outcome measures written to result files.
%   NAMES = METRIC_FIELDS() returns the column names in a fixed order.
%   [NAMES, VALUES] = METRIC_FIELDS(M) also returns the corresponding
%   values of the structure M from SIGNAL_METRICS as a row vector.

names = {'TH_mean', 'GPi_mean', 'TH_RMSE', 'u_late', 'Je', 'Je_start', 'Je_late', ...
    'Ju', 'Ju_start', 'Ju_late', 'U1', 'u_end', 'u_sd_late', 'sat_late', 't_settle', ...
    'TH_smooth_max', 'Ju_settle', 'TH_peak', 'TH_beta', 'GPi_beta', 'on_target', ...
    'TH_mean_s', 'GPi_mean_s', 'TH_RMSE_s', 'u_late_s', ...
    'TH_mean_g', 'GPi_mean_g', 'TH_RMSE_g', 'u_late_g'};
if nargin > 0
    values = cellfun(@(f) M.(f), names);
else
    values = [];
end
end
