function [mu,sig1,sig2] = AddMatchPortMix(pars,mpn,mpr)

N        = size(pars.meanmat,1); 
[mu,sig] = Mixture_Moments(pars);

mu          = [mu;mpn.er;mpr.er];    %Voeg alpha matching portefeuille toe
[stdev,cor] = cov2stdcor(sig);

stdev         = [stdev;mpn.te;mpr.te];
hulp          = eye(N+2,N+2);
hulp(1:N,1:N) = cor;

for i=1:2
    if mpn.cor_bm(i)>0
        hulp(N+1,mpn.cor_bm(i)) = mpn.cor(i);
        hulp(mpn.cor_bm(i),N+1) = mpn.cor(i);
    end
    if mpr.cor_bm(i)>0
        hulp(N+2,mpr.cor_bm(i)) = mpr.cor(i);
        hulp(mpr.cor_bm(i),N+2) = mpr.cor(i);
    end
end

%Check correlatiematrix
W = 0.01+zeros(N+2,N+2);
for i=1:2
    if mpn.cor_bm(i)>0
        W(N+1,mpn.cor_bm(i)) = 1;
        W(mpn.cor_bm(i),N+1) = 1;
    end
    if mpr.cor_bm(i)>0
        W(N+2,mpr.cor_bm(i)) = 1;
        W(mpr.cor_bm(i),N+2) = 1;
    end
end
W(1:N,1:N) = 10*ones(N,N);
[cor]      = CorMatHdm(hulp,W,ones(N+2,1),1e-5,1e-8);
sig        = cor.*(stdev*stdev');

P_er  = [eye(N) zeros(N,2)];
if mpn.bm>0    
    P_er(mpn.bm,N+1) = 1;
end
if mpr.bm>0    
    P_er(mpr.bm,N+2) = 1;
end

P_te1 = P_er;
P_te2 = P_er;

if pars.bm_er>0
	P_er(:,pars.bm_er) = P_er(:,pars.bm_er)-1;
end
if pars.bm_te1>0
	P_te1(:,pars.bm_te1) = P_te1(:,pars.bm_te1)-1;
end
if pars.bm_te2>0
	P_te2(:,pars.bm_te2) = P_te2(:,pars.bm_te2)-1;
end

mu   = P_er*mu;
sig1 = P_te1*sig*P_te1';
sig2 = P_te2*sig*P_te2';

end