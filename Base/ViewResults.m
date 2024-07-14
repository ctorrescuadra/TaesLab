classdef ViewResults < matlab.apps.AppBase
%ViewResults - Matlab application for displaying cResultSet objects.
%   Allows to display the tables and graph of a cResultSet in a similar way to TaesApp.
%   Tables can be selected using the tree widget in the left panel. 
%   The index table, result tables and graphs are displayed in the right pane.
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
        ContextMenu       matlab.ui.container.ContextMenu
        OpenAsFigureMenu  matlab.ui.container.Menu
    end
   
    properties (Access = private)
        State            % Results State
        Colorbar         % Colorbar
        ExpandedNode=[]  % Current Node
        TableIndex       % Table Index
    end
    
    methods (Access = private)
        % View the graph of a ICT table
        function GraphCost(app,tbl)
        % get the graph parameter
            obj=cGraphResults(tbl);
            M=numel(obj.Legend);
            cm=turbo(M);
            if app.isColorbar
                delete(app.Colorbar);
            end
            % Plot the bar graph
            b=bar(obj.yValues,...
                'EdgeColor','none','BarWidth',0.5,...
                'BarLayout','stacked',...
                'BaseValue',obj.BaseLine,...
                'FaceColor','flat',...
                'Parent',app.UIAxes);
            for i=1:M
                b(i).CData=cm(i,:);
            end
            app.SetGraphParameters(obj);
            app.UIAxes.Visible='on';
        end
        
        % View the graph of a diagnosis table
        function GraphDiagnosis(app,tbl)
            % get the graph parameters
            obj=cGraphResults(tbl);
            M=numel(obj.Legend);
            cm=turbo(M);
            if app.isColorbar
                delete(app.Colorbar);
            end

            % Plot the bar graph
            b=bar(obj.yValues,...
                    'EdgeColor','none','BarWidth',0.5,...
                    'BarLayout','stacked',...
                    'BaseValue',obj.BaseLine,...
                    'FaceColor','flat',...
                    'Parent',app.UIAxes);
            for i=1:M
                b(i).CData=cm(i,:);
            end
            bs=b.BaseLine;
            bs.BaseValue=0.0;
            bs.LineStyle='-';
            bs.Color=[0.6,0.6,0.6];
            app.SetGraphParameters(obj);
            app.UIAxes.Visible='on';
        end

        % View the graph of summary table
        function GraphSummary(app,tbl,res)
            % get the graph parameters
            if tbl.isFlowsTable
                var=res.getDefaultFlowVariables;
            else
                var=res.getDefaultProcessVariables; 				       
            end
            obj=cGraphResults(tbl,var);
            % plot the graph
            if app.isColorbar
                delete(app.Colorbar);
            end
            % Plot the bar graph
            bar(obj.xValues, obj.yValues,...
                    'EdgeColor','none','BarWidth',0.5,...
                    'BaseValue',obj.BaseLine,...
                    'FaceColor','flat',...
                    'Parent',app.UIAxes);
            app.SetGraphParameters(obj);
            app.UIAxes.Visible='on';
        end

        % View the graph recycling
        function GraphRecycling(app,tbl)
            % Get the graph properties
            wkey=tbl.ColNames{end};
            obj=cGraphResults(tbl,wkey);
            % plot the graph
            if app.isColorbar
                delete(app.Colorbar);
            end
		    plot(obj.xValues,obj.yValues,...
                'Marker','diamond',...
                'LineWidth',1,...
                'Parent',app.UIAxes);
            app.SetGraphParameters(obj);
            app.UIAxes.Visible='on';
        end

        % Show Waste Allocation graph
        function GraphWasteAllocation(app,tbl)
            % Get graph Properties
            obj=cGraphResults(tbl);
            % Plot the bar graph
            if app.isColorbar
                delete(app.Colorbar);
            end
            bar(obj.xValues,obj.yValues',...
                'EdgeColor','none',...
                'BarLayout','stacked',...
                'Horizontal','on',...
                'Parent',app.UIAxes);
            title(app.UIAxes,obj.Title,'FontSize',14);
            xlabel(app.UIAxes,obj.xLabel,'FontSize',12);
            ylabel(app.UIAxes,obj.yLabel,'FontSize',12);
            legend(app.UIAxes,obj.Categories,'FontSize',8);
            app.UIAxes.Legend.Location='bestoutside';
            app.UIAxes.Legend.Orientation='horizontal';
            xtick=(0:10:100);
            app.UIAxes.XTick = xtick;
            app.UIAxes.XTickLabel=arrayfun(@(x) sprintf('%3d',x),xtick,'UniformOutput',false);
            app.UIAxes.XLimMode="auto";
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'off';
            % Show the figure after all components are created
            app.UIAxes.Visible = 'on';
        end

        function ShowDiagramFP(app,tbl)
            obj=cGraphResults(tbl);
            app.UIAxes.YLimMode="auto";
            r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
            app.UIAxes.Colormap=red2blue;
            plot(app.UIAxes,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat");
            app.Colorbar=colorbar(app.UIAxes);
            app.Colorbar.Label.String=['Exergy ', tbl.Unit];
            app.UIAxes.Title.String=obj.Title;
            app.UIAxes.XLabel.String='';
            app.UIAxes.YLabel.String='';
            app.UIAxes.XTick=[];
            app.UIAxes.YTick=[];
            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'off';
            legend(app.UIAxes,'off');
            app.UIAxes.Visible='on';
        end

        % Show digraphs (productiveDiagram, diagramFP object)
        function ShowDigraph(app,tbl,res)
            % get the graph properties
            nodes=res.getNodeTable(tbl.Name);
            obj=cGraphResults(tbl,nodes);
            colors=eye(3);
            nodetable=obj.xValues.Nodes;
            nodecolors=colors(nodetable.Type,:);
            nodenames=nodetable.Name;
            plot(app.UIAxes,obj.xValues,"Layout","auto","NodeLabel",nodenames,"NodeColor",nodecolors,"Interpreter","none");         
            app.UIAxes.Title.String=[tbl.Description, ' [',app.State,']'];
            app.UIAxes.XLabel.String='';
            app.UIAxes.YLabel.String='';
            app.UIAxes.XTick=[];
            app.UIAxes.YTick=[];
            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'off';
            legend(app.UIAxes,'off');
            app.UIAxes.Visible='on';
        end
        % Set some common graph parameters
        function SetGraphParameters(app,obj)
            title(app.UIAxes,obj.Title,'FontSize',14);
            xlabel(app.UIAxes,obj.xLabel,'FontSize',12);
            ylabel(app.UIAxes,obj.yLabel,'FontSize',12);
            legend(app.UIAxes,obj.Legend,'FontSize',8);
            yticks(app.UIAxes,'auto');
            app.UIAxes.XTick=obj.xValues;
            app.UIAxes.XTickLabel=obj.Categories;
            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.YLimMode="auto";
            tmp=ylim(app.UIAxes);
            app.UIAxes.YLim=[obj.BaseLine, tmp(2)];
            app.UIAxes.TickLabelInterpreter='none';
            app.UIAxes.Legend.Location='northeastoutside';
            app.UIAxes.Legend.Orientation='vertical';    
        end
        
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
            if isValid(vh)
                app.Table.HTMLSource=vh.getMarkupHTML;
            else
                printLogger(vh);
            end
            app.Table.Visible=true;    
        end
        
        % Show table in graph panel
        function ViewGraph(app,tbl,res)
            switch tbl.GraphType
                case cType.GraphType.COST
                    app.GraphCost(tbl);
                case cType.GraphType.DIAGNOSIS
                    app.GraphDiagnosis(tbl);
                case cType.GraphType.SUMMARY
                    app.GraphSummary(tbl,res)
                case cType.GraphType.DIAGRAM_FP
                    app.ShowDiagramFP(tbl);
                case cType.GraphType.DIGRAPH_FP
                    app.ShowDiagramFP(tbl);
                case cType.GraphType.DIGRAPH
                    app.ShowDigraph(tbl,res);
                case cType.GraphType.RECYCLING
                    app.GraphRecycling(tbl);
                case cType.GraphType.WASTE_ALLOCATION
                    app.GraphWasteAllocation(tbl);
            end           
        end

        % Clear Tab contents befere new results calculation
        function ClearTabContent(app)
            app.Table.Visible=false;
            app.ClearGraphTab;
            app.LogField.Text='';
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

        % Check if Colorbar object is defined
        function res=isColorbar(app)
            try
                res=~isempty(app.Colorbar);
            catch
                res=false;
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, arg)
            log=cStatus();
            if nargin~=2
                log.printError('Values to show are required');
                log.printError('Usage: ViewModelResuls(res)');
                delete(app);
                return
            end
            if ~isa(arg,'cResultSet')
                log.printError('Results must be a cResultSet object');
                delete(app);
                return
            end
            mt=arg.getResultInfo;
            switch arg.classId
            case cType.ClassId.RESULT_INFO
                val={mt};
                state=arg.State;
            case cType.ClassId.RESULT_MODEL
                val=arg.getModelResults;
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
        end

        % Selection changed function: Tree
        function TreeSelectionChanged(app, ~)
            selectedNodes = app.Tree.SelectedNodes;
            tbl=selectedNodes.NodeData;
            if isempty(tbl)
                return
            end
            if isa(tbl,'cTable')
                resultNode=selectedNodes.Parent;
                logtext=sprintf(' INFO: %s for State %s. %s ',...
                resultNode.Text,tbl.State,resultNode.UserData);
                app.LogField.Text=logtext;
                app.ViewTable(tbl);               
                app.TabGroup.SelectedTab=app.TablesTab;
                if tbl.isGraph
                    app.ViewGraph(tbl,resultNode.NodeData.Info);
                    app.ExpandedNode=resultNode;
                else
                    app.ClearGraphTab;
                end
            elseif isa(tbl,'cResultInfo')
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
            app.ExpandedNode=[];
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            indices = event.Indices;
            idx=indices(1);
            tbl=app.TableIndex.Content{idx};
            app.ViewTable(tbl);
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
        function OpenAsFigureMenuSelected(app, ~)
            newfigure = figure;
            copyobj(app.UIAxes, newfigure);
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
            app.UITable.RowName = {};
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
            app.LogField.Text = '';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);
            app.ContextMenu.ContextMenuOpeningFcn = createCallbackFcn(app, @OpenAsFigureMenuSelected, true);

            % Create OpenAsFigureMenu
            app.OpenAsFigureMenu = uimenu(app.ContextMenu);
            app.OpenAsFigureMenu.MenuSelectedFcn = createCallbackFcn(app, @OpenAsFigureMenuSelected, true);
            app.OpenAsFigureMenu.Accelerator = 'F';
            app.OpenAsFigureMenu.Text = 'Open As Figure';
            
            % Assign app.ContextMenu
            app.UIAxes.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

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