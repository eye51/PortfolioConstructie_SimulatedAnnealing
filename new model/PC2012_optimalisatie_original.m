close all;

% Nassets = 8;


ret_cats = InPortefeuille==2;

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

%Pas scenariokansen aan
for i=1:scenarios
    p = ScenarioKans(i,:);
    if sum(p)>1
        p(2:end) = p(2:end)*(1-p(1));
    end
    ScenarioKans(i,:) = p;
end

for i=1:scenarios
    if strcmp(doorrekenen(i),'Nee')
        i = i+1;
        continue;
    end
	stream = RandStream('mt19937ar','seed',20111008); 
	RandStream.setDefaultStream(stream);
	
    Restricties.MinRet = MinRet(i);
    Restricties.MaxTE  = MaxTE(i);
    Restricties.MinRet_actief = MinRet_actief(i);
    Restricties.MaxTE_actief = MaxTE_actief(i);
    Restricties.MaxLPM  = MaxLPM(i);
    Restricties.MaxLPM_actief = MaxLPM_actief(i);
    Restricties.A = A;
    Restricties.b = b;
    Restricties.w0 = w_t0;
    Restricties.dw0 = Rest_turnover;
    Restricties.Ax = Rest_extra_A;
    Restricties.bx = Rest_extra_b;
    Restricties.onx = Rest_extra;

    pars.probs = ScenarioKans(i,:)'; 
    pars.bm    = bm_nr;
	pars.lpm_target = lpm_target;
	pars.lpm_orde   = lpm_orde;
       
    output   = PortefeuilleOptimalisatie(doelstelling(i),pars,Restricties,Niter,Nport,scen_names(i));
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

    view(i).wts = view_wts;
    view(i).mu  = view_mu;
    view(i).te  = view_te;
   
    %Bepaal gewichten binnen return portefeuille
    hwts           = view_wts(ret_cats,:);
    retport(i).wts = matdiv(hwts,sum(hwts)+1e-16);    
end

for i=1:scenarios
    if strcmp(doorrekenen(i),'Nee')
        i = i+1;
        continue;
    end

    %Vat gevonden mixen samen
    mix_mu   = mean(retport(i).wts,2);
    mix_std  = std(retport(i).wts,[],2); 
    mix_perc = quantile(retport(i).wts',[0.16 0.5 0.84])'; 
    [mw,f_mix,r2_mix] = AnalyseWts(retport(i).wts);
    f_mix    = matdiv(f_mix,max(abs(f_mix)));
    f_mix    = matmul(f_mix,max(f_mix)==1)-matmul(f_mix,min(f_mix)==-1);
    
    hulp = [mix_mu mix_std mix_perc f_mix];
    rmix_eval(:,:,i) = hulp;
    rmix_r2(i,:)     = r2_mix;
    
    %Binnen return portefeuille
    mix_mu   = mean(view(i).wts,2);
    mix_std  = std(view(i).wts,[],2); 
    mix_perc = quantile(view(i).wts',[0.25 0.5 0.75])'; 
    [mw,f_mix,r2_mix] = AnalyseWts(view(i).wts);
    f_mix    = matdiv(f_mix,max(abs(f_mix)));
    f_mix    = matmul(f_mix,max(f_mix)==1)-matmul(f_mix,min(f_mix)==-1);
    
    hulp  = [mix_mu mix_std mix_perc f_mix];
    mix_eval(:,:,i) = hulp;
    mix_r2(i,:)     = r2_mix;
end

if strcmp(show_plot,'Ja')
    figure('Units','normalized','Position',[0.05 0.5 0.4 0.4]);
    plot(100*view(scenarios).te,100*view(scenarios).mu,'or','LineWidth',3);
%     plot(100*view(6).te,100*view(6).mu,'or','LineWidth',3);

    grid on;
    axis tight;
    %xlim([6 7.1]);
    %ylim([0.6 0.8]);
    xlabel('Tracking error (%)','FontSize',20);
    ylabel('Verwacht overrendement (%)','FontSize',20);
    set(gca,'FontSize',18);
end
