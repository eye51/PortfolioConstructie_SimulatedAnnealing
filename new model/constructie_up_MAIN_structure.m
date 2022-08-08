%
%
%

% first clear/close everything
function constructie_up_MAIN_structure()

close all hidden;
%clear all;
clc;


% flag voor productie / experimenteel

productieVersie=false;


% set up main layout -> window with tabs
mainW = figure( 'Name', 'Constructie v0.1', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'NumberTitle', 'off');


scrsz = get(0,'ScreenSize');

set(mainW,'Position',[scrsz(3)/8 100 3*scrsz(3)/4 scrsz(4)-150])

tabpanel = uiextras.TabPanel( 'Parent', ...
    mainW, ...
    'Padding', 0);


%% read current portfolio data..

%
% get asset classes -> current weighting
%
%inputFile = 'views_curr.Bp2014_finalv1.Mitt.VCM_4yr.5-Sept.updatBaseCase.xlsx'
%inputFile = 'views_curr.Bp2014_finalv1.MN.VCM_4yr.5-Sept.updatBaseCase.xlsx'
inputFile = 'views_curr.Bp2014.PME.VCM_4yr.xlsx'

%inputFile = 'views_curr.tst_equi.xlsx'
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



if (sum(strcmp('extra restricties',sheets) > 0))
% get extra restrictions
    [restrictionNR assetClsER lowerBoundER upperBoundER  groupLowerBound groupUpperBound groupLimitActive] = getExtraRestrictions(inputFile);
else
    restrictionNR=[];
    assetClsER =[];
    lowerBoundER =[];
    upperBoundER  =[];
    groupLowerBound =[];
    groupUpperBound =[];
    groupLimitActive=[];
end



% % determine risk contribution for each asset
% [volConCurrent] = volContribution (cur_weight, corr_curr, stdev_curr);
% 
% volPortCurrent = portfolioVol (cur_weight, corr_curr, stdev_curr);

tabNR=0;





%%
% Views panel --> 1e tab
%

tabNR=tabNR+1;                  % om toevoegen tabs flexibel te maken
tabName{tabNR} = 'Views';       %


global ViewsSetupTable;
global ViewsProbabilityTable;
global BLViewReturns;
global BLViewUncertainty;
global BLCorrTable;
global equilibriumTable;
global portConsTable;


tables = [ViewsSetupTable ViewsProbabilityTable BLViewReturns BLViewUncertainty BLCorrTable equilibriumTable portConsTable];
viewsTAB( tabpanel, tables , assetCl, viewNames, viewReturns, viewProb, viewStDev);



%%
% Evenwichts situatie
%

tabNR=tabNR+1;
tabName{tabNR} = 'Equilibrium';


evenwichtsTAB( tabpanel, assetCl, corr_curr, stdev_curr,corNames, assetCategorie, cur_weight, lowerBound, upperBound, lowerBsubPort, upperBsubPort, turnOver,productieVersie);


%%
% Black Litterman overzicht
%

tabNR=tabNR+1;
tabName{tabNR} = 'BL instellingen';


BlackLittermanTAB(tabpanel, assetCl, corr_curr, stdev_curr,corNames, viewNames, viewReturns, assetCategorie,productieVersie);


%%
%
%
tabNR=tabNR+1;
tabName{tabNR} = 'Rb instellingen';

riskbudgettingTAB( tabpanel, assetCl,assetCategorie,cur_weight, corr_curr, stdev_curr,corNames, viewNames, viewReturns,productieVersie)

%%
%   New file / update tables tab
%

% tabNR=tabNR+1;
% tabName{tabNR} = 'New File';
% 
% readNew (tabpanel, assetCl, corr_curr, stdev_curr, viewNames, viewReturns, assetCategorie);


%%  -------------------------------------------------------------------------------
%   results page / Portfolio Contructiion
%   -------------------------------------------------------------------------------

tabNR=tabNR+1;
tabName{tabNR} = 'Construction';


constructionTAB(tabpanel, assetCl, corr_curr, stdev_curr,corNames, viewNames, assetCategorie, cur_weight, lowerBound, upperBound, lowerBsubPort, upperBsubPort, turnOver,restrictionNR, assetClsER, lowerBoundER, upperBoundER,groupLowerBound,groupUpperBound,groupLimitActive,productieVersie) 




%% Update the tab titles
tabpanel.TabNames = tabName;
tabpanel.TabSize = 150;

%% Show the first tab
tabpanel.SelectedChild = 1;


end
