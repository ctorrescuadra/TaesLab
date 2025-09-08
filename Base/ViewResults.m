classdef ViewResults < matlab.apps.AppBase
%ViewResults - MATLAB app for displaying results tables.
%    Allows displaying the tables and graphs of a cResultSet in a similar way to TaesApp.
%    Tables can be selected using the tree widget in the left panel. 
%    The index table, result tables, and graphs are displayed in the right panel.
%  
%   Syntax
%     ViewResults(res)
%
%   Input Arguments
%     res - cResultSet object
%
%   See also cThermoeconomicTool
%
    % Properties that correspond to app components
    properties (Access = private)
        UIFigure          matlab.ui.Figure
        GridLayout        matlab.ui.container.GridLayout
        LogField          matlab.ui.control.Label
        TabGroup          matlab.ui.container.TabGroup
        IndexTab          matlab.ui.container.Tab
        Label             matlab.ui.control.Label
        UITable           matlab.ui.control.Table
        TablesTab         matlab.ui.container.Tab
        Table             matlab.ui.control.HTML
        GraphsTab         matlab.ui.container.Tab
        UIAxes            matlab.ui.control.UIAxes
        Tree              matlab.ui.container.Tree
        ContextMenu1      matlab.ui.container.ContextMenu
        OpenAsFigMenu     matlab.ui.container.Menu
        ContextMenu2      matlab.ui.container.ContextMenu
        SaveResultsMenu   matlab.ui.container.Menu
        ContextMenu3      matlab.ui.container.ContextMenu
        SaveTableMenu     matlab.ui.container.Menu
        Colorbar                    
    end
   
    properties (Access = private)
        State            % Results State
        ExpandedNode     % Current Node
        TableIndex       % Table Index
        CurrentTable     % Current Table
        ResultInfo       % Result Info
    end
    
    methods (Access = private)
        % Show the index table in table panel
        function ViewIndexTable(app,res)
            app.Label.Text=res.ResultName;
            tbl=res.getTableIndex;
            app.UITable.ColumnWidth={'auto','9x','1x'};
            app.UITable.Data=[tbl.RowNames',tbl.Data];
            app.Label.Visible=true;
            app.UITable.Visible=true;
            app.TableIndex=tbl;
        end

        % Show table in table panel
        function ViewTable(app,tbl)
            vh=cBuildHTML(tbl);
            if vh.status
                app.Table.HTMLSource=vh.getMarkupHTML;
            else
                printLogger(vh);
            end
            app.Table.Visible=true;    
        end
        
        % Show table in graph panel
        function ViewGraph(app,tbl,info)
            switch tbl.GraphType
                case cType.GraphType.COST
                    gr=cGraphCost(tbl);
                case cType.GraphType.DIAGNOSIS
                    gr=cGraphDiagnosis(tbl,info);
                case cType.GraphType.SUMMARY
                    gr=cGraphSummary(tbl,info);
                case cType.GraphType.DIAGRAM_FP
                    gr=cGraphDiagramFP(tbl);
                case cType.GraphType.DIGRAPH
                    gr=cDigraph(tbl,info);
                case cType.GraphType.RECYCLING
                    gr=cGraphRecycling(tbl);
                case cType.GraphType.WASTE_ALLOCATION
                    gr=CGraphWaste(tbl,info,false);
            end
            gr.showGraphUI(app)           
        end

        % Clear Tab contents befere new results calculation
        function ClearTabContent(app)
            app.Table.Visible=false;
            app.ClearGraphTab;
            app.LogField.Text=cType.EMPTY_CHAR;
        end
        % Clear Graph Tab
        function ClearGraphTab(app)
            app.UIAxes.Visible="off";
            if app.isColorbar
                delete(app.Colorbar);
            end
            if ~isempty(app.UIAxes.Legend)
                app.UIAxes.Legend.Visible=false;
            end
            delete(app.UIAxes.Children);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, arg)
            log=cMessageLogger();
            if nargin~=2 || ~isObject(arg,'cResultSet')
                log.printError(cMessages.ResultSetRequired);
                log.printError(cMessages.ShowHelp);
                delete(app);
                return
            end
            mt=arg.getResultInfo;
            switch arg.ClassId
            case cType.ClassId.RESULT_INFO
                val={mt};
                state=arg.State;
            case cType.ClassId.RESULT_MODEL
                val=getModelResults(arg);
                state=arg.State;
            case cType.ClassId.DATA_MODEL
                val={mt};
                state='DATA';
            end
 
            app.UIFigure.Name=['View Results ','[',arg.ModelName,'/',state,']'];
            % Create Tree nodes
            for i=1:numel(val)
                tmp=val{i};
                ts=uitreenode(app.Tree);
                ts.Text=tmp.ResultName;
                ts.NodeData=tmp;
                tables=fieldnames(tmp.Tables);
                for j=1:numel(tables)
                    tn=uitreenode(ts);
                    tn.Text=tables{j};
                    tn.NodeData=tmp.Tables.(tables{j});
                end
            end
            app.State=state;
            app.ViewIndexTable(mt);
            app.TabGroup.SelectedTab=app.IndexTab;
            app.ResultInfo=mt;
        end

        % Selection changed function: Tree
        function TreeSelectionChanged(app, ~)
            selectedNodes = app.Tree.SelectedNodes;
            tbl=selectedNodes.NodeData;
            if isempty(tbl)
                return
            end
            if isObject(tbl,'cTable')
                resultNode=selectedNodes.Parent;
                logtext=sprintf(' INFO: %s for State %s. %s ',...
                resultNode.Text,tbl.State,resultNode.UserData);
                app.LogField.Text=logtext;
                app.ViewTable(tbl);               
                app.TabGroup.SelectedTab=app.TablesTab;
                app.CurrentTable=tbl;
                if tbl.isGraph
                    app.ViewGraph(tbl,resultNode.NodeData.Info);
                    app.ExpandedNode=resultNode;
                else
                    app.ClearGraphTab;
                end
            elseif isObject(tbl,'cResultInfo')
                app.ViewIndexTable(tbl);
                app.TabGroup.SelectedTab=app.IndexTab;
                app.LogField.Text=sprintf(' INFO: %s selected',tbl.ResultName);            
            end
        end

        % Node expanded function: Tree
        function TreeNodeExpanded(app, event)
            node = event.Node;
            if ~isempty(app.ExpandedNode)
                app.ExpandedNode.collapse;
            end
            app.ExpandedNode=node;
            app.ViewIndexTable(node.NodeData);
            app.TabGroup.SelectedTab=app.IndexTab;
        end

        % Node collapsed function: Tree
        function TreeNodeCollapsed(app, ~)
            app.ClearTabContent;
            app.TabGroup.SelectedTab=app.IndexTab; 
            app.ExpandedNode=cType.EMPTY;
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            indices = event.Indices;
            idx=indices(1);
            tbl=app.TableIndex.Content{idx};
            app.ViewTable(tbl);
            app.CurrentTable=tbl;
            if tbl.isGraph
                app.ViewGraph(tbl,app.TableIndex.Info);
            else
                app.ClearGraphTab;
            end
            if indices(2)==cType.GRAPH_COLUMN
                app.TabGroup.SelectedTab=app.GraphsTab;
            else
                app.TabGroup.SelectedTab=app.TablesTab;
            end
        end

        % Callback function: ContextMenu, OpenAsFigureMenu
        function OpenAsFig(app, ~)
            newfigure = figure;
            copyobj(app.UIAxes, newfigure);
        end

        % Callback function:  SaveResultsMenu
        function SaveResults(app, ~)
            % Save the model results
            app.UIFigure.WindowStyle="normal";
            default_file=strcat(cType.RESULT_FILE,cType.FileExt.XLSX);
	        [file,path,ext]=uiputfile(cType.SAVE_RESULTS,'Select File',default_file);
            app.UIFigure.WindowStyle="alwaysontop";
            if ext % File has been selected
                cd(path)
                log=saveResults(app.ResultInfo,file);
                if log.status
                    logtext=sprintf(' INFO: Results Available in file %s',file);
                else
                    logtext=sprintf(' WARNING: Results have NOT saved. See Log');
                end
	        else
		        logtext=sprintf(' WARNING: Results are NOT Available');
            end
            app.LogField.Text=logtext;
        end

        % Menu selected function: SaveTableMenu
        function SaveTable(app, ~)
            % Save the model results
            logtext=sprintf(' WARNING: Table is NOT available');
            if ~isempty(app.CurrentTable)
                app.UIFigure.WindowStyle="normal";
                default_file=strcat(cType.TABLE_FILE,cType.FileExt.XLSX);
			    [file,path,ext]=uiputfile(cType.SAVE_TABLES,'Select File',default_file);
                app.UIFigure.WindowStyle="alwaysontop";
                if ext % File has been selected
                    cd(path)
                    log=saveTable(app.CurrentTable,file);
                    if log.status
                        logtext=sprintf(' INFO: Table saved in file %s',file);
                    else
                        logtext=sprintf(' WARNING: Table is NOT saved. See Log');
                    end
                else
                    logtext=sprintf(' WARNING: Table is NOT saved');
                end
            end
            app.LogField.Text=logtext;
        end

        % Close request function: UIFigure
        function CloseApp(app, ~)
            selection = uiconfirm(app.UIFigure,{'Close the Application?'},'Confirmation');   
            switch selection
                case 'OK'
                    delete(app)                      
                case 'Cancel'
                    return
            end        
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 1];
            app.UIFigure.Position = [100 100 976 530];
            app.UIFigure.Name = 'View Results';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @CloseApp, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {200, '4x'};
            app.GridLayout.RowHeight = {'1x', 24};
            app.GridLayout.BackgroundColor = [0.9804 0.9804 0.9804];

            % Create Tree
            app.Tree = uitree(app.GridLayout);
            app.Tree.SelectionChangedFcn = createCallbackFcn(app, @TreeSelectionChanged, true);
            app.Tree.NodeExpandedFcn = createCallbackFcn(app, @TreeNodeExpanded, true);
            app.Tree.NodeCollapsedFcn = createCallbackFcn(app, @TreeNodeCollapsed, true);
            app.Tree.Layout.Row = 1;
            app.Tree.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 2;

            % Create IndexTab
            app.IndexTab = uitab(app.TabGroup);
            app.IndexTab.Title = 'Index';
            app.IndexTab.BackgroundColor = [1 1 1];

            % Create UITable
            app.UITable = uitable(app.IndexTab);
            app.UITable.ColumnName = {'Tables'; 'Description'; 'Graph'};
            app.UITable.RowName = cType.EMPTY_CELL;
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Multiselect = 'off';
            app.UITable.Tooltip = {'Select a cell to display the results as table or graph'};
            app.UITable.Visible = 'off';
            app.UITable.Position = [12 12 720 400];

            % Create Label
            app.Label = uilabel(app.IndexTab);
            app.Label.FontSize = 14;
            app.Label.FontWeight = 'bold';
            app.Label.Visible = 'off';
            app.Label.Position = [12 420 676 22];

            % Create TablesTab
            app.TablesTab = uitab(app.TabGroup);
            app.TablesTab.Title = 'Tables';
            app.TablesTab.BackgroundColor = [1 1 1];

            % Create Table
            app.Table = uihtml(app.TablesTab);
            app.Table.Visible = 'off';
            app.Table.Position = [10 10 720 432];

            % Create GraphsTab
            app.GraphsTab = uitab(app.TabGroup);
            app.GraphsTab.Title = 'Graphs';
            app.GraphsTab.BackgroundColor = [1 1 1];

            % Create UIAxes
            app.UIAxes = uiaxes(app.GraphsTab);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.XColor = [0 0 0];
            app.UIAxes.Box = 'on';
            app.UIAxes.Visible = 'off';
            app.UIAxes.Position = [1 1 700 445];
            app.UIAxes.Colormap=turbo;

            % Create LogField
            app.LogField = uilabel(app.GridLayout);
            app.LogField.BackgroundColor = [0.8 0.8 0.8];
            app.LogField.Layout.Row = 2;
            app.LogField.Layout.Column = [1 2];
            app.LogField.Text = cType.EMPTY_CHAR;

   	        % Create ContextMenu1
            app.ContextMenu1 = uicontextmenu(app.UIFigure);

            % Create OpenAsFigMenu
            app.OpenAsFigMenu = uimenu(app.ContextMenu1);
            app.OpenAsFigMenu.MenuSelectedFcn = createCallbackFcn(app, @OpenAsFig, true);
            app.OpenAsFigMenu.Text = 'Open As Fig';
            
            % Assign app.ContextMenu1
            app.GraphsTab.ContextMenu = app.ContextMenu1;
     
            % Create ContextMenu2
            app.ContextMenu2 = uicontextmenu(app.UIFigure);

            % Create SaveInWorkspaceMenu
            app.SaveResultsMenu = uimenu(app.ContextMenu2);
            app.SaveResultsMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveResults, true);
            app.SaveResultsMenu.Text = 'Save Results';
            
            % Assign app.ContextMenu2
            app.Tree.ContextMenu = app.ContextMenu2;

            % Create ContextMenu3
            app.ContextMenu3 = uicontextmenu(app.UIFigure);

            % Create SaveTableContextMenu
            app.SaveTableMenu = uimenu(app.ContextMenu3);
            app.SaveTableMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveTable, true);
            app.SaveTableMenu.Text = 'Save Table';
            
            % Assign app.ContextMenu3
            app.TablesTab.ContextMenu = app.ContextMenu3;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        %Check Colorbar
        function res=isColorbar(app)
            try
                res=~isempty(app.Colorbar);
            catch
                res=false;
            end
        end

        % Construct app
        function app = ViewResults(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app) 
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end