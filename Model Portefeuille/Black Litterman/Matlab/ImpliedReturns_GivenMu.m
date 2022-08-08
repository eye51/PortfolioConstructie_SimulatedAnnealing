function [ir,lambda] = ImpliedReturns_GivenMu(wts,pars,er_bm)

% PURPOSE: calculates expected (relative) returns given 'equilibrium'
%          portfolio weights and set of equality and inequality
%          restrictions
%---------------------------------------------------
% USAGE: [P,q] = ReverseConstrainedMVO( wts,lambda,Sigma,A,b,Aeq,beq )
% where: wts       = Kx1 vector with (equilibrium) portfolio weights 
%        lambda    = risk aversion parameter
%		 Sigma	   = estimate of return covariance matrix	
%	     A         = matrix w.r.t. inequality constraints: Aw<=b 
%		 b		   = vector w.r.t. inequality constraints: Aw<=b
%	     Aeq       = matrix w.r.t. equality constraints: Aeq w=beq 
%		 beq       = vector w.r.t. equality constraints: Aeq w=beq
%---------------------------------------------------
% RETURNS: 
%		P = matrix w.r.t. relative views on expected returns: Pm = q
%		q = vector w.r.t. relative views on expected returns: Pm = q
% --------------------------------------------------
% NOTES:
% 1. Output P and q can be used in Black Litterman model
% 2. Apparently, A and b should only include binding restrictions
%    and could therefore be included in Aeq and beq
% --------------------------------------------------
% SEE ALSO: ...
%---------------------------------------------------
% REFERENCES: Zagst, R. and M. Pöschik (2008), "Inverse portfolio
%             optimisation under constraints", Journal of Asset Management,
%			  Vol. 9, 239-253.
%---------------------------------------------------
% Written on June 12, 2009 by:
% Henk Hoek
% henk.hoek@mn-services.nl
%---------------------------------------------------

%Step (1): split the constraint matrix in two parts
[nw,np] = size(wts);
Aeq     = ones(1,nw);
beq     = 1;

[mu,sig] = Mixture_Moments(pars);
P = eye(nw);
if pars.bm_te1>0
	P(:,pars.bm_te1) = P(:,pars.bm_te1)-1;
end
sigma = P*sig*P';

if pars.bm_er>0
	r_bm = mu(pars.bm_er);
else
	r_bm = 0;
end

[RP,Rq]  = ReverseConstrainedMVO(wts,1,sigma,[],[],Aeq,beq);
RP       = [zeros(1,nw);RP];
RP(1,1)  = 1;             % Rendement nom matching
q        = [zeros(1,np);Rq];

%Schaal q zdd excess return is er_bm%
q       = RP\q;  
if abs(er_bm)>1e-8;
    lhulp = sum(matmul(wts,q))/er_bm; 
else
    lhulp = sum(matmul(wts,q))/1e-8; 
end
lambda  = 1./lhulp;
q       = matmul(lambda,q);
ir      = q+r_bm; 

end