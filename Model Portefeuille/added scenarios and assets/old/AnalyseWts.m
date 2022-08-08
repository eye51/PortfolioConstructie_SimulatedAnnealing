function [ w_m,f_w,f_r2 ] = AnalyseWts(wts)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

w_m = mean(wts,2);
h   = matsub(wts,w_m);

[u,s,v] = svd(cov(h'));
f_w     = u*sqrt(s);

N = size(wts,1);
for i=1:N
    x       = f_w(:,i);
    b       = (x'*x)\(x'*h);
    e       = h-x*b;
    f_r2(i) = 1-sum(sum(e.*e))/sum(sum(h.*h)); 
end

f_w = f_w(:,1:N);

end

