classdef cResultGraph < cStatusLogger
%cResultGraph Show a bar graph from result tables
%   It takes the information from cTable objects and define
%   the graph/figure  properties
%   Methods:
%       obj=cResultGraph(table,state)
%       obj.showGraph
%
    properties(GetAccess=public,SetAccess=private)
        FigName         % Figure Name on Graph Window
        Title           % Graph Title
        Categories      % Categories (x-axis)
        XAxisLabel      % Label for x-axis
        YAxisLabel      % Label for y-axis
        Legend          % Legend Text
        BaseValue       % Base Value for graphs
        Values          % Values to show
        CostGraph       % Is cost graph
        DiagnosisGraph  % Is diagnosis graph
    end
    methods
        function obj = cResultGraph(tbl,state)
        % cResultGraph Construct an instance of this class
            obj=obj@cStatusLogger(cType.VALID);
            if ~isa(tbl,'cTableMatrix') || ~tbl.isGraphTable
                obj.messageLog(cType.ERROR,'The table cannot be show as graph');
                return
            end
            if nargin==2
                obj.FigName=[tbl.Description,' [',state,']'];
            else
                obj.FigName=tbl.Description;
            end
            %  Build the graphic properties of the graph
            %  GraphType Info from printformat.json
            %    bit 1: graph (true/false)
            %    bit 2: Flow/Process
            %    bit 3: Base Value (0,1)
            %    bit 4: Diagnosis (true/false)
            obj.DiagnosisGraph=bitget(tbl.GraphType,4); %Diagnosis Graph
            obj.Title=obj.FigName;
            obj.BaseValue=bitget(tbl.GraphType,3); % Base Value
            if bitget(tbl.GraphType,2) % Processes table
                obj.XAxisLabel='Processes';
            else
                obj.XAxisLabel='Flows';
            end
            if obj.DiagnosisGraph
                obj.Legend=tbl.RowNames(1:end-1);
                obj.Categories=tbl.ColNames(2:end);
                obj.Values=cell2mat(tbl.Data(1:end-1,:))';
                obj.YAxisLabel=['Exergy ',tbl.Unit];
                obj.CostGraph=false;
            else
                obj.Legend={'ENV',tbl.RowNames{1:end-2}};
                obj.Categories=tbl.ColNames(2:end);
                obj.Values=circshift(cell2mat(tbl.Data(1:end-1,1:end)),1)';
                obj.YAxisLabel=['Unit Cost ',tbl.Unit];
                obj.CostGraph=true;
            end
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
            N=numel(obj.Categories);
            f=figure('name',obj.FigName, 'numbertitle','off',...
            'units','normalized','position',[0.05 0.1 0.4 0.6]);
            ax=axes(f,'position', [0.1 0.1 0.75 0.8]);
            if obj.CostGraph
                hold(ax,'on');
                bar(obj.Values,'stacked','edgecolor','none','barwidth',0.5,'parent',ax); 
                limits=ylim(ax);
                limits(1)=obj.BaseValue;
                ylim(ax,limits);
                hold(ax,'off');
            end 
            if obj.DiagnosisGraph
                hold(ax,'on');
                zt=obj.Values;
                zt(zt>0)=0; % Plot negative values
                bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
                zt=obj.Values;
                zt(zt<0)=0; % Plot positive values
                bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
                hold(ax,'off');
            end 
            title(ax,obj.Title,'fontsize',14);
            set(ax,'xtick',(1:N),'xticklabel',obj.Categories);
            xlabel(ax,obj.XAxisLabel,'fontsize',12);
            ylabel(ax,obj.YAxisLabel,'fontsize',12);
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            box(ax,'on');
            hl=legend(ax,obj.Legend);
            set(hl,'location','northeastoutside','orientation','vertical');
        end

        function showGraph_ML(obj)
        % Show the graph (Matlab version)
        %
            N=numel(obj.Categories);
            M=numel(obj.Legend);
            f = figure('NumberTitle','off','Name',obj.FigName,...
            'units','normalized','position',[0.1 0.1 0.4 0.6],'color',[1,1,1]);
            ax = axes(f,'Position',[0.1 0.1 0.85 0.8]);
            cm=colormap(jet(M));
            hold(ax,'on');
            b=bar(obj.Values,...
                 'EdgeColor','none','BarWidth',0.5,...
                 'BarLayout','stacked',...
                 'FaceColor','flat',...
                 'BaseValue',obj.BaseValue,...
                 'Parent',ax);
            for i=1:M
                b(i).CData=cm(i,:);
            end
            if obj.DiagnosisGraph
                bs=b.BaseLine;
                bs.BaseValue=0.0;
                bs.LineStyle='-';
                bs.Color=[0.6,0.6,0.6];
            end
            set(ax,'XTick',(1:N),'XTickLabel',obj.Categories,'FontSize',9);
            title(ax,obj.Title,'FontSize',12);
            xlabel(ax,obj.XAxisLabel,'fontsize',10);
            ylabel(ax,obj.YAxisLabel,'fontsize',10);
            box(ax,'on');
            set(ax,'ygrid','on');
            set(ax,'xgrid','off')
            hold(ax,'off');
            hl=legend(ax,obj.Legend,'FontSize',8);
            set(hl,'location','northeastoutside','orientation','vertical');
        end
    end
end