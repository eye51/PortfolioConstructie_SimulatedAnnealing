function [PosteriorMean,PosteriorCov] = QualitativeViews(P_M,q_M,P_V,q_V,m_eq,V_eq)

% PURPOSE: Transforms qualitative views to expected returns and covariance matrix
%---------------------------------------------------
% USAGE: [PriorMean,PriorCov] = QualitativeViews(P_M,q_M,P_V,q_V,m_eq,V_eq,wts_M,wts_V)
% where: P_M    = NxK matrix with relative views (on expected returns), where K is the
%				  number of asset classes. Each row gives the portfolio weights of the
%				  view portfolio
%		 q_M    = Nx1 vector with qualitative views on the returns
%		 P_V	= MxK matrix with relative views (on the covariance matrix). Each row
%				  gives the portfolio weights of the view portfolio
%		 q_V    = MxM matrix with qualitative views on the covariance matrix
%		 m_eq   = Kx1 vector with "equilibrium" returns per asset class
%		 V_eq   = KxK matrix with "equilibrium" covariance matrix
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
% Written on October 5, 2009 by:
% Henk Hoek
% henk.hoek@mn-services.nl
%--------------------------------------------------

%Calculate covariance matrix of view portfolios (mean)
N = size(m_eq,1)	%Number of asset categories

N_m = size(P_M,1);
N_V = size(P_V,1);

M_cov = P_M*V_eq*P_M';

q_mean = P_M*m_eq+q_M.*sqrt(diag(M_cov));

%Calculate covariance matrix of view portfolios (covariance matrix)
%Split covariance matrix in variances and correlations
V_cov     = P_V*V_eq*P_V';
diag_cov  = diag(V_cov);
diag_std  = diag(1+q_V).*sqrt(diag_cov);

hulp      = q_V-diag(diag(q_V));
cor_cov   = Cov2Cor(V_cov);
cor_view  = cor_cov+hulp;

%Correlation matrix could be non positive definite: make necessary adjustments using
%Matlab code of Qi and Sun (2008). Weights per element are equal to absolute value of
%view
tau = 1e-8;	%lower bound on eigenvalues of correlation matrix
tol = 5e-6;	%tolerance parameter

if min(eig(cor_view))<tau
	cor_view = CorMatHdm(cor_view,abs(q_V),ones(N_V,1),tau,tol);
end

q_cov = cor_view.*(diag_std*diag_std');		%Final view covariance matrix

[PosteriorMean,PosteriorCov] = PosteriorMeanCov(P_M,q_mean,P_V,q_cov,m_eq,V_eq);

end