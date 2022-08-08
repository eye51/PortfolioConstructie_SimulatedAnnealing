function [mu,covm] = VertaalMat(mat)

[T,K] = size(mat);
mu    = mat(:,1);
stdev = mat(:,2);
corm  = mat(:,3:K);   % dit is de correlatie matrix
covm  = corm.*(stdev*stdev'); % bereken hier de covariantie matrix, dit is 
                              % een input voor simulated annealing. 

end