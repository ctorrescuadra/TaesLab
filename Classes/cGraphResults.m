classdef cGraphResults < cStatusLogger
% cGraphSummary plot as bar summary tables
    properties(GetAccess=public,SetAccess=private)
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

    methods
        function obj = cGraphResults(tbl,options)
			if ~isValid(tbl) || ~isGraph(tbl)
				obj.messageLog('Invalid Graph Table %s',obj.key);
				return
			end
			obj.Type=tbl.GraphType;
			switch obj.Type
			case cType.GraphType.COST
				obj.setGraphCostParameters(tbl);
			case cType.GraphType.DIAGNOSIS
				obj.setGraphDiagnosisParameters(tbl);
			case cType.GraphType.SUMMARY
				obj.setGraphSummaryParameters(tbl,options)
			case cType.GraphType.RECYCLING
				obj.setGraphRecyclingParameters(tbl,options)
			otherwise
				obj.messageLog('Invalid Graph Type %d',obj.GraphType);
				return
			end
		end

		function graphCost(obj)
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

		function graphDiagnosis(obj)
            if isOctave
                graphDiagnosis_OC(obj)
            else
				graphDiagnosis_ML(obj)
            end
        end

		function graphSummary(obj)
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
			set(ax,'xgrid','off','ygrid','on');
			box(ax,'on');
			hl=legend(obj.Legend);
			set(hl,'Orientation','horizontal','Location','southoutside');
		end

		function graphRecycling(obj)
			f=figure('name',obj.Name,'numbertitle','off',...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			plot(obj.xValues,obj.yValues,'Marker','diamond');
			title(ax,obj.Title,'fontsize',14);
			xlabel(ax,obj.xLabel,'fontsize',12);
			ylabel(ax,obj.yLabel,'fontsize',12);
			set(ax,'xgrid','off','ygrid','on');
			box(ax,'on');
			hl=legend(obj.Legend);
			set(hl,'Orientation','horizontal','Location','southoutside');
		end
	end
   
	methods(Access=private)
		function setGraphCostParameters(obj,tbl)
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

		function setGraphDiagnosisParameters(obj,tbl)
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

		function setGraphSummaryParameters(obj,tbl,idx)
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

		function setGraphRecyclingParameters(obj,tbl,label)
			obj.Name='Recycling Cost Analysis';
			obj.Title=[tbl.Description ' [',tbl.State,'/',label,']'];
			obj.Categories={};
			obj.xValues=(0:10:100);
			obj.yValues=cell2mat(tbl.Data);
			obj.xLabel='Recycling (%)';
			obj.yLabel=['Unit Cost ',tbl.Unit];
			obj.Legend=tbl.ColNames(2:end);
			if tbl.isGeneralCostTable || tbl.isFlowsTable
				obj.BaseLine=0.0;
			else
				obj.BaseLine=1.0;
			end
		end

		function graphDiagnosis_OC(obj)
		% Show the diagnosis graph (Octave Version)
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
	
		function graphDiagnosis_ML(obj)
		% Show the diagnosis graph (Matlab version)
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
			bs.BaseValue=obj.BaseLine;
			bs.LineStyle='-';
			bs.Color=[0.6,0.6,0.6];
			set(ax,'XTick',obj.xValues,'XTickLabel',obj.Categories,'FontSize',9);
			title(ax,obj.Title,'FontSize',12);
			xlabel(ax,obj.xLabel,'fontsize',10);
			ylabel(ax,obj.yLabel,'fontsize',10);
			box(ax,'on');
			set(ax,'ygrid','on','xgrid','off')
			hold(ax,'off');
			hl=legend(ax,obj.Legend,'FontSize',8);
			set(hl,'location','northeastoutside','orientation','vertical');
		end
    end
end