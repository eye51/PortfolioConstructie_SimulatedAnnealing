function [ assetCls viewNames viewReturns viewProb viewStDev] = getCurViews(inputFileName)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here


[a b c]=xlsread(inputFileName);


noAsset=size(a,1)-2;
noView=size(a,2);


assetCls=cell(1,noAsset);
viewNames=cell(1,noView);

for i=1:noAsset
    assetCls{i}=b{i+1,1};
end


for i=1:noView
    viewNames{i}=b{1,i+1};
end

viewReturns = a(1:end-2,:);
viewProb = a(end-1,:);
viewStDev = a(end,:);
end

