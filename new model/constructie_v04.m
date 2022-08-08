%
%
%

% first clear/close everything
function portfolioConstrMain()

close all hidden;
%clear all;
clc;




% set up main layout -> window with tabs
mainW = figure( 'Name', 'Constructie v0.1', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'NumberTitle', 'off');

cmap = colormap;

scrsz = get(0,'ScreenSize');

set(mainW,'Position',[scrsz(3)/8 100 3*scrsz(3)/4 scrsz(4)-150])

tabpanel = uiextras.TabPanel( 'Parent', ...
    mainW, ...
    'Padding', 0);


%% read current portfolio data..

%
% get asset classes -> current weighting
%

%inputFile = 'views_curr_v01.xlsx' 
inputFile = 'views_Unisys_reduced.xlsx' 

[assetCl assetCategorie cur_weight lowerBound upperBound lowerBsubPort upperBsubPort turnOver] = getCurPortfolio(inputFile);
noAssets = size(assetCl,1);

% get current views / scenarios
[~,viewNames,viewReturns,viewProb,viewStDev] = getCurViews(inputFile);
noViews = size(viewNames,2);
viewCalc=false(1,noViews);      % logical om aan tegeven welke views doorgerekend moeten worden
viewCalc(1)=true;               % 1e view is 'Base-Case'



% get current VCM
[ ~,corr_curr, stdev_curr] = getCor(inputFile);



% determine risk contribution for each asset
[volConCurrent] = volContribution (cur_weight, corr_curr, stdev_curr);

volPortCurrent = portfolioVol (cur_weight, corr_curr, stdev_curr);

tabNR=0;



%%
% Views panel --> 1e tab
%

tabNR=tabNR+1;                  % om toevoegen tabs flexibel te maken
tabName{tabNR} = 'Views';       %


% hoofd layout van de tab:
viewsLayout = uiextras.VBoxFlex('Parent',tabpanel); 
views = [assetCl num2cell(viewReturns)];

%
%   Details of the views 
%

% first table format / layout:
columnname = cell(1,noViews+1);
columnname{1}='<html><b>AssetClass';

columneditable=true(1,noViews+1);

for kk=1:noViews
    columnname(1+kk)=cellstr(strcat('<html><b>',viewNames(kk)));
end
    
colwith = cell(1,noViews+1);
colwith{1} = 150;
colwith(2:end) = num2cell(150);
 

ViewsSetupTable = uitable('Parent',viewsLayout,...
            'Data', views,... 
            'ColumnName', columnname,...
            'RowName',[],...
            'ColumnWidth',colwith,...
            'ColumnEditable',columneditable,...
            'BackgroundColor',[1 1 1]);


        
%        
% second table format / layout   
%


rowNames = cell(2,1);
rowNames{1}='Probability';
rowNames{2}='St. Dev. View';
rowNames{3}='Calculate';

%rowformat = {'bank', 'bank', 'logical'};

viewProbStDev =  [viewProb;viewStDev;viewCalc];
viewProbStDev =  [rowNames num2cell(viewProbStDev)];


ViewsProbabilityTable = uitable('Parent',viewsLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', viewProbStDev,... 
            'ColumnName', columnname,...
            'RowName',[],...
            'ColumnWidth',colwith,...  
            'ColumnEditable',columneditable,...            
            'BackgroundColor',[1 1 1]);


%
% panel with graphs
%

barChartLayout = uiextras.HBox('Parent',viewsLayout,'Spacing',10);


uiextras.Empty('Parent',barChartLayout);

colW=ones(1,noViews+1)*140;
for kk=1:noViews

    barCH(kk) = axes ('Parent', barChartLayout,'Position',[1 1 140 200]);
    barh(barCH(kk),viewReturns(:,kk));

%    colW=[colW 140];
end



set(barCH(2:end), 'YTick', []);
set(barCH(1),'YTickLabel',assetCl);



set( barChartLayout, 'Sizes', colW);

% panel with buttons(?)        
viewButtonPanel = uiextras.Panel( 'Parent', viewsLayout, 'Padding', 5);        

b = uiextras.HButtonBox( 'Parent', viewButtonPanel );
uicontrol( 'Parent', b, 'String', 'One' );
uicontrol( 'Parent', b, 'String', 'Two' );
uicontrol( 'Parent', b, 'String', 'Three' );
set( b, 'ButtonSize', [130 35], 'Spacing', 5, 'HorizontalAlignment','left' );



%
set( viewsLayout, 'Sizes', [-1 100 -1 50]);


%%
% Evenwichts situatie
%
tabNR=tabNR+1;
tabName{tabNR} = 'Equilibrium';

equilibriumLayout = uiextras.VBox('Parent',tabpanel);


%
% table met huidige gewichten en restricties:
%

columnname =   {'<html><b>AssetClass', '<html><b>Equilibrium Weight', '<html><b>Lower Limit', '<html><b>Upper Limit', '<html><b>Equilibrium Returns', '<html><b>Equilibrium IR', '<html><b>Eq. Ret (based on IR)', '<html><b>Equilibrium IR'};
columnformat = {'char', 'short', 'short', 'short', 'short'};
columneditable =  [false true false false true true true true]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1:end) = num2cell(150);

currentEqui = [assetCl num2cell(cur_weight) num2cell(lowerBound) num2cell(upperBound) num2cell(zeros(noAssets,1)) num2cell(zeros(noAssets,1)) num2cell(zeros(noAssets,1)) num2cell([0;0.16*ones(noAssets-1,1)])];

htab4_table = uitable('Parent',equilibriumLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', currentEqui,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);

        
        
%
% table met huidige correlatie:
%

% --> ??

%
% table met fixed asset returns
%

columnname =   {'<html><b>AssetClass Fixed', '<html><b>Return Fixed','<html><b>IR (Implied)'};
columnformat = {assetCl', 'bank'};
columneditable =  [true true]; 

fixedAsset = [1 2];
fixedRet = [0 0.03];

FixedEqui = [assetCl(fixedAsset) num2cell(fixedRet') num2cell(fixedRet'./stdev_curr(fixedAsset))];

equilibriumFixedTable = uitable('Parent',equilibriumLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', FixedEqui,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',{150 150},...
            'BackgroundColor',[1 1 1],...            
            'RowName',[]);


%        
% panel with restrictions / conditions
%

equilibriumGrid = uiextras.Grid( 'Parent', equilibriumLayout, 'Spacing', 5 );

uicontrol('Parent',equilibriumGrid,'Style','text','String','TE','HorizontalAlignment','left');
uiextras.Empty( 'Parent', equilibriumGrid );
uicontrol('Parent',equilibriumGrid,'Style','text','String','Use restrictions ','HorizontalAlignment','left');

TE_text=uicontrol('Parent',equilibriumGrid,'Style','text','BackgroundColor',[1 1 1],'String',volPortCurrent);
uiextras.Empty( 'Parent', equilibriumGrid );
regionBox = uicontrol('Parent',equilibriumGrid,'Style','checkbox');
% uicontrol( 'Parent', equilibriumGrid, 'String', 'Update Table','Callback', @updatePoolTable);

set( equilibriumGrid, 'ColumnSizes', [100 100], 'RowSizes', [20 20 20]);


%
% bar-graphs
%

%
%   Weights
%

% TODO : tijdelijk gedelete -> ook als losse graphs?

equilibriumGrphV = uiextras.VBox( 'Parent', equilibriumLayout, 'Spacing', 20 );
uiextras.Empty( 'Parent', equilibriumGrphV );

equilibriumGrph = uiextras.HBox( 'Parent', equilibriumGrphV,'Padding',5);

uiextras.Empty( 'Parent', equilibriumGrph );

eqWeightGrap = axes('Parent', equilibriumGrph); %
barh(eqWeightGrap,cur_weight);
set(eqWeightGrap,'YTickLabel',assetCl);
set(eqWeightGrap,'XGrid','on');
colormap(eqWeightGrap,cmap);
%set(eqWeightGrap,'XAxisLocation','top')
%xticklabel_rotate(eqWeightGrap,45)


%
%   TE / contribution to TE
%



volConNormalized = volConCurrent/sum(volConCurrent);    % nromalize for pie chart
volContrChart = axes ('Parent', equilibriumGrph);

%explode = [1 0 0 0 0 0 0 0]; % hardcoded! -> 8 asset classes, 1e is norminal matching
explode=zeros(1,noAssets);
explode(1)=1;
pie(volContrChart, volConNormalized,explode, assetCl);



uiextras.Empty( 'Parent', equilibriumGrphV );
set(equilibriumGrph,'Sizes',[5 -1 -1]);
set(equilibriumGrphV,'Sizes',[1 -1 1]);


%
% panel with buttons(?)       
%

equilibriumButtonPanel = uiextras.Panel( 'Parent', equilibriumLayout, 'Padding', 5);        

equiBut = uiextras.HButtonBox( 'Parent', equilibriumButtonPanel );
uicontrol( 'Parent', equiBut, 'String', 'Calc Eq. returns' ,'Callback',@calc_eq_returns);
uicontrol( 'Parent', equiBut, 'String', 'Graph 1','Callback',@ret_graph_eq );
uicontrol( 'Parent', equiBut, 'String', 'TE Graph','Callback',@TE_graph_eq );
set( equiBut, 'ButtonSize', [130 35], 'Spacing', 5, 'HorizontalAlignment','left' );


set( equilibriumLayout, 'Sizes', [-1 75 75 -1 50]);


%%  -------------------------------------------------------------------------------
%   results page / Portfolio Contructiion
%   -------------------------------------------------------------------------------
tabNR=tabNR+1;
tabName{tabNR} = 'Construction';


constructionLayout = uiextras.VBox('Parent',tabpanel,'Padding',10);

%   ----------------------------------------
%   Porfolio Constuction -> top panel
%   kiezen view, optimazation target etc
%   ----------------------------------------

filterGrid = uiextras.Grid( 'Parent', constructionLayout, 'Spacing', 5 );

% Select View for portfolio optimalization
uicontrol('Parent',filterGrid,'Style','text','String','Select View','HorizontalAlignment','left');
viewCnstrBox = uicontrol('Parent',filterGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',[viewNames 'Equilibrium']);
uiextras.Empty( 'Parent', filterGrid );
uicontrol( 'Parent', filterGrid, 'String', 'Update Table','Callback', @updateConstructionTable);


uicontrol('Parent',filterGrid,'Style','text','String','Select Target','HorizontalAlignment','left');
targetCnstrBox = uicontrol('Parent',filterGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',{'Maxt Return' 'Min TE' 'Min LPM<not implemented'});
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
%
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );

% use restrictie
uiextras.Empty( 'Parent', filterGrid );
uicontrol('Parent',filterGrid,'Style','text','String','Use Restrictions','HorizontalAlignment','left');
uicontrol('Parent',filterGrid,'Style','text','String','Target TE','HorizontalAlignment','left');
uiextras.Empty( 'Parent', filterGrid );


uiextras.Empty( 'Parent', filterGrid );
constUseRestr = uicontrol('Parent',filterGrid,'Style','checkbox');
constUseTE = uicontrol('Parent',filterGrid,'Style','checkbox','value',true);
uiextras.Empty( 'Parent', filterGrid );


uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
constTargetTE = uicontrol('Parent',filterGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.10);
uiextras.Empty( 'Parent', filterGrid );

uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );

% CHOOSE No interations / No portfolios Simulated Annealing
uiextras.Empty( 'Parent', filterGrid );
uicontrol('Parent',filterGrid,'Style','text','String','No. Iter','HorizontalAlignment','left');
uicontrol('Parent',filterGrid,'Style','text','String','No. Port','HorizontalAlignment','left');
uiextras.Empty( 'Parent', filterGrid );


uiextras.Empty( 'Parent', filterGrid );
constNIter= uicontrol('Parent',filterGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',500);
constNPort = uicontrol('Parent',filterGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',500);
uiextras.Empty( 'Parent', filterGrid );

set( filterGrid, 'ColumnSizes', [100 100 200 100 20 100 200 100 100], 'RowSizes', [20 20 20 20] );

sizePanels=100;

%   ----------------------------------------
%
% table met weight restricties:
%
%   ----------------------------------------

columnname =   {'<html><b>AssetClass','<html><b>Asset Categorie', '<html><b>Lower Limit', '<html><b>Upper Limit','<html><b>Low.Lim.Sub', '<html><b>Up.Lim.Sub','<html><b>Target TE Contrib (Rel)', '<html><b>View Returns'};
columnformat = {'char',{'Matching portefeuille' 'Return portefeuille'}, 'short', 'short', 'short','short', 'short', 'short'};
columneditable =  [false true true true true true true true]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1:2) = num2cell(150);
colwith(3:end) = num2cell(75);

assetRestRet = [assetCl assetCategorie num2cell(lowerBound) num2cell(upperBound) num2cell(lowerBsubPort) num2cell(upperBsubPort) num2cell(zeros(noAssets,1))];

constrRestr = uitable('Parent',constructionLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', assetRestRet,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        
sizePanels=[sizePanels -1];   



%   ----------------------------------------
% Portfolio Constructie tab:
% buttons for construction method
%
%   ----------------------------------------


constrGraphButtonGrid = uiextras.Grid( 'Parent', constructionLayout, 'Spacing', 5 );

uicontrol( 'Parent', constrGraphButtonGrid, 'String', 'Pie Weights','Callback', @pieChartWeights);

uicontrol( 'Parent', constrGraphButtonGrid, 'String', 'Pie TE contribution','Callback', @pieChartTEContribution);
uicontrol( 'Parent', constrGraphButtonGrid, 'String', 'Bar Weights','Callback', @barChartWeigths);
uicontrol( 'Parent', constrGraphButtonGrid, 'String', 'Bar TE contribution','Callback', @barChartTEContribution);



set( constrGraphButtonGrid, 'ColumnSizes', [100 100 100 100 100], 'RowSizes', [20] );

sizePanels=[sizePanels 40];

%   ----------------------------------------
% Portfolio Constructie tab: 
% Na optimalisatie table met berekende gewichten:
%
%   ----------------------------------------

columnname =   {'<html><b>AssetClass','<html><b>Equilibrium Weight','<html><b>Eq. TE Con (Abs)','<html><b>Eq. TE Con (Rel)', '<html><b>Optimal Weight','<html><b>Opt. TE Con (Abs)','<html><b>Opt. TE Con (Rel)', '<html><b>Difference'};
columnformat = {'char', 'short', 'short', 'short'};
columneditable =  [false false false false]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1) = num2cell(150);
colwith(2:end) = num2cell(75);

assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight;sum(cur_weight)]) ...
    num2cell([volConCurrent';sum(volConCurrent)]) num2cell([volConCurrent'/sum(volConCurrent);1]) ...
    num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1))];


portConsTable = uitable('Parent',constructionLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', assetWeights,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        
sizePanels=[sizePanels -1];   

% Portfolio Constructie tab:
% buttons for construction method
%

constrButtonGrid = uiextras.Grid( 'Parent', constructionLayout, 'Spacing', 5 );

uicontrol( 'Parent', constrButtonGrid, 'String', 'Markowitz','Callback', @ConstructionMarkowitz);
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );

uicontrol( 'Parent', constrButtonGrid, 'String', 'Black Litterman 1','Callback', @ConstructionBL);
uiextras.Empty( 'Parent', constrButtonGrid );
uicontrol('Parent',constrButtonGrid,'Style','text','String','min TE','HorizontalAlignment','left');
uicontrol('Parent',constrButtonGrid,'Style','text','String','max TE','HorizontalAlignment','left');
uiextras.Empty( 'Parent', constrButtonGrid );

uicontrol( 'Parent', constrButtonGrid, 'String', 'Markowitz TE','Callback', @ConstructionMWTERange);
uicontrol( 'Parent', constrButtonGrid, 'String', 'Black Litterman TE','Callback', @ConstructionBLTERange);
constMinTERange = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.00);
constMaxTERange = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.20);
uiextras.Empty( 'Parent', constrButtonGrid );


uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uicontrol('Parent',constrButtonGrid,'Style','text','String','Asset','HorizontalAlignment','left');
uicontrol('Parent',constrButtonGrid,'Style','text','String','min Return','HorizontalAlignment','left');
uicontrol('Parent',constrButtonGrid,'Style','text','String','max Return','HorizontalAlignment','left');



uicontrol( 'Parent', constrButtonGrid, 'String', 'MW return range','Callback', @ConstructionReturnRangeMW);
uicontrol( 'Parent', constrButtonGrid, 'String', 'BL return range','Callback', @ConstructionReturnRangeBL);
AssetCnstrBox = uicontrol('Parent',constrButtonGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',assetCl,'Callback',@updateAssetRange);
constMinReturn = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.00);
constMaxReturn = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.20);


uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );

uicontrol( 'Parent', constrButtonGrid, 'String', 'copy weights to equilibrium','Callback', @CopyConstructionWeightsToEqui);
uicontrol( 'Parent', constrButtonGrid, 'String', 'Risk-Parity','Callback', @SetUpRiskParity);
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uicontrol( 'Parent', constrButtonGrid, 'String', 'Markow. Risk-Target','Callback', @MWRiskTarget);

set( constrButtonGrid, 'ColumnSizes', [100 100 100 120 100 200 100], 'RowSizes', [20 20 20 20 20] );

sizePanels=[sizePanels 120];

set( constructionLayout, 'Sizes', sizePanels);


% set Base-Case as selection:
updateConstructionTable(0, 0)

%%
% Black Litterman overzicht
%

tabNR=tabNR+1;
tabName{tabNR} = 'BL instellingen';

BLLayout = uiextras.VBox('Parent',tabpanel,'Spacing',10);


%
BLButtonGrid = uiextras.Grid( 'Parent', BLLayout, 'Spacing', 5 );

% Select View 
uicontrol('Parent',BLButtonGrid,'Style','text','String','Select View','HorizontalAlignment','left');
BLViewBox = uicontrol('Parent',BLButtonGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',[viewNames 'Equilibrium']);
uiextras.Empty( 'Parent', BLButtonGrid );
uicontrol( 'Parent', BLButtonGrid, 'String', 'Update Table','Callback', @updateViewReturnTable);


% empty space
uiextras.Empty( 'Parent', BLButtonGrid );
uiextras.Empty( 'Parent', BLButtonGrid );
uiextras.Empty( 'Parent', BLButtonGrid );
uiextras.Empty( 'Parent', BLButtonGrid );


% standard view type selections
uicontrol( 'Parent', BLButtonGrid, 'String', 'only diagonal','Callback', @viewDiagonalUncertainty);
uicontrol( 'Parent', BLButtonGrid, 'String', 'suggest. Meucci','Callback', @viewMeucciUncertainty);
uiextras.Empty( 'Parent', BLButtonGrid );
uiextras.Empty( 'Parent', BLButtonGrid );


set( BLButtonGrid, 'ColumnSizes', [100 200 100], 'RowSizes', [20 20 20 20] );
sizePanels=[120] ;


%
% table met views
%   View bestaat uit returns + onzekerheid over returns



% view returns

% first deterime default views


BLViews = uiextras.HBox('Parent',BLLayout);

columnname =   {'<html><b>View Returns'};
columnformat = {'char', 'short'};
columneditable =  [false true]; 


columnname{1}=cell(1,noAssets+1);
columnformat{1}=cell(1,noAssets+1);
colwith{1} = cell(1,noAssets+1);

columnname{1} =   '<html><b>AssetClass';
columnformat{1} = 'char';
columneditable =  [false true(1,noAssets)]; 
colwith(1) = num2cell(100);
colwith(2:end) = num2cell(75);

for ii=1:noAssets
    columnname{ii+1} =   ['<html><b>' assetCl{ii}];
    columnformat{ii+1} = 'short';
end





% http://www.mathworks.com/matlabcentral/newsreader/view_thread/284331
viewN = cell(2,noAssets);

viewN(1,1:noAssets)={'tst '};
viewN(2,1:noAssets)={'1'};
D1 = num2cell(viewN,1)
D1 = strcat(viewN{:})


assetRestRet = [assetCl num2cell(diag(viewReturns(:,1)))];

BLViewReturns = uitable('Parent',BLViews,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', assetRestRet,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        

% uncertainty on views

columnname=cell(1,noAssets+1);
columnformat=cell(1,noAssets+1);
colwith = cell(1,noAssets+1);

columnname{1} =   '<html><b>AssetClass';
columnformat{1} = 'char';
columneditable =  [false true(1,noAssets)]; 
colwith(1)=num2cell(150);
colwith(2:end) = num2cell(75);

for ii=1:noAssets

columnname{ii+1} =   ['<html><b>' assetCl{ii}];
columnformat{ii+1} = 'short';


end






BLViewUncertainty= uitable('Parent',BLViews,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], ... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);

        
        
sizePanels=[sizePanels -1];


c=1.0;  % schaling voor onzekerheid op views -> TODO: flexible maken.

[P, Ohm]= BLViewMeucci();


currentCorr = [assetCl num2cell(Ohm)];

set(BLViewUncertainty,'Data', currentCorr);

set(BLViews,'Sizes',[-1 -1]);
        
%
% table met huidige correlatie matrix / st-dev
%
BLCorrStdev = uiextras.HBox('Parent',BLLayout);


% correlatie matrix


columnname=cell(1,noAssets+1);
columnformat=cell(1,noAssets+1);
colwith = cell(1,noAssets+1);


columnname{1} =   '<html><b>AssetClass';
columnformat{1} = 'char';
columneditable =  [false true(1,noAssets)]; 
colwith{1}=150;
colwith(2:end) = num2cell(75);


for ii=1:noAssets
    columnname{ii+1} =   ['<html><b>' assetCl{ii}];
    columnformat{ii+1} = 'short';
end


%noCol = size(columnname,2);


currentCorr = [assetCl num2cell(Ohm)];

BLCorrTable = uitable('Parent',BLCorrStdev ,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', currentCorr,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);

% lege ruimte tussen correlatie en stdev        
uiextras.Empty('Parent',BLCorrStdev);        


% stabndaar deviatie..
columnname=cell(1,1);
columnformat=cell(1,1);
columnname{1} =   '<html><b>St. Dev.';
columnformat{1} = 'short';
columneditable =  [true]; 


colwith = num2cell(100); 


currentStdev = num2cell(stdev_curr);

BLSTdev = uitable('Parent',BLCorrStdev ,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', currentStdev,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);

        
set( BLCorrStdev, 'Sizes', [-3 5 -1]);        
        
        
sizePanels=[sizePanels -1];



set( BLLayout, 'Sizes', sizePanels);


%% Update the tab titles
tabpanel.TabNames = tabName;

%% Show the first tab
tabpanel.SelectedChild = 1;

%%
    function calc_eq_returns (~,~)
    % CALCULATE EQUILIBRIUM returns
        
        % get weight equilibrium portfolio
        equiAllocation = get(htab4_table,'Data');        
        w0=cell2mat(equiAllocation(:,2));    
            
        % for which assets the returns are 'fixed':
        fixed_assets = get(equilibriumFixedTable,'Data');
        fixed_ret = cell2mat(fixed_assets(:,2));
     
        [~, a2]=sort(fixed_assets(:,1));
        [~, c]=intersect(equiAllocation(:,1),fixed_assets(:,1)); % werkt niet direkt -> wordt gesorteerd! -> 2013 kan het wel
        fixed_assets=c(a2);   
        
        % Calculate equilibrium returns using restriction / based on method
        % ....
        [m_eq, te]=detEQReturns(stdev_curr, corr_curr, w0, fixed_assets, fixed_ret);
        
        % Calculate equilibrium returns using fixed IR
        % ....
        
        
        IR=cell2mat(equiAllocation(2,8));
        
        
        [m_eq_IR]=detEQReturnsIR(stdev_curr, IR);
        
        
        
        
        % update table / graphs
        
        equiAllocation(:,5)=num2cell(m_eq);
        equiAllocation(:,6)=num2cell(m_eq./stdev_curr);
        
        equiAllocation(:,7)=num2cell(m_eq_IR);
        equiAllocation(:,8)=num2cell(m_eq_IR./stdev_curr);
        
        
        
        set(htab4_table,'Data',equiAllocation);
        set(TE_text,'String',te);
        
        
        
    end


    function CopyConstructionWeightsToEqui(~,~)
    
    
        optimized_portfolio=get(portConsTable,'Data');
        
        equiAllocation = get(htab4_table,'Data');        
        %w0=cell2mat(equiAllocation(:,2));    
        
        equiAllocation(:,2)=optimized_portfolio(:,2);

        set(htab4_table,'Data',equiAllocation);
    end
        

    %%
    function updateConstructionTable(~, ~)
    
    % which view is selected:
    
    
    selectView = get(viewCnstrBox,'value');
    
    % get current resticties    
    curConstRest = get(constrRestr,'Data');
    
    
    if (selectView > noViews)
    % equilibrium choosen as scenario
        equiAllocation = get(htab4_table,'Data');
        curConstRest = [curConstRest(:,1:6) equiAllocation(:,end)];    
        
    else
    
    % add returns of the view
    curConstRest = [curConstRest(:,1:7) num2cell(viewReturns(:,selectView))];
    
    end
    
    set(constrRestr,'Data',curConstRest); % update table
    
    % update ook summary gegevens
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight;sum(cur_weight)]) ...
    num2cell([volConCurrent';sum(volConCurrent)]) num2cell([volConCurrent'/sum(volConCurrent);1]) ...
    num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1))];


    set(portConsTable,'Data',assetWeights);

    end

    function updateViewReturnTable(~, ~)
    
    % which view is selected:
    
    
    selectView = get(BLViewBox,'value');
    
    
    if (selectView > noViews)
    % equilibrium choosen as scenario
        equiAllocation = get(htab4_table,'Data');
        viewRet = [assetCl equiAllocation(:,end)];    
        
    else
    
    % add returns of the view
    viewRet = [assetCl num2cell(viewReturns(:,selectView))];
    
    end
    
    set(BLViewReturns,'Data',viewRet); % update table
    
    % update ook summary gegevens
%     assetWeights=[assetCl num2cell(cur_weight) num2cell(zeros(noAssets,1)) num2cell(zeros(noAssets,1))];
%     set(portConsTable,'Data',viewRet);

    end


    %%
    function ConstructionMarkowitz(~,~)
    %CONSTRUCTIONMARKOWITZ
    %   
    
    % which view is selected:
    selectView = get(viewCnstrBox,'value');
    
    if (selectView > noViews)
        scen_names='Equilibrium';
    else
        scen_names=viewNames(selectView);
    end
    curConstRest = get(constrRestr,'Data');  
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,end));
    cov_est = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev

    [optTarget,pars,Restricties]=setUpOptimizationRestrictions();
    
    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;
    
    Niter=str2num(get(constNIter,'String'));
    Nport=str2num(get(constNPort,'String'));
        
    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);
    
    
    % bepaal nieuwe volContribution
    
    [volConOpt] = volContribution (opt_weight, corr_curr, stdev_curr);
    
   
    % update tabel met gewichten
    
    
    % asset class, current (equilibrium) weight, new weight, difference:
    
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight;sum(cur_weight)]) ...
    num2cell([volConCurrent';sum(volConCurrent)]) num2cell([volConCurrent'/sum(volConCurrent);1]) ...
    num2cell([opt_weight;sum(opt_weight)]) num2cell([volConOpt';sum(volConOpt)]) num2cell([volConOpt'/sum(volConOpt);1]) num2cell([opt_weight-cur_weight;0])];


    set(portConsTable,'Data',assetWeights);
    
    
    end

    function SetUpRiskParity(~,~)
    
    % get restrictions
    curRestr=get(constrRestr,'Data');

    assetCategorieID = strcmp(assetCategorie, 'Return portefeuille');
    
    RiskBudget=zeros(noAssets,1);

    
    RiskBudget(~assetCategorieID)=volConCurrent(~assetCategorieID);
    
    RiskBudget(assetCategorieID)= sum(volConCurrent(assetCategorieID))/sum(assetCategorieID);
    
    
    set(constrRestr,'Data',[curRestr(:,1:6) num2cell(RiskBudget) curRestr(:,end)]);
    end
        

    function MWRiskTarget(~,~)
    % TODO: optimize return portfolio with equal risk-budget for assets
    
    
    % which view is selected:
    selectView = get(viewCnstrBox,'value');
    
    tt=assetCategorie;
    
    if (selectView > noViews)
        scen_names='Equilibrium';
    else
        scen_names=viewNames(selectView);
    end
    curConstRest = get(constrRestr,'Data');  
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,end));
    cov_est = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev

    [optTarget,pars,Restricties]=setUpOptimizationRestrictions();
    
    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    
    % extra restrictie / instellingen voor risk-budgetting

    % get current restrictions
    curRestr=get(constrRestr,'Data');    
     
    
    pars.useRiskBudgetting = true;
    pars.assetCategorie = strcmp(assetCategorie, 'Return portefeuille');
    
    pars.RiskBudget=cell2mat(curRestr(:,7))
    pars.RiskBudget=(pars.RiskBudget/sum(pars.RiskBudget))*sum(volConCurrent);

    
%     pars.RiskBudget(~pars.assetCategorie)=volConCurrent(~pars.assetCategorie);
%     pars.RiskBudget(pars.assetCategorie)= sum(volConCurrent(pars.assetCategorie))/sum(pars.assetCategorie);
    
    
    Restricties.MaxTE_actief = 0; % turn off target TE -> already in risk-budgets
    

    
    Niter=str2num(get(constNIter,'String'));
    Nport=str2num(get(constNPort,'String'));
        
    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);
    mu=mean(output.mu);
    sig=mean(output.sig);
    
    % TE contribution after Optimization:
    
    [volAfterOpt] = volContribution (opt_weight, corr_curr, stdev_curr);
    
    
    % asset class, current (equilibrium) weight, new weight, difference:
    assetWeights=[assetCl num2cell(cur_weight) num2cell(volConCurrent') num2cell(volConCurrent'/sum(volConCurrent)) num2cell(opt_weight) num2cell(volAfterOpt') num2cell(volAfterOpt'/sum(volAfterOpt)) num2cell(opt_weight-cur_weight)];


    set(portConsTable,'Data',assetWeights);
        
    
    
    end


        
    function ConstructionBL (~,~)

    % which view / scenario is selected

    selectView = get(viewCnstrBox,'value');
    scen_names=viewNames(selectView);
        
    [mu_BL_pos,Sig_BL_pos]=BL_classic();


    [optTarget,pars,Restricties]=setUpOptimizationRestrictions();

    pars.meanmat=mu_BL_pos;
    pars.covmat=Sig_BL_pos;

    Niter=str2num(get(constNIter,'String'));
    Nport=str2num(get(constNPort,'String'));

    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);    
    mu=mean(output.mu);
    sig=mean(output.sig);

    explode=zeros(1,noAssets);
    explode(1)=1;                   % TODO: aanneme dat matching 1e asset is
    
    pie(pieOptWeights, opt_weight,explode, assetCl);
        
    % update tabel met gewichten
    % asset class, current (equilibrium) weight, new weight, difference:
    assetWeights=[assetCl num2cell(cur_weight) num2cell(opt_weight) num2cell(opt_weight-cur_weight)];


    set(portConsTable,'Data',assetWeights);

    
        
    
    end
    
    function ConstructionMWTERange(~,~)
 

    
    % which view / scenario is selected

    selectView = get(viewCnstrBox,'value');
    scen_names=viewNames(selectView);
    
    
      curConstRest = get(constrRestr,'Data');  
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,end));
    cov_est = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev

    % set up restrictions
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions();

    pars.meanmat=return_est;
    pars.covmat=cov_est;
    pars.useRiskBudgetting=false;
    
    Niter=str2num(get(constNIter,'String'));
    Nport=str2num(get(constNPort,'String'));


    % range TE
    noTESteps=10;
    
    minTE = str2num(get(constMinTERange,'String'));
    maxTE = str2num(get(constMaxTERange,'String'));
    
    stepSizeTE=(maxTE - minTE)/noTESteps;
    
    
    weighMatrix=zeros(noAssets,(noTESteps+1));
    portfolioMu=zeros((noTESteps+1),1);
    portfolioSig=zeros((noTESteps+1),1);
    
    for kk=0:noTESteps
    
        stream = RandStream('mt19937ar','seed',20111008); % simulated annealing is met Niter=500 en Nport=500 nog steeds erg gevoelig voor 
        RandStream.setDefaultStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        
        
        Restricties.MaxTE=(minTE+stepSizeTE*kk);
        output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

        % resultaat -> neem gemidddelde van simulated annealing
        weighMatrix(:,kk+1)=mean(output.wts,2);    
        portfolioMu(kk+1)=mean(output.mu);
        portfolioSig(kk+1)=mean(output.sig);
        
    end
    
    % allocation as function of TE
    areaPl=figure('Name','Allocation as function of TE');
    area(weighMatrix');
    legend(assetCl, 'Location', 'SouthWest');
    
    xlabel('TE');
    ylabel('Weights');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minTE:stepSizeTE:maxTE)
    axis([1 (noTESteps+1) 0 1]);
            
    
    % portfolio return as function of TE
    PortMEFig=figure('Name','Estimated Return as function of TE');
    
    
    portRet=plot(minTE:stepSizeTE:maxTE,portfolioMu);
    
    xlabel('TE');
    ylabel('Portfolio Return');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minTE:stepSizeTE:maxTE)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        

    % portfolio IR as function of TE
    PortMEFig=figure('Name','IR as function of TE');
    
    
    portRet=plot(minTE:stepSizeTE:maxTE,(portfolioMu./portfolioSig));
    
    xlabel('TE');
    ylabel('Portfolio IR');
    
    set(gca,'Layer','top');
    set(gca,'XTickLabel',minTE:stepSizeTE:maxTE);
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        
    
    
    
    end

    function ConstructionBLTERange(~,~)

    
    % which view / scenario is selected

    selectView = get(viewCnstrBox,'value');
    scen_names=viewNames(selectView);
        
    [mu_BL_pos,Sig_BL_pos]=BL_classic();

    % set up restrictions
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions();

    pars.meanmat=mu_BL_pos;
    pars.covmat=Sig_BL_pos;

    Niter=str2num(get(constNIter,'String'));
    Nport=str2num(get(constNPort,'String'));

    % range TE
    noTESteps=10;
    
    minTE = str2num(get(constMinTERange,'String'));
    maxTE = str2num(get(constMaxTERange,'String'));
    
    stepSizeTE=(maxTE - minTE)/noTESteps;
    
    
    weighMatrix=zeros(noAssets,(noTESteps+1));
    portfolioMu=zeros((noReturnSteps+1),1);
    portfolioSig=zeros((noReturnSteps+1),1);
    
    for kk=0:noTESteps
    
        stream = RandStream('mt19937ar','seed',20111008); % simulated annealing is met Niter=500 en Nport=500 nog steeds erg gevoelig voor 
        RandStream.setDefaultStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        
        Restricties.MaxTE=(minTE+stepSizeTE*kk);
        output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

        % resultaat -> neem gemidddelde van simulated annealing
        weighMatrix(:,kk+1)=mean(output.wts,2);    
        portfolioMu(kk+1)=mean(output.mu);
        portfolioSig(kk+1)=mean(output.sig);
        
    end
    
    % first graphs -> allocation as function of TE
    areaPl=figure('Name','Allocation as function of TE');
    area(weighMatrix');
    legend(assetCl, 'Location', 'SouthWest');
    
    xlabel('TE');
    ylabel('Weights');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minTE:stepSizeTE:maxTE)
    axis([1 (noTESteps+1) 0 1]);
    
    
    
    
    end


    function [optTarget,pars,Restricties]=setUpOptimizationRestrictions()

    
    curConstRest = get(constrRestr,'Data');  
    % which optimization target is selected:
    
    optTarget = get(targetCnstrBox,'value');
    
    
    % check of restricties gebruikt moeten worden
    useRest = get (constUseRestr,'value');
    useTE =  get (constUseTE,'value');
    
    %Verwerk restricties op portefeuillegewichten
    A_restr   = [-eye(noAssets);eye(noAssets)]; 
     
    
    if (useRest) 
        lowerLimWeights = cell2mat(curConstRest(:,3));
        upperLimWeights = cell2mat(curConstRest(:,4));
    else
        lowerLimWeights = zeros(noAssets,1);
        upperLimWeights = ones(noAssets,1);
    end
    
    b_restr   = [-lowerLimWeights;upperLimWeights]; % restricties totale portfefeuille
    

   %Maak ook restrictiematrix apart voor matching en return portefeuille
   
   % TODO: nog aanpassen met selectbox die aangeeft om wel of niet
   % restricties te gebruiken!
   
    b_p  = zeros(2*noAssets,1);
    ex_1 = double(strcmp(curConstRest(:,2),'Matching portefeuille'));
    ex_2 = double(strcmp(curConstRest(:,2),'Return portefeuille'));
    C_p  = ex_1*ex_1'+ex_2*ex_2'; 
    A_p1 = -(eye(noAssets)-diag(lowerBsubPort)*C_p);
    A_p2 = (eye(noAssets)-diag(upperBsubPort)*C_p);
    A_p  = [A_p1;A_p2];
    A_restr    = [A_restr;A_p];
    b_restr    = [b_restr;b_p]; 
    
    %Maak tenslotte restricties op basis van huidige portefeuille gewichten
    
    Rest_t0=ones(noAssets,1)*0.99;  % max turn over
    
    A_h  = [-eye(noAssets);eye(noAssets)]; 
    b_h  = [-(cur_weight-Rest_t0);cur_weight+Rest_t0];
    A_restr    = [A_restr;A_h];
    b_restr    = [b_restr;b_h];  
    
    
    % verwerk restrictie TE
        
    useTElimit = get(constUseTE,'value');
    targetTE=str2num(get(constTargetTE,'String'));
    
    % min return / LPM -> niet gebruikt op dit moment
    MinRet=0;
    MinRet_actief=0;
    
    MaxLPM=0.02;
    MaxLPM_actief=0;
    
    doelstelling=1; % max return
    
    Rest_turnover=1.0;  % restrictie max-turnover -> niet gebruikt op dit moment
    
	stream = RandStream('mt19937ar','seed',20111008); 
	RandStream.setDefaultStream(stream);
	
    Restricties.MinRet = MinRet;
    Restricties.MaxTE  = targetTE;
    Restricties.MinRet_actief = MinRet_actief;
    Restricties.MaxTE_actief = useTElimit;
    
    Restricties.MaxLPM  = MaxLPM;               % lower-partial-moment -> op dit moment niet gebruikt
    Restricties.MaxLPM_actief = MaxLPM_actief;
    
    Restricties.A = A_restr;
    Restricties.b = b_restr;
    Restricties.w0 = cur_weight;
    Restricties.dw0 = Rest_turnover;
    
    
    Rest_extra_A=zeros(noAssets,noAssets);
    Rest_extra_b=zeros(1,noAssets);
    Rest_extra=zeros(1,noAssets);
    
    Restricties.Ax = Rest_extra_A;  % extra restricties -> op dit moment niet gebruikt.
    Restricties.bx = Rest_extra_b;
    Restricties.onx = Rest_extra;

    pars=struct;
    
    pars.probs = 1; % not used
    pars.bm    = 0; % not used
    
    lpm_target=0;   % not used
    lpm_orde=2;     % not used
	pars.lpm_target = lpm_target;
 	pars.lpm_orde   = lpm_orde;

    
    end

    function pieChartWeights(~,~)
        
        
        
        
    end

    function ret_graph_eq(~,~)
    
    equiAllocation = get(htab4_table,'Data');      
    
    
    end


    function pieChartTEContribution(~,~)
    end

    function barChartWeigths(~,~)
    end
    
    function barChartTEContribution(~,~)
        
        % first determine TE contribution current / equilibrium allocation
        [ volCon_equi ] = volContribution (cur_weight, corr_curr, stdev_curr);
        
        
        % get weights of optimized portfolio
        
        optimizedWeights =  get(portConsTable,'Data');
        
        % TODO: als correlatie / stdev aanpasbaar wordt in GUI -> hier ook
        % ophalen!
        
        [ volCon_opt ] = volContribution (cell2mat(optimizedWeights(:,3)), corr_curr, stdev_curr);
        
        
        
        curColMap = colormap();
        % define colormap for stacked bar-chart
        colMap(1,:) = ([1 1 1]);
        colMap(2,:) = ([0 0 143/255]);

        
        % sort risk-contribution
        [volContributionSort id]=sort(volCon_opt,'descend')
        [volContributionSortEqui idEqui]=sort(volCon_equi,'descend')
        
        
        yy=[0 cumsum(volContributionSort(1:(end-1)))];
        
        yy_equi=[0 cumsum(volContributionSortEqui(1:(end-1)))];
        
        
        TEConTR=figure('Name','Contribution to Risk (after optimization)');
        TEGraph = axes('Parent', TEConTR); % 'Position',[1 50 100 150]
        bar(TEGraph,1:noAssets,[yy' volContributionSort'],0.8, 'stack','edgecolor','none')
        set(TEGraph,'XTickLabel',assetCl(id));
        colormap(TEGraph,colMap)
        hText = xticklabel_rotate([],90)

        
        TEConTR_equi=figure('Name','Contribution to Risk (current)');
        
        eqTEGraph = axes('Parent', TEConTR_equi); % 'Position',[1 50 100 150]
        bar(eqTEGraph,1:noAssets,[yy_equi' volContributionSortEqui'],0.8, 'stack','edgecolor','none')
        set(eqTEGraph,'XTickLabel',assetCl(idEqui));
        colormap(eqTEGraph,colMap)
        hText = xticklabel_rotate([],90)
        
        
        
    end

        function [mu_BL_pos,Sig_BL_pos]=BL_classic()
        % Black Litterman
        %   
        %   mu_BL_pos = posterior return estimates
        %   Sig_BL_pos = posterior covariance matrix
        



        curConstRest = get(constrRestr,'Data');  

        % view return
        
        % kies uit view tab
        
        return_est = cell2mat(curConstRest(:,end));
        
        
        % Equilibrium Cov / weights
        cov_est = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev


 %      corr = corr + triu(corr,1)' ; 
        equiAllocation = get(htab4_table,'Data');        
        
        w_market=cell2mat(equiAllocation(:,2));     % evenwichts gewichten
        pi_market = cell2mat(equiAllocation(:,5));  % evenwichts returns
        
        % tau -> make variable
        tau = 0.4;

        % views
        % probeer eerst "absolute views"
        
        c=1.0;
        
        [P, Ohm]= BLViewMeucci()


        % posterior:
        % form (15) / (16)-> 

        A = tau * cov_est;
        % B = P'* (Ohm\P);

        % C = P'* (Ohm\v);
        E = cov_est*P';
        D = P*E;

        
        %   Meucci -->
        %   form 19 / 20
        % 


        mu_BL_pos = pi_market+A*P'*((tau*D+Ohm)\(v-P*pi_market)); % check --> implementatie (15) / (19) agree
        Sig_BL_pos = (1+tau)*cov_est-((tau*tau)*cov_est*P'/(tau*D+Ohm))*P*cov_est;  % check --> implementatie (18) / (20) agree



        %
        % Meucci --> full confidence posterior
        % (27) & (28)


        mu_BL_full_conf = pi_market + E/D*(v-P*pi_market);
        Sig_BL_full_conf = (1+tau)*cov_est-tau*E/D*E';


        end
    
    function ConstructionReturnRangeMW(~,~)
    
    %
    %   change return of a specific asset class between the selected range
    %   and see how this impacts the allocaion
    %
 
    
    % which view / scenario is selected
    % returns other assets are kept constant -> returns from the view are
    % used
    
    selectView = get(viewCnstrBox,'value');
    scen_names=viewNames(selectView);
    
    
    curConstRest = get(constrRestr,'Data');  
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,end));
    cov_est = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev

    % set up restrictions
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions();

    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;
    
    Niter=str2num(get(constNIter,'String'));
    Nport=str2num(get(constNPort,'String'));


    % range Return
    noSteps=10;   % TODO: currently hardcoded -> change?
    
    minReturn = str2num(get(constMinReturn,'String'));
    maxReturn = str2num(get(constMaxReturn,'String'));
    
    stepSize=(maxReturn - minReturn)/noSteps;
    
    
    % selected asset
    selAss=get(AssetCnstrBox,'value');
    
    weighMatrix=zeros(noAssets,(noSteps+1));
    portfolioMu=zeros((noSteps+1),1);
    portfolioSig=zeros((noSteps+1),1);
    
    for kk=0:noSteps
    
        stream = RandStream('mt19937ar','seed',20111008); % simulated annealing is met Niter=500 en Nport=500 nog steeds erg gevoelig voor 
        RandStream.setDefaultStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        
        return_est(selAss)=minReturn+kk*stepSize;
        pars.meanmat=return_est;       
        
        output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

        % resultaat -> neem gemidddelde van simulated annealing
        weighMatrix(:,kk+1)=mean(output.wts,2);    
        portfolioMu(kk+1)=mean(output.mu);
        portfolioSig(kk+1)=mean(output.sig);
        
    end
    
    % allocation as function of TE
    areaPl=figure('Name',['Allocation as function of Return ',assetCl{selAss}]);
    area(weighMatrix');
    legend(assetCl, 'Location', 'SouthWest');
    
    xlabel('Return');
    ylabel('Weights');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    axis([1 (noSteps+1) 0 1]);
            
    
    % portfolio return as function of TE
    PortMEFig=figure('Name',['Estimated Return as function of Return ',assetCl{selAss}]);
    
    
    portRet=plot(minReturn:stepSize:maxReturn,portfolioMu);
    
    xlabel('Return');
    ylabel('Portfolio Return');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        

    % portfolio IR as function of return
    PortMEFig=figure('Name',['IR as function of Return ',assetCl{selAss}]);
    
    
    portRet=plot(minReturn:stepSize:maxReturn,(portfolioMu./portfolioSig));
    
    xlabel('Return');
    ylabel('Portfolio IR');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        
    
    
    
    % WEIGHT selected asset as function of return
    PortMEFig=figure('Name',['Weight as function of Return ',assetCl{selAss}]);
    
    
    portRet=plot(minReturn:stepSize:maxReturn,weighMatrix(selAss,:));
    
    xlabel('Return');
    ylabel('Weight Asset');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');
    
    
    end
    
    function [P, Ohm]= BLViewMeucci()
    % views
    % probeer eerst "absolute views"
    
        cov_est = corr_curr.*(stdev_curr*stdev_curr'); % calculate cov. from correlation / st.dev

        P = eye(noAssets);  % per asset-class hebben we 1 view 

        Ohm= (1/c)* P * cov_est * P';

    end

    function [Ohm]=viewMeucciUncertainty(~,~)
        [P, Ohm]= BLViewMeucci();
        currentCorr = [assetCl num2cell(Ohm)];
        set(BLViewUncertainty,'Data',currentCorr);
    
    end



    function [Ohm]=viewDiagonalUncertainty(~,~)


        Ohm= (1/c)* diag(stdev_curr.*stdev_curr);
        currentCorr = [assetCl num2cell(Ohm)];
        set(BLViewUncertainty,'Data',currentCorr);
    
    end


    function updateAssetRange(~,~)
        
         
        selectedAssdt = get (AssetCnstrBox,'value');
        selectedView = get (viewCnstrBox,'value');
        
        viewReturn = viewReturns(selectedAssdt,selectedView);
        
        set(constMinReturn,'String',-2*viewReturn);
        set(constMaxReturn,'String', 2*viewReturn);
        
    end

    

end
