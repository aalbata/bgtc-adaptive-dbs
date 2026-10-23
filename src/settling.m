function [tSettle, peak, thf, tf] = settling(t, TH, ref, tol, t0, t1, tPeak)
%SETTLING Settling time and peak of the 1-s moving mean of the thalamic output.
%   [TS, PEAK] = SETTLING(T, TH, REF, TOL, T0, T1, TPEAK) interpolates TH
%   onto a 0.01-s grid over (T0, T1] (closed at T0 when T0 = 0), takes the
%   centered 101-point (1-s) moving mean within that interval, and returns
%   the first time after T0 from which the moving mean stays within TOL of
%   REF until T1 (0 if it never leaves the band, NaN if it is outside the
%   band at T1), measured from T0. PEAK is the largest value of the moving
%   mean at times T >= T0 + TPEAK. The grid and the moving mean are also
%   returned.

if nargin < 7, tPeak = 0; end
tf = (0:round(t1/0.01))' * 0.01;
if t0 > 0, tf = tf(tf > t0 + 1e-9); else, tf = tf(tf >= 0); end
thf = movmean(on_grid(t, TH, tf), 101);
outBand = abs(thf - ref) >= tol;
if ~outBand(end)
    k = find(outBand, 1, 'last');
    if isempty(k), tSettle = 0; else, tSettle = tf(k + 1) - t0; end
else
    tSettle = NaN;
end
sel = tf >= t0 + tPeak - 1e-9;
peak = max(thf(sel));
end
