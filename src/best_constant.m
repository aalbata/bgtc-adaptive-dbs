function [u, F] = best_constant(uGrid, H, w, ref, uMax)
%BEST_CONSTANT Constant command that minimizes the weighted static error.
%   [U, F] = BEST_CONSTANT(UGRID, H, W, REF, UMAX) interpolates the static
%   thalamic responses H(:, s) to the commands UGRID in each state s by
%   piecewise cubic Hermite interpolation and returns the command U in
%   [0, UMAX] that minimizes F(U) = sum_s W(s) (H_s(U) - REF)^2 on a grid of
%   step 1e-5. W are the fractions of time spent in each state.

uGrid = uGrid(:);
uf = (0:round(uMax / 1e-5))' * 1e-5;
F = zeros(size(uf));
for s = 1:size(H, 2)
    F = F + w(s) * (interp1(uGrid, H(:, s), uf, 'pchip') - ref).^2;
end
[F, k] = min(F);
u = uf(k);
end
