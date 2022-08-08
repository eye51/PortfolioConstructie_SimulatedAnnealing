function riskbudgettingTAB( tab_handle, assetCl,assetCategorie,cur_weight, corr_curr, stdev_curr,corNames, viewNames, viewReturns,productieVersie )
% [ BLViewReturns, BLViewUncertainty, BLCorrTable] = BlackLittermanTAB( tab_handle, assetCl, corr_curr, stdev_curr, viewNames, viewReturns, assetCategorie )


%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
RBLayout = uiextras.VBox('Parent',tab_handle,'Padding',5);


global RiskBudgetTable;

used_corr=corr_curr{1};
used_stdev=stdev_curr{1};


[volConCurrent] = volContribution (cur_weight, used_corr, used_stdev);

%
RBButtonGrid = uiextras.Grid( 'Parent', RBLayout, 'Spacing', 5 );

% Select View 
uicontrol('Parent',RBButtonGrid,'Style','text','String','Select View','HorizontalAlignment','left');
RBViewBox = uicontrol('Parent',RBButtonGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',[viewNames 'Equilibrium'],'Callback', @updateViewReturnTable);
uiextras.Empty( 'Parent', RBButtonGrid );
uiextras.Empty( 'Parent', RBButtonGrid );
uiextras.Empty( 'Parent', RBButtonGrid );
% uicontrol( 'Parent', RBButtonGrid, 'String', 'Update Table','Callback', @updateViewReturnTable);

% Select Market Cov
uicontrol('Parent',RBButtonGrid,'Style','text','String','Select VCM','HorizontalAlignment','left');
MarketCov = uicontrol('Parent',RBButtonGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',corNames,'Callback', @updateCov);
uiextras.Empty( 'Parent', RBButtonGrid );
uiextras.Empty( 'Parent', RBButtonGrid );
uiextras.Empty( 'Parent', RBButtonGrid );


%
uiextras.Empty( 'Parent', RBButtonGrid );
uicontrol('Parent',RBButtonGrid,'Style','text','String','Current TE','HorizontalAlignment','left');
uiextras.Empty( 'Parent', RBButtonGrid );
uiextras.Empty( 'Parent', RBButtonGrid );
uicontrol( 'Parent', RBButtonGrid, 'String', 'Gradial RB','Callback', @updateGradialRB);

%
uiextras.Empty( 'Parent', RBButtonGrid );
% constCurrentTE = uicontrol('Parent',RBButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',num2str(sum(volConCurrent)));
constCurrentTE = uicontrol('Parent',RBButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',num2str(sum(volConCurrent)));
uiextras.Empty( 'Parent', RBButtonGrid );
uiextras.Empty( 'Parent', RBButtonGrid );
uicontrol( 'Parent', RBButtonGrid, 'String', 'Bucket RB','Callback', @updateBucketRB);

% RiskBudget Limits
uiextras.Empty( 'Parent', RBButtonGrid );
uicontrol('Parent',RBButtonGrid,'Style','text','String','Target TE','HorizontalAlignment','left');
uicontrol('Parent',RBButtonGrid,'Style','text','String','Use Target TE','HorizontalAlignment','left');
uicontrol('Parent',RBButtonGrid,'Style','text','String','only pos. IR','HorizontalAlignment','left');
uicontrol( 'Parent', RBButtonGrid, 'String', 'Risk Parity','Callback', @SetUpRiskParity);


uiextras.Empty( 'Parent', RBButtonGrid );
constTargetTE = uicontrol('Parent',RBButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.10);
constUseTargetTE = uicontrol('Parent',RBButtonGrid,'Style','checkbox','value',false);
constOnlyPositiveTE = uicontrol('Parent',RBButtonGrid,'Style','checkbox','value',false);

if productieVersie
    uiextras.Empty( 'Parent', RBButtonGrid );
else    
    uicontrol( 'Parent', RBButtonGrid, 'String', 'Barclay RB','Callback', @updateBarclayRB);
end


% 
% 
% % standard view type selections
% uicontrol( 'Parent', RBButtonGrid, 'String', 'only diagonal','Callback', @viewDiagonalUncertainty);
% uicontrol( 'Parent', RBButtonGrid, 'String', 'suggest. Meucci','Callback', @viewMeucciUncertainty);
% uiextras.Empty( 'Parent', RBButtonGrid );
% uiextras.Empty( 'Parent', RBButtonGrid );


set( RBButtonGrid, 'ColumnSizes', [100 100 100 100 100 100], 'RowSizes', [20 20 20 20 20] );
sizePanels=120;


%
% table met Asset Ranking
%


% IRView = viewReturns(:,1)./used_stdev;
% rankIRView = rankIR(IRView,assetCategorie);

RBViews = uiextras.HBox('Parent',RBLayout);

columnname =   {'<html><b>AssetClass','<html><b>Asset Categorie', '<html><b>Return', '<html><b>St.Dev', '<html><b>Curr. RB','<html><b>IR','<html><b>Rank IR', '<html><b>RiskBudget', '<html><b>%RiskBudget'};
columnformat = {'char',{'Matching portefeuille' 'Return portefeuille'}, 'bank', 'bank', 'bank', 'bank', 'bank', 'bank', 'bank'};
columneditable =  [false true true true true true]; 

noCol = size(columnname,2);

colwith = cell(1,noCol);
colwith(1:2) = num2cell(150);   
colwith(3:end) = num2cell(75);


% target TE -> beschikbare risk-budget

RiskBudgetTable = uitable('Parent',RBViews,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9],... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        

% fill table with initial RB
updateRBTable()




sizePanels=[sizePanels -1];



set( RBLayout, 'Sizes', sizePanels);


    function updateGradialRB(~,~)
        
        noViews = size (viewNames,2);   
        selectedView = get (RBViewBox,'value');    
        
        
        if (selectedView > noViews)
        % equilibrium choosen as scenario
            equiAllocation = get(equilibriumTable,'Data');
            viewRet = [assetCl equiAllocation(:,end)];    

        else

        % add returns of the view
            viewRet = num2cell(100*viewReturns(:,selectedView));
            IRView = viewReturns(:,selectedView)./used_stdev;
        end

        useOnlyPosIR = get(constOnlyPositiveTE,'value');
        
        useTargetTE = get(constUseTargetTE,'value');
        
        
        if useTargetTE
            TEtarget=str2double(get(constTargetTE,'String'));
        else
            TEtarget=sum(volConCurrent); 
        end
        


        [RiskBudgetGradial]=gradialScaleRiskBudget(assetCategorie,TEtarget,cur_weight, used_corr, used_stdev,IRView,useOnlyPosIR);
        
        [volConCurrent] = volContribution (cur_weight, used_corr, used_stdev);


        rankIRView = rankIR(IRView,assetCategorie);

        assetRestRet = [assetCl assetCategorie num2cell(100*viewReturns(:,1)) num2cell(100*used_stdev) num2cell(100*volConCurrent') num2cell(IRView) num2cell(rankIRView') num2cell(100*RiskBudgetGradial) num2cell(100*RiskBudgetGradial./sum(RiskBudgetGradial)) ];
        
        set(RiskBudgetTable,'Data',assetRestRet);
    
    end

    function updateBucketRB(~,~)

        noViews = size (viewNames,2);   
        selectedView = get (RBViewBox,'value');    
        
        if (selectedView > noViews)
        % equilibrium choosen as scenario
            equiAllocation = get(equilibriumTable,'Data');
            viewRet = [assetCl equiAllocation(:,end)];    

        else

        % add returns of the view
            viewRet = num2cell(100*viewReturns(:,selectedView));
            IRView = viewReturns(:,selectedView)./used_stdev;
        end
        
        useOnlyPosIR = get(constOnlyPositiveTE,'value');
        
        useTargetTE = get(constUseTargetTE,'value');
        
        
        if useTargetTE
            TEtarget=str2double(get(constTargetTE,'String'));
        else
            TEtarget=sum(volConCurrent); 
        end
        

        [RiskBudgetBucket]=rankBucketRiskBudget(assetCategorie,TEtarget,cur_weight, used_corr, used_stdev,IRView,useOnlyPosIR);

        RiskBudgetBucket=RiskBudgetBucket';
        
        
        rankIRView = rankIR(IRView,assetCategorie);

        assetRestRet = [assetCl assetCategorie num2cell(100*viewReturns(:,1)) num2cell(100*used_stdev) num2cell(100*volConCurrent') num2cell(IRView) num2cell(rankIRView') num2cell(100*RiskBudgetBucket) num2cell(100*RiskBudgetBucket./sum(RiskBudgetBucket)) ];
        
        set(RiskBudgetTable,'Data',assetRestRet);
    
    end

    function updateBarclayRB(~,~)

        noViews = size (viewNames,2);   
        selectedView = get (RBViewBox,'value');    
        
        if (selectedView > noViews)
        % equilibrium choosen as scenario
            equiAllocation = get(equilibriumTable,'Data');
            viewRet = [assetCl equiAllocation(:,end)];    

        else

        % add returns of the view
            viewRet = num2cell(100*viewReturns(:,selectedView));
            IRView = viewReturns(:,selectedView)./used_stdev;
        end
        
        useOnlyPosIR = get(constOnlyPositiveTE,'value');
        
        useTargetTE = get(constUseTargetTE,'value');
        
        
        if useTargetTE
            TEtarget=str2double(get(constTargetTE,'String'));
        else
            TEtarget=sum(volConCurrent); 
        end
        

        [RiskBudget]=BarclayMethodRiskBudget(assetCategorie,TEtarget,cur_weight, used_corr, used_stdev,IRView,useOnlyPosIR);


        rankIRView = rankIR(IRView,assetCategorie);
        assetRestRet = [assetCl assetCategorie num2cell(100*viewReturns(:,1)) num2cell(100*used_stdev) num2cell(100*volConCurrent') num2cell(IRView) num2cell(rankIRView') num2cell(100*RiskBudget) num2cell(100*RiskBudget./sum(RiskBudget)) ];
        
        set(RiskBudgetTable,'Data',assetRestRet);
    
    end



    function SetUpRiskParity(~,~)
        
        
        % determine used risk-budgets with current weigths
        [volConCurrent] = volContribution (cur_weight, used_corr, used_stdev);

        
        
        noViews = size (viewNames,2);   
        selectedView = get (RBViewBox,'value');    

        if (selectedView > noViews)
        % equilibrium choosen as scenario
            equiAllocation = get(equilibriumTable,'Data');
            viewRet = [assetCl equiAllocation(:,end)];    

        else

        % add returns of the view
            viewRet = num2cell(100*viewReturns(:,selectedView));
            IRView = viewReturns(:,selectedView)./used_stdev;
        end

        
        useOnlyPosIR = get(constOnlyPositiveTE,'value');
        
        
        useTargetTE = get(constUseTargetTE,'value');
        
        
        if useTargetTE
            TEtarget=str2double(get(constTargetTE,'String'));
        else
            TEtarget=sum(volConCurrent); 
        end
        
        [RiskBudget] = riskParity(assetCategorie,TEtarget,cur_weight, used_corr, used_stdev,IRView,useOnlyPosIR);
        
        rankIRView = rankIR(IRView,assetCategorie);
        assetRestRet = [assetCl assetCategorie num2cell(100*viewReturns(:,1)) num2cell(100*used_stdev) num2cell(100*volConCurrent') num2cell(IRView) num2cell(rankIRView') num2cell(100*RiskBudget) num2cell(100*RiskBudget./sum(RiskBudget)) ];
        
        set(RiskBudgetTable,'Data',assetRestRet);
        
        
    end
        

    


    function updateViewReturnTable(~,~)
        

    noViews = size (viewNames,2);   
    selectedView = get (RBViewBox,'value');    
    
    if (selectedView > noViews)
    % equilibrium choosen as scenario
        equiAllocation = get(equilibriumTable,'Data');
        viewRet = [assetCl equiAllocation(:,end)];    
        
    else
    
    % add returns of the view
        viewRet = num2cell(100*viewReturns(:,selectedView));
        IRView = viewReturns(:,selectedView)./used_stdev;
    end
    
    
    
    rankIRView = rankIR(IRView,assetCategorie);
    
    assetRestRet = [assetCl assetCategorie viewRet num2cell(100*used_stdev) num2cell(100*volConCurrent') num2cell(IRView) num2cell(rankIRView') num2cell(100*RiskBudget) num2cell(100*RiskBudget./sum(RiskBudget)) ];


    set(RiskBudgetTable,'Data',assetRestRet); 
        
        
    end        
       
    function updateCov(~,~)
            
        selectCov = get(MarketCov,'value');
        
        
        
        used_corr=corr_curr{selectCov};
        used_stdev=stdev_curr{selectCov};
        
        updateRBTable()
        
    end
        
    function updateRBTable(~,~)
    
    % determine used risk-budgets with current weigths
    [volConCurrent] = volContribution (cur_weight, used_corr, used_stdev);
   
    % determin IR based on selected view / VCM    
    IRView = viewReturns(:,1)./used_stdev;
    rankIRView = rankIR(IRView,assetCategorie);
    
    useTargetTE = get (constUseTargetTE,'Value');
    
    
    TEtarget=str2double(get(constTargetTE,'String'));

    [RiskBudget]=gradialScaleRiskBudget(assetCategorie,TEtarget,cur_weight, used_corr, used_stdev,IRView);

    assetRestRet = [assetCl assetCategorie num2cell(100*viewReturns(:,1)) num2cell(100*used_stdev) num2cell(100*volConCurrent') num2cell(IRView) num2cell(rankIRView') num2cell(100*RiskBudget) num2cell(100*RiskBudget./sum(RiskBudget)) ];

    set(RiskBudgetTable,'Data',assetRestRet);
    
    set(constCurrentTE,'String',num2str(sum(volConCurrent)));    
        
    end

end

