function [param] = AddPortMatch(pars,mpn,mpr)

N        = size(pars.meanmat,1); 
K        = size(pars.meanmat,2);

for i=1:K
    mu  = pars.meanmat(:,i);
    sig = pars.covmat(:,:,i);

    mu          = [mu;mpn.er;mpr.er];    %Voeg alpha matching portefeuille toe
    [stdev,cor] = cov2stdcor(sig);

    stdev         = [stdev;mpn.te;mpr.te];
    hulp          = eye(N+2,N+2);
    hulp(1:N,1:N) = cor;

    for j=1:2
        if mpn.cor_bm(j)>0
            hulp(N+1,mpn.cor_bm(j)) = mpn.cor(j);
            hulp(mpn.cor_bm(j),N+1) = mpn.cor(j);
        end
        if mpr.cor_bm(j)>0
            hulp(N+2,mpr.cor_bm(j)) = mpr.cor(j);
            hulp(mpr.cor_bm(j),N+2) = mpr.cor(j);
        end
    end

    %Check correlatiematrix
    W = 0.01+zeros(N+2,N+2);
    for j=1:2
        if mpn.cor_bm(j)>0
            W(N+1,mpn.cor_bm(j)) = 1;
            W(mpn.cor_bm(j),N+1) = 1;
        end
        if mpr.cor_bm(j)>0
            W(N+2,mpr.cor_bm(j)) = 1;
            W(mpr.cor_bm(j),N+2) = 1;
        end
    end
    W(1:N,1:N) = 10*ones(N,N);
    [cor]      = CorMatHdm(hulp,W,ones(N+2,1),1e-5,1e-8);
    sig        = cor.*(stdev*stdev');

    P_er  = [zeros(2,N+2); eye(N) zeros(N,2)];
    if mpn.bm>0    
        P_er(1,mpn.bm)     = 1;
        P_er(mpn.bm+2,N+1) = 1;
    end
    if mpr.bm>0    
        P_er(2,mpr.bm)     = 1;
        P_er(mpr.bm+2,N+2) = 1;
    end

    param.meanmat(:,i)  = P_er*mu;
    param.covmat(:,:,i) = P_er*sig*P_er';    
end

end