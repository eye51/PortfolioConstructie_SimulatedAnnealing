function [ volCon ] = volContribution (w0, correlM, stdevA)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


covar = correlM.*(stdevA*stdevA'); % calculate cov. from correlation / st.dev


volCon = w0'.*(w0'* covar)/sqrt(w0'*covar*w0); % (w0'*covar) * diag (w0)
end