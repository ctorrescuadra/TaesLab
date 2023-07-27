classdef ViewResults < matlab.apps.AppBase
% ViewResult app shows in a GUI interface the results of the moodel
%   USAGE:
%       ViewResults(res)
%   INPUTS:
%       res - cResultInfo or cThermoeconomicModel to show
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        GridLayout        matlab.ui.container.GridLayout
        LogField          matlab.ui.control.Label
        TabGroup          matlab.ui.container.TabGroup
        TablesTab         matlab.ui.container.Tab
        Label             matlab.ui.control.Label
        UITable           matlab.ui.control.Table
        GraphsTab         matlab.ui.container.Tab
        UIAxes            matlab.ui.control.UIAxes
        Tree              matlab.ui.container.Tree
        ContextMenu       matlab.ui.container.ContextMenu
        OpenAsFigureMenu  matlab.ui.container.Menu
    end
    
    properties (Access = private)
        State           % Results State
        Colorbar        % Colorbar
        CurrentNode=[]  % Current Node
    end
    
    methods (Access = private)
        % View the graph of a ICT table
        function GraphCost(app,tbl)
        % get the graph parameter
            obj=cGraphResults(tbl);
            M=numel(obj.Legend);
            app.UIAxes.Visible='off';
            app.UIAxes.Colormap=turbo(M);
            % Plot the bar graph
            b=bar(obj.yValues,...
                'EdgeColor','none','BarWidth',0.5,...
                'BarLayout','stacked',...
                'BaseValue',obj.BaseLine,...
                'FaceColor','flat',...
                'Parent',app.UIAxes);
            for i=1:M
                b(i).CData=app.UIAxes.Colormap(i,:);
            end
            title(app.UIAxes,obj.Title,'FontSize',12);
            xlabel(app.UIAxes,obj.xLabel,'FontSize',10);
            ylabel(app.UIAxes,obj.yLabel,'FontSize',10);
            legend(app.UIAxes,obj.Legend,'FontSize',8);
            colorbar(app.UIAxes,'off');
            app.UIAxes.XTick=obj.xValues; 
            app.UIAxes.XTickLabel=obj.Categories;
            app.UIAxes.Legend.Location='northeastoutside';
            app.UIAxes.Legend.Orientation='vertical';
            app.UIAxes.Visible='on';
        end
        
        % View the graph of a diagnosis table
        function GraphDiagnosis(app,tbl)
            % get the graph parameters
            obj=cGraphResults(tbl);
            M=numel(obj.Legend);
            app.UIAxes.Visible='off';
            app.UIAxes.Colormap=turbo(M);
            % Plot the bar graph
            b=bar(obj.yValues,...
                    'EdgeColor','none','BarWidth',0.5,...
                    'BarLayout','stacked',...
                    'BaseValue',obj.BaseLine,...
                    'FaceColor','flat',...
                    'Parent',app.UIAxes);
            for i=1:M
                b(i).CData=app.UIAxes.Colormap(i,:);
            end
            bs=b.BaseLine;
            bs.BaseValue=0.0;
            bs.LineStyle='-';
            bs.Color=[0.6,0.6,0.6];
            title(app.UIAxes,obj.Title,'FontSize',12);
            xlabel(app.UIAxes,obj.xLabel,'FontSize',10);
            ylabel(app.UIAxes,obj.yLabel,'FontSize',10);
            legend(app.UIAxes,obj.Legend,'FontSize',8);
            colorbar(app.UIAxes,'off');
            app.UIAxes.XTick=obj.xValues; 
            app.UIAxes.XTickLabel=obj.Categories;
            app.UIAxes.Legend.Location='northeastoutside';
            app.UIAxes.Legend.Orientation='vertical';
            app.UIAxes.Visible='on';
        end

        % View the graph of summary table
        function GraphSummary(app,tbl)
            % get the graph parameters
            if tbl.isFlowsTable
                res=app.Tree.SelectedNodes.Parent.NodeData;
                var=res.Info.getDefaultFlowVariables;
                idx=res.Info.getFlowIndex(var);
                obj=cGraphResults(tbl,idx);
            else
                return
            end
            % plot the graph
            M=numel(obj.Legend);
            app.UIAxes.Visible='off';
            app.UIAxes.Colormap=turbo(M);
            % Plot the bar graph
            b=bar(obj.xValues, obj.yValues,...
                    'EdgeColor','none','BarWidth',0.5,...
                    'BaseValue',obj.BaseLine,...
                    'FaceColor','flat',...
                    'Parent',app.UIAxes);
            for i=1:M
                b(i).CData=app.UIAxes.Colormap(i,:);
            end
            title(app.UIAxes,obj.Title,'FontSize',12);
            xlabel(app.UIAxes,obj.xLabel,'FontSize',10);
            ylabel(app.UIAxes,obj.yLabel,'FontSize',10);
            legend(app.UIAxes,obj.Legend,'FontSize',8);
            colorbar(app.UIAxes,'off');
            %app.UIAxes.XTick=obj.xValues;
            app.UIAxes.TickLabelInterpreter='none';
            app.UIAxes.XTickLabel=obj.Categories;
            app.UIAxes.Legend.Location='northeastoutside';
            app.UIAxes.Legend.Orientation='vertical';
            app.UIAxes.Visible='on';
        end

        % View the graph recycling
        function GraphRecycling(app,tbl)
            % Get the graph properties
            res=app.Tree.SelectedNodes.Parent.NodeData;
            wkey=res.Info.wasteFlow;
            obj=cGraphResults(tbl,wkey);
            % plot the graph
            app.UIAxes.Visible='off';
		    plot(obj.xValues,obj.yValues,...
                'Marker','diamond',...
                'Parent',app.UIAxes);
		    title(app.UIAxes,obj.Title,'Fontsize',12);
		    yl=app.UIAxes.YLim;yl(1)=obj.BaseLine;
            app.UIAxes.YLim=yl;
		    xlabel(app.UIAxes,obj.xLabel,'fontsize',10);
		    ylabel(app.UIAxes,obj.yLabel,'fontsize',10);
		    set(app.UIAxes,'xgrid','off','ygrid','on');
		    box(app.UIAxes,'on');
            legend(app.UIAxes,obj.Legend,'FontSize',8);
            app.UIAxes.Legend.Location='northeastoutside';
            app.UIAxes.Legend.Orientation='vertical';
            app.UIAxes.Visible='on';
        end

        % Show digraphs (productiveDiagram, diagramFP object)
        function ShowDigraph(app,tbl)
            % get the graph properties
            obj=cGraphResults(tbl);
            % plot the graph
            if obj.isColorbar
                r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
                app.UIAxes.Colormap=red2blue;
                plot(app.UIAxes,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat");
                c=colorbar(app.UIAxes);
                c.Label.String=['Exergy ', tbl.Unit];
            else
                plot(app.UIAxes,obj.xValues,"Layout","auto");
            end
            app.UIAxes.Title.String=[tbl.Description, ' [',app.State,']'];
            app.UIAxes.XLabel.String='';
            app.UIAxes.YLabel.String='';
            app.UIAxes.XTick=[];
            app.UIAxes.YTick=[];
            legend(app.UIAxes,'off');
            app.UIAxes.Visible='on';
        end
        
        % Show table in table panel
        function ViewTable(app,tbl)
            app.Label.Text=tbl.getDescriptionLabel;
            app.UITable.ColumnName = tbl.ColNames(2:end);
            app.UITable.RowName = tbl.RowNames;
            app.UITable.ColumnWidth=repmat({cType.colWidth},1,tbl.NrOfCols); 
            app.UITable.Data=tbl.formatData;
            app.UITable.ColumnFormat=tbl.getColumnFormat;
            app.Label.Visible=true;
            app.UITable.Visible=true;      
        end

        % Show the index table in table panel    
        function ViewIndexTable(app,res)
            app.Label.Text=res.ResultName;
            tbl=res.getIndexTable;
            app.UITable.ColumnName = tbl.ColNames(2:end);
            app.UITable.RowName = tbl.RowNames;
            app.UITable.ColumnWidth={'auto','auto'};
            app.UITable.ColumnFormat={'char','char'};
            app.UITable.Data=tbl.Data;
            app.Label.Visible=true;
            app.UITable.Visible=true;    
        end

        
        % Show table in graph panel
        function ViewGraph(app,tbl)
            if tbl.isGraph
                switch tbl.GraphType
                    case cType.GraphType.COST
                            app.GraphCost(tbl);
                    case cType.GraphType.DIAGNOSIS
                            app.GraphDiagnosis(tbl);
                    case cType.GraphType.SUMMARY
                            app.GraphSummary(tbl)
                    case cType.GraphType.DIAGRAM_FP
                            app.ShowDigraph(tbl);
                    case cType.GraphType.DIGRAPH
                            app.ShowDigraph(tbl);
                    case cType.GraphType.RECYCLING
                            app.GraphRecycling(tbl);
                end
            end            
        end
    end

    % Callbacks that handle component events
    methods (Access = private)
        % Code that executes after component creation
        function startupFcn(app, res)
            log=cStatus();
            if nargin~=2
                log.printError('Values to show are required');
                log.printError('Usage: ViewModelResuls(res)');
                delete(app);
                return
            end
            if isa(res,'cResultInfo')
                val={res};
            elseif isa(res,'cThermoeconomicModel')
                val=res.getModelInfo;
            else
                log.printError('Results must be a cResultInfo object');
                delete(app);
                return
            end
            app.UIFigure.Name=['View Results ','[',res.ModelName,'/',res.State,']'];
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
            app.State=res.State;
        end

        % Selection changed function: Tree
        function TreeSelectionChanged(app, ~)
            selectedNodes = app.Tree.SelectedNodes;
            tbl=selectedNodes.NodeData;
            if isempty(tbl)
                return
            end
            if isa(tbl,'cTableResult')
                resultNode=selectedNodes.Parent;
                logtext=sprintf(' INFO: %s for State %s. %s ',...
                resultNode.Text,tbl.State,resultNode.UserData);
                app.LogField.Text=logtext;
                app.ViewTable(tbl);
                app.ViewGraph(tbl);
                app.CurrentNode=resultNode;
            elseif isa(tbl,'cResultInfo')
                app.ViewIndexTable(tbl);
                app.LogField.Text=sprintf(' INFO: %s selected',tbl.ResultName);            
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
            delete(app);            
        end

        % Node expanded function: Tree
        function TreeNodeExpanded(app, event)
            node = event.Node;
            if ~isempty(app.CurrentNode)
                app.CurrentNode.collapse;
            end
            app.CurrentNode=node;
            app.ViewIndexTable(node.NodeData);
            app.TabGroup.SelectedTab=app.TablesTab;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 931 530];
            app.UIFigure.Name = 'View Results';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @CloseApp, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {200, '4x'};
            app.GridLayout.RowHeight = {'1x', 24};

            % Create Tree
            app.Tree = uitree(app.GridLayout);
            app.Tree.SelectionChangedFcn = createCallbackFcn(app, @TreeSelectionChanged, true);
            app.Tree.NodeExpandedFcn = createCallbackFcn(app, @TreeNodeExpanded, true);
            app.Tree.Layout.Row = 1;
            app.Tree.Layout.Column = 1;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 2;

            % Create TablesTab
            app.TablesTab = uitab(app.TabGroup);
            app.TablesTab.Title = 'Tables';
            app.TablesTab.BackgroundColor = [1 1 1];

            % Create UITable
            app.UITable = uitable(app.TablesTab);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Visible = 'off';
            app.UITable.Position = [12 1 669 418];

            % Create Label
            app.Label = uilabel(app.TablesTab);
            app.Label.FontWeight = 'bold';
            app.Label.Visible = 'off';
            app.Label.Position = [12 425 650 22];

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
            app.UIAxes.Position = [2 1 679 446];

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