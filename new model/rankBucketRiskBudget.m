function [RiskBudget]=rankBucketRiskBudget(assetCategorie,TEtarget,cur_weight, corr_curr, stdev_curr,IRforRB,useOnlyPosIR)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


    
    noAssets=size(assetCategorie,1);
    % get current restrictions
    AssetsWRiskBudget= strcmp(assetCategorie, 'Return portefeuille');


    noAssetsInMatching = sum(~AssetsWRiskBudget);

    IRforRB(~AssetsWRiskBudget) = -1.0;

    
    if useOnlyPosIR
        noAssetsRb=sum(IRforRB>0);
    else
    
    noAssetsRb = noAssets-noAssetsInMatching;
    
    end
    % determine risk contribution for each asset
    [volConCurrent] = volContribution (cur_weight, corr_curr, stdev_curr);

    % determine Size RB


    RiskBudgetTot=TEtarget - sum(volConCurrent(~AssetsWRiskBudget)); % alleen risk-budgetting op return portfolio, matching blijft constant

    
    [IRsort,IDsRanking]=sort(IRforRB,'descend')
    
    
    noAssetsInBucket=floor((noAssetsRb)/4);
    
    
    % verdeel riskbudget over de buckets:
    %
    %   1e (hoogste IR) -> 40% RB
    %   2e              -> 30%
    %   3e              -> 20%
    %   4e              -> 10%
    % rest = 0%
    
    RiskBudget(IDsRanking(1:noAssetsInBucket))=(0.40*RiskBudgetTot)/noAssetsInBucket;
    RiskBudget(IDsRanking((noAssetsInBucket+1):(2*noAssetsInBucket)))=(0.30*RiskBudgetTot)/noAssetsInBucket;
    RiskBudget(IDsRanking((2*noAssetsInBucket+1):(3*noAssetsInBucket)))=(0.20*RiskBudgetTot)/noAssetsInBucket;
    RiskBudget(IDsRanking((3*noAssetsInBucket+1):(4*noAssetsInBucket)))=(0.10*RiskBudgetTot)/noAssetsInBucket;
    RiskBudget(IDsRanking((4*noAssetsInBucket+1):end))=0;
    
    
    % matching krijgt risk-budget die het al had:
    
    RiskBudget(~AssetsWRiskBudget)=volConCurrent(~AssetsWRiskBudget);




end

