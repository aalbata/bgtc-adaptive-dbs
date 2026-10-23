function [u, Je, JeMin] = perf_match_grid(P, target, T, uGrid, JeGrid)
%PERF_MATCH_GRID Smallest constant command that reaches a full-horizon error.
%   [U, JE, JEMIN] = PERF_MATCH_GRID(P, TARGET, T, UGRID, JEGRID) uses the
%   open-loop errors JEGRID = Je(T) at the increasing commands UGRID (simulated
%   here when JEGRID is empty) to bracket the smallest command whose error
%   is at most TARGET below the grid command that minimizes Je, and refines
%   it with PERF_MATCH. U = 0 if no stimulation already meets the target;
%   U = NaN if no grid command reaches it. JEMIN is the smallest grid error.

uGrid = uGrid(:);
if nargin < 5 || isempty(JeGrid)
    JeGrid = zeros(size(uGrid));
    for k = 1:numel(uGrid)
        M = run_fixed(P, uGrid(k), T);
        JeGrid(k) = M.Je;
    end
end
JeGrid = JeGrid(:);
[JeMin, m] = min(JeGrid);
k = find(JeGrid(1:m) <= target, 1);
if isempty(k)
    u = NaN; Je = NaN;
elseif k == 1
    u = uGrid(1); Je = JeGrid(1);
else
    [u, Je] = perf_match(P, target, T, uGrid(k-1), uGrid(k));
end
end
