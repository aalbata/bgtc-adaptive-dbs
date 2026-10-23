function R = segment_metrics(S, P, t0, t1)
%SEGMENT_METRICS Outcome measures of the segment [t0, t1] of a scheduled run.
%   R = SEGMENT_METRICS(S, P, T0, T1) returns
%     TH_last10, u_last10   time-weighted means over the last 10 s of the segment
%     TH_RMSE_last10        RMS deviation of TH from TH_ref over the last 10 s
%     Ju_segment, Je_segment  int u^2 dt and int (TH - TH_ref)^2 dt over [t0, t1]
%     t_settle              settling time from t0 (SETTLING, NaN if never)
%     TH_smooth_max, TH_smooth_min  extremes of the 1-s moving mean of TH
%     time_off              fraction of the segment with the 1-s moving mean
%                           at least P.onTargetTol away from TH_ref

ref = P.TH_ref;
R.TH_last10 = win_int(S.t, S.TH, t1 - 10, t1) / 10;
R.u_last10 = win_int(S.t, S.u, t1 - 10, t1) / 10;
R.TH_RMSE_last10 = sqrt(win_int(S.t, (S.TH - ref).^2, t1 - 10, t1) / 10);
R.Ju_segment = win_int(S.t, S.u.^2, t0, t1);
R.Je_segment = win_int(S.t, (S.TH - ref).^2, t0, t1);
[R.t_settle, R.TH_smooth_max, thf] = settling(S.t, S.TH, ref, P.onTargetTol, t0, t1);
R.TH_smooth_min = min(thf);
R.time_off = mean(abs(thf - ref) >= P.onTargetTol);
end
