classdef cGraphDiagnosis < cStatusLogger
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
        function obj = cGraphDiagnosis(tbl)
        % Create the object with the graph properties      
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description,' [',tbl.State,']'];
            obj.Categories=tbl.ColNames(2:end);
            obj.xValues=(1:tbl.NrOfCols-1)';
            obj.yValues=cell2mat(tbl.Data(1:end-1,:))';
            obj.xLabel='Processes';
            obj.yLabel=['Exergy ',tbl.Unit];
            obj.Legend=tbl.RowNames(1:end-1);
            obj.BaseLine=0.0;

        end

        function showGraph(obj)
            if isOctave
                showGraph_OC(obj)
            else
                showGraph_ML(obj)
            end
        end
    end

    methods(Access=private)
        function showGraph_OC(obj)
        % Show the graph (Octave Version)
        %
            f=figure('name',obj.Name, 'numbertitle','off',...
            'units','normalized','position',[0.05 0.1 0.4 0.6]);
            ax=axes(f,'position', [0.1 0.1 0.75 0.8]);
            hold(ax,'on');
            zt=obj.yValues;
            zt(zt>0)=0; % Plot negative values
            bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
            zt=obj.yValues;
            zt(zt<0)=0; % Plot positive values
            bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
            hold(ax,'off');
            title(ax,obj.Title,'fontsize',14);
            set(ax,'xtick',obj.xValues,'xticklabel',obj.Categories);
            xlabel(ax,obj.xLabel,'fontsize',12);
            ylabel(ax,obj.yLabel,'fontsize',12);
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            box(ax,'on');
            hl=legend(ax,obj.Legend);
            set(hl,'location','northeastoutside','orientation','vertical');
        end

        function showGraph_ML(obj)
        % Show the graph (Matlab version)
        %
            M=numel(obj.Legend);
            f = figure('NumberTitle','off','Name',obj.Name,...
            'units','normalized','position',[0.1 0.1 0.4 0.6],'color',[1,1,1]);
            ax = axes(f,'Position',[0.1 0.1 0.85 0.8]);
            cm=colormap(jet(M));
            hold(ax,'on');
            b=bar(obj.yValues,...
                 'EdgeColor','none','BarWidth',0.5,...
                 'BarLayout','stacked',...
                 'FaceColor','flat',...
                 'BaseValue',obj.BaseLine,...
                 'Parent',ax);
            for i=1:M
                b(i).CData=cm(i,:);
            end
            bs=b.BaseLine;
            bs.BaseValue=0.0;
            bs.LineStyle='-';
            bs.Color=[0.6,0.6,0.6];
            set(ax,'XTick',obj.xValues,'XTickLabel',obj.Categories,'FontSize',9);
            title(ax,obj.Title,'FontSize',12);
            xlabel(ax,obj.xLabel,'fontsize',10);
            ylabel(ax,obj.yLabel,'fontsize',10);
            box(ax,'on');
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            hold(ax,'off');
            hl=legend(ax,obj.Legend,'FontSize',8);
            set(hl,'location','northeastoutside','orientation','vertical');
        end
    end
end