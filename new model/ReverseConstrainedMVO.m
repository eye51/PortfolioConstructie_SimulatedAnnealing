function [P,q] = ReverseConstrainedMVO( wts,lambda,Sigma,A,b,Aeq,beq)

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
Amat = [A;Aeq];      
[n,k] = size(Amat);
if (n==0)   %no restrictions
    P = eye(rows(wts));
else
    [A_full,A_rem,Perm] = GetPartition(Amat);
    iPerm = inv(Perm);  %Inverse matrix for getting the original ordering
    % Now, apply theorem 2
    P = [-A_rem'*inv(A_full') eye(k-n)];
    P = P*iPerm;        %Adjust ordering of P, to correspond to initial ordering
end
q = lambda*P*Sigma*wts;    

end

%---------------------------------------------------
%The next function performs the partition of equation (2) in Zagst and
%Pöschik (2008). Note that also the asset categories need to be renumerated.
%For this the matrix Perm is used (and the inverse of Perm for getting
%the original ordering).
%---------------------------------------------------

function [A_full,A_rem,Perm] = GetPartition(Amat)
[n,k] = size(Amat);
A_full = [];
A_rem  = [];
Perm1  = [];
Perm2  = [];
unity  = eye(k);
for i=1:k
    temp = [A_full Amat(:,i)];
    if (rank(temp)==size(temp,2))
        A_full = temp;
        Perm1 = [Perm1 unity(:,i)]; 
    else
        A_rem = [A_rem Amat(:,i)];
        Perm2 = [Perm2 unity(:,i)]; 
    end
end
Perm = [Perm1 Perm2];

end