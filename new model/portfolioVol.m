function [ vol ] = portfolioVol (w0, correlM, stdevA)

%PortfolioVOL calculate volatility of a portfolio of assets
%   w0      = weights assets
%   correlM = correlation matrix
%   stdevA  = standard deviations assets


covar = correlM.*(stdevA*stdevA'); % calculate cov. from correlation / st.dev


vol   = sqrt(w0'*covar*w0);

end

