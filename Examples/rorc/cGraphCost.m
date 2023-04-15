classdef cGraphCost < cStatusLogger
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
        function obj = cGraphCost(tbl)
        % Create the object with the graph properties      
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description,' [',tbl.State,']'];
            obj.Categories=tbl.ColNames(2:end);
            obj.xValues=(1:tbl.NrOfCols-1)';
            obj.yValues=circshift(cell2mat(tbl.Data(1:end-1,1:end)),1)';
            if tbl.isFlowsTable
                obj.xLabel='Flows';
            else
                obj.xLabel='Processes';
            end
            obj.yLabel=['Unit Cost ',tbl.Unit];
            obj.Legend={'ENV',tbl.RowNames{1:end-2}};
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
            bar(obj.yValues,'stacked','edgecolor','none','barwidth',0.5,'parent',ax); 
            title(ax,obj.Title,'fontsize',14);
            tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
            set(ax,'xtick',obj.xValues,'xticklabel',obj.Categories,'fontsize',12);
            xlabel(ax,obj.xLabel,'fontsize',12);
            ylabel(ax,obj.yLabel,'fontsize',12);
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            box(ax,'on');
            hl=legend(obj.Legend);
            set(hl,'location','northeastoutside','orientation','vertical');
        end
    end
end