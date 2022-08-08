function covmat = ALSCov2Cov(covm)
    
K     = size(covm,1);
stdev = diag(covm);
ex    = ones(K,K)-eye(K);
corm  = covm.*ex+eye(K);

covmat = corm*(stdev*stdev');

end