function [ viewReturns viewProbabilities] = getViewReturnEstimates( ViewsReturnTable, ViewsProbabilityTable)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here



viewReturns = get (ViewsReturnTable,'Data');
viewReturns = cell2mat( viewReturns(:,2:end))/100;

viewProbabilities=get(ViewsProbabilityTable,'Data');
viewProbabilities=cell2mat(viewProbabilities(:,2:end));

end

