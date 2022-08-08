
%Programma voor berekening beleggingsplan 2010
%P1 = path;
%P2 = 'J:\06 Beleid\Portefeuilleconstructie\BP2011\matlab';
%path(P2,P1);

%1e stap: schat ontbrekende waarnemingen
%Let op: ontbrekende waarnemingen worden nu ingelezen als 0

%Uitgangspunten IR analyse
K = size(m_eq,1);

cov_eq = cor_eq.*(std_eq*std_eq');

m_view   = Pm_eq + Pm_delta;    % returns visie

ex1 = (strcmp(Pm_meenemen,'Ja')).*(sum(Pm.*Pm,2)~=0);   % filter assets die niet meegenomen moeten worden
if sum(ex1)>0
    Pm     = Pm(logical(ex1),:);
    m_view = m_view(logical(ex1));
else
    Pm     = eye(K);
    m_view = m_eq;
end

ex2 = sum(Pcov.*Pcov,2)~=0;
if sum(ex2)>0
    Pcov          = Pcov(ex2,:);
    Pcov_meenemen = Pcov_meenemen(ex2,ex2);
    
    ex3 = strcmp(Pcov_meenemen,'Ja');
    if sum(sum(ex3))>0
        cov_view = Pcov_eq(ex2,ex2)+ex3.*Pcov_delta(ex2,ex2);

        std_view = diag(cov_view);
        ns       = size(cov_view,1);
        H        = ones(ns,ns)-eye(ns);
        cor_view = H.*cov_view+eye(ns);
        %Correlation matrix could be non positive definite: make necessary adjustments using
        %Matlab code of Qi and Sun (2008). Weights per element are equal to absolute value of
        %view
        tau = 1e-8;	%lower bound on eigenvalues of correlation matrix
        tol = 5e-6;	%tolerance parameter

        if min(eig(cor_view))<tau
            cor_view = CorMatHdm(cor_view,ex3,ones(size(ex3,1),1),tau,tol);
        end

        cov_view = cor_view.*(std_view*std_view');	%Final view covariance matrix
    else
        Pcov     = eye(K);
        cov_view = cov_eq;
    end
else
    Pcov     = eye(K);
    cov_view = cov_eq;
end
    
[M_visie,V_visie]     = PosteriorMeanCov(Pm,m_view,Pcov,cov_view,m_eq,cov_eq);
[std_visie,cor_visie] = Cov2StdCor(V_visie);

