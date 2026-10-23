function P = apply_dopamine(P, D)
%APPLY_DOPAMINE Set the dopamine level and the gains that depend on it.
%   P = APPLY_DOPAMINE(P, D) clips D to [0, 1], stores it in P.D, and sets
%   the reciprocal GPe-STN, STN-GPi and GPi-thalamus gains and the amplitude
%   of the prescribed beta input from the severity s = 1 - D.

D = min(max(D, 0), 1);
P.D = D;
sev = 1 - D;

P.w_GPeSTN = P.w_GPeSTN_base * (1 + P.betaCouplingGain*sev);
P.w_STNGPe = P.w_STNGPe_base * (1 + P.betaCouplingGain*sev);
P.w_STNGPi = P.w_STNGPi_base * (1 + P.stnGpiDiseaseGain*sev);
P.w_GPiTH  = P.w_GPiTH_base  * (1 + P.gpiThDiseaseGain*sev);

P.betaDriveAmp = P.betaDriveHealthy + ...
    P.betaDriveDiseaseGain * sev.^P.betaDriveExponent;
end
