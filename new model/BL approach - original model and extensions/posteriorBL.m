function [ mu_BL_full_conf  Sig_BL_full_conf] = posteriorBL( pi_market, covm, v, P)
%   posteriorBL - calculate the posterior distributions /
%   covariance 
%   ref: Meucci, "The Black-Litterman Approach, original model and
%   extensions", Aug-2008

% inputs:

% outputs:

% equations (19) & (20)

A = tau * covm;
% B = P'* (Ohm\P);
% 
% C = P'* (Ohm\v);

E = covm*P';
D = P*E;


mu_BL = pi_market+A*P'*((tau*D+Ohm)\(v-P*pi_market)); % check --> implementatie (15) / (19) agree
Sig_BL = (1+tau)*covm-((tau*tau)*covm*P'/(tau*D+Ohm))*P*covm;  % check --> implementatie (18) / (20) agree


end

