function [ alscov ] = Cov2ALSCov( covm )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
K = size(covm,1);
N = size(covm,3);

alscov = zeros(K,K,N);

for i=1:N
    covi          = covm(:,:,i);
    std           = sqrt(diag(covi));
    hulp          = covi./(std*std');   % correlatie matrix
    ex            = std*std'==0;    
    hulp(ex)      = 0;
    alscov(:,:,i) = diagrv(hulp,std);   % correlatie matrix waarbij diagonaal vervangen is voor st.dev. 
end

end

%----------------------------------------------------

function y = diagrv(x,v)
% PURPOSE: replaces main diagonal of a square matrix
% -----------------------------------------
% USAGE: y - diagrv(x,v)
% where: x = input matrix
%        v = vector to replace main diagonal
% -----------------------------------------
% RETURNS: y = matrix x with v placed on main diagonal
% -----------------------------------------
% NOTE: a Gauss compatability function
% -----------------------------------------------------

% written by:
% James P. LeSage, Dept of Economics
% University of Toledo
% 2801 W. Bancroft St,
% Toledo, OH 43606
% jpl@jpl.econ.utoledo.edu
  
[r,c] = size(x);
if r ~= c;
  error('x matrix not square')
end;
if length(v) ~= r;
  error('v is not conformable with x')
end;
y = x - diag(diag(x)) + diag(v);

end
