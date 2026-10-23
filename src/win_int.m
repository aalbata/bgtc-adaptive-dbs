function I = win_int(t, x, a, b)
%WIN_INT Time integral of a recorded signal over the window [a, b].
%   I = WIN_INT(T, X, A, B) integrates X(T) over [A, B] by the trapezoidal
%   rule on the recorded time points, with the values at A and B obtained by
%   linear interpolation. Repeated time stamps keep their last value. The
%   result does not depend on how densely the solver sampled the window.

t = t(:); x = x(:);
[tu, iu] = unique(t, 'last');
xu = x(iu);
if a < tu(1) - 1e-12 || b > tu(end) + 1e-12
    error('Window [%g, %g] lies outside the recorded interval.', a, b);
end
a = max(a, tu(1)); b = min(b, tu(end));
if b <= a, I = 0; return; end
k = tu > a & tu < b;
tt = [a; tu(k); b];
xw = [interp1(tu, xu, a); xu(k); interp1(tu, xu, b)];
I = trapz(tt, xw);
end
