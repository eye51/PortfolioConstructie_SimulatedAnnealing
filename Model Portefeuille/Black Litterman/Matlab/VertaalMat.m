function [mu,covm] = VertaalMat(mat)

[T,K] = size(mat);
mu    = mat(:,1);
stdev = mat(:,2);
corm  = mat(:,3:K);
covm  = corm.*(stdev*stdev');

end