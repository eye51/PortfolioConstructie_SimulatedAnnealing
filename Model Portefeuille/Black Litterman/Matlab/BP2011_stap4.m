
%Programma voor berekening beleggingsplan 2010
%P1 = path;
%P2 = 'J:\06 Beleid\Portefeuilleconstructie\BP2011\matlab';
%path(P2,P1);

%Zet random seed vast (en daarmee de uitkomsten)
stream = RandStream('mt19937ar','seed',12102009); 
RandStream.setDefaultStream(stream); 

wts      = gewichten;
ex       = sum(wts.*wts)>0;
wts      = wts(:,ex);
if size(wts,2)>0
    wts = matdiv(wts,sum(wts));
end
plot_pdf = plot_pdf(ex);
naam_mix = naam_mix(ex);

%1e stap: schat ontbrekende waarnemingen
%Let op: ontbrekende waarnemingen worden nu ingelezen als 0

Nassets = 10;
Nvisies = 4;

pars.bm_er         = bm_reeks_er;
pars.bm_te1        = bm_reeks_te1;
pars.bm_te2        = bm_reeks_te2;

lpm_par.order  = lpm_orde;
lpm_par.target = lpm_target;

mpn.bm     = match1_bm;
mpn.cor_bm = match1_cor_bm; 
mpn.er     = match1_er;
mpn.te     = match1_te;
mpn.cor    = match1_cor;
mpr.bm     = match2_bm;
mpr.cor_bm = match2_cor_bm; 
mpr.er     = match2_er;
mpr.te     = match2_te;
mpr.cor    = match2_cor;

param   = AddPortMatch(pars,mpn,mpr);
Nassets = Nassets+5;    %Voeg derivaten toe
P_bm1 = eye(Nassets+2);
P_bm1(:,1) = P_bm1(:,1)-1;
P_bm1 = P_bm1(3:end,:);

derpar.strike = cell2mat(derivaat(:,4));
derpar.rente  = cell2mat(derivaat(:,6));
for i=1:5
    derpar.onder(i,:) = (1:rows(asset_names))*strcmp(asset_names,derivaat(i,2));
    derpar.type(i,:)  = strcmp(derivaat(i,3),'Call')-strcmp(derivaat(i,3),'Put');
end
derpar.impvol = cell2mat(derivaat(:,5));
derpar.P0 = BlackScholesPrice(1,derpar.strike,derpar.rente,1,0,derpar.impvol,derpar.type);

%Nu optimalisatie per scenario
for i=1:6
	stream = RandStream('mt19937ar','seed',12102009); 
	RandStream.setDefaultStream(stream);

	scenario       = param;
    scenario.probs = ScenarioKans(i,:)';
    
    %Genereer scenario's
    R = Mixture_Scenarios(scenario,nscen);
  
    %Voeg scenarios van derivaten toe
    R = AddScenariosDerivatives(R,derpar);    
    Rscen(:,:,i) = R;
end

evaluation = EvaluatePortfolios_Scen(wts,Rscen,pars,lpm_par); 

hulp = evaluation.totaal;
K = size(hulp,3);
for i=1:K
    evalmat(:,i) = vec(hulp(:,:,i));
end

j = 0;
for i=1:size(wts,2)
    if strcmp(plot_pdf(i),'Nee')
        continue;
    end
    j = j+1;
    for s=1:6
        h                        = squeeze(evaluation.scenarios(:,i,s));
        vpv                      = squeeze(evaluation.scenariosVPV(:,s));
        h = 100*dg*(1+matdiv(h,1+vpv));
        [f(:,j,s),xi(:,j,s)] = ksdensity(h,'npoints',100);    
        hs(:,j,s) = sort(h);
    end
end

figure;
for i=2:5
    subplot(2,2,i-1);
    plot(xi(:,:,i),f(:,:,i),'LineWidth',3);
    title(scen_names(i),'FontSize',20);
    legend(naam_mix,'FontSize',12,'Location','NorthEast');
    xlabel('Dekkingsgraad einde periode','FontSize',10);
    set(gca,'ytick',[]);    
    grid on;
end

figure;
i = 6;
plot(xi(:,:,i),f(:,:,i),'LineWidth',3);
title(scen_names(i),'FontSize',24);
legend(naam_mix,'FontSize',16,'Location','NorthEast');
xlabel('Dekkingsgraad einde periode','FontSize',16);
set(gca,'ytick',[]);    
grid on;

figure;
for i=2:5
    subplot(2,2,i-1);
    plot(hs(:,:,i),(1:nscen)/nscen,'LineWidth',3);
    title(scen_names(i),'FontSize',20);
    legend(naam_mix,'FontSize',12,'Location','NorthEast');
    xlabel('Dekkingsgraad einde periode','FontSize',10);    
    grid on;
end

figure;
i = 6;
plot(hs(:,:,i),(1:nscen)/nscen,'LineWidth',3);
title(scen_names(i),'FontSize',24);
legend(naam_mix,'FontSize',16,'Location','NorthEast');
xlabel('Dekkingsgraad einde periode','FontSize',16);
grid on;