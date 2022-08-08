function [RiskBudget]=BarclayMethodRiskBudget(assetCategorie,TEtarget,cur_weight, corr_curr, stdev_curr,IRView,useOnlyPosTE )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


    % extra restrictie / instellingen voor risk-budgetting

    
    noAssets=size(assetCategorie,1);
    % get current restrictions
    AssetsWRiskBudget= strcmp(assetCategorie, 'Return portefeuille');


    noAssetsInMatching = sum(~AssetsWRiskBudget);




    % determine risk contribution for each asset
    [volConCurrent] = volContribution (cur_weight, corr_curr, stdev_curr);




    IRforRB = IRView;
    IRforRB(~AssetsWRiskBudget) = -1.0;

    noAssetsRB = sum(IRforRB>0);

    [IRsort,IDsRanking]=sort(IRforRB,'descend')



    % determine Size RB


    RiskBudgetTot=TEtarget - sum(volConCurrent(~AssetsWRiskBudget)); % alleen risk-budgetting op return portfolio, matching blijft constant



    RiskBudget=zeros(noAssets,1);
    RiskBudget(~AssetsWRiskBudget)=volConCurrent(~AssetsWRiskBudget);

    RiskBudget(IDsRanking(1))=0.3 * RiskBudgetTot;
    RiskBudget(IDsRanking(2))=0.2 * RiskBudgetTot;
    RiskBudget(IDsRanking(3))=0.1 * RiskBudgetTot;
    RiskBudget(IDsRanking(4))=0.05 * RiskBudgetTot;


    RiskBudget(IRforRB>0)=RiskBudget(IRforRB>0)+(1-0.65)*RiskBudgetTot/noAssetsRB;




end

