function [PosteriorMean,PosteriorCov] = PosteriorMeanCov(PM1,Pm,PV1,Pcov,mu,covmat)

% PURPOSE: Transforms (relative) views to expected returns and covariance matrix
%---------------------------------------------------
% USAGE: [PriorMean,PriorCov] = PosteriorMeanCov(PM1,Pm,PV1,Pcov,mu,covmat)
% where: PM1    = NxK matrix with relative views (on expected returns), where K is the
%				  number of asset classes. Each row gives the portfolio weights of the
%				  view portfolio
%		 Pm     = Nx1 vector with expected returns on the view portfolios
%		 PV1	= MxK matrix with relative views (on the covariance matrix). Each row
%				  gives the portfolio weights of the view portfolio
%		 Pcov   = MxM matrix with the covariance matrix of the view portfolio
%		 mu	    = Kx1 vector with "equilibrium" returns per asset class
%		 covmat = KxK matrix with "equilibrium" covariance matrix
%---------------------------------------------------
% RETURNS: 
%		PosteriorMean =	Kx1 mean vector with expected returns (full confidence in views)
%		PosteriorCov  = KxK covariance matrix (full confidence in views).
% --------------------------------------------------
% NOTES: The view matrices PM1 and PV1 can be different, with the following special cases:
%	(1) PM1 = eye(K), Pm = mu: 			no view on expected returns
%	(2) PV1 = eye(K), Pcov = covmat:	no view on covariance matrix
% --------------------------------------------------
% SEE ALSO: ...
%---------------------------------------------------
% REFERENCES: 	Meucci (2008), "Fully flexible views: theory and practice",
%					Risk, October 2008, pp 97-102
%---------------------------------------------------
% Written on September 22, 2009 by:
% Henk Hoek
% henk.hoek@mn-services.nl
%--------------------------------------------------

%View on expected return
PosteriorMean = mu+covmat*PM1'/(PM1*covmat*PM1')*(Pm-PM1*mu);       % (31) in Meucci (2008)

K = size(covmat,1);
M = size(PV1,1);        % number of views

if (M<K)
    PV2 = null(PV1*covmat)';
    PV  = [PV1;PV2];    
elseif (M==K)
    PV  = PV1;
else
	error('Too many views on covariance matrix');
end

hulp          = PV*covmat*PV';
hulp(1:M,1:M) = Pcov;

PosteriorCov = PV\hulp/PV';                                         % vgl (32) Meucci

end