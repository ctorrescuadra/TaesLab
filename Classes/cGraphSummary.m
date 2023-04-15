classdef cGraphSummary < cStatusLogger
% cGraphSummary plot as bar summary tables
    properties(GetAccess=public,SetAccess=private)
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

    methods
        function obj = cGraphSummary(tbl,idx)
        % Create the object with the graph properties
            obj.Name='Cost Summary';
            obj.Title=tbl.Description;
            obj.Categories=tbl.ColNames(2:end);
            obj.xValues=(1:tbl.NrOfCols-1)';
            obj.yValues=cell2mat(tbl.Data(idx,:))';
            obj.xLabel='States';
            obj.yLabel=['Unit Cost ',tbl.Unit];
            obj.Legend=tbl.RowNames(idx);
            if tbl.isGeneralCostTable || tbl.isFlowsTable
                obj.BaseLine=0.0;
            else
                obj.BaseLine=1.0;
            end
        end

        function showGraph(obj)
        % Plot the graph
            f=figure('name',obj.Name, 'numbertitle','off', ...
                'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
            ax=axes(f);
            bar(obj.xValues,obj.yValues,'edgecolor','none','barwidth',0.8,'parent',ax);
            title(ax,obj.Title,'fontsize',14);
            tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
            set(ax,'xtick',obj.xValues,'xticklabel',obj.Categories,'fontsize',12);
            xlabel(ax,obj.xLabel,'fontsize',12);
            ylabel(ax,obj.yLabel,'fontsize',12);
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            box(ax,'on');
            hl=legend(obj.Legend);
            set(hl,'Orientation','horizontal','Location','southoutside');
        end
    end
end