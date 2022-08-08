%
%       Stap 3 van portfolio contructie -> optimalisatie stap
%


PP = genpath('C:\Users\bgt\Documents\offline\Portfolio Constructie\Model Portefeuille\Black Litterman\Matlab');
addpath(PP);

%Zet random seed vast (en daarmee de uitkomsten)
stream = RandStream('mt19937ar','seed',12102009); 
RandStream.setDefaultStream(stream); 

% hardcoded aantal assets + visies
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

ret_cats   = InPortefeuille==2;

param = AddPortMatch(pars,mpn,mpr);
P_bm1 = eye(Nassets+2);
P_bm1(:,1) = P_bm1(:,1)-1;
P_bm1 = P_bm1(3:end,:);

%Verwerk restricties op portefeuillegewichten
A   = [-eye(Nassets);eye(Nassets)]; 
b   = [-Rest_tot(:,1);Rest_tot(:,2)];
%Maak ook restrictiematrix apart voor matching en return portefeuille
b_p  = zeros(2*Nassets,1);
ex_1 = double(InPortefeuille==1);
ex_2 = double(InPortefeuille==2);
C_p  = ex_1*ex_1'+ex_2*ex_2'; 
A_p1 = -(eye(Nassets)-diag(Rest_port(:,1))*C_p);
A_p2 = (eye(Nassets)-diag(Rest_port(:,2))*C_p);
A_p  = [A_p1;A_p2];
A    = [A;A_p];
b    = [b;b_p];
%Maak tenslotte restricties op basis van huidige portefeuille gewichten
A_h  = [-eye(Nassets);eye(Nassets)];
b_h  = [-(w_t0-Rest_t0);w_t0+Rest_t0];
A    = [A;A_h];
b    = [b;b_h];

%Nu optimalisatie per scenario
for i=1:6
    if strcmp(doorrekenen(i),'Nee')
        i = i+1;
        continue;
    end
	stream = RandStream('mt19937ar','seed',12102009); 
	RandStream.setDefaultStream(stream);
	
    RetBounds  = [MinRet(i);99];
    RiskBounds = [0 0;MaxTE1(i) MaxTE2(i)];

    pars.probs = ScenarioKans(i,:)'; 
    
    tekst = ['Scenario (' num2str(i,0) '), optimalisatie...'];

    % simulated annealing:
    output = Check_Restricties2(doelstelling(i),RetBounds,RiskBounds,pars,mpn,mpr,Niter,Nport,A,b,tekst,w_t0,Rest_turnover,lpm_par);
    view_nut = output.nut;
    ex       = view_nut==0;      %Voldoet aan risico en rendement restricties
    if sum(ex)>0
        view_wts = output.wts(:,ex);
        view_mu  = output.mu(:,ex);
        view_te  = output.sig(:,ex);
        view_nut = view_nut(:,ex);
    else
        view_wts = output.wts;
        view_mu  = output.mu;
        view_te  = output.sig;        
    end

    if min(size(view_wts))>0
        if Xsort==1
            [view_mu,six] = sort(view_mu,2,'descend');
            view_wts      = view_wts(:,six);
            view_te       = view_te(:,six);
        elseif Xsort==2
            [hulp,six] 	  = sort(view_te(1,:),2,'ascend');
            view_te       = view_te(:,six);
            view_wts      = view_wts(:,six);
            view_mu       = view_mu(:,six);
        elseif Xsort==3
            [hulp,six] 	  = sort(view_te(2,:),2,'ascend');
            view_te       = view_te(:,six);			
            view_wts      = view_wts(:,six);
            view_mu       = view_mu(:,six);
        else
            [hulp,six] 	  = sort(view_nut,2,'ascend');
            view_te       = view_te(:,six);			
            view_wts      = view_wts(:,six);
            view_mu       = view_mu(:,six);
        end
    else
        view_wts = 99*ones(Nassets,10);
        view_mu  = 99*ones(1,10);
        view_te  = 99*ones(1,10);
    end
    
    view(i).wts = view_wts;
    view(i).mu  = view_mu;
    view(i).te  = view_te;
   
    %Bepaal gewichten binnen return portefeuille
    hwts           = view_wts(ret_cats,:);
    retport(i).wts = matdiv(hwts,sum(hwts)+1e-16);
    
    %Bepaal nu de implied returns en de risicoaversie parameter per mix
    [ir,lambda] = ImpliedReturns_GivenMu(view_wts,pars,MinRet(i));
    
    view(i).ir = ir;
    view(i).lambda = lambda;    
end

for i=1:6
    if strcmp(doorrekenen(i),'Nee')
        i = i+1;
        continue;
    end

    pars.probs    = ScenarioKans;
    evaluation(i) = EvaluatePortfolios2BM(view(i).wts,pars,mpn,mpr,lpm_par); 
    
    %Vat gevonden mixen samen
    mix_mu   = mean(view(i).wts,2);
    mix_std  = std(view(i).wts,[],2); 
    mix_perc = quantile(view(i).wts',[0.25 0.5 0.75])'; 
    [mw,f_mix,r2_mix] = AnalyseWts(view(i).wts);
    f_mix    = matdiv(f_mix,max(abs(f_mix)));
    f_mix    = matmul(f_mix,max(f_mix)==1)-matmul(f_mix,min(f_mix)==-1);
    
    hulp  = [mix_mu mix_std mix_perc f_mix];
    mix_eval(:,:,i) = hulp;
    mix_r2(i,:)     = r2_mix;
    
    rmix_mu   = mean(retport(i).wts,2);
    rmix_std  = std(retport(i).wts,[],2); 
    rmix_perc = quantile(retport(i).wts',[0.25 0.5 0.75])'; 
    [rmw,rf_mix,rr2_mix] = AnalyseWts(retport(i).wts);
    rf_mix    = matdiv(rf_mix,max(abs(rf_mix)));
    rf_mix    = matmul(rf_mix,max(rf_mix)==1)-matmul(rf_mix,min(rf_mix)==-1);
    
    rhulp  = [rmix_mu rmix_std rmix_perc rf_mix];
    rmix_eval(:,:,i) = rhulp;
    rmix_r2(i,:)     = rr2_mix;

end

if strcmp(plot_r,'Ja') %Maak grafieken van de rendementsverdelingen
    rpdf = zeros(100,Nassets,rows(scen_names));
    xas  = zeros(100,Nassets,rows(scen_names));

    hulp = pars;
    for i=1:rows(scen_names)
        hulp.probs = ScenarioKans(i,:)';
        R = Mixture_Scenarios(hulp,100000);
        for j=1:Nassets
            h = R(:,j);
            h = h(abs(h)<=1);
            [f,xi] = ksdensity(h,'npoints',100,'support',[-1 1]); 
            rpdf(:,j,i) = f';
            xas(:,j,i) = xi';
        end
    end

    figure;
    n2 = floor(sqrt(Nassets+1));
    n1 = ceil(Nassets/n2);
    for i=1:Nassets
        subplot(n1,n2,i);
        plot(squeeze(xas(:,i,:)),squeeze(rpdf(:,i,:)),'LineWidth',2);   
        grid on;
        title(asset_names(i));
    end
    subplot(n1,n2,i+1);
    plot(repmat((1:Nassets)',1,Nassets),repmat((1:Nassets)',1,Nassets));
    title('Legenda');
    legend(scen_names);
    axis off;
end
