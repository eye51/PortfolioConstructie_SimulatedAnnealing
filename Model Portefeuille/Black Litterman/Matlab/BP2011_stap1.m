
%Programma voor berekening beleggingsplan 2010
%P1 = path;
%P2 = 'J:\06 Beleid\Portefeuilleconstructie\BP2011\matlab';
%path(P2,P1);

%1e stap: schat ontbrekende waarnemingen
%Let op: ontbrekende waarnemingen worden nu ingelezen als 0

%Uitgangspunten IR analyse

%
%   rdata = (jaar) rendementen asset classes
%   bjaar = start datum (jaar) voor te gebruiken range van historische data
%   ejaar = eind datum (jaar) 
%   bm_reeks1_ir = id. benchmark 1
%   rm_rend = rendement BM 1
%   ir = IR BM 1 (TODO: klopt dit ????)



[m_eq,cov_eq,rt] = IR_assumptions(rdata,bjaar,ejaar,bm_reeks1_ir,bm_rend,ir);   % (evenwichts?) rendementen, vol en covariante uit historische data
                                                                                % bepaal evenwichts rendementen uit covariantie asset + IR BM.
ft               = GetData(fdata,bjaar,ejaar);  % economische data
[std_eq,cor_eq]  = Cov2StdCor(cov_eq); % splits covariantiematrix in standaarddeviaties en correlatie matrix

Nassets = size(m_eq,1);
Nvisies = 4;            % TODO: hardcoded!

Pbm = eye(Nassets);
if bm_reeks1_ir>0
    Pbm(:,bm_reeks1_ir) = Pbm(:,bm_reeks1_ir)-1;
end

if bm_reeks2_ir>0 && bm_reeks1_ir>0     % zet evenwichts returns gelijk voor beide BM
    m_eq(bm_reeks2_ir) = m_eq(bm_reeks1_ir);
end

% 'equilibrium' scenario:
pars.meanmat(:,1)  = m_eq;
pars.covmat(:,:,1) = cov_eq; 
pars.stdev(:,1)    = std_eq;
pars.cormat(:,:,1) = cor_eq;

%Verwerk visies


% rend_view(:,i)  = expected rendementen van de assets in scenario i
% stdfac_view = factor waarmee standaard deviaties geschaald worden in
%               schenario i. Factor > 1, dan vol. hoger in scenario.
% 

for i=1:Nvisies
    m_view(:,i)          = rend_view(:,i);
    [m_alt(:,i),cov_view(:,:,i)] = LocalPolyReg(rt,ft,factor_view(:,i)',0);     % bereken een nieuwe covariante matrix voor scenario i
                                                                                % nieuwe covar matrix is gebasseerd op 
                                                                                % waar komt deze methode vandaag?
                                                                                % hier 0e orde polynoom
                                                                                % observaties worden gewogen aan de hand vd economische grootheden (GDP en CPI)
    pars.meanmat(:,i+1)  = m_view(:,i);
    cov_view(:,:,i)      = cov_view(:,:,i).*(stdfac_view(:,i)*stdfac_view(:,i)');
    pars.covmat(:,:,i+1) = cov_view(:,:,i);    
    [stda,cova]          = cov2stdcor(cov_view(:,:,i));
    pars.stdev(:,i+1)    = stda;
    pars.cormat(:,:,i+1) = cova;
end

