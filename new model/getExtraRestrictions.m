function [restrictionNR assetCls lowerBound upperBound groupLowerBound groupUpperBound groupLimitActive] = getExtraRestrictions(inputFileName)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


[a b c]=xlsread(inputFileName,4);

%[a b c]=xlsread('views_curr_v01.xlsx',3);

noExtrRestr=size(a,1);

restrictionNR=a(:,1);
% lowerBound=a(:,3);
% upperBound=a(:,4);

lowerBound=a(:,6);
upperBound=a(:,7);



assetCls=cell(noExtrRestr,1);

% groupLowerBound = a(:,5);
% groupUpperBound = a(:,6);
% groupLimitActive = a(:,7);


groupLowerBound = a(:,3);
groupUpperBound = a(:,4);
groupLimitActive = a(:,5);


for i=1:noExtrRestr
    assetCls{i}=b{i+1,2};
end



end

