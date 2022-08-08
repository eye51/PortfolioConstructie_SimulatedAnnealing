function [ RiskBudget ] = riskParity(assetCategorie,TEtarget,cur_weight, corr_curr, stdev_curr,IRforRB,useOnlyPosTE)
% geef (return) assets gelijk risico-budget



    noAssets=size(assetCategorie,1);

    
    AssetsWRiskBudget= strcmp(assetCategorie, 'Return portefeuille');

    noAssetsInMatching = sum(~AssetsWRiskBudget);

     % determine risk contribution for each asset
    [volConCurrent] = volContribution (cur_weight, corr_curr, stdev_curr);

    % determine Size RB
    RiskBudgetTot=TEtarget - sum(volConCurrent(~AssetsWRiskBudget)); % alleen risk-budgetting op return portfolio, matching blijft constant
   
    
    
    IRforRB(~AssetsWRiskBudget) = -1.0;

    RiskBudget=zeros(noAssets,1);
    
    
    if useOnlyPosTE
        noAssetsRb=sum(IRforRB>0);
        
        RiskBudget(IRforRB>0)=RiskBudgetTot/noAssetsRb;
    else
    
        noAssetsRb = noAssets-noAssetsInMatching;
        RiskBudget(AssetsWRiskBudget)=RiskBudgetTot/noAssetsRb;

    
    end

   RiskBudget(~AssetsWRiskBudget)=volConCurrent(~AssetsWRiskBudget);
    

end

