function [ covarCon ] = covarContribution (w0, correlM, stdevA)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here




covarCon = w0 .*(stdevA .* (correlM*(w0.*stdevA)));



end