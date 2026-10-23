function [u, Je] = perf_match(P, target, T, uLo, uHi, tol)
%PERF_MATCH Constant command whose full-horizon tracking error equals a target.
%   [U, JE] = PERF_MATCH(P, TARGET, T, ULO, UHI) finds by bisection the
%   constant command U in [ULO, UHI] at which the open-loop error
%   Je(T) = int_0^T (TH - TH_ref)^2 dt equals TARGET, given that Je - TARGET
%   changes sign between ULO and UHI. Je decreases with the command below
%   the command that minimizes it, so with UHI at or below that command the
%   result is the smallest constant command that reaches the target error.
%   Bisection stops when the bracket is narrower than TOL (default 1e-5).
%   JE is the error of the returned command; U and JE are NaN when the
%   bracket does not contain a sign change.

if nargin < 6, tol = 1e-5; end
fLo = je_fixed(P, uLo, T) - target;
fHi = je_fixed(P, uHi, T) - target;
if sign(fLo) == sign(fHi)
    u = NaN; Je = NaN; return;
end
while uHi - uLo > tol
    um = 0.5 * (uLo + uHi);
    fm = je_fixed(P, um, T) - target;
    if sign(fm) == sign(fLo), uLo = um; fLo = fm; else, uHi = um; end
end
u = 0.5 * (uLo + uHi);
Je = je_fixed(P, u, T);
end

function J = je_fixed(P, u, T)
M = run_fixed(P, u, T);
J = M.Je;
end
