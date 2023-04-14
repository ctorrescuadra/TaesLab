classdef cGraphSummary < cStatusLogger
% cGraphSummary plot as bar summary tables
    properties(GetAccess=public,SetAccess=private)
        Name        % Name of the graph (window name)
        Title       % Title of the graph
        XData       % X-Data (Categories)
        XTicks      % x-axis Categories
        YData       % Y-Data Values
        XLabel      % X-axis label
        YLabel      % Y-axis label
        BaseLine    % Base Line
        Legend      % Legend Categories
    end

    methods
        function obj = cGraphSummary(tbl,idx)
        % Create the object with the graph properties
            obj.Name='Cost Summary';
            obj.Title=tbl.Description;
            obj.XTicks=tbl.ColNames(2:end);
            obj.XData=(1:tbl.NrOfCols-1);
            obj.YData=cell2mat(tbl.Data(idx,:));
            obj.XLabel='States';
            obj.YLabel=['Unit Cost ',tbl.Unit];
            obj.Legend=tbl.RowNames(idx);
            if tbl.isGeneralCostTable
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
            bar(obj.XData',obj.YData','edgecolor','none','barwidth',0.8,'parent',ax);
            title(ax,obj.Title,'fontsize',14);
            tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
            set(ax,'xtick',obj.XData,'xticklabel',obj.XTicks,'fontsize',12);
            xlabel(ax,obj.XLabel,'fontsize',12);
            ylabel(ax,obj.YLabel,'fontsize',12);
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            box(ax,'on');
            hl=legend(obj.Legend);
            set(hl,'Orientation','horizontal','Location','southoutside');
        end
    end
end