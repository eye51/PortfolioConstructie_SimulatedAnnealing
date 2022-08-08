
function [m_eq]=detEQReturns(stdev,IR)
%
% huidge standaard deviaties zijn al relatief aan BM, geen aanpassing nodig
% 

m_eq=IR*stdev;

end
