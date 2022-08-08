function BlackLittermanTAB( tab_handle, assetCl, corr_curr, stdev_curr,corNames, viewNames, viewReturns, ~ ,productieVersie)
% [ BLViewReturns, BLViewUncertainty, BLCorrTable] = BlackLittermanTAB( tab_handle, assetCl, corr_curr, stdev_curr, viewNames, viewReturns, assetCategorie )


%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
BLLayout = uiextras.VBox('Parent',tab_handle,'Padding',5);


global BLViewReturns;
global BLViewUncertainty;
global constViewUncertainty;
global BLCovriancePrior;
global BLCovriancePosterior;

global BLReturns;

global equilibriumTable;

global BLViewBox;
global constMarketUncertainty;



% start GUI-tab with standaard market correlation and st.dev

used_corr=corr_curr{1};
used_stdev=stdev_curr{1};

noAssets = size(assetCl,1);
noViews = size(viewNames,2);
 
% set up GUI voor Black-Litterman settings
%
%
%
BLButtonGrid = uiextras.Grid( 'Parent', BLLayout, 'Spacing', 5 );

% Select View 
uicontrol('Parent',BLButtonGrid,'Style','text','String','Select View','HorizontalAlignment','left');
BLViewBox = uicontrol('Parent',BLButtonGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',[viewNames 'Equilibrium'],'Callback', @updateViewAbsoluut);
uiextras.Empty( 'Parent', BLButtonGrid );
uiextras.Empty( 'Parent', BLButtonGrid );
%uicontrol( 'Parent', BLButtonGrid, 'String', 'Update Table','Callback', @updateViewAbsoluut);

% Select Market Cov
uicontrol('Parent',BLButtonGrid,'Style','text','String','Select VCM','HorizontalAlignment','left');
BLMarketCovBox = uicontrol('Parent',BLButtonGrid,'Style','popupmenu','BackgroundColor',[1 1 1],'String',corNames,'Callback', @updateCov);
uiextras.Empty( 'Parent', BLButtonGrid );
uiextras.Empty( 'Parent', BLButtonGrid );
%uicontrol( 'Parent', BLButtonGrid, 'String', 'Update Cov','Callback', @updateCov);

% empty space
uiextras.Empty( 'Parent', BLButtonGrid );
uicontrol('Parent',BLButtonGrid,'Style','text','String','C','HorizontalAlignment','left');
uicontrol('Parent',BLButtonGrid,'Style','text','String','Tau','HorizontalAlignment','left');
uiextras.Empty( 'Parent', BLButtonGrid );


% BL settings
uiextras.Empty( 'Parent', BLButtonGrid );
constViewUncertainty= uicontrol('Parent',BLButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',1.0);
constMarketUncertainty= uicontrol('Parent',BLButtonGrid,'Style','edit','BackgroundColor',[1 1 1],'HorizontalAlignment','right','String',0.4);
uiextras.Empty( 'Parent', BLButtonGrid );



% standard view type selections
uiextras.Empty( 'Parent', BLButtonGrid );
uicontrol( 'Parent', BLButtonGrid, 'String', 'only diagonal','Callback', @viewDiagonalUncertainty);
uicontrol( 'Parent', BLButtonGrid, 'String', 'suggest. Meucci','Callback', @viewMeucciUncertainty);
uiextras.Empty( 'Parent', BLButtonGrid );



set( BLButtonGrid, 'ColumnSizes', [100 100 100 100 100], 'RowSizes', [20 20 20 20] );
sizePanels=120;


%
% table met views
%   View bestaat uit returns + onzekerheid over returns



% view returns
% first determine default views


BLViews = uiextras.HBox('Parent',BLLayout);

columnname =   {'<html><b>View Returns'};
columnformat = {'char', 'short'};

columnname{1}=cell(1,noAssets+1);
columnformat{1}=cell(1,noAssets+1);
colwith{1} = cell(1,noAssets+1);

columnname{1} =   '<html><b>AssetClass';
columnformat{1} = 'char';
columneditable =  [false true(1,noAssets)]; 
colwith(1) = num2cell(100);
colwith(2:end) = num2cell(75);

for ii=1:noAssets
    columnname{ii+1} =   ['<html><b> ' assetCl{ii}];
    columnformat{ii+1} = 'short';
end





% http://www.mathworks.com/matlabcentral/newsreader/view_thread/284331
viewN = cell(noAssets,1);





for ii=1:noAssets
viewN(ii)={['View ' num2str(ii)]};
    
end

assetRestRet = [viewN num2cell(diag(viewReturns(:,1)))];

BLViewReturns = uitable('Parent',BLViews,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9], 'Data', assetRestRet,... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        

% Uncertainty factor per view

% lege ruimte
uiextras.Empty('Parent',BLViews);        

% stabndaar deviatie..
columnname=cell(1,1);
columnformat=cell(1,1);
columnname{1} =   '<html><b>Unc. Factor';
columnformat{1} = 'short';
columneditable =  true; 


colwith = num2cell(100); 


% currentStdev = num2cell(100*used_stdev);

BLUncerPerView = uitable('Parent',BLViews ,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9],... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);

uncPerView=num2cell(ones(noAssets,1));
        

set(BLUncerPerView,'Data',uncPerView);

% lege ruimte tussen tdev en BL returns
uiextras.Empty('Parent',BLViews);        

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
columnformat{ii+1} = 'bank';


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


Ohm=viewMeucciUncertainty();


updateUncTable(Ohm)
% viewUncertainty = [assetCl num2cell(Ohm)];
% 
% set(BLViewUncertainty,'Data', viewUncertainty);

set(BLViews,'Sizes',[-1 10 125 10 -1]);
        
%
% table met huidige correlatie matrix / st-dev
%
BLCorrStdev = uiextras.HBox('Parent',BLLayout);


% covariance matrix prior


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
    columnformat{ii+1} = 'bank';
end


%noCol = size(columnname,2);


BLCovriancePrior = uitable('Parent',BLCorrStdev ,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9],... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);

% lege ruimte tussen correlatie en stdev        
uiextras.Empty('Parent',BLCorrStdev);        


% covariance matrix posterior

BLCovriancePosterior = uitable('Parent',BLCorrStdev ,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9],... 
            'ColumnName', columnname(2:end),...
            'ColumnFormat', columnformat(2:end),...
            'ColumnEditable', columneditable(2:end),...
            'ColumnWidth',colwith(2:end),...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);





% lege ruimte tussen tdev en BL returns
uiextras.Empty('Parent',BLCorrStdev);        
        
        
% returns na BL ..
columnname=cell(1,1);
columnformat=cell(1,1);
columnname{1} =   '<html><b>BL. Ret.';
columnformat{1} = 'short';
columneditable =  true; 


colwith = num2cell(100); 


% currentStdev = num2cell(100*used_stdev);

BLReturns = uitable('Parent',BLCorrStdev ,'Units','normalized','Position',...
            [0.1 0.1 0.9 0.9],... 
            'ColumnName', columnname,...
            'ColumnFormat', columnformat,...
            'ColumnEditable', columneditable,...
            'ColumnWidth',colwith,...            
            'BackgroundColor',[1 1 1],...
            'RowName',[]);
        
        
% fill tables with data        
updateCovarianceTable()
        
set( BLCorrStdev, 'Sizes', [-3 5 -3 5 -1]);        
sizePanels=[sizePanels -1];
set( BLLayout, 'Sizes', sizePanels);




    function Ohm=viewMeucciUncertainty(~,~)
    %
    %   setup onzekerheids functie op BL-Views
    %   methode Meuci -> gebasseerd op standaard deviaties / correlatie vd assets
    %

        % 'schaal' functie voor onzekerheid op views -> hogere C geeft
        % minder zekerheid in views -> minder gewicht aan views tov.
        % evenwicht
        
        C=str2double(get(constViewUncertainty,'String')); 
        
        
        uncerPerView = cell2mat(get(BLUncerPerView,'Data'));
        
    
        % 'structuur' van de views. Absolute (single) views, ranking of
        % relatieve viers
        
        views=get(BLViewReturns,'Data');        
        views=cell2mat(views(:,2:end));        
        P=(views~=0);
        
        stDevForUncertainty = used_stdev.*uncerPerView; % scale st.dev with factor to decrease / increase uncertainty in view
        
        
        Ohm=BLViewMeucci(used_corr,stDevForUncertainty,C,P);
        
        currentCorr = [assetCl num2cell(100*Ohm)];
        set(BLViewUncertainty,'Data',currentCorr);
    
    end



    function [Ohm]=viewDiagonalUncertainty(~,~)
    %
    %   setup onzekerheids functie op BL-Views
    %   alleen diagonaal -> gebasseerd op standaard deviaties vd assets
    %
        


    C=str2double(get(constViewUncertainty,'String'));   % 'schaal' functie voor onzekerheid

    uncerPerView = cell2mat(get(BLUncerPerView,'Data'));
    stDevForUncertainty = used_stdev.*uncerPerView; % scale st.dev with factor to decrease / increase uncertainty in view
        

    Ohm= (1/C)* diag(stDevForUncertainty.*stDevForUncertainty);
    currentCorr = [assetCl num2cell(100*Ohm)];
    set(BLViewUncertainty,'Data',currentCorr);
    
    end

% 
%     function updateAssetRange(~,~)
%     % todo: !!    
%          
%         selectedAssdt = get (AssetCnstrBox,'value');
%         selectedView = get (viewCnstrBox,'value');
%         
%         viewReturn = viewReturns(selectedAssdt,selectedView);
%         
%         set(constMinReturn,'String',-2*viewReturn);
%         set(constMaxReturn,'String', 2*viewReturn);
%         
%     end
%     

    function updateViewAbsoluut(~,~)
    %
    %   genereer BL-view gebasseerd op de wereld-beeld / transitie kanaal
    %   'cases'. Hieruit worden 'absolute' views gemaakt.
    %   
    %
    selectedView = get (BLViewBox,'value');    
      
        selectView = get(BLViewBox,'value');
    
    
    if (selectedView > noViews)
    % equilibrium choosen as scenario
        equiAllocation = get(equilibriumTable,'Data');
        viewRet = [assetCl  num2cell(diag(cell2mat(equiAllocation(:,7))))];    
        
    else
    
    % add returns of the view
    viewRet = [assetCl num2cell(diag(viewReturns(:,selectView)))];
    
    end
    

    set(BLViewReturns,'Data',viewRet); 
        
        
    end

    function updateCov(~,~)
            
        selectCov = get(BLMarketCovBox,'value');
        
        
        
        used_corr=corr_curr{selectCov};
        used_stdev=stdev_curr{selectCov};
        
        
        
        updateCovarianceTable()
    end
    
    function updateCovarianceTable(~,~)

    
        covarianceMatrix = used_corr.*(used_stdev*used_stdev'); % calculate cov. from correlation / st.dev

        
        corrTableData = [assetCl num2cell(100*covarianceMatrix)];
        
        set (BLCovriancePrior,'Data',corrTableData);
        set (BLCovriancePosterior,'Data',num2cell(zeros(noAssets,noAssets)));
        
        
    
    end

    function updateUncTable(Ohm)


    viewUncertainty = [assetCl num2cell(Ohm)];

    set(BLViewUncertainty,'Data', viewUncertainty);

    
    end


end

