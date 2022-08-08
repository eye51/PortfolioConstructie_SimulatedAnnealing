%
%
%       volg Meucci Aug-2008.
%
%

clear; close all; clc; 


% market data
load 'corr_inpu.mat'; %
load 'vol.mat'; %


corr = corr + triu(corr,1)' ; 

covm  = corr.*(vol*vol');

w_market = [0.04;0.04;0.05;0.08;0.71;0.08];

pi_market = [0.06;0.07;0.09;0.08;0.17;0.10];

tau = 0.4;

% views

P = [0 1 0 0 0 0; 0 0 0 0 1 -1];

v = [0.12;-0.10];
c=1.0;

Ohm= (1/c)* P * covm * P';


% posterior:
% form (15) / (16)-> 

A = tau * covm;
B = P'* (Ohm\P);

C = P'* (Ohm\v);
E = covm*P';
D = P*E;
mu_BL = (inv(A)+B)\(A\pi_market+C);     % (15)

Sig_BL_pos = covm + inv(inv(tau*covm)+B); % (18)


% form 19 / 20
% 



mu_BL_2 = pi_market+A*P'*((tau*D+Ohm)\(v-P*pi_market)); % check --> implementatie (15) / (19) agree
Sig_BL_pos_2 = (1+tau)*covm-((tau*tau)*covm*P'/(tau*D+Ohm))*P*covm;  % check --> implementatie (18) / (20) agree



%
% Meucci --> full confidence posterior
% (27) & (28)


mu_BL_full_conf = pi_market + E/D*(v-P*pi_market);
Sig_BL_full_conf = (1+tau)*covm-tau*E/D*E';



% M_=M+S*Q'*inv(Q*S*Q')*(M_Q-Q*M);
% S_=S+(S*G')*( inv(G*S*G')*S_G*inv(G*S*G') -inv(G*S*G') )*(G*S);

% check full conf

Ohm = zeros(2,2);
mu_BL_full_2 = pi_market+A*P'*((tau*D+Ohm)\(v-P*pi_market)); % check --> implementatie (15) / (19) agree --> agree with (27) & (28)


Sig_BL_pos_full_2 = (1+tau)*covm-((tau*tau)*covm*P'/(tau*D+Ohm))*P*covm;  % check --> implementatie (18) / (19) agree




%
%   VIEW op Market ipv. mu (zie pg. 7.)
% 	(31) & (32)



mu_BL_meucci_market = pi_market + E/(D+Ohm)*(v-P*pi_market);
Sig_BL_meucci_market = covm-tau*E/(D+Ohm)*E';

