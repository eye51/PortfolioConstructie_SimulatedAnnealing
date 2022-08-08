    function Ohm= BLViewMeucci(corr_curr,stdev_curr,C,P);
    %   setup onzekerheids functie op BL-Views
    %   methode Meuci -> gebasseerd op standaard deviaties / correlatie vd assets


    
        cov_est = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev
        Ohm= (1/C)* P * cov_est * P';

    end
