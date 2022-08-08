function constructionTAB(tab_handle, assetCl, corr_curr, stdev_curr,corNames,viewNames, assetCategorie, cur_weight, lowerBound, upperBound, lowerBsubPort, upperBsubPort, turnOver,restrictionNR, assetClsER, lowerBoundER, upperBoundER,groupLowerBound,groupUpperBound,groupLimitActive,productieVersie)

% function [ portConsTable ] = constructionTAB 
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here



global BLViewReturns;               % views set up, structure of views + returns
global BLViewUncertainty;           % uncertainty on views.
global constViewUncertainty;
global constMarketUncertainty;

global BLCovriancePrior;
global BLCovriancePosterior;

global BLReturns;

global equilibriumTable;
global portConsTable;
global constrExtraRestr;
global BLViewBox;
global RiskBudgetTable;

% from views tab:
global ViewsSetupTable;
global ViewsProbabilityTable;


%cmap = colormap;

used_corr=corr_curr{1};
used_stdev=stdev_curr{1};

noAssets = size(assetCl,1);


% get view returns

[ viewReturns viewProbabilities] = getViewReturnEstimates( ViewsSetupTable, ViewsProbabilityTable);



% determine risk contribution for each asset
[volConCurrent] = volContribution (cur_weight, used_corr, used_stdev);
constructionLayout = uiextras.VBox('Parent',tab_handle,'Padding',10);

%   ----------------------------------------
%   Porfolio Constuction -> top panel
%   kiezen view, optimazation target etc
%   ----------------------------------------


optimalizationTarget={'Maxt Return' 'Min TE' 'Min LPM<not implemented'};

filterGrid = uiextras.Grid( 'Parent', constructionLayout, 'Spacing', 5 );

% Select View for portfolio optimalization
uicontrol('Parent',filterGrid,'Style','text','String','Select View','HorizontalAlignment','left');
viewCnstrBox = uicontrol('Parent',filterGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',[viewNames 'Equilibrium'],'Callback', @updateConstructionTable);
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
% uicontrol( 'Parent', filterGrid, 'String', 'Update Table','Callback', @updateConstructionTable);

% Select covariance for portfolio optimalization
uicontrol('Parent',filterGrid,'Style','text','String','Select VCM','HorizontalAlignment','left');
VCMCnstrBox = uicontrol('Parent',filterGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',corNames,'Callback', @updateCov);
uiextras.Empty( 'Parent', filterGrid );
uiextras.Empty( 'Parent', filterGrid );
% uicontrol( 'Parent', filterGrid, 'String', 'Update Table','Callback', @updateConstructionTable);

uicontrol('Parent',filterGrid,'Style','text','String','Select Target','HorizontalAlignment','left');
targetCnstrBox = uicontrol('Parent',filterGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',optimalizationTarget);
uiextras.Empty( 'Parent', filterGrid );
uicontrol( 'Parent', filterGrid, 'String', 'Add extra Restriction','Callback', @addExtraRestriction);
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

set( filterGrid, 'ColumnSizes', [100 100 100 200 100 20 100 200 100 100], 'RowSizes', [20 20 20 20] );

sizePanels=100;

%   ----------------------------------------
%
% table met weight restricties:
%
%   ----------------------------------------

columnname =   {'<html><b>AssetClass','<html><b>Asset Categorie', '<html><b>Lower Limit', '<html><b>Upper Limit','<html><b>Low.Lim.Sub', '<html><b>Up.Lim.Sub','<html><b>Target TE Contrib (Rel)', '<html><b>View Returns','<html><b>st.dev','<html><b>View IR'};
columnformat = {'char',{'Matching portefeuille' 'Return portefeuille'}, 'bank', 'bank', 'bank','bank', 'bank', 'short'};
columneditable =  [false true true true true true true true false]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1:2) = num2cell(150);
colwith(3:end) = num2cell(75);

assetRestRet = [assetCl assetCategorie num2cell(lowerBound*100) num2cell(upperBound*100) num2cell(lowerBsubPort*100) num2cell(upperBsubPort*100) num2cell(zeros(noAssets,1)) num2cell(zeros(noAssets,1)) num2cell(zeros(noAssets,1))];

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
%   Portfolio Constructie tab: 
%   extra restricties -> relatieve gewichten asset classes
%
%   ----------------------------------------



columnname =   {'<html><b>Restrictie','<html><b>Asset Class', '<html><b>Lower Limit', '<html><b>Upper Limit', '<html><b>Active', '<html><b>Group LL', '<html><b>Group UL', '<html><b>GrLimitActive'};
columnformat = {'char',assetCl', 'bank', 'bank', 'logical', 'bank', 'bank', 'logical'};
columneditable =  [true true true true true true true true]; 

noCol = size(columnname,2);

noER= size(restrictionNR,1);
ERActive = true(noER,1);

ExtraRestricties = [num2cell(restrictionNR) assetClsER num2cell(lowerBoundER*100) num2cell(upperBoundER*100) num2cell(ERActive) num2cell(groupLowerBound*100) num2cell(groupUpperBound*100) num2cell(logical(groupLimitActive))];


colwith = cell(1,noCol);
colwith(1:2) = num2cell(150);
colwith(3:end) = num2cell(100);

constrExtraRestr = uitable('Parent',constructionLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9],  'Data', ExtraRestricties,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        
sizePanels=[sizePanels -1];   




%   ----------------------------------------
% Portfolio Constructie tab: 
% Na optimalisatie table met berekende gewichten:
%
%   ----------------------------------------


constructionResultsLayout = uiextras.HBox('Parent',constructionLayout,'Padding',10);



columnname =   {'<html><b>AssetClass','<html><b>Equilibrium Weight','<html><b>Eq. TE Con (Abs)','<html><b>Eq. TE Con (Rel)', '<html><b>Optimal Weight','<html><b>Opt. TE Con (Abs)','<html><b>Opt. TE Con (Rel)', '<html><b>Difference','<html><b>rel all.','<html><b>Group W.','<html><b>Min W.','<html><b>Max W.','<html><b>St.Dev W.','<html><b>Experi'};
columnformat = {'char', 'bank', 'bank', 'bank', 'bank', 'bank', 'bank', 'bank', 'bank', 'bank'};
columneditable =  [false false false false]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1) = num2cell(150);
colwith(2:end) = num2cell(75);


portConsTable = uitable('Parent',constructionResultsLayout,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9],... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        
%
% summary
%

summaryGrid = uiextras.Grid( 'Parent', constructionResultsLayout, 'Spacing', 5 );

uiextras.Empty( 'Parent', summaryGrid );
uiextras.Empty( 'Parent', summaryGrid );
uiextras.Empty( 'Parent', summaryGrid );
uiextras.Empty( 'Parent', summaryGrid );
uiextras.Empty( 'Parent', summaryGrid );
uiextras.Empty( 'Parent', summaryGrid );
uiextras.Empty( 'Parent', summaryGrid );


uicontrol('Parent',summaryGrid,'Style','text','String','opt. return','HorizontalAlignment','left');
uicontrol('Parent',summaryGrid,'Style','text','String','opt. TE','HorizontalAlignment','left');
uicontrol('Parent',summaryGrid,'Style','text','String','opt. IR','HorizontalAlignment','left');
uiextras.Empty( 'Parent', summaryGrid );
uicontrol('Parent',summaryGrid,'Style','text','String','opt. return','HorizontalAlignment','left');
uicontrol('Parent',summaryGrid,'Style','text','String','opt. TE','HorizontalAlignment','left');
uicontrol('Parent',summaryGrid,'Style','text','String','opt. IR','HorizontalAlignment','left');


opt_return_result=uicontrol('Parent',summaryGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right');
opt_TE_result=uicontrol('Parent',summaryGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right');
opt_IR_result=uicontrol('Parent',summaryGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right');
uiextras.Empty( 'Parent', summaryGrid );
opt_return_MLFT=uicontrol('Parent',summaryGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right');
opt_TE__MLFT=uicontrol('Parent',summaryGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right');
opt_IR__MLFT=uicontrol('Parent',summaryGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right');


set( summaryGrid, 'ColumnSizes', [50 100 100], 'RowSizes', [20 20 20 20 20 20 20] );
        
set(constructionResultsLayout,'Sizes',[-2 -1]);        
sizePanels=[sizePanels -1];   







% Portfolio Constructie tab:
% buttons for construction method
%

constrButtonGrid = uiextras.Grid( 'Parent', constructionLayout, 'Spacing', 5 );

uicontrol( 'Parent', constrButtonGrid, 'String', 'Markowitz','Callback', @ConstructionMarkowitz);
uicontrol( 'Parent', constrButtonGrid, 'String', 'Mark. m. Extra','Callback', @ConstructionMarkowitzExtraRestrictions);


if (~productieVersie)

uicontrol( 'Parent', constrButtonGrid, 'String', 'BL to Excel','Callback', @BL2Excel);

else
uiextras.Empty( 'Parent', constrButtonGrid );

end

uicontrol( 'Parent', constrButtonGrid, 'String', 'Export Opt to excel','Callback', @exportOptimalizationToExcel);



uiextras.Empty( 'Parent', constrButtonGrid );

uicontrol( 'Parent', constrButtonGrid, 'String', 'Black Litterman','Callback', @ConstructionBL);


if productieVersie
    uiextras.Empty( 'Parent', constrButtonGrid );
else
    uicontrol( 'Parent', constrButtonGrid, 'String', 'BL Weicht Sc.','Callback', @ConstructionBLWeighted);
end


uicontrol('Parent',constrButtonGrid,'Style','text','String','min TE','HorizontalAlignment','left');
uicontrol('Parent',constrButtonGrid,'Style','text','String','max TE','HorizontalAlignment','left');
uiextras.Empty( 'Parent', constrButtonGrid );

%
% optimalizatie over range tracking error
%
uicontrol( 'Parent', constrButtonGrid, 'String', 'Markowitz TE','Callback', @ConstructionMWTERange);

if productieVersie
    uiextras.Empty( 'Parent', constrButtonGrid );
else
    uicontrol( 'Parent', constrButtonGrid, 'String', 'Black Litterman TE','Callback', @ConstructionBLTERange);
end
constMinTERange = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.00);
constMaxTERange = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.20);
uiextras.Empty( 'Parent', constrButtonGrid );

%
% text 
%
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uicontrol('Parent',constrButtonGrid,'Style','text','String','Asset','HorizontalAlignment','left');
uicontrol('Parent',constrButtonGrid,'Style','text','String','min Return','HorizontalAlignment','left');
uicontrol('Parent',constrButtonGrid,'Style','text','String','max Return','HorizontalAlignment','left');

%
%   buttons voor bepalen schaduw prijzen mbv markowicz of Black-Litterman
%   + select box voor kiezen asset-class
%
uicontrol( 'Parent', constrButtonGrid, 'String', 'MW return range','Callback', @ConstructionReturnRangeMW);

if productieVersie
    uiextras.Empty( 'Parent', constrButtonGrid );
else
    uicontrol( 'Parent', constrButtonGrid, 'String', 'BL return range','Callback', @ConstructionReturnRangeBL);
end
AssetCnstrBox = uicontrol('Parent',constrButtonGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',assetCl,'Callback',@updateAssetRange);
constMinReturn = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.00);
constMaxReturn = uicontrol('Parent',constrButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.20);

%
% check-boxes voor exporteren 'schaduw' prijzen naar excel
%
exportMWreturnRangeToExcel = uicontrol('Parent',constrButtonGrid,'Style','checkbox');

if productieVersie
    uiextras.Empty( 'Parent', constrButtonGrid );
else
    exportBLreturnRangeToExcel = uicontrol('Parent',constrButtonGrid,'Style','checkbox');
end
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );
uiextras.Empty( 'Parent', constrButtonGrid );

% buttons voor risk-budgetting en copieren van gewichten naar evenwichts
% tab
%
uicontrol( 'Parent', constrButtonGrid, 'String', 'copy weights to equilibrium','Callback', @CopyConstructionWeightsToEqui);
uicontrol( 'Parent', constrButtonGrid, 'String', 'copy Risk-Budget','Callback', @copyRiskBudget);
uicontrol( 'Parent', constrButtonGrid, 'String', 'RiskBudget Opt','Callback', @RBtarget);
uiextras.Empty( 'Parent', constrButtonGrid );

if productieVersie
    uiextras.Empty( 'Parent', constrButtonGrid );
else
    uicontrol( 'Parent', constrButtonGrid, 'String', 'Markow. Risk-Target','Callback', @MWRiskTarget);
end

%
%buttons voor grafieken
%

if productieVersie
    uiextras.Empty( 'Parent', constrButtonGrid );
    uiextras.Empty( 'Parent', constrButtonGrid );
    uiextras.Empty( 'Parent', constrButtonGrid );
    uiextras.Empty( 'Parent', constrButtonGrid );
    uiextras.Empty( 'Parent', constrButtonGrid );    
else
    uicontrol( 'Parent', constrButtonGrid, 'String', 'Pie Weights','Callback', @pieChartWeights);
    uicontrol( 'Parent', constrButtonGrid, 'String', 'Pie TE contribution','Callback', @pieChartTEContribution);
    uicontrol( 'Parent', constrButtonGrid, 'String', 'Bar Weights','Callback', @barChartWeigths);
    uicontrol( 'Parent', constrButtonGrid, 'String', 'Bar TE contribution','Callback', @barChartTEContribution);
    uiextras.Empty( 'Parent', constrButtonGrid );
end


%
set( constrButtonGrid, 'ColumnSizes', [100 100 100 120 100 200 100 100], 'RowSizes', [20 20 20 20 20] );

sizePanels=[sizePanels 120];
set( constructionLayout, 'Sizes', sizePanels);


% set Base-Case as selection:
updateConstructionTable()

    function updateConstructionTable(~, ~)
    %
    % update table with restrictions and selected view
    %
    
    % first get view returns from view tab to include updates
    [ viewReturns ~] = getViewReturnEstimates( ViewsSetupTable, ViewsProbabilityTable);

    
    % which view is selected:
    noViews = size(viewNames,2);
    selectView = get(viewCnstrBox,'value');
    
    % get current resticties    
    curConstRest = get(constrRestr,'Data');
    
    
    if (selectView > noViews)
    % equilibrium choosen as scenario
        equiAllocation = get(equilibriumTable,'Data');
        curConstRest = [curConstRest(:,1:6) equiAllocation(:,5)];    
        curConstRest = [curConstRest(:,1:6) num2cell(zeros(noAssets,1)) equiAllocation(:,5)];
        
    else
    
    % add returns of the view
    curConstRest = [curConstRest(:,1:7) num2cell(viewReturns(:,selectView)*100) num2cell(used_stdev*100) num2cell(viewReturns(:,selectView)./used_stdev)];
    
    end
    
    set(constrRestr,'Data',curConstRest); % update table
    
    % update ook summary gegevens
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight*100;sum(cur_weight)*100]) ...
    num2cell([volConCurrent'*100;sum(volConCurrent*100)]) num2cell([100*volConCurrent'/sum(volConCurrent);1]) ...
    num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1))];


    set(portConsTable,'Data',assetWeights);

    end


    function CopyConstructionWeightsToEqui(~,~)
    
    
        optimized_portfolio=get(portConsTable,'Data');
        
        equiAllocation = get(equilibriumTable,'Data');        
        %w0=cell2mat(equiAllocation(:,2));    
        
        equiAllocation(:,2)=optimized_portfolio(1:(end-1),5);

        set(equilibriumTable,'Data',equiAllocation);
    end
        

    %%
    function ConstructionMarkowitz(~,~)
    % CONSTRUCTIONMARKOWITZ
    % Optimize portfolio weights using Markowitz 
    
    updateConstructionTable()
    
    % get return-estimates from WB / TK cases
    % which view / return estimates is selected:
    selectView = get(viewCnstrBox,'value');
    
    noViews = size(viewNames,2);
    
    if (selectView > noViews)
        scen_names='Equilibrium';
    else
        scen_names=viewNames(selectView);
    end
    
    curConstRest = get(constrRestr,'Data');
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,8))/100;
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

  
    % met matlab Financial Toolbox -->nog unrestricted
    
    port_setup=Portfolio('Name','tst_Markwowitz');
    
    port_setup=port_setup.setAssetList (assetCl);
    port_setup=port_setup.setAssetMoments(return_est,cov_est);
  
    
    
    % set up restrictions for portfolio optimalization
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);
    
    
    % check of restricties gebruikt moeten worden
    
    port_setup = port_setup.setDefaultConstraints; % set budget constraints
    
    useRest = get (constUseRestr,'value');
    
    if (useRest) 
         port_setup=port_setup.setBounds(-Restricties.b(1:noAssets),Restricties.b(noAssets+1:2*noAssets));
    end

    
    
    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;   
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));
        
    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);
    mu=mean(output.mu);
    sig=mean(output.sig);

    min_opt_weights= min(output.wts,[],2);
    max_opt_weights= max(output.wts,[],2);
    
    st_dev_opt_weights=std(output.wts,[],2);
    
  
    bwgt = port_setup.estimateFrontierByRisk(Restricties.MaxTE);
    [PortRisk, PortReturn] = portstats(return_est', cov_est,bwgt')
    
    
    % bepaal nieuwe volContribution
    
    [volConOpt] = volContribution (opt_weight, used_corr, used_stdev);
    

    %
    % update tabel met gewichten
    %
    
    
    % bepaal relatieve gewichten, binnen de extra restricties
    
    maxER = max(Restricties.onx); % aantal sub-restricties
    relW=zeros(noAssets,1);
    for ii=1:maxER
    
    relativeW=Restricties.Ax(Restricties.onx==ii,:)*opt_weight/(sum(abs(Restricties.Ax(Restricties.onx==ii,:)*opt_weight),1)/2);
    
    relativeW=(relativeW' * Restricties.Ax(Restricties.onx==ii,:))/2;
    
    relW(relativeW>0)=relativeW(relativeW>0);
    end
    
    % asset class, current (equilibrium) weight, new weight, difference:
    
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight*100;sum(cur_weight)*100]) ...
    num2cell([volConCurrent'*100;sum(volConCurrent)*100]) num2cell([volConCurrent'*100/sum(volConCurrent);100]) ...
    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1)) num2cell([min_opt_weights;0]) num2cell([max_opt_weights;0]) num2cell([st_dev_opt_weights;0]) num2cell([100*bwgt;sum(100*bwgt)])];
%    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1))];

    set(portConsTable,'Data',assetWeights);
    
    
    
    set (opt_return_result,'String',mu);
    set (opt_TE_result,'String',sig);
    set (opt_IR_result,'String',mu/sig);        
    
    % restults using matlab financial toolbox
    set (opt_return_MLFT,'String',PortReturn);
    set (opt_TE__MLFT,'String',PortRisk);
    set (opt_IR__MLFT,'String',PortReturn/PortRisk);        
    
    
    
    showPlotAnnealing (output)
    end

 

    function ConstructionMarkowitz_tst(~,~)
    % CONSTRUCTIONMARKOWITZ
    % Optimize portfolio weights using Markowitz 
    
    updateConstructionTable()
    
    % get return-estimates from WB / TK cases
    % which view / return estimates is selected:
    
    selectView = get(viewCnstrBox,'value');
    
    noViews = size(viewNames,2);
    
    if (selectView > noViews)
        scen_names='Equilibrium';
    else
        scen_names=viewNames(selectView);
    end
    
    curConstRest = get(constrRestr,'Data');
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,8))/100;
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

    
    
    % set up portfolio object
    
    p=Portfolio ('Name',scen_names);
    
    p.setAssetList (assetCl);
    
    
    p.setAssetMoments(return_est,cov_est);
    
    % set up restrictions for portfolio optimalization
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);
    
    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;   
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));
        
    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);
    mu=mean(output.mu);
    sig=mean(output.sig);

    min_opt_weights= min(output.wts,[],2);
    max_opt_weights= max(output.wts,[],2);
    
    st_dev_opt_weights=std(output.wts,[],2);
    
    % bepaal nieuwe volContribution
    
    [volConOpt] = volContribution (opt_weight, used_corr, used_stdev);
    

    %
    % update tabel met gewichten
    %
    
    
    % bepaal relatieve gewichten, binnen de extra restricties
    
    maxER = max(Restricties.onx); % aantal sub-restricties
    relW=zeros(noAssets,1);
    for ii=1:maxER
    
    relativeW=Restricties.Ax(Restricties.onx==ii,:)*opt_weight/(sum(abs(Restricties.Ax(Restricties.onx==ii,:)*opt_weight),1)/2);
    
    relativeW=(relativeW' * Restricties.Ax(Restricties.onx==ii,:))/2;
    
    relW(relativeW>0)=relativeW(relativeW>0);
    end
    
    % asset class, current (equilibrium) weight, new weight, difference:
    
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight*100;sum(cur_weight)*100]) ...
    num2cell([volConCurrent'*100;sum(volConCurrent)*100]) num2cell([volConCurrent'*100/sum(volConCurrent);100]) ...
    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1)) num2cell([min_opt_weights;0]) num2cell([max_opt_weights;0]) num2cell([st_dev_opt_weights;0])];
%    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1))];

    set(portConsTable,'Data',assetWeights);
    
    
    
    set (opt_return_result,'String',mu);
    set (opt_TE_result,'String',sig);
    set (opt_IR_result,'String',mu/sig);        
    
    
    showPlotAnnealing (output)

    end
    %%
    function ConstructionMarkowitzExtraRestrictions(~,~)
    %
    % extra mogelijkheid om restricties op groep assets te doen.
    % ipv. restrictie op 1 asset, som van weight van groep assets is
    % restricted
    updateConstructionTable()
    
    selectView = get(viewCnstrBox,'value');
    
    noViews = size(viewNames,2);
    
    if (selectView > noViews)
        scen_names='Equilibrium';
    else
        scen_names=viewNames(selectView);
    end
    curConstRest = get(constrRestr,'Data');  
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,8))/100;
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(true);
    
    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));
        
    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);

    mu=mean(output.mu);
    sig=mean(output.sig);

    min_opt_weights= min(output.wts,[],2);
    max_opt_weights= max(output.wts,[],2);
    
    st_dev_opt_weights=std(output.wts,[],2);
    
    
    % bepaal nieuwe volContribution
    
    [volConOpt] = volContribution (opt_weight, used_corr, used_stdev);
    
   
    % update tabel met gewichten
    
    
    
    % bepaal relatieve gewichten, binnen de extra restricties
    
    maxER = max(Restricties.onx); % aantal sub-restricties
    relW=zeros(noAssets,1);
    
    groupW=zeros(noAssets,1);
    
    for ii=1:maxER
    
    relativeW=Restricties.Ax(Restricties.onx==ii,:)*opt_weight/(sum(abs(Restricties.Ax(Restricties.onx==ii,:)*opt_weight),1)/2);
    
    relativeW=(relativeW' * Restricties.Ax(Restricties.onx==ii,:))/2;
    
    relW(relativeW>0)=relativeW(relativeW>0);
    groupW(relativeW>0)=(sum(abs(Restricties.Ax(Restricties.onx==ii,:)*opt_weight),1)/2);

    
    end
    
    % asset class, current (equilibrium) weight, new weight, difference:
    
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight*100;sum(cur_weight)*100]) ...
    num2cell([volConCurrent'*100;sum(volConCurrent)*100]) num2cell([volConCurrent'*100/sum(volConCurrent);100]) ...
    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1)) num2cell([min_opt_weights;0]) num2cell([max_opt_weights;0]) num2cell([st_dev_opt_weights;0])];
%    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1))];

    set(portConsTable,'Data',assetWeights);
    
    
    % show plot met resultaten Annealing
    showPlotAnnealing (output)
        
    end

    %%
    function ConstructionMarkowitzWeightedScenarios(~,~)
    % CONSTRUCTIONMARKOWITZ
    % Optimize portfolio weights using Markowitz over different scenarios
    
    % use weighted utility function over all scenarios
    
    updateConstructionTable()
    
    % get return-estimates from WB / TK cases
    % which view / return estimates is selected:
    
    scen_names='Weighted Markowitz';
    
    
    % first get view returns from view tab to include updates
    [ viewReturns viewProbabilities] = getViewReturnEstimates( ViewsSetupTable, ViewsProbabilityTable);

    viewReturns =  viewReturns(:,viewProbabilities(1,:)~=0);    
    viewProbabilities=viewProbabilities(1,viewProbabilities(1,:)~=0);
    
    noNonZeroProb = size(viewProbabilities,2);
    weightedReturns=zeros(noAssets,1);
    for ii=1:noNonZeroProb
    
        weightedReturns = weightedReturns+viewProbabilities(ii)*viewReturns(:,ii);
        
    end
    
    
    
    % get current resticties    
    curConstRest = get(constrRestr,'Data');
    


    % add returns of the view
    curConstRest = [curConstRest(:,1:7) num2cell(weightedReturns*100) num2cell(used_stdev*100) num2cell(weightedReturns./used_stdev)];
    

    
    set(constrRestr,'Data',curConstRest); % update table

    
    % cov matrix
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

    
    % set up restrictions for portfolio optimalization
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);
    
    pars.meanmat=viewReturns;
    pars.probs = viewProbabilities;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;   
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));
        
    output   = PortefeuilleOptimalisatieWeighted(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);
    mu=mean(output.mu);
    sig=mean(output.sig);

    min_opt_weights= min(output.wts,[],2);
    max_opt_weights= max(output.wts,[],2);
    
    st_dev_opt_weights=std(output.wts,[],2);

    
    % bepaal nieuwe volContribution
    
    [volConOpt] = volContribution (opt_weight, used_corr, used_stdev);
    

    %
    % update tabel met gewichten
    %
    
    
    % bepaal relatieve gewichten, binnen de extra restricties
    
    maxER = max(Restricties.onx); % aantal sub-restricties
    relW=zeros(noAssets,1);
    for ii=1:maxER
    
    relativeW=Restricties.Ax(Restricties.onx==ii,:)*opt_weight/(sum(abs(Restricties.Ax(Restricties.onx==ii,:)*opt_weight),1)/2);
    
    relativeW=(relativeW' * Restricties.Ax(Restricties.onx==ii,:))/2;
    
    relW(relativeW>0)=relativeW(relativeW>0);
    end
    
    % asset class, current (equilibrium) weight, new weight, difference:
    
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight*100;sum(cur_weight)*100]) ...
    num2cell([volConCurrent'*100;sum(volConCurrent)*100]) num2cell([volConCurrent'*100/sum(volConCurrent);100]) ...
    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1)) num2cell([min_opt_weights;0]) num2cell([max_opt_weights;0]) num2cell([st_dev_opt_weights;0])];
%    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1))];

    set(portConsTable,'Data',assetWeights);
    
    
    
    set (opt_return_result,'String',mu);
    set (opt_TE_result,'String',sig);
    set (opt_IR_result,'String',mu/sig);        
    
    
    showPlotAnnealing (output)
    
    end


    %%
 


    function MWRiskTarget(~,~)
    % TODO: optimize return portfolio with equal risk-budget for assets
    
    noViews = size(viewNames,2);
    
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
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);
    
    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    
    % extra restrictie / instellingen voor risk-budgetting

    % get current restrictions
    curRestr=get(constrRestr,'Data');    
     
    
    pars.useRiskBudgetting = true;
    pars.assetCategorie = strcmp(assetCategorie, 'Return portefeuille');
    
    pars.RiskBudget=cell2mat(curRestr(:,7))/100;
    Restricties.MaxTE_actief = 0; % turn off target TE -> already in risk-budgets
    

    % aantal interaties en portfolios voor Simulated Annealing
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));
        
    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);
    
    mu=mean(output.mu);
    sig=mean(output.sig);

    min_opt_weights= min(output.wts,[],2);
    max_opt_weights= max(output.wts,[],2);
    
    st_dev_opt_weights=std(output.wts,[],2);
    
    % TE contribution after Optimization:
    
    [volConOpt] = volContribution (opt_weight, used_corr, used_stdev);
    
    % update tabel met resultaten
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([100*cur_weight;100*sum(cur_weight)]) ...
    num2cell([100*volConCurrent';100*sum(volConCurrent)]) num2cell([100*volConCurrent'/sum(volConCurrent);100]) ...
    num2cell([100*opt_weight;100*sum(opt_weight)]) num2cell([100*volConOpt';100*sum(volConOpt)]) num2cell([100*volConOpt'/sum(volConOpt);100]) num2cell(100*[opt_weight-cur_weight;0])];


    set(portConsTable,'Data',assetWeights);
        
    set (opt_return_result,'String',mu);
    set (opt_TE_result,'String',sig);
    set (opt_IR_result,'String',mu/sig);
    
    end


%%        
    function ConstructionBL (~,~)
    
    %
    %   black litterman optimalization volgens Meuci
    %   'The Black Litterman Approach, original model and extensions'
    %   Aug-2008
        
        
    % which view / scenario is selected
    return_est = get(BLViewReturns,'Data');
    return_est=cell2mat(return_est(:,2:end));

%     stdev_est = get (BLSTdev,'Data');
%     
%     corr_est=cell2mat(corr_est(:,2:end))/100;
%     stdev_est=cell2mat(stdev_est)/100;
%     
    
    covPrior= get(BLCovriancePrior, 'Data');
    cov_est = cell2mat(covPrior(:,2:end))/100;; % calculate cov. from correlation / st.dev

    
    
    selectView = get(BLViewBox,'value');
    scen_names=viewNames(selectView);
        

    
    % bepaal views structuur -> absolute visies of relatieve
    views=get(BLViewReturns,'Data');
    views=cell2mat(views(:,2:end));

    P=(views~=0);

    if P==eye(size(P))  
        
        % alleen absolute visies
    
        return_est=diag(return_est);
    
    end
    
    
    % bepaal onzekerheid op visies
    Ohm=get(BLViewUncertainty,'Data');
    Ohm=cell2mat(Ohm(:,2:end));

    % onzekerheid parameter op markt/evenwicht
    tau=str2double(get(constMarketUncertainty,'String'));
    
    % market equilibrium --> TODO:
    
    equiAllocation = get (equilibriumTable,'Data');
    
    w_market=cell2mat(equiAllocation(:,2))/100;     % evenwichts gewichten
    pi_market = cell2mat(equiAllocation(:,5))/100;  % evenwichts returns

    
    
    %
    
    
    [mu_BL_pos,Sig_BL_pos,mu_BL_full_conf,Sig_BL_full_conf]=BL_classic(return_est,cov_est,pi_market,tau,P,Ohm);


    set(BLReturns,'Data',num2cell(100*mu_BL_pos));
    set(BLCovriancePosterior,'Data',num2cell(100*Sig_BL_pos));
    
    
    
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);

    pars.meanmat=mu_BL_pos;
    pars.covmat=Sig_BL_pos;

    pars.useRiskBudgetting=false;   % geen risk-budgetting
    
    
    
    
    % met matlab Financial Toolbox:
    
    port_setup=Portfolio('Name','tst_BL');
    
    port_setup=port_setup.setAssetList (assetCl);
    port_setup=port_setup.setAssetMoments(mu_BL_pos,Sig_BL_pos);

    port_setup = port_setup.setDefaultConstraints;
    
    % check of restricties gebruikt moeten worden
    
    port_setup = port_setup.setDefaultConstraints; % set budget constraints
    
    useRest = get (constUseRestr,'value');
    
    if (useRest) 
         port_setup=port_setup.setBounds(-Restricties.b(1:noAssets),Restricties.b(noAssets+1:2*noAssets));
    end
    
    
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));

    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);    
    mu=mean(output.mu);
    sig=mean(output.sig);

    min_opt_weights= min(output.wts,[],2);
    max_opt_weights= max(output.wts,[],2);
    
    st_dev_opt_weights=std(output.wts,[],2);
    
    
    

    bwgt = port_setup.estimateFrontierByRisk(Restricties.MaxTE);
    [PortRisk, PortReturn] = portstats(return_est', cov_est,bwgt')

    
    % bepaal nieuwe volContribution
    
    [volConOpt] = volContribution (opt_weight, used_corr, used_stdev);
    

    %
    % update tabel met gewichten
    %
    
    
    % bepaal relatieve gewichten, binnen de extra restricties
    
    maxER = max(Restricties.onx); % aantal sub-restricties
    relW=zeros(noAssets,1);
    for ii=1:maxER
    
    relativeW=Restricties.Ax(Restricties.onx==ii,:)*opt_weight/(sum(abs(Restricties.Ax(Restricties.onx==ii,:)*opt_weight),1)/2);
    
    relativeW=(relativeW' * Restricties.Ax(Restricties.onx==ii,:))/2;
    
    relW(relativeW>0)=relativeW(relativeW>0);
    end
    
    % asset class, current (equilibrium) weight, new weight, difference:
    
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight*100;sum(cur_weight)*100]) ...
    num2cell([volConCurrent'*100;sum(volConCurrent)*100]) num2cell([volConCurrent'*100/sum(volConCurrent);100]) ...
    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1)) num2cell([min_opt_weights;0]) num2cell([max_opt_weights;0]) num2cell([st_dev_opt_weights;0]) num2cell([100*bwgt;sum(100*bwgt)])];
%    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1))];

    set(portConsTable,'Data',assetWeights);
    
    
    % result simulated annealing
    set (opt_return_result,'String',mu);
    set (opt_TE_result,'String',sig);
    set (opt_IR_result,'String',mu/sig);        
    
    % results using matlab financial toolbox
    set (opt_return_MLFT,'String',PortReturn);
    set (opt_TE__MLFT,'String',PortRisk);
    set (opt_IR__MLFT,'String',PortReturn/PortRisk);    
    
    
    showPlotAnnealing (output)    
    
    end

%%
    function ConstructionBLWeighted (~,~)
    %
    %   black litterman optimalization volgens Meuci
    %   'The Black Litterman Approach, original model and extensions'
    %   Aug-2008
        

    % experimental -> use weighted views
    

    
    % temporay: use standard views for weighted scenarios:

    % first get view returns from view tab to include updates
    [ viewReturns viewProbabilities] = getViewReturnEstimates( ViewsSetupTable, ViewsProbabilityTable);

    viewReturns =  viewReturns(:,viewProbabilities(1,:)~=0);    
    viewProbabilities=viewProbabilities(1,viewProbabilities(1,:)~=0);
    
    noNonZeroProb = size(viewProbabilities,2);

    % standard views:
    
    P=diag(ones(noAssets,1));
    
    
    % use one CVM
    corr_est= get(BLCorrTable, 'Data');
    stdev_est = get (BLSTdev,'Data');
    
    corr_est=used_corr;
    stdev_est=used_stdev;
    
    cov_est = corr_est.*(stdev_est*stdev_est'); % calculate cov. from correlation / st.dev
    
    
    
    scen_names='Weighted Black Litterman';
        

 
    
    % bepaal onzekerheid op visies
    Ohm=get(BLViewUncertainty,'Data');
    Ohm=cell2mat(Ohm(:,2:end));
    
    
    C=str2double(get(constViewUncertainty,'String')); 
    OhmWeight=zeros(noNonZeroProb*noAssets,noAssets);
    
    for ii=1:noNonZeroProb
    
    Cweight=C/viewProbabilities(ii);    
        
    Ohm= BLViewMeucci(used_corr,used_stdev,Cweight,P);
    OhmWeight((ii-1)*noAssets+1:(ii*noAssets),:)=Ohm;
    end
    
    P=repmat(P,3,1)
    
    % onzekerheid parameter op markt/evenwicht
    tau=str2double(get(constMarketUncertainty,'String'));
    
    % market equilibrium --> TODO:
    
    equiAllocation = get (equilibriumTable,'Data');
    
    w_market=cell2mat(equiAllocation(:,2))/100;     % evenwichts gewichten
    pi_market = cell2mat(equiAllocation(:,5))/100;  % evenwichts returns

    
    
    %
    
    
    [mu_BL_pos,Sig_BL_pos,mu_BL_full_conf,Sig_BL_full_conf]=BL_classicWeighted(viewReturns(:),cov_est,pi_market,tau,P,OhmWeight);


    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);

    pars.meanmat=mu_BL_pos;
    pars.covmat=Sig_BL_pos;

    pars.useRiskBudgetting=false;   % geen risk-budgetting
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));

    output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

    % resultaat -> neem gemidddelde van simulated annealing
    opt_weight=mean(output.wts,2);    
    mu=mean(output.mu);
    sig=mean(output.sig);
    
    min_opt_weights= min(output.wts,[],2);
    max_opt_weights= max(output.wts,[],2);
    
    st_dev_opt_weights=std(output.wts,[],2);
   
    % bepaal nieuwe volContribution
    
    [volConOpt] = volContribution (opt_weight, used_corr, used_stdev);
    

    %
    % update tabel met gewichten
    %
    
    
    % bepaal relatieve gewichten, binnen de extra restricties
    
    maxER = max(Restricties.onx); % aantal sub-restricties
    relW=zeros(noAssets,1);
    for ii=1:maxER
    
    relativeW=Restricties.Ax(Restricties.onx==ii,:)*opt_weight/(sum(abs(Restricties.Ax(Restricties.onx==ii,:)*opt_weight),1)/2);
    
    relativeW=(relativeW' * Restricties.Ax(Restricties.onx==ii,:))/2;
    
    relW(relativeW>0)=relativeW(relativeW>0);
    end
    
    % asset class, current (equilibrium) weight, new weight, difference:
    
    assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([cur_weight*100;sum(cur_weight)*100]) ...
    num2cell([volConCurrent'*100;sum(volConCurrent)*100]) num2cell([volConCurrent'*100/sum(volConCurrent);100]) ...
    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1)) num2cell([min_opt_weights;0]) num2cell([max_opt_weights;0]) num2cell([st_dev_opt_weights;0])];
%    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1))];
    set(portConsTable,'Data',assetWeights);
    
    
    
    set (opt_return_result,'String',mu);
    set (opt_TE_result,'String',sig);
    set (opt_IR_result,'String',mu/sig);        
    
    
    showPlotAnnealing (output)            
        
        
    end

    
    function ConstructionMWTERange(~,~)
    %
    % optimalizeer portfolio met verschillende Tracking Error targets
    %
 
    % which view / scenario is selected

    selectView = get(viewCnstrBox,'value');
    scen_names=viewNames(selectView);
    
    
     curConstRest = get(constrRestr,'Data');  
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,end));
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

    % set up restrictions
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);

    pars.meanmat=return_est;
    pars.covmat=cov_est;
    pars.useRiskBudgetting=false;
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));


    % range TE
    noTESteps=10;
    
    minTE = str2double(get(constMinTERange,'String'));
    maxTE = str2double(get(constMaxTERange,'String'));
    
    stepSizeTE=(maxTE - minTE)/noTESteps;
    
    
    weighMatrix=zeros(noAssets,(noTESteps+1));
    portfolioMu=zeros((noTESteps+1),1);
    portfolioSig=zeros((noTESteps+1),1);
    
    for kk=0:noTESteps
    
        stream = RandStream('mt19937ar','seed',20111008); % simulated annealing is met Niter=500 en Nport=500 nog steeds erg gevoelig voor 
%         RandStream.setDefaultStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        RandStream.setGlobalStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        
        
        Restricties.MaxTE=(minTE+stepSizeTE*kk);
        output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

        % resultaat -> neem gemidddelde van simulated annealing
        weighMatrix(:,kk+1)=mean(output.wts,2);    
        portfolioMu(kk+1)=mean(output.mu);
        portfolioSig(kk+1)=mean(output.sig);
        
    end
    
    % allocation as function of TE
    figure('Name','Allocation as function of TE');
    area(weighMatrix');
    legend(assetCl, 'Location', 'SouthWest');
    
    xlabel('TE');
    ylabel('Weights');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minTE:stepSizeTE:maxTE)
    axis([1 (noTESteps+1) 0 1]);
            
    
    % portfolio return as function of TE
    figure('Name','Estimated Return as function of TE');
    plot(minTE:stepSizeTE:maxTE,portfolioMu);
    
    xlabel('TE');
    ylabel('Portfolio Return');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minTE:stepSizeTE:maxTE)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        

    % portfolio IR as function of TE
    figure('Name','IR as function of TE');
    plot(minTE:stepSizeTE:maxTE,(portfolioMu./portfolioSig));
    
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

    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));

    % range TE
    noTESteps=10;
    
    minTE = str2double(get(constMinTERange,'String'));
    maxTE = str2double(get(constMaxTERange,'String'));
    
    stepSizeTE=(maxTE - minTE)/noTESteps;
    
    
    weighMatrix=zeros(noAssets,(noTESteps+1));
    portfolioMu=zeros((noReturnSteps+1),1);
    portfolioSig=zeros((noReturnSteps+1),1);
    
    for kk=0:noTESteps
    
        stream = RandStream('mt19937ar','seed',20111008); % simulated annealing is met Niter=500 en Nport=500 nog steeds erg gevoelig voor 
%         RandStream.setDefaultStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        RandStream.setGlobalStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        
        Restricties.MaxTE=(minTE+stepSizeTE*kk);
        output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

        % resultaat -> neem gemidddelde van simulated annealing
        weighMatrix(:,kk+1)=mean(output.wts,2);    
        portfolioMu(kk+1)=mean(output.mu);
        portfolioSig(kk+1)=mean(output.sig);
        
    end
    
    % first graphs -> allocation as function of TE
    figure('Name','Allocation as function of TE');
    area(weighMatrix');
    legend(assetCl, 'Location', 'SouthWest');
    
    xlabel('TE');
    ylabel('Weights');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minTE:stepSizeTE:maxTE)
    axis([1 (noTESteps+1) 0 1]);
    
    
    
    
    end


    function [optTarget,pars,Restricties]=setUpOptimizationRestrictions(ERActive)
    
    % set up optimization restriction
    % ERActive = TRUE / FALSE flag voor extra restricties
    
    
    
    
    % Haal restricties uit tabel:
    curConstRest = get(constrRestr,'Data');  
    
    
 
    % which optimization target is selected:
    optTarget = get(targetCnstrBox,'value');
    
    
    % check of restricties gebruikt moeten worden
    useRest = get (constUseRestr,'value');
    
    %Verwerk restricties op portefeuillegewichten
    A_restr   = [-eye(noAssets);eye(noAssets)]; 
     
    
    if (useRest) 
        lowerLimWeights = cell2mat(curConstRest(:,3))/100;
        upperLimWeights = cell2mat(curConstRest(:,4))/100;
        
        
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
    targetTE=str2double(get(constTargetTE,'String'));
    
    % min return / LPM -> niet gebruikt op dit moment
    MinRet=0;
    MinRet_actief=0;
    
    MaxLPM=0.02;
    MaxLPM_actief=0;
    
    doelstelling=1; % max return
    
    Rest_turnover=1.0;  % restrictie max-turnover -> niet gebruikt op dit moment
    
	stream = RandStream('mt19937ar','seed',20111008); 
% 	RandStream.setDefaultStream(stream);
    RandStream.setGlobalStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
	
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
    

    % extra restricties, gebruik voor relatieve gewichten verschillende
    % asset classes
    
    if (ERActive)
    % Extra restricties
    extraRestr = get(constrExtraRestr,'Data');    
    activeER = cell2mat(extraRestr(:,8));
    noActiveER = sum(activeER);
    
    
    Rest_extra_NR=extraRestr(activeER,:);
    
    % set up restrictie matrix voor extra-restricties
    ERAsset=zeros(noActiveER,1);
    ER.A = zeros(noActiveER*2,noAssets);
    
    ER.min_w = cell2mat(extraRestr(:,6))/100;           % groep limieten
    ER.max_w = cell2mat(extraRestr(:,7))/100;

    ER.include_groupLimit = cell2mat(extraRestr(:,8));
    
    for ii=1:noActiveER
    
        
        ERAsset(ii)=(1:noAssets)*strcmp(assetCl,extraRestr{ii,2});

        ER.A(ii,:)=-strcmp(assetCl,extraRestr{ii,2});           
        ER.A(noActiveER+ii,:)=strcmp(assetCl,extraRestr{ii,2});


     
    end
    
    ER.b=[-cell2mat(extraRestr(:,3))/100;cell2mat(extraRestr(:,4))/100];

    % extra restricties op relatieve gewichten.
    % 1e kolom geeft restrictie NR. Relatieve gewichten gelden binnen dit
    % restrictie NR. Dus, de gewichten van alle assets die gemerkt worden 
    % met restrictie NR 1, tellen op tot 100%, en dan geldt de restrictie
    % op de (relatieve) gewichten van deze assets
    
    Restricties.ExtraActive = ERActive;
    Restricties.Ax = ER.A;  % extra restricties -> op dit moment niet gebruikt.
    Restricties.bx = ER.b;
    Restricties.groupLB = ER.min_w;
    Restricties.groupUB = ER.max_w;
    Restricties.includeGL = ER.include_groupLimit;
    Restricties.onx = [cell2mat(extraRestr(:,1));cell2mat(extraRestr(:,1))];   
    
    else
        Restricties.Ax=[];
        Restricties.onx=[];
        Restricties.ExtraActive = false;
    end % Extra Restricties Active
    
%     Rest_extra_A=extraRestr(cell2mat(extraRestr(:,5)),:);
%     Rest_extra_b=zeros(1,noAssets);
%     Rest_extra=zeros(1,noAssets);
    


    
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

%     function ret_graph_eq(~,~)
%     
%     equiAllocation = get(equilibriumTable,'Data');      
%     
%     
%     end


    function pieChartTEContribution(~,~)
    end

    function barChartWeigths(~,~)
    end
    
    function barChartTEContribution(~,~)
        
        
        
        % get weights of optimized portfolio
        
        optimizedWeights =  get(portConsTable,'Data');
        
        % TODO: als correlatie / stdev aanpasbaar wordt in GUI -> hier ook
        % ophalen!
        
        % first determine TE contribution current / equilibrium allocation
        % weights equilibrium / current portfolio in column 2
        [ volCon_equi ] = volContribution (cell2mat(optimizedWeights(1:(end-1),2)), used_corr, used_stdev);
 
        % weights optimized portfolio in column 5:
        [ volCon_opt ] = volContribution (cell2mat(optimizedWeights(1:(end-1),5)), used_corr, used_stdev);
        
        
        
        %curColMap = colormap();
        % define colormap for stacked bar-chart
        colMap(1,:) = ([1 1 1]);
        colMap(2,:) = ([0 0 143/255]);

        
        % sort risk-contribution
        [volContributionSort id]=sort(volCon_opt,'descend');
        [volContributionSortEqui idEqui]=sort(volCon_equi,'descend');
        
        
        yy=[0 cumsum(volContributionSort(1:(end-1)))];
        
        yy_equi=[0 cumsum(volContributionSortEqui(1:(end-1)))];
        
        
        TEConTR=figure('Name','Contribution to Risk (after optimization)');
        TEGraph = axes('Parent', TEConTR); % 'Position',[1 50 100 150]
        bar(TEGraph,1:noAssets,[yy' volContributionSort'],0.8, 'stack','edgecolor','none')
        set(TEGraph,'XTickLabel',assetCl(id));
        colormap(TEGraph,colMap)
        xticklabel_rotate([],90);

        
        TEConTR_equi=figure('Name','Contribution to Risk (current)');
        
        eqTEGraph = axes('Parent', TEConTR_equi); % 'Position',[1 50 100 150]
        bar(eqTEGraph,1:noAssets,[yy_equi' volContributionSortEqui'],0.8, 'stack','edgecolor','none')
        set(eqTEGraph,'XTickLabel',assetCl(idEqui));
        colormap(eqTEGraph,colMap)
        xticklabel_rotate([],90)
        
        
        
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
    return_est = cell2mat(curConstRest(:,8))/100;
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

    % set up restrictions
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);

    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));


    % range Return
    noSteps=20;   % TODO: currently hardcoded -> change?
    
    minReturn = str2double(get(constMinReturn,'String'));
    maxReturn = str2double(get(constMaxReturn,'String'));
    
    stepSize=(maxReturn - minReturn)/noSteps;
    
    
    % selected asset
    selAss=get(AssetCnstrBox,'value');
    
    weighMatrix=zeros(noAssets,(noSteps+1));
    portfolioMu=zeros((noSteps+1),1);
    portfolioSig=zeros((noSteps+1),1);
    
    for kk=0:noSteps
    
        stream = RandStream('mt19937ar','seed',20111008); % simulated annealing is met Niter=500 en Nport=500 nog steeds erg gevoelig voor 
%         RandStream.setDefaultStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        RandStream.setGlobalStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        
        return_est(selAss)=minReturn+kk*stepSize;
        pars.meanmat=return_est;       
        
        output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

        % resultaat -> neem gemidddelde van simulated annealing
        weighMatrix(:,kk+1)=mean(output.wts,2);    
        portfolioMu(kk+1)=mean(output.mu);
        portfolioSig(kk+1)=mean(output.sig);
        
    end
    
    % allocation as function of TE
    figure('Name',['Allocation as function of Return ',assetCl{selAss}]);
    area(weighMatrix');
    legend(assetCl, 'Location', 'SouthWest');
    
    xlabel('Return');
    ylabel('Weights');
    
    set(gca,'Layer','top')

    axis([1 (noSteps+1) 0 1]);
%     set(gca,'XTickLabel',minReturn:stepSize:maxReturn)           
     
     set(gca,'XTickLabel',(minReturn+2*stepSize):2*stepSize:maxReturn) % qucik and dirty
    
    % portfolio return as function of TE
    figure('Name',['Estimated Return as function of Return ',assetCl{selAss}]);
    plot(minReturn:stepSize:maxReturn,portfolioMu);
    
    xlabel('Return');
    ylabel('Portfolio Return');
    
    set(gca,'Layer','top')
%     set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'XTickLabel',(minReturn+2*stepSize):2*stepSize:maxReturn) % qucik and dirty
    
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        

    % portfolio IR as function of return
    figure('Name',['IR as function of Return ',assetCl{selAss}]);
    plot(minReturn:stepSize:maxReturn,(portfolioMu./portfolioSig));
    
    xlabel('Return');
    ylabel('Portfolio IR');
    
    set(gca,'Layer','top')
%     set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'XTickLabel',(minReturn):2*stepSize:maxReturn) % qucik and dirty
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        
    
    
    
    % WEIGHT selected asset as function of return
    figure('Name',['Weight as function of Return ',assetCl{selAss}]);
    plot(minReturn:stepSize:maxReturn,weighMatrix(selAss,:));
    
    xlabel('Return');
    ylabel('Weight Asset');
    
    set(gca,'Layer','top')
%     set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'XTickLabel',(minReturn):2*stepSize:maxReturn) % qucik and dirty
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');
    
    % check if results also needs to be exported to excel:
    
    exportToExcel = get (exportMWreturnRangeToExcel,'value');
    
    if exportToExcel
    
        % gewicht als functie return
        
        weightFunRet = [(minReturn:stepSize:maxReturn)' (weighMatrix(selAss,:))'];
        
          xlswrite('port_contr.xlsx',[{'return' 'weight'};num2cell(weightFunRet)],['schaduw ' assetCl{selAss}],'A1');

        
        
    end
    
    
    end
    


    function ConstructionReturnRangeBL(~,~)
    %
    %   change return of a specific asset class between the selected range
    %   and see how this impacts the allocaion
    %
    
    
    % TODO --> aanpassen voor Black-Litterman
    
    
    % which view / scenario is selected
    % returns other assets are kept constant -> returns from the view are
    % used
    
    selectView = get(viewCnstrBox,'value');
    scen_names=viewNames(selectView);
    
    
    curConstRest = get(constrRestr,'Data');  
    
    % view return / cov
    return_est = cell2mat(curConstRest(:,8))/100;
    cov_est = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

    % set up restrictions
    [optTarget,pars,Restricties]=setUpOptimizationRestrictions(false);

    pars.meanmat=return_est;
    pars.covmat=cov_est;
    
    pars.useRiskBudgetting=false;
    
    Niter=str2double(get(constNIter,'String'));
    Nport=str2double(get(constNPort,'String'));


    % range Return
    noSteps=10;   % TODO: currently hardcoded -> change?
    
    minReturn = str2double(get(constMinReturn,'String'));
    maxReturn = str2double(get(constMaxReturn,'String'));
    
    stepSize=(maxReturn - minReturn)/noSteps;
    
    
    % selected asset
    selAss=get(AssetCnstrBox,'value');
    
    weighMatrix=zeros(noAssets,(noSteps+1));
    portfolioMu=zeros((noSteps+1),1);
    portfolioSig=zeros((noSteps+1),1);
    
    for kk=0:noSteps
    
        stream = RandStream('mt19937ar','seed',20111008); % simulated annealing is met Niter=500 en Nport=500 nog steeds erg gevoelig voor 
%         RandStream.setDefaultStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        RandStream.setGlobalStream(stream);              % start waarde Random NR, kan 5% verschil in allocatie opleveren!!  
        
        return_est(selAss)=minReturn+kk*stepSize;
        pars.meanmat=return_est;       
        
        output   = PortefeuilleOptimalisatie(optTarget,pars,Restricties,Niter,Nport,scen_names);

        % resultaat -> neem gemidddelde van simulated annealing
        weighMatrix(:,kk+1)=mean(output.wts,2);    
        portfolioMu(kk+1)=mean(output.mu);
        portfolioSig(kk+1)=mean(output.sig);
        
    end
    
    
    
    %
    %   Graphs - Schaduw rendementen
    %
    
    % allocation as function of TE
    figure('Name',['Allocation as function of Return ',assetCl{selAss}]);
    area(weighMatrix');
    legend(assetCl, 'Location', 'SouthWest');
    
    xlabel('Return');
    ylabel('Weights');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    axis([1 (noSteps+1) 0 1]);
            
    
    % portfolio return as function of TE
    figure('Name',['Estimated Return as function of Return ',assetCl{selAss}]);
    plot(minReturn:stepSize:maxReturn,portfolioMu);
    
    xlabel('Return');
    ylabel('Portfolio Return');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        

    % portfolio IR as function of return
    figure('Name',['IR as function of Return ',assetCl{selAss}]);
    plot(minReturn:stepSize:maxReturn,(portfolioMu./portfolioSig));
    
    xlabel('Return');
    ylabel('Portfolio IR');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');        
    
    
    
    % WEIGHT selected asset as function of return
    figure('Name',['Weight as function of Return ',assetCl{selAss}]);
    plot(minReturn:stepSize:maxReturn,weighMatrix(selAss,:));
    
    xlabel('Return');
    ylabel('Weight Asset');
    
    set(gca,'Layer','top')
    set(gca,'XTickLabel',minReturn:stepSize:maxReturn)
    set(gca,'Xgrid','on');
    set(gca,'Ygrid','on');
    
    
    
    %
    % check if results also needs to be exported to excel:
    %
    
    exportToExcel = get (exportBLreturnRangeToExcel,'value');
    
    if exportToExcel
    
        % gewicht als functie return
        
        weightFunRet = [(minReturn:stepSize:maxReturn)' (weighMatrix(selAss,:))'];
        
          xlswrite('port_contr.xlsx',[{'return' 'weight'};num2cell(weightFunRet)],['schaduw ' assetCl{selAss}],'A1');

        
        
    end    
        
        
    end
        


    function addExtraRestriction(~,~)

    %
    %
    %
    
    extraRestr = get(constrExtraRestr,'Data');
    
    set(constrExtraRestr,'Data',[extraRestr ; {max(cell2mat(extraRestr(:,1)))+1 assetCl{1} 0.0 0.0 false}]);
    
    
    
    end
    function exportOptimalizationToExcel(~,~)
    
    % export optimalization results to excel file    
    % get data from table;
    optData = get(portConsTable,'Data'); 
    
    % get the name of the scenario which is used:
    availableScenarios = [viewNames 'Equilibrium'];
    scenario = get (viewCnstrBox,'value');
    VCM=get(VCMCnstrBox,'value');
    
    selectedScenario=availableScenarios(scenario);
    selectedVCM=corNames(VCM);
    
    tabname=strcat(selectedScenario,'_',selectedVCM);
   optCols={'AssetClass','Equilibrium Weight','Eq. TE Con (Abs)','Eq. TE Con (Rel)', 'Optimal Weight','Opt. TE Con (Abs)','Opt. TE Con (Rel)', 'Difference','<html><b>rel allocation','<html><b>Group Weight','<html><b>Min Weight','<html><b>Max Weight','<html><b>St.Dev Weight','<html><b>exp. Opt'};

   
    xlswrite('port_contr.xlsx',[optCols;optData],tabname{1},'A1');
    
    
    % also export optimalization parameters:
    
    targetNo=get(targetCnstrBox,'value');     % selected optimalization target
    OptTarget=['optimization target' optimalizationTarget(targetNo) '_'];
    
    useTErestrtion = get(constUseTE,'value');
    
    if useTErestrtion
    
        TETarget = {'TE target = ' get(constTargetTE,'String') ' _ '};

        
        
        
    else
        TETarget = {'TE target = ' 'no ' ' TE target '};
        
    end
    
    useAssetBounds = get(constUseRestr,'value');
    
    if useAssetBounds
        
        optRestrictions = get (constrRestr,'Data');
        
        restrOverview = [optRestrictions(:,1) optRestrictions(:,3) optRestrictions(:,4)];
   
         xlswrite('port_contr.xlsx',[OptTarget;TETarget;restrOverview],tabname{1},'A20');
        
    else
         xlswrite('port_contr.xlsx',[OptTarget;TETarget],tabname{1},'A20');
        
    end
    
    
   

        
    end

    function BL2Excel(~,~)
    
    % export BL optimalization results to excel file
    % plus BL settings
    
    % get data from table;
    optData = get(portConsTable,'Data'); 
    
    % get the name of the scenario which is used:
    availableScenarios = [viewNames 'Equilibrium'];
    scenario = get (viewCnstrBox,'value');
    VCM=get(VCMCnstrBox,'value');
    
    selectedScenario=availableScenarios(scenario);
    selectedVCM=corNames(VCM);
    
   tabname=strcat('BL_',selectedScenario,'_',selectedVCM);
   optCols={'AssetClass','Equilibrium Weight','Eq. TE Con (Abs)','Eq. TE Con (Rel)', 'Optimal Weight','Opt. TE Con (Abs)','Opt. TE Con (Rel)', 'Difference','<html><b>rel allocation','<html><b>Group Weight','<html><b>Min Weight','<html><b>Max Weight','<html><b>St.Dev Weight','<html><b>exp. Opt'};

   
    xlswrite('port_contr.xlsx',[optCols;optData],tabname{1},'A1');
    
    
    % also export optimalization parameters / restrictions:
    
    targetNo=get(targetCnstrBox,'value');     % selected optimalization target
    OptTarget=['optimization target' optimalizationTarget(targetNo) '_'];
    
    useTErestrtion = get(constUseTE,'value');
    
    if useTErestrtion
        TETarget = {'TE target = ' get(constTargetTE,'String') ' _ '};
    else
        TETarget = {'TE target = ' 'no ' ' TE target '};
    end
    
    useAssetBounds = get(constUseRestr,'value');
    
    if useAssetBounds
        
        optRestrictions = get (constrRestr,'Data');
        
        restrOverview = [optRestrictions(:,1) optRestrictions(:,3) optRestrictions(:,4)];
   
         xlswrite('port_contr.xlsx',[OptTarget;TETarget;restrOverview],tabname{1},['A' num2str(10)]);
        
    else
         xlswrite('port_contr.xlsx',[OptTarget;TETarget],tabname{1},['A' num2str(noAssets+4)]);
        
    end
    
    
    % export equilibrium data from table to excel file
    
    % get data from table;
    equiData = get(equilibriumTable,'Data'); 
    
    equiCol =   {'AssetClass', 'Equilibrium Weight', 'Low. Limit', 'Upp. Limit', 'Eq. Returns', 'Eq. IR', 'Eq. Ret (on IR)', 'Eq. IR (fixed)', 'TE Contr.'};
    
    xlswrite('port_contr.xlsx',[equiCol;equiData],tabname{1},['A' num2str(2*(noAssets+4))]);
   
    
    % export BL-returns data from table to excel file
    
    % get data from table;
    BLretuns = get(BLReturns,'Data'); 
    BLPriorCov = get (BLCovriancePrior,'Data');
    BLPosteriorCov = get (BLCovriancePosterior,'Data');
    
    BLRetCol =   {'BL Returns'};
    
    xlswrite('port_contr.xlsx',[BLPriorCov BLPosteriorCov BLretuns],tabname{1},['A' num2str(3*(noAssets+4))]);
   
        
    end

    function copyRiskBudget(~,~)
        % neem risk-budget target over van de risk-budget tab
        % Dit is nodig als je wilt optimaliseren naar een risk-budget per asset

        % risk-budget per asset 
        RiskBudgetSetup = get(RiskBudgetTable,'Data');


        % huidge restricties per asset
        curRestr=get(constrRestr,'Data');    
        curRestr(:,7)=RiskBudgetSetup(:,8); % update risk-budget per asset
        set(constrRestr,'Data',curRestr);  
    end



    function RBtarget(~,~)
        
        global covar;
        global RiskBudgetTarget;
        
        RiskBudgetSettings = get(constrRestr,'Data');
        
        RiskBudgetTarget = cell2mat(RiskBudgetSettings(:,7))/100;
        
        
        covar = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

        
        % clear previous optimalization results
         assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([100*cur_weight;100*sum(cur_weight)]) ...
        num2cell([100*volConCurrent';100*sum(volConCurrent)]) num2cell([100*volConCurrent'/sum(volConCurrent);100])];

%         ...
%         num2cell(zeros(noAssets+1,1)) num2cell([100*volConOpt';100*sum(volConOpt)]) num2cell([100*volConOpt'/sum(volConOpt);100]) num2cell(100*[x_optimal-cur_weight;0])];


        set(portConsTable,'Data',assetWeights);

        
        w_rb=zeros(noAssets,1);
        w_rb(1:end)=1/noAssets;
        
        
        
        
        optRBTargetFun(w_rb);
        
        options = optimset('Display','iter','TolFun',1e-32,'TolX',1e-16);
      
        [x,~]=fsolve(@optRBTargetFun,w_rb,options);
        
        x_optimal=abs(x)/sum(abs(x));
        
        [ volConOpt ] = volContribution (x_optimal, used_corr, used_stdev);
        

        
        assetWeights=[ [assetCl;'<html><b>total portfolio'] num2cell([100*cur_weight;100*sum(cur_weight)]) ...
        num2cell([100*volConCurrent';100*sum(volConCurrent)]) num2cell([100*volConCurrent'/sum(volConCurrent);100]) ...
    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1)) num2cell(zeros(noAssets+1,1))];
%    num2cell([opt_weight*100;sum(opt_weight*100)]) num2cell([volConOpt'*100;sum(volConOpt)*100]) num2cell([volConOpt'*100/sum(volConOpt);100]) num2cell([(opt_weight-cur_weight)*100;0]) num2cell([relW*100;0]) num2cell(zeros(noAssets+1,1))];

        set(portConsTable,'Data',assetWeights);

        
    end

    function error=optRBTargetFun(w_opt)
    % optimalizatie functie voor risk-budgetting

        global covar;               % global nodig omdat optimizer alleen weight meegeeft
        global RiskBudgetTarget;


        w_opt=abs(w_opt)/sum(abs(w_opt));   % maak alle weights positief en schaal som naar 100%
                                            % dit is een quick-and-dirty manier
                                            % om budget restrictie en long-only
                                            % restrictie te implenteren

        % error functie -> verschil risk-contributies - target
        f1=(w_opt.*(covar * w_opt)/sqrt(w_opt'*covar*w_opt)-RiskBudgetTarget);
        error=f1'*f1;

    end


    
    function updateCov(~,~)
            
        selectCov = get(VCMCnstrBox,'value');
        
        
        
        used_corr=corr_curr{selectCov};
        used_stdev=stdev_curr{selectCov};
        
        updateConstructionTable();
    end

    

end

