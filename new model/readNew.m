function [ output_args ] = Untitled( input_args )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


[assetCl assetCategorie cur_weight lowerBound upperBound lowerBsubPort upperBsubPort turnOver] = getCurPortfolio(inputFile);
noAssets = size(assetCl,1);

% get current views / scenarios
[~,viewNames,viewReturns,viewProb,viewStDev] = getCurViews(inputFile);
noViews = size(viewNames,2);



% get current VCM
[ ~,corr_curr, stdev_curr] = getCor(inputFile);

% get extra restrictions
[restrictionNR assetClsER lowerBoundER upperBoundER] = getExtraRestrictions(inputFile);


% determine risk contribution for each asset
[volConCurrent] = volContribution (cur_weight, corr_curr, stdev_curr);

volPortCurrent = portfolioVol (cur_weight, corr_curr, stdev_curr);

tabNR=0;


end

