N = size(stdev,1);

% transformeer de correlatie matrix naar een cov matrix. 
sig = cormat.*(stdev*stdev');

vcm = sig;
P   = eye(N);

% maak een relatieve covariantie matrix indien een bmnr is opgegeven. 
if bm_nr>0
    P(:,bm_nr) = P(:,bm_nr)-1;
    vcm        = P*vcm*P';
end

% voer de reverse engineering uit en bereken het evenwichtsrendement. 
% OPM Bastiaan: harcoded dat er geen soft-restricties zijn -> dit is niet
% correct (?) -> hier is een min/max limiet van 0% - 100% / in constrained case
% user defiened soft limieten..

% op dit moment alleen limiet dat gewichten optellen naar 1.
% geen short-selling / max 100% limiet (?)
% short selling limiet is impliciet door gebruikte methode (?) (zie theorem 1
% pg. 241 / Zagst, R. and M. Pöschik (2008), "Inverse portfolio
%             optimisation under constraints", Journal of Asset Management,
%			  Vol. 9, 239-253.

% risk-aversion is harcoded op 1

[Pv,qv] = ReverseConstrainedMVO(w0,1,vcm,[],[],ones(1,N),1); % function [P,q] = ReverseConstrainedMVO( wts,lambda,Sigma,A,b,Aeq,beq)

H       = eye(N);
Pv      = [H(vast_nr(1),:);Pv];
qv      = [vast_ret(1);qv];
q       = Pv\qv;                    %  formula ii) Theorem 2 Zagst, R. and M. Pöschik
m_eq    = q*vast_ret(2)/(H(vast_nr(2),:)*q); % evenwichtrendement. -> mij niet helemaal duidelijk.. TODO: uitwerken..

% bereken de tracking error van de reversed engineered portfolio
te   = sqrt(w0'*vcm*w0);

