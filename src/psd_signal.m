function [tu, xu, fs] = psd_signal(t, x, P, tEnd)
%PSD_SIGNAL Post-transient, uniformly resampled, mean-centered signal.
%   [TU, XU, FS] = PSD_SIGNAL(T, X, P) discards samples before
%   P.psdStartTime, resamples the remainder at P.psdFs by piecewise cubic
%   Hermite interpolation and removes the mean. PSD_SIGNAL(T, X, P, TEND)
%   also discards samples after TEND.

t = t(:); x = x(:);
if numel(t) ~= numel(x), error('t and x must have equal length.'); end
if nargin < 4 || isempty(tEnd), tEnd = Inf; end
keep = isfinite(t) & isfinite(x) & (t >= P.psdStartTime) & (t <= tEnd + 1e-12);
t = t(keep); x = x(keep);
if numel(t) < 10, error('Insufficient post-transient samples.'); end
[t, ia] = unique(t, 'stable'); x = x(ia);
fs = P.psdFs;
tu = (t(1):1/fs:t(end))';
if numel(tu) < 128, error('Post-transient segment is too short.'); end
xu = interp1(t, x, tu, 'pchip');
xu = xu - mean(xu, 'omitnan');
end
