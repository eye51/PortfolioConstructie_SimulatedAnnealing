function [output] = EvaluatePortfolios_Scen(wt,Rscen,pars,lpm_par)

[N,K,S] = size(Rscen);

%Calculate mu and sigma per scenario
for i=1:S
    R = Rscen(:,3:end,i);
    if pars.bm_er>0
        ER = matsub(R,Rscen(:,pars.bm_er,i));
    else
        ER = R;
    end
    if pars.bm_te1>0
        TE1 = matsub(R,Rscen(:,pars.bm_te1,i));
    else
        TE1 = R;
    end
    if pars.bm_te2>0
        TE2 = matsub(R,Rscen(:,pars.bm_te2,i));
    else
        TE2 = R;
    end

    output.mu(:,i)           = mean(ER*wt)';
    output.te1(:,i)          = std_alt(TE1*wt)';
	output.te2(:,i)          = std_alt(TE2*wt)';
    output.lpm(:,i)          = Scenario_LPM(ER*wt,lpm_par.order,lpm_par.target);
    output.totaal(:,i,:)     = [output.mu(:,i) output.te1(:,i) output.te2(:,i) output.lpm(:,i)]';
    output.scenarios(:,:,i)  = ER*wt;
    output.scenariosVPV(:,i) = Rscen(:,pars.bm_er,i);
end

end

