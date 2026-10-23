function [betaPower, totalPower, f, Pxx] = beta_power(x, fs, band)
%BETA_POWER Welch PSD and power integrated over a frequency band.
%   [BP, TP, F, PXX] = BETA_POWER(X, FS, BAND) estimates the one-sided PSD
%   of X with Hamming windows of about 2 s, 50% overlap and an FFT length
%   of at least 512 points, and integrates it by the trapezoidal rule over
%   BAND (default [13 30] Hz) and over all frequencies.

if nargin < 3 || isempty(band), band = [13 30]; end
x = x(:);
x = x(isfinite(x));
x = x - mean(x);
N = numel(x);
if N < 64, error('Signal is too short for a Welch PSD.'); end

L = min(N, max(64, round(2*fs)));
if L == N && N > 128, L = floor(N/2); end
step = max(1, floor(L/2));
nfft = max(512, 2^nextpow2(L));
w = 0.54 - 0.46*cos(2*pi*(0:L-1)'/(L-1));
U = sum(w.^2);
starts = 1:step:(N-L+1);
acc = zeros(nfft/2+1, 1);
for k = 1:numel(starts)
    X = fft(x(starts(k):starts(k)+L-1) .* w, nfft);
    S = (abs(X).^2) / (fs*U);
    S = S(1:nfft/2+1);
    if numel(S) > 2, S(2:end-1) = 2*S(2:end-1); end
    acc = acc + S;
end
Pxx = acc / max(1, numel(starts));
f = (0:nfft/2)' * fs / nfft;
inBand = f >= band(1) & f <= band(2);
betaPower = trapz(f(inBand), Pxx(inBand));
totalPower = trapz(f, Pxx);
end
