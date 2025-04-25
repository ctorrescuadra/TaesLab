classdef cGraphWaste < cBuildGraph
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function obj = cGraphWaste(tbl,wf)
			obj.Name='Waste Allocation';
			if (nargin==2) && (~isempty(wf))  % Use pie chart for the waste flow
				cols=tbl.ColNames(2:end);
				idx=find(strcmp(cols,wf),1);
				if isempty(idx)
					obj.messageLog(cType.ERROR,cMessages.InvalidParameter);
					return
				end
				x=cell2mat(tbl.Data(:,idx));
				jdx=find(x>1.0);
				obj.isPieChart=true;
				obj.Title=[tbl.Description ' [',tbl.State,'/',wf,']'];
				obj.xValues=x(jdx);
				obj.Legend=tbl.RowNames(jdx);
				obj.yValues=cType.EMPTY;
				obj.xLabel=cType.EMPTY_CHAR;
				obj.yLabel=cType.EMPTY_CHAR;
				obj.BaseLine=0.0;
				obj.Categories=cType.EMPTY_CELL;
			else % Use bar to show all waste flows
				obj.isPieChart=false;
				obj.Title=[tbl.Description ' [',tbl.State,']'];
				obj.xValues=tbl.ColNames(2:end);
				obj.yValues=cell2mat(tbl.Data);
                obj.Legend=tbl.RowNames;
				obj.xLabel=tbl.Unit;
				obj.yLabel='Waste Flows';
				obj.BaseLine=0.0;
				obj.Categories=tbl.RowNames;
			end
        end

        function showGraph(obj)
            if obj.isPieChart
                obj.showPieChart;
            else
                obj.showBarGraph
            end
        end
    end

    methods(Access=private)
        function showPieChart(obj)
    	% Plot the waste allocation pie chart
			f=figure('name',obj.Name,'numbertitle','off','colormap',turbo,...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			if isMatlab
				pie(obj.xValues,'%5.1f%%');
			else
				pie(obj.xValues);
			end
			title(ax,obj.Title,'fontsize',14);
			hl=legend(obj.Legend);
			set(hl,'Orientation','horizontal','Location','southoutside');
        end
        
        function showBarGraph(obj)
        		f=figure('name',obj.Name, 'numbertitle','off', 'colormap',turbo,...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			barh(obj.xValues,obj.yValues,'stacked','edgecolor','none','parent',ax); 
			title(ax,obj.Title,'fontsize',14);
			set(ax,'xtick',(0:10:100),'Fontsize',12);
			xlabel(ax,obj.xLabel,'fontsize',12);
			ylabel(ax,obj.yLabel,'fontsize',12);
			set(ax,'ygrid','on','fontsize',12);
			set(ax,'xgrid','off','fontsize',12)
			box(ax,'on');
			hl=legend(obj.Legend);
			set(hl,'location','southoutside','orientation','horizontal','fontsize',10);
        end
    end
end