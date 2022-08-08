function [ mu_BL_full_conf  Sig_BL_full_conf] = posteriorBL_fullconfidence( pi_market, covm, v, P)
%   posteriorBL_fullconfidence - calculate the posterior distributions /
%   covariance based on full confidence in the views
%   ref: Meucci, "The Black-Litterman Approach, original model and
%   extensions", Aug-2008

% inputs:

% outputs:

% equations (27) & (28)

% A = tau * covm;
% B = P'* (Ohm\P);
% 
% C = P'* (Ohm\v);

E = covm*P';
D = P*E;

mu_BL_full_conf = pi_market + E/D*(v-P*pi_market);
Sig_BL_full_conf = (1+tau)*covm-tau*E/D*E';



end

