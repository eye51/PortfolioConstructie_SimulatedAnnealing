function [ stdev,mcor ] = Cov2StdCor(mcov)
%Cov2StdCor: transform covariance matrix to correlation matrix
%   
stdev = sqrt(diag(mcov));
mcor  = mcov./(stdev*stdev');

end