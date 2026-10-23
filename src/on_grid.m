function y = on_grid(t, x, tg, method)
%ON_GRID Interpolate a recorded signal onto a uniform time grid.
%   Y = ON_GRID(T, X, TG) interpolates X(T) linearly at the times TG.
%   ON_GRID(T, X, TG, 'previous') holds the last recorded value instead.

if nargin < 4, method = 'linear'; end
[tu, iu] = unique(t(:), 'last');
y = interp1(tu, x(iu), tg(:), method, 'extrap');
end
