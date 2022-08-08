function [ranking] = rankIR(IRView,assetCategorie);
% Bepaal Ranking van de IRs
%   Detailed explanation goes here

    returnPort= strcmp(assetCategorie, 'Return portefeuille');
    IRView(~returnPort) = -1.0;
    
    
    [IRsort,IDsRanking]=sort(IRView,'descend');
    
    ranking(IDsRanking)=1:size(assetCategorie,1);
    ranking(~returnPort)=0;
end

