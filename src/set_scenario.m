function P = set_scenario(name, D)
%SET_SCENARIO Parameter set for a named simulation condition.
%   P = SET_SCENARIO(NAME) returns the parameters for one of
%     'healthy', 'mild_pd', 'moderate_pd', 'severe_pd'  (baseline model)
%     'no_dbs', 'open_loop', 'closed_loop'               (DBS model)
%   The DBS conditions use D = 0.35 unless a second argument D is given.

P = bgtc_params();
if nargin < 2, D = 0.35; end

switch lower(strtrim(name))
    case 'healthy'
        P = apply_dopamine(P, 1.00);
    case 'mild_pd'
        P = apply_dopamine(P, 0.60);
    case 'moderate_pd'
        P = apply_dopamine(P, 0.35);
    case 'severe_pd'
        P = apply_dopamine(P, 0.15);
    case 'no_dbs'
        P = apply_dopamine(P, D);
        P.DBS_mode = 0; P.DBS_open_effective = 0;
        P.Kp = 0; P.Ki = 0; P.Kd = 0;
    case 'open_loop'
        P = apply_dopamine(P, D);
        P.DBS_mode = 0;
    case 'closed_loop'
        P = apply_dopamine(P, D);
        P.DBS_mode = 1;
    otherwise
        error('Unknown scenario: %s', name);
end
end
