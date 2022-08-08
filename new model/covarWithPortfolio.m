function [ covarWPort ] = covarWithPortfolio (w0, correlM, stdevA)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here




covarWPort = stdevA .* (correlM*(w0.*stdevA));



end

