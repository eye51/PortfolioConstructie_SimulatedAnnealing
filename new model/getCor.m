function [ assetCls corrMat stdev corNames] = getCor(inputFileName)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here


[a b c]=xlsread(inputFileName,2);



noAsset=size(a,2)-1;



noCovars = floor(size(a,1)/size(a,2));

corrMat=cell(noCovars,1);
stdev=cell(noCovars,1);
corNames=cell(noCovars,1);

 for ii=1:noAsset
     assetCls{ii}=b{ii+1,1};
 end
 
 
 for ii=1:noCovars
     corrMat{ii} = a(1+(ii-1)*(noAsset+2):(ii-1)*(noAsset+2)+noAsset,1:noAsset);
     stdev{ii} = a(1+(ii-1)*(noAsset+2):(ii-1)*(noAsset+2)+noAsset,end);
     corNames{ii}=b{1+(ii-1)*(noAsset+2),1};
     
 end
 
end
