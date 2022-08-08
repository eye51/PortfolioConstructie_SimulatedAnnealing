
function [mu_BL_pos,Sig_BL_pos,mu_BL_full_conf,Sig_BL_full_conf]=BL_classic(return_est,cov_est,pi_equi,tau,P,Ohm)
% Black Litterman
%   
%   mu_BL_pos = posterior return estimates
%   Sig_BL_pos = posterior covariance matrix

% posterior:
    
    A = tau * cov_est;
    % B = P'* (Ohm\P);

    % C = P'* (Ohm\v);
    E = cov_est*P';
    D = P*E;


    %   Meucci -->
    %   form 19 / 20
    % 


    mu_BL_pos = pi_equi+A*P'*((tau*D+Ohm)\(return_est-P*pi_equi)); % check --> implementatie (15) / (19) agree
    Sig_BL_pos = (1+tau)*cov_est-((tau*tau)*cov_est*P'/(tau*D+Ohm))*P*cov_est;  % check --> implementatie (18) / (20) agree



    %
    % Meucci --> full confidence posterior
    % (27) & (28)


    mu_BL_full_conf = pi_equi + E/D*(return_est-P*pi_equi);
    Sig_BL_full_conf = (1+tau)*cov_est-tau*E/D*E';


end
    

