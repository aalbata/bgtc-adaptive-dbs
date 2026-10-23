function [X, names, lo, hi] = cohort_design(N, seed)
%COHORT_DESIGN Latin hypercube sample of the virtual-cohort parameters.
%   [X, NAMES, LO, HI] = COHORT_DESIGN(N, SEED) returns an N-by-20 matrix
%   X whose columns are uniform Latin hypercube samples of the parameters
%   NAMES on the intervals [LO, HI]. For each column in turn, a random
%   permutation and N uniform offsets are drawn from a Mersenne Twister
%   generator initialized once with SEED, so that every interval
%   [(k-1)/N, k/N) of every parameter contains exactly one subject.
%     D            dopamine level of the stationary state
%     g            multiplier of the GPe-STN, STN-GPe and STN-GPi gains
%     a_n          multiplier of both disturbance standard deviations
%     tau_*        multipliers of the seven population time constants
%     d_*          multipliers of the six transmission delays
%     G_DBS        effective stimulation gain
%     sensor_delay observation delay of the thalamic output (s)
%     sensor_noise observation-noise standard deviation (a.u.)
%     dD           dopamine decrease during the second segment of the
%                  state-change protocol

names = {'D', 'g', 'a_n', 'tau_C', 'tau_D1', 'tau_D2', 'tau_GPe', 'tau_STN', 'tau_GPi', ...
    'tau_TH', 'd_TC', 'd_CSTN', 'd_GPeSTN', 'd_STNGPe', 'd_STNGPi', 'd_GPiTH', ...
    'G_DBS', 'sensor_delay', 'sensor_noise', 'dD'};
lo = [0.15 0.70 0.30 0.70*ones(1, 7) 0.50*ones(1, 6) 0.50 0.00 0.00 0.10];
hi = [0.60 1.30 1.80 1.30*ones(1, 7) 1.50*ones(1, 6) 1.50 0.50 0.03 0.30];
rng(seed, 'twister');
d = numel(names);
U = zeros(N, d);
for j = 1:d
    p = randperm(N)';
    U(:, j) = (p - 1 + rand(N, 1)) / N;
end
X = lo + U .* (hi - lo);
end
