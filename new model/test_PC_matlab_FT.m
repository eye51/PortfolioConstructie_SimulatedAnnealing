
inputFile = 'views_curr.tst_equi.xlsx'
%
%inputFile = 'views_curr.Bp2014.koopvaardij.MN.VCM_4yr.xlsx'
%inputFile = 'views_curr.Bp2014_finalv1.MN.VCM_4yr.5-Sept.updatBaseCase.xlsx'
% first determine which inputs are given in file:



[~,sheets,~] = xlsfinfo(inputFile);

[assetCl assetCategorie cur_weight lowerBound upperBound lowerBsubPort upperBsubPort turnOver] = getCurPortfolio(inputFile);

% get current views / scenarios
[~,viewNames,viewReturns,viewProb,viewStDev] = getCurViews(inputFile);

% get current VCM
[ ~,corr_curr, stdev_curr,corNames] = getCor(inputFile);

port_setup=Portfolio ('Name','tst_PC');
port_setup=port_setup.setBounds(lowerBound,upperBound);



targetTE=0.0971051174698195;


return_est=viewReturns(:,end);
cov_est = corr_curr{1}.*(stdev_curr{1}*stdev_curr{1}'); % calculate cov. from correlation / st.dev


    
port_setup=port_setup.setAssetList (assetCl);
port_setup=port_setup.setAssetMoments(return_est,cov_est);

% port_setup = port_setup.setDefaultConstraints;


% port_restrictions = portcons('AssetLims',lowerBound,upperBound);

bwgt = port_setup.estimateFrontierByRisk(targetTE)

[PortRisk, PortReturn] = portstats(return_est', cov_est,bwgt')
% pwgt = p.estimateFrontier(20);
% [prsk, pret] = p.estimatePortMoments(pwgt);
