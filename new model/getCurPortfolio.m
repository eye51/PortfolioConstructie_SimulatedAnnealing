function [assetCls Categorie CurrentW lowerBound upperBound lowerBsubPort upperBsubPort turnOver] = getCurPortfolio(inputFileName)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


[a b c]=xlsread(inputFileName,3);

%[a b c]=xlsread('views_curr_v01.xlsx',3);

noAsset=size(a,1);



assetCls=cell(noAsset,1);
Categorie=cell(noAsset,1);

for i=1:noAsset
    assetCls{i}=b{i+1,1};
    Categorie{i}=b{i+1,2};
end


CurrentW = a(:,1);

lowerBound=a(:,2);

upperBound=a(:,3);
lowerBsubPort =a(:,4);
upperBsubPort =a(:,5);
turnOver=a(:,6);

end

