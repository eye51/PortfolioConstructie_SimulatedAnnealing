function [m0,cov0,yt] = EM_miss(xt)

%
%   xt = time-series (jaar-returns vd assets)
%

[T,K] = size(xt);   % T = aantal observaties per serie (T = aantal jaar), K = aantal asset classes

ex1 = isnan(xt);        % filter NaN
ex2 = sum(ex1,2)==0;    % tijdstappen waarvoor alle series observaties hebben

m0   = mean(xt(ex2,:)); % gemiddelde returns in tijdvlak waarvoor voor alle series observaties zijn
cov0 = cov(xt(ex2,:));  % covariantie matrix voor tijdvlak waarvoor voor alle series observaties zijn

yt = xt;

for j=1:100             % iteratief process om tot missing returns te komen 
    for i=1:T
        if ex2(i)==0    % heeft een serie op deze tijdstap geen observatie?
            ix1       = logical(ex1(i,:));  % series met missing observaties
            ix2       = not(ex1(i,:));      % series met observatie
            Cou       = cov0(ix1,ix2);
            Coo       = inv(cov0(ix2,ix2));
            yt(i,ix1) = m0(ix1)+(xt(i,ix2)-m0(ix2))*Coo*Cou'; % schat return voor missing observation mbv covariantie voor tijd-range dat er wel observaties zijn
        end    
    end
    m0   = mean(yt);
    cov0 = cov(yt);
end

end