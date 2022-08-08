% This script compares the numerical and the analytical solution of entropy-pooling, see
% "A. Meucci - Fully Flexible Views: Theory and Practice -
% The Risk Magazine, October 2008, p 100-106"
% available at www.symmys.com > Research > Working Papers

% Code by A. Meucci, September 2008
% Last version available at www.symmys.com > Teaching > MATLAB

clear;  close all

% path
p = path
%path(p,'H:\Users\Bastiaan de Geeter\Development\Matlab\portfolio constructie\EntropyPooling\AnalyticalVsNumerical\')

path(p,'C:\Users\bgt\Documents\offline\Portfolio Constructie\Model Portefeuille\Black Litterman\Meucci\EntropyPooling\AnalyticalVsNumerical\');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % analytical representation
% N=2; % market dimension
% Mu=zeros(N,1);  % average returns = 0
% r=.6;
% Sigma=(1-r)*eye(N)+r*ones(N,N);
% 

inputFile = 'C:\Users\bgt\Documents\offline\Portfolio Constructie\new model\views_curr_v01.Juni2013.standaardVCM.xlsx'

[assetCl,assetCategorie,cur_weight,lowerBound,upperBound,lowerBsubPort,upperBsubPort,turnOver] = getCurPortfolio(inputFile);
noAssets = size(assetCl,1);

% get current views / scenarios
[~,viewNames,viewReturns,viewProb,viewStDev] = getCurViews(inputFile);

% get current VCM
[~,corr_curr,stdev_curr] = getCor(inputFile);

% Equilibrium Cov / weights
Sigma = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev

fixed_assets=[1 2];
fixed_ret=[0.0 0.03];
% Calculate equilibrium returns
[Mu, te]=detEQReturns(stdev_curr, corr_curr, cur_weight, fixed_assets, fixed_ret);








% numerical representation -> simulate paths 
J=100000;
p = ones(J,1)/J;
dd = mvnrnd(Mu,Sigma,J/2);
X=ones(J,1)*Mu'+[dd;-dd];


tst_Mu_paths = mean(X)-Mu';
tst_corr = corr(X) ./ corr_curr;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% views
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tau=0.4;

%tau=1.0;

c=1.0;


% "full view" -> voor elke asset class
% % location
Q=eye(noAssets);            % "visie", 1 vaste return schatting per asset
Mu_Q=viewReturns(:,1);      % return 

% scatter -> geen view op covariantie
G=eye(noAssets);
% Sigma_G=Sigma;

Sigma_G= (1/c)* Q * Sigma * Q';

% "single view" -> voor eenasset class
% location

% posViews = eye(noAssets);  
% 
% viewOnAsset = 4;
% 
% Q= posViews(viewOnAsset,:)         % "visie", 1 vaste return schatting per asset
% Mu_Q=viewReturns(viewOnAsset,1);      % return 

% scatter -> geen view op covariantie
% CovViews=eye(noAssets);
% G=CovViews(viewOnAsset,:) 
% 
% Sigma_G=Sigma(viewOnAsset,viewOnAsset) ;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  posterior 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% analytical posterior
[Mu_s, Sigma_s]=Prior2Posterior(Mu,Q,Mu_Q,Sigma,G,Sigma_G);



% numerical posterior
Aeq = ones(1,J);  % constrain probabilities to sum to one...
beq=1;

QX = X*Q';
Aeq = [Aeq   % ...constrain the first moments...
    QX'];
beq=[beq
    Mu_Q];

SecMom=G*Mu_s*Mu_s'*G'+Sigma_G;  % ...constrain the second moments...
GX = X*G';
for k=1:size(G,1)
    for l=k:size(G,1)
        Aeq = [Aeq
            (GX(:,k).*GX(:,l))'];
        beq=[beq
            SecMom(k,l)];
    end
end
tic
p_ = EntropyProg(p,[],[],Aeq ,beq); % ...compute posterior probabilities
toc
PlotDistributions(X,p,Mu,Sigma,p_,Mu_s,Sigma_s,assetCl)

pause()
% Naiv calculation:

%Mu_naiv = Mu+((Mu_s(viewOnAsset) - Mu(viewOnAsset))/stdev_curr(viewOnAsset))*stdev_curr;




% posterior:
% form (15) / (16)-> 


Ohm= (1/c)* Q * Sigma * Q';

A = tau * Sigma;
B = Q'* (Ohm\Q);

C = Q'* (Ohm\Mu_Q);
E = Sigma*Q';
D = Q*E;


%
% Meucci --> full confidence posterior
% (27) & (28)


Mu_BL_full_conf_s = Mu + E/D*(Mu_Q-Q*Mu);
Sig_BL_full_conf_s = (1+tau)*Sigma-tau*E/D*E';





%   Meucci -->
%   form 19 / 20




Mu_BL_s = Mu+A*Q'*((tau*D+Ohm)\(Mu_Q-Q*Mu)); % check --> implementatie (15) / (19) agree
Sig_BL_pos_s = (1+tau)*Sigma-((tau*tau)*Sigma*Q'/(tau*D+Ohm))*Q*Sigma;  % check --> implementatie (18) / (20) agree



%
%   VIEW op Market ipv. mu (zie pg. 7.)
% 	(31) & (32)


 
Mu_BL_meucci_market = Mu + E/(D+Ohm)*(Mu_Q-Q*Mu);
Sig_BL_meucci_market = Sigma-E/(D+Ohm)*E';


% impl prob:
Cimp = (Mu_BL_s-Mu)./(Mu_s - Mu); %see 23, Meucci, full flexible views



% PURPOSE: Get first two moments from mixture distribution
%---------------------------------------------------
% USAGE: [mu,sig] = MixMoments(pars)
% where: pars is a structure with
%			meanmat: NxK matrix with mean vectors (columnwise)
%			covmat:  NxNxK array with covariance matrices 
%			probs:	 Kx1 vector with probabilities per regime


pars.meanmat=[Mu_s Mu];
pars.covmat(:,:,1)=Sig_BL_full_conf_s
pars.covmat(:,:,2)=Sigma;
pars.probs=[Cimp(1) (1-Cimp(1))];





[mu,sig] = Mixture_Moments(pars);



%   Ohm -> 0 levert zelfde als full confidence (?)

Ohm= 0;
tau=0.4;

A = tau * Sigma;
B = Q'* (Ohm\Q);

C = Q'* (Ohm\Mu_Q);
E = Sigma*Q';
D = Q*E;



%   Meucci -->
%   form 19 / 20
%   Ohm -> 0 levert zelfde als full confidence.



mu_BL_chk_Ohm0_s = Mu+A*Q'*((tau*D+Ohm)\(Mu_Q-Q*Mu)); % check --> implementatie (15) / (19) agree
Sig_BL_pos_chk_Ohm0_s = (1+tau)*Sigma-((tau*tau)*Sigma*Q'/(tau*D+Ohm))*Q*Sigma;  % check --> implementatie (18) / (20) agree



%
%   VIEW op Market ipv. mu (zie pg. 7.)
% 	(31) & (32)



Mu_BL_meucci_market = Mu + E/(D+Ohm)*(Mu_Q-Q*Mu);
Sig_BL_meucci_market = Sigma-E/(D+Ohm)*E';


% 
% 
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % prior
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % analytical representation
% N=2; % market dimension
% Mu=zeros(N,1);  % average returns = 0
% r=.6;
% Sigma=(1-r)*eye(N)+r*ones(N,N);
% 
% % numerical representation
% J=100000;
% p = ones(J,1)/J;
% dd = mvnrnd(zeros(N,1),Sigma,J/2);
% X=ones(J,1)*Mu'+[dd;-dd];
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % views
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % location
% Q=[1 -1];
% Mu_Q=.5;
% 
% % scatter
% G=[-1 1];
% Sigma_G=.5^2;
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %  posterior 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % analytical posterior
% [Mu_2, Sigma_2]=Prior2Posterior(Mu,Q,Mu_Q,Sigma,G,Sigma_G);
% 
% 
% 
% 
% % posterior:
% % form (15) / (16)-> 
% 
% 
% Ohm= (1/c)* Q * Sigma * Q';
% Ohm=0
% 
% A = tau * Sigma;
% B = Q'* (Ohm\Q);
% 
% C = Q'* (Ohm\Mu_Q);
% E = Sigma*Q';
% D = Q*E;
% 
% 
% %
% % Meucci --> full confidence posterior
% % (27) & (28)
% 
% 
% mu_BL_full_conf2 = Mu + E/D*(Mu_Q-Q*Mu);
% Sig_BL_full_conf2 = (1+tau)*Sigma-tau*E/D*E';
% 
% 
% 
% 
% 
% %   Meucci -->
% %   form 19 / 20
% %   Ohm -> 0 levert zelfde als full confidence.
% 
% 
% 
% mu_BL2 = Mu+A*Q'*((tau*D+Ohm)\(Mu_Q-Q*Mu)); % check --> implementatie (15) / (19) agree
% Sig_BL_pos2 = (1+tau)*Sigma-((tau*tau)*Sigma*Q'/(tau*D+Ohm))*Q*Sigma;  % check --> implementatie (18) / (20) agree
% 
% 
% 
% 


% numerical posterior
% Aeq = ones(1,J);  % constrain probabilities to sum to one...
% beq=1;
% 
% QX = X*Q';
% Aeq = [Aeq   % ...constrain the first moments...
%     QX'];
% beq=[beq
%     Mu_Q];
% 
% SecMom=G*Mu_*Mu_'*G'+Sigma_G;  % ...constrain the second moments...
% GX = X*G';
% for k=1:size(G,1)
%     for l=k:size(G,1)
%         Aeq = [Aeq
%             (GX(:,k).*GX(:,l))'];
%         beq=[beq
%             SecMom(k,l)];
%     end
% end
% tic
% p_ = EntropyProg(p,[],[],Aeq ,beq); % ...compute posterior probabilities
% toc
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % plots
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PlotDistributions(X,p,Mu,Sigma,p_,Mu_,Sigma_)