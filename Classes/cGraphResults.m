classdef (Abstract) cGraphResults < cMessageLogger
%cGraphResults - Abstract class for show graphs in interactive mode and apps
%   
%   cGraphResults Derived classes:
%     cDigraph        - Show productive structure diagrams
%     cGraphCost      - Show Irreversibility-Cost bar graphs
%     cGraphDiagnosis - Show Thermoeconomic Diagnosis bar graphs
%     cGraphDiagramFP - Show Diagram FP
%     cGraphRecycling - Show Waste Recycling graphs
%     cGraphSummary   - Show Summary results graphs
%     cGraphWaste    - Show Waste Allocation graphs
%
    properties(Access=public)
        Type        % Graph Type
        Name        % Name of the graph (window name)
        Title       % Title of the graph
        Categories  % X-axis Categories
        xValues     % X-Valuea
        yValues     % Y-values
        xLabel      % X-axis label
        yLabel      % Y-axis label
        BaseLine    % Base Line
        Legend      % Legend Categories
    end

    methods(Access=protected)
		function setGraphParameters(obj,ax)
        %setGraphParameters - Set axis graph parameters
        %   Input:
        %     ax - axis graphic object
            hold(ax,'off');
            title(ax,obj.Title,'fontsize',14);
            set(ax,'xtick',obj.xValues,'xticklabel',obj.Categories);
            xlabel(ax,obj.xLabel,'fontsize',12);
            ylabel(ax,obj.yLabel,'fontsize',12);
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            box(ax,'on');
            hl=legend(ax,obj.Legend);
            set(hl,'location','southoutside','orientation','horizontal','fontsize',10);
        end

        function setGraphParametersUI(obj,app)
        %setGraphParametersUI - Set axis graph parameters for GUI applications
        %   Input:
        %     app - app reference for UIAxes
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
    end

end