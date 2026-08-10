classdef (Abstract) cGraphResults < cTaesLab
%cGraphResults - Abstract base class for all thermoeconomic graph objects.
%   Provides the shared protected properties and axis-configuration helpers
%   used by every concrete graph class.  Each subclass must implement
%   showGraph (standalone figure) and showGraphUI (embedded in an App Designer app).
%
%   cGraphResults Properties (protected):
%     Type       - Graph type identifier (see cType.GraphType)
%     Name       - Figure window title
%     Title      - Axes title string displayed on the graph
%     Categories - Cell array of category labels for the X-axis tick marks
%     xValues    - Numeric X-axis tick positions or digraph object
%     yValues    - Numeric data matrix for bar/line series
%     xLabel     - X-axis label string
%     yLabel     - Y-axis label string
%     BaseLine   - Minimum Y-axis value (0.0 for general costs, 1.0 for unit costs)
%     Legend     - Cell array of legend entry labels
%     Style      - Graph style identifier (see cType.GraphStyles)
%
%   cGraphResults Methods (protected):
%     setGraphParameters   - Configure axis tick labels, grid, and legend (standalone figure)
%     setGraphParametersUI - Configure axis properties for an App Designer UIAxes
%
%   cGraphResults Derived Classes:
%     cDigraph        - Productive structure directed-graph diagram
%     cGraphCost      - Irreversibility-cost stacked bar graph
%     cGraphCostRSC   - Resource-specific cost stacked bar graph or pie chart
%     cGraphDiagnosis - Thermoeconomic diagnosis stacked bar graph
%     cGraphDiagramFP - Fuel-Product (FP) diagram directed graph
%     cGraphRecycling - Waste recycling cost line graph
%     cGraphSummary   - Multi-state or multi-sample summary bar/line graph
%     cGraphWaste     - Waste allocation pie chart or horizontal bar graph
%
%   See also cType.GraphStyles, cResultInfo
%
    properties(Access=protected)
        Type        % Graph type identifier (see cType.GraphType)
        Name        % Figure window title string
        Title       % Axes title string displayed inside the graph
        Categories  % Cell array of X-axis category label strings
        xValues     % X-axis tick positions (numeric vector) or digraph object
        yValues     % Data matrix: each column is one bar/line series
        xLabel      % X-axis label string
        yLabel      % Y-axis label string
        BaseLine    % Minimum Y-axis value (0.0 general costs, 1.0 unit costs)
        Legend      % Cell array of legend entry label strings
        Style       % Graph style identifier (see cType.GraphStyles)
    end

    methods(Access=protected)
		function setGraphParameters(obj,ax)
        %setGraphParameters - Apply tick labels, grid, and legend settings to a MATLAB axes object
        %   Called at the end of showGraph to finalise the standalone figure.
        %
        %   Syntax:
        %     obj.setGraphParameters(ax)
        %   Input Arguments:
        %     ax - MATLAB axes object to configure
        %
            hold(ax,'off');
            title(ax,obj.Title,'fontsize',14);
            set(ax,'xtick',obj.xValues,'xticklabel',obj.Categories);
            xlabel(ax,obj.xLabel,'fontsize',12,'interpreter','none');
            ylabel(ax,obj.yLabel,'fontsize',12,'interpreter','none');
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            box(ax,'on');
            hl=legend(ax,obj.Legend,'interpreter','none');
            set(hl,'Location','northeastoutside',...,
                'Interpreter','none','FontSize',10);
        end

        function setGraphParametersUI(obj,app)
        %setGraphParametersUI - Apply tick labels, grid, and legend settings to an App Designer UIAxes
        %   Called at the end of showGraphUI to finalise the embedded graph.
        %   Also adjusts YLim so it does not drop below BaseLine.
        %
        %   Syntax:
        %     obj.setGraphParametersUI(app)
        %   Input Arguments:
        %     app - matlab.apps.AppBase object whose UIAxes property is configured
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
            if (tmp(1)>0)
                app.UIAxes.YLim=[obj.BaseLine, tmp(2)];
            end
            app.UIAxes.TickLabelInterpreter='none';
            app.UIAxes.Legend.Location='northeastoutside';
            app.UIAxes.Legend.Orientation='vertical';      
        end
    end

end