function P = BlackScholesPrice(S,K,r,T,t,sig,w)

%w=1 voor een call optie en w=-1 voor een put optie

d1 = (log(S./K)+(r+sig.*sig/2).*(T-t))./(sig.*sqrt(T-t));
d2 = d1-sig.*sqrt(T-t);

P  = S.*w.*normcdf(w.*d1)-K.*w.*exp(-r.*(T-t)).*normcdf(w.*d2);

end