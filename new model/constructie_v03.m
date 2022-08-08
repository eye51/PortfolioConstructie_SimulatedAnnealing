%
%
%

% first clear/close everything

close all hidden;
clear all;
clc;


% set up main layout -> window with tabs
mainW = figure( 'Name', 'Constructie v0.1', ...
    'MenuBar', 'none', ...
    'Toolbar', 'none', ...
    'NumberTitle', 'off');



scrsz = get(0,'ScreenSize');

set(mainW,'Position',[scrsz(3)/8 scrsz(4)/4 3*scrsz(3)/4 scrsz(4)/2])

tabpanel = uiextras.TabPanel( 'Parent', ...
    mainW, ...
    'Padding', 0);


%
% get asset classes -> current weighting
%

[assetCl cur_weight lowerBound upperBound] = getCurPortfolio();

noAssets = size(assetCl,1);




%% Create some contents
% 
%   first tab: current portfolio
%


%
%       +------+------+
%       |      |      |
%       |      |      |
%       +------+------+
%       |      |      |
%       |      |      |
%       +------+------+
%
%

tabName{1} = 'Current Portfolio';
CurrentPortGrid = uiextras.Grid('Parent',tabpanel)

% current allocation -> table
columnname =   {'AssetClass', 'Current Weight', 'Lower Limit', 'Upper Limit'};
columnformat = {'char', 'bank', 'bank', 'bank'};
columneditable =  [false false false false]; 

% set up data for table:
asset_current = [assetCl num2cell(cur_weight) num2cell(lowerBound') num2cell(upperBound')];

tableCurWeights = uitable('Parent',CurrentPortGrid,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', asset_current,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'RowName',[]);
        


% table restrictions (?)
tableRestrictions = uitable('Parent',CurrentPortGrid,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', asset_current,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'RowName',[]);
        
        
%
%   current allocation -> PIE chart
%

pieCurrWeights = axes ('Parent', CurrentPortGrid);

explode = [1 0 0 0 0 0 0 0]; % hardcoded! -> 8 asset classes, 1e is norminal matching
pie(pieCurrWeights, cur_weight,explode, assetCl);



        
% bar chart TE decomp?

Y = [5 1 2
     8 3 7
     9 6 8
     5 5 5
     4 2 3];

 fig_2 = axes ('Parent', CurrentPortGrid);

bar(Y,'stack')
grid on
set(gca,'Layer','top')
        

% set sizes:

set( CurrentPortGrid, 'ColumnSizes', [-1 -2], 'RowSizes', [-1 -1] );


%%
% Views panel --> 2e tab
%

tabName{2} = 'Views';

viewsLayout = uiextras.VBoxFlex('Parent',tabpanel);

% get current views
[assetCls viewNames viewReturns viewProb viewStDev] = getCurViews();
noViews = size(viewNames,2);


views = [assetCl num2cell(viewReturns)];



% first table format / layout:
columnname = cell(1,noViews+1)
columnname{1}='<html><b>AssetClass';

for kk=1:noViews
    columnname(1+kk)=cellstr(strcat('<html><b>',viewNames(kk)));
end
    
colwith = cell(1,noViews+1);
colwith{1} = 150;
% colwith(2:end) = cellstr('auto')
colwith(2:end) = num2cell(150);
 

ViewsSetupTable = uitable('Parent',viewsLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', views,... 
            'ColumnName', columnname,...
            'RowName',[],...
            'ColumnWidth',colwith,...
            'BackgroundColor',[1 1 1]);

        
        
% second table format / layout   

columnname = cell(1,noViews+1)
for kk=1:noViews
    columnname(kk+1)=cellstr(strcat('<html><b>',viewNames(kk)));
end
    
colwith = cell(1,noViews+1);
colwith{1} = 150;
% colwith(2:end) = cellstr('auto')
colwith(2:end) = num2cell(150);

rowNames = cell(2,1);

rowNames{1}='Probability';
rowNames{2}='St. Dev. View';

viewProbStDev =  [viewProb;viewStDev];
viewProbStDev =  [rowNames num2cell(viewProbStDev)]


ViewsProbabilityTable = uitable('Parent',viewsLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', viewProbStDev,... 
            'ColumnName', columnname,...
            'RowName',[],...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1]);


%
% panel with graphs
%

barChartLayout = uiextras.HBox('Parent',viewsLayout,'Spacing',10);

barCH_empty = axes ('Parent', barChartLayout,'Position',[10 1 130 200]);;
set(barCH_empty,'YTickLabel',viewNames);

colW = [140];

for kk=1:noViews

    barCH(kk) = axes ('Parent', barChartLayout,'Position',[10 1 140 200]);
    barh(barCH(kk),viewReturns(:,kk));

    colW=[colW 140];
end



set( barChartLayout, 'Sizes', colW);

% panel with buttons(?)        
viewButtonPanel = uiextras.Panel( 'Parent', viewsLayout, 'Padding', 5);        

b = uiextras.HButtonBox( 'Parent', viewButtonPanel );
uicontrol( 'Parent', b, 'String', 'One' );
uicontrol( 'Parent', b, 'String', 'Two' );
uicontrol( 'Parent', b, 'String', 'Three' );
set( b, 'ButtonSize', [130 35], 'Spacing', 5, 'HorizontalAlignment','left' );
% uicontrol('Parent',viewButtonPanel,'Style', 'pushbutton', 'String', 'Clear',...
%         'Position', [20 20 10 10],...
%         'Callback', 'cla');        % 
%uicontrol


%
set( viewsLayout, 'Sizes', [-2 -1 -1 50]);



%%
%   results page
%

tabName{3} = 'Construction';


htab3 = uiextras.Panel( 'Parent', tabpanel, 'Padding', 5, 'Title', 'Samenvatting mixen');

htab3_hbox = uiextras.HBox ('Parent',htab3)

x1 = axes ('Parent', htab3_hbox);

x2 = axes ('Parent', htab3_hbox);
% vb Pie -> later met "echte" data vullen

X=[0.1 0.2 0.3 0.4];
pie(x2, X)

set(htab3_hbox, 'Sizes',[-1 -1])



%%
% Evenwichts situatie
%

tabName{4} = 'Equilibrium';

equilibriumLayout = uiextras.VBox('Parent',tabpanel);

%
% table met huidige gewichten en restricties:
%

columnname =   {'<html><b>AssetClass', '<html><b>Equilibrium Weight', '<html><b>Lower Limit', '<html><b>Upper Limit', '<html><b>Equilibrium Returns'};
columnformat = {'char', 'bank', 'bank', 'bank', 'bank'};
columneditable =  [false true false false true]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1:end) = num2cell(150);

currentEqui = [asset_current num2cell(zeros(noAssets,1))]

htab4_table = uitable('Parent',equilibriumLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', currentEqui,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);

%
% table met fixed asset returns
%

columnname =   {'<html><b>AssetClass Fixed', '<html><b>Return Fixed'};
columnformat = {assetCl', 'bank'};
columneditable =  [true true]; 

fixedAsset = [1 2];
fixedRet = [0 0.03];
FixedEqui = [assetCl(fixedAsset) num2cell(fixedRet')]

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

uicontrol('Parent',equilibriumGrid,'Style','text','String','Use restrictions ','HorizontalAlignment','left');
regionBox = uicontrol('Parent',equilibriumGrid,'Style','checkbox');
%uiextras.Empty( 'Parent', equilibriumGrid )
% uiextras.Empty( 'Parent', equilibriumGrid )
% uicontrol( 'Parent', equilibriumGrid, 'String', 'Update Table','Callback', @updatePoolTable);

set( equilibriumGrid, 'ColumnSizes', [100 100], 'RowSizes', [20] );


%
% bar-graphs
%

%
%   Weights
%
equilibriumGrphV = uiextras.VBox( 'Parent', equilibriumLayout, 'Spacing', 20 );
uiextras.Empty( 'Parent', equilibriumGrphV )

equilibriumGrph = uiextras.HBox( 'Parent', equilibriumGrphV, 'Spacing', 150,'Padding',10);

uiextras.Empty( 'Parent', equilibriumGrph )

eqWeightGrap = axes('Parent', equilibriumGrph,'Position',[1 1 100 150]); %
barh(eqWeightGrap,cell2mat(asset_current(:,2)))
set(eqWeightGrap,'YTickLabel',asset_current(:,1));
set(eqWeightGrap,'Clipping','off')
%xticklabel_rotate(eqWeightGrap,45)


%
%   TE
%



eqTEGrap = axes('Parent', equilibriumGrph,'Position',[1 1 100 150]); % 
barh(eqTEGrap,cell2mat(asset_current(:,2)))
set(eqTEGrap,'YTickLabel',asset_current(:,1));

%rotateticklabel(eqTEGrap,45)

% sizes

set(equilibriumGrph,'Sizes',[5 -1 -1]);

uiextras.Empty( 'Parent', equilibriumGrphV )

set(equilibriumGrphV,'Sizes',[1 -1 1]);
% panel with buttons(?)        
equilibriumButtonPanel = uiextras.Panel( 'Parent', equilibriumLayout, 'Padding', 5);        

equiBut = uiextras.HButtonBox( 'Parent', equilibriumButtonPanel );
uicontrol( 'Parent', equiBut, 'String', 'One' );
uicontrol( 'Parent', equiBut, 'String', 'Two' );
uicontrol( 'Parent', equiBut, 'String', 'Three' );
set( equiBut, 'ButtonSize', [130 35], 'Spacing', 5, 'HorizontalAlignment','left' );


set( equilibriumLayout, 'Sizes', [-1 75 50 -2 50]);
        
%% Update the tab titles
tabpanel.TabNames = tabName;

%% Show the first tab
tabpanel.SelectedChild = 1;