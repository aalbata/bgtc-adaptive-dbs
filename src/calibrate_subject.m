function C = calibrate_subject(x, i, Ds, uGrid, Tcal)
%CALIBRATE_SUBJECT Individually optimized constant commands of one subject.
%   C = CALIBRATE_SUBJECT(X, I, DS, UGRID, TCAL) runs open-loop simulations
%   of length TCAL with the calibration noise seeds of subject I
%   (SUBJECT_PARAMS) at each dopamine level DS(s) and each command in UGRID,
%   and records the late-window thalamic mean h_s(u). The individually
%   optimized command u*_s is the command at which h_s(u) = TH_ref: 0 if
%   h_s(0) >= TH_ref, P.DBS_max if h_s(P.DBS_max) < TH_ref (reference not
%   attainable), and otherwise the root bracketed by UGRID refined by the
%   Illinois variant of regula falsi until |h_s(u) - TH_ref| < 1e-4 (at
%   most 10 steps). The best constant for a schedule that spends the
%   fractions 2/3 and 1/3 of the time at DS(1) and DS(2), C.u_best,
%   minimizes (2/3)(h_1(u) - TH_ref)^2 + (1/3)(h_2(u) - TH_ref)^2 over
%   [0, P.DBS_max]; the best constant after the change, C.u_best_after,
%   minimizes the same error with the weights 1/2 and 1/2 of a window that
%   spends equal times in the two states. Each h_s is interpolated by
%   piecewise cubic Hermite interpolation through all calibration runs at
%   that level.

P0 = set_scenario('open_loop');
ref = P0.TH_ref; uMax = P0.DBS_max;
C.u_star = zeros(1, numel(Ds)); C.h0 = zeros(1, numel(Ds)); C.hmax = zeros(1, numel(Ds));
C.attainable = zeros(1, numel(Ds)); C.n_runs = 0;
us = cell(1, numel(Ds)); hs = cell(1, numel(Ds));
for s = 1:numel(Ds)
    P = subject_params(set_scenario('open_loop', Ds(s)), x, Ds(s), i, true);
    u = uGrid(:); h = zeros(size(u));
    for k = 1:numel(u)
        h(k) = calib_run(P, u(k), Tcal);
    end
    C.n_runs = C.n_runs + numel(u);
    C.h0(s) = h(1); C.hmax(s) = h(end);
    if h(1) >= ref
        C.u_star(s) = 0; C.attainable(s) = 1;
    elseif h(end) < ref
        C.u_star(s) = uMax; C.attainable(s) = 0;
    else
        C.attainable(s) = 1;
        k = find(h(1:end-1) < ref & h(2:end) >= ref, 1);
        a = u(k); fa = h(k) - ref; b = u(k+1); fb = h(k+1) - ref;
        side = 0; c = a; fc = fa;
        for it = 1:10
            c = (a*fb - b*fa) / (fb - fa);
            hc = calib_run(P, c, Tcal); fc = hc - ref;
            C.n_runs = C.n_runs + 1;
            u(end+1) = c; h(end+1) = hc; %#ok<AGROW>
            if abs(fc) < 1e-4, break; end
            if sign(fc) == sign(fb)
                b = c; fb = fc;
                if side == 1, fa = fa / 2; end
                side = 1;
            else
                a = c; fa = fc;
                if side == -1, fb = fb / 2; end
                side = -1;
            end
        end
        C.u_star(s) = c;
    end
    [us{s}, ord] = unique(u); hs{s} = h(ord);
end
uf = (0:round(uMax / 1e-5))' * 1e-5;
e1 = (interp1(us{1}, hs{1}, uf, 'pchip') - ref).^2;
e2 = (interp1(us{2}, hs{2}, uf, 'pchip') - ref).^2;
[~, k] = min((2/3) * e1 + (1/3) * e2);
C.u_best = uf(k);
[~, k] = min((1/2) * e1 + (1/2) * e2);
C.u_best_after = uf(k);
end

function h = calib_run(P, u, T)
M = run_fixed(P, u, T);
h = M.TH_mean;
end
