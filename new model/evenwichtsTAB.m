function evenwichtsTAB( tab_handle, assetCl, corr_curr, stdev_curr,corNames, assetCategorie, cur_weight, lowerBound, upperBound, lowerBsubPort, upperBsubPort, turnOver,productieVersie)

% [equilibriumTable] = evenwichtsTAB( tab_handle, assetCl, corr_curr, stdev_curr, assetCategorie, cur_weight, lowerBound, upperBound, lowerBsubPort, upperBsubPort, turnOver)

%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


global ViewsSetupTable;
global ViewsProbabilityTable;
global BLViewReturns;
global BLViewUncertainty;
global BLCorrTable;
global equilibriumTable;
global portConsTable;


equilibriumLayout = uiextras.VBox('Parent',tab_handle);

cmap = colormap;


% start with base covar
used_corr=corr_curr{1};
used_stdev=stdev_curr{1};


%
%
%
noAssets = size(assetCl,1);
volPortCurrent = portfolioVol (cur_weight, used_corr, used_stdev);

% determine risk contribution for each asset
[volConCurrent] = volContribution (cur_weight, used_corr, used_stdev);

%
% table met huidige gewichten en restricties:
%

columnname =   {'<html><b>AssetClass', '<html><b>Equilibrium Weight', '<html><b>Low. Limit', '<html><b>Upp. Limit', '<html><b>Eq. Returns', '<html><b>Eq. IR', '<html><b>Eq. Ret (on IR)', '<html><b>Eq. IR (fixed)', '<html><b>TE Contr.'};
columnformat = {'char', 'bank', 'bank', 'bank', 'bank', 'bank', 'bank', 'bank'};
columneditable =  [false true false false true true true true false]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1:end) = num2cell(100);

currentEqui = [assetCl num2cell(cur_weight*100) num2cell(lowerBound*100) num2cell(upperBound*100) num2cell(zeros(noAssets,1)) num2cell(zeros(noAssets,1)) num2cell(zeros(noAssets,1)) num2cell([0;0.16*ones(noAssets-1,1)]) num2cell(100*volConCurrent') ];

equilibriumTable = uitable('Parent',equilibriumLayout,'Units','normalized','Position',...
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
fixedRet = [0 3.00];



FixedEqui = [assetCl(fixedAsset) num2cell(fixedRet') num2cell(fixedRet'./used_stdev(fixedAsset))];

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


uicontrol('Parent',equilibriumGrid,'Style','text','String','Select Cov','HorizontalAlignment','left');
selectCovBox = uicontrol('Parent',equilibriumGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',corNames,'Callback',@updateCov);


uicontrol('Parent',equilibriumGrid,'Style','text','String','TE','HorizontalAlignment','left');
%uiextras.Empty( 'Parent', equilibriumGrid );


if (productieVersie) 
    uiextras.Empty( 'Parent', equilibriumGrid );
else
 uicontrol('Parent',equilibriumGrid,'Style','text','String','Use restrictions ','HorizontalAlignment','left');
end

% if (productieVersie) 
%     uiextras.Empty( 'Parent', equilibriumGrid );
%     uiextras.Empty( 'Parent', equilibriumGrid );
% else
%  uicontrol('Parent',equilibriumGrid,'Style','text','String','Use restrictions ','HorizontalAlignment','left');
%     uiextras.Empty( 'Parent', equilibriumGrid );
% end


uiextras.Empty( 'Parent', equilibriumGrid );
uiextras.Empty( 'Parent', equilibriumGrid );

TE_text=uicontrol('Parent',equilibriumGrid,'Style','text','BackgroundColor',[1 1 1],'String',volPortCurrent);

if (productieVersie) 
    uiextras.Empty( 'Parent', equilibriumGrid );
else
    useRestrictions = uicontrol('Parent',equilibriumGrid,'Style','checkbox');
end


% if (productieVersie) 
%     uiextras.Empty( 'Parent', equilibriumGrid );
%     uiextras.Empty( 'Parent', equilibriumGrid );
% else
%     useRestrictions = uicontrol('Parent',equilibriumGrid,'Style','checkbox');
%     uiextras.Empty( 'Parent', equilibriumGrid );
% end

% uicontrol( 'Parent', equilibriumGrid, 'String', 'Update Table','Callback', @updatePoolTable);

set( equilibriumGrid, 'ColumnSizes', [100 100], 'RowSizes', [20 20 20 20]);


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
uicontrol( 'Parent', equiBut, 'String', 'Export Excel','Callback',@exportEvenwichExcel );

if (productieVersie)
  uiextras.Empty( 'Parent', equilibriumGrphV );  
else
    uicontrol( 'Parent', equiBut, 'String', 'TE Graph','Callback',@TE_graph_eq );
end



set( equiBut, 'ButtonSize', [130 35], 'Spacing', 5, 'HorizontalAlignment','left' );


set( equilibriumLayout, 'Sizes', [-1 75 75 -1 50]);

%%
    function calc_eq_returns (~,~)
    % CALCULATE EQUILIBRIUM returns
        
        % get weight equilibrium portfolio
        equiAllocation = get(equilibriumTable,'Data');        
        w0=cell2mat(equiAllocation(:,2))/100;    
            
        % for which assets the returns are 'fixed':
        fixed_assets = get(equilibriumFixedTable,'Data');
        fixed_ret = cell2mat(fixed_assets(:,2))/100;
     
        [~, a2]=sort(fixed_assets(:,1));
        [~, c]=intersect(equiAllocation(:,1),fixed_assets(:,1)); % werkt niet direkt -> wordt gesorteerd! -> 2013 kan het wel
        fixed_assets=c(a2);   
        
        
        % used corr matrix:
        
        used_corr_matrix=used_corr;
        used_std=stdev_curr{1};
        
        % Calculate equilibrium returns using restriction / based on method
        % ....
        [m_eq, te]=detEQReturns(used_std, used_corr_matrix, w0, fixed_assets, fixed_ret);
        
        % Calculate equilibrium returns using fixed IR
        % ....
        
        
        IR=cell2mat(equiAllocation(2,8));
        
        
        [m_eq_IR]=detEQReturnsIR(used_std, IR);
        
        
        
        
        % update table / graphs
        
        equiAllocation(:,5)=num2cell(100*m_eq);
        equiAllocation(:,6)=num2cell(100*m_eq./used_std);
        
        equiAllocation(:,7)=num2cell(m_eq_IR);
        equiAllocation(:,8)=num2cell(m_eq_IR./used_std);
        
        
        
        set(equilibriumTable,'Data',equiAllocation);
        set(TE_text,'String',te);
        
        
        
    end
    
    function exportEvenwichExcel(~,~)

    % export equilibrium data from table to excel file
    
    % get data from table;
    equiData = get(equilibriumTable,'Data'); 
    
    equiCol =   {'AssetClass', 'Equilibrium Weight', 'Low. Limit', 'Upp. Limit', 'Eq. Returns', 'Eq. IR', 'Eq. Ret (on IR)', 'Eq. IR (fixed)', 'TE Contr.'};
    
    xlswrite('port_contr.xlsx',[equiCol;equiData],'Equi','a1');
   
    
    end


    function TE_graph_eq(~,~)
    end
    
    function updateCov(~,~)
            
        selectCov = get(selectCovBox,'value');
        
        
        
        used_corr=corr_curr{selectCov};
        used_stdev=stdev_curr{selectCov};
    end


end

