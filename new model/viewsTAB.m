function viewsTAB( tab_handle, tables, assetCl, viewNames, viewReturns, viewProb, viewStDev)
% [ViewsSetupTable,ViewsProbabilityTable] = viewsTAB( tab_handle, assetCl, viewNames, viewReturns, viewProb, viewStDev)

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


noViews = size(viewNames,2);

viewCalc=false(1,noViews);      % logical om aan tegeven welke views doorgerekend moeten worden
viewCalc(1)=true;               % 1e view is 'Base-Case'

global ViewsSetupTable;
global ViewsProbabilityTable;


% hoofd layout van de tab:
viewsLayout = uiextras.VBoxFlex('Parent',tab_handle); 
views = [assetCl num2cell(viewReturns*100)];

%
%   Details of the views 
%

% first table format / layout:
ColViewTable = cell(1,noViews+1);
ColViewTable{1}='<html><b>AssetClass';

columneditable=true(1,noViews+1);
columnformat = cell(1,noViews+1);

columnformat{1}='char';
for kk=1:noViews
    
    ColViewTable(1+kk)=cellstr(strcat('<html><b>',viewNames(kk)));
    columnformat{1+kk}='bank';


end
    
colwith = cell(1,noViews+1);
colwith{1} = 150;
colwith(2:end) = num2cell(150);
 


ViewsSetupTable = uitable('Parent',viewsLayout,...
            'Data', views,... 
            'ColumnName', ColViewTable,...
            'RowName',[],...
            'ColumnWidth',colwith,...
            'ColumnFormat', columnformat,...            
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
            'ColumnName', ColViewTable,...
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
uicontrol( 'Parent', b, 'String', 'Export to Excel','Callback', @exportViewsToExcel );

set( b, 'ButtonSize', [130 35], 'Spacing', 5, 'HorizontalAlignment','left' );



%
set( viewsLayout, 'Sizes', [-1 100 -1 50]);


    function exportViewsToExcel(~,~)

    % export views to excel file
    
    % get data from table;
    viewData = get(ViewsSetupTable,'Data'); 
    
    viewProbData = get(ViewsProbabilityTable,'Data');
    % 
    
    xlswrite('port_contr.xlsx',[ColViewTable;viewData;viewProbData],'Views','a1');
   
    
    end

end

