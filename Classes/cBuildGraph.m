classdef (Abstract) cBuildGraph < cMessageLogger
    properties(Access=protected)
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
		isColorbar  % Colorbar activated
		isPieChart  % Use Pie Chart
    end

    methods(Access=protected)
		function setGraphParameters(obj,ax)
        % Set axis graph parameters
        % Input:
        %   ax - axis graphic object
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
    end
end