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
		isColorbar  % Colorbar activated
    end

    methods
        function obj = cGraphResults(tbl, varargin)
		% Constructor. Create the object with the graph properties  
            obj.status=cType.VALID;
			if ~isa(tbl,'cTableResult')
				obj.messageLog(cType.ERROR,'Invalid graph table. It must be cTableResult');
				return
			end
			if ~isValid(tbl) || ~isGraph(tbl)
				obj.messageLog(cType.ERROR,'Invalid Graph Table %s',tbl.Name);
				return
			end
			obj.Type=tbl.GraphType;
            obj.isColorbar=false;
            switch obj.Type
			case cType.GraphType.COST
				obj.setGraphCostParameters(tbl);
			case cType.GraphType.DIAGNOSIS
				obj.setGraphDiagnosisParameters(tbl,varargin{:});
			case cType.GraphType.SUMMARY
				obj.setGraphSummaryParameters(tbl,varargin{:})
			case cType.GraphType.RECYCLING
				obj.setGraphRecyclingParameters(tbl,varargin{:})
			case cType.GraphType.WASTE_ALLOCATION
				obj.setGraphWasteAllocationParameters(tbl,varargin{:})
            case cType.GraphType.DIGRAPH
                if isMatlab
				    obj.setDigraphParameters(tbl);
                end
            case cType.GraphType.DIAGRAM_FP
                if isMatlab
                    obj.setProcessDiagramParameters(tbl);
                end
			otherwise
				obj.messageLog(cType.ERROR,'Invalid Graph Type %d',obj.Type);
				return
            end
        end

        function showGraph(obj)
            switch obj.Type
			case cType.GraphType.COST
				obj.graphCost;
			case cType.GraphType.DIAGNOSIS
				obj.graphDiagnosis;
			case cType.GraphType.SUMMARY
				obj.graphSummary;
			case cType.GraphType.RECYCLING
				obj.graphRecycling;
			case cType.GraphType.WASTE_ALLOCATION
				obj.graphWasteAllocation;
            case cType.GraphType.DIGRAPH
                if isMatlab
				    obj.showDigraph;
                end
            case cType.GraphType.DIAGRAM_FP
                if isMatlab
                    obj.showDigraph;
                end
			otherwise
				obj.messageLog(cType.ERROR,'Invalid Graph Type %d',obj.Type);
				return
            end   
        end

		function graphCost(obj)
		% Plot the ICT graph cost
			f=figure('name',obj.Name, 'numbertitle','off', ...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			bar(obj.yValues,'stacked','edgecolor','none','barwidth',0.5,'parent',ax); 
			title(ax,obj.Title,'fontsize',14);
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			set(ax,'xtick',obj.xValues,'xticklabel',obj.Categories,'fontsize',12);
			xlabel(ax,obj.xLabel,'fontsize',12);
			ylabel(ax,obj.yLabel,'fontsize',12);
			set(ax,'ygrid','on','fontsize',12);
			set(ax,'xgrid','off','fontsize',12)
			box(ax,'on');
			hl=legend(obj.Legend);
			set(hl,'location','northeastoutside','orientation','vertical','fontsize',10);
		end

		function graphDiagnosis(obj)
		% Plot diagnosis graphs
            if isOctave
                graphDiagnosis_OC(obj)
            else
				graphDiagnosis_ML(obj)
            end
        end

		function graphSummary(obj)
		% Plot the summary graph
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
		% Plot the graph recycling
			f=figure('name',obj.Name,'numbertitle','off',...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			plot(obj.xValues,obj.yValues,'Marker','diamond');
			title(ax,obj.Title,'fontsize',14);
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			xlabel(ax,obj.xLabel,'fontsize',12);
			ylabel(ax,obj.yLabel,'fontsize',12);
			set(ax,'xgrid','off','ygrid','on');
			box(ax,'on');
			hl=legend(obj.Legend);
			set(hl,'Orientation','horizontal','Location','southoutside');
		end

		function graphWasteAllocation(obj)
		% Plot the waste allocation pie chart
			f=figure('name',obj.Name,'numbertitle','off',...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			pie(obj.xValues,'%5.1f%%');
			title(ax,obj.Title,'fontsize',14);
			hl=legend(obj.Legend);
			set(hl,'Orientation','horizontal','Location','southoutside');
		end

		function showDigraph(obj)
		% Plot Productive and FP digraphs
			f=figure('name',obj.Name, 'numbertitle','off', ...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]); 
			ax=axes(f);
			% Plot the digraph with colobar     
			if obj.isColorbar
				r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
				colormap(red2blue);
				plot(ax,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat");
                c=colorbar(ax);
			    c.Label.String=obj.xLabel;
				c.Label.FontSize=12;
			else
				plot(ax,obj.xValues,"Layout","auto","interpreter","none");
			end
			title(ax,obj.Title,'fontsize',14);
		end
	end
   
	methods(Access=private)
		function setGraphCostParameters(obj,tbl)
        % Set the properties of GraphCost   
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

		function setGraphDiagnosisParameters(obj,tbl,opt)
		% Set the properties of diagnosis graph
		% Input:
		%	tbl - Name of the table
		%	opt - Remove ENV info in graph
			if nargin==2
				opt=false;
			end
			obj.Name=tbl.Description;
			obj.Title=[tbl.Description,' [',tbl.State,']'];
			if opt
				obj.Categories=tbl.ColNames(2:end-1);
				obj.xValues=(1:tbl.NrOfCols-2)';
				obj.yValues=cell2mat(tbl.Data(1:end-1,1:end-1))';
			else
				obj.Categories=tbl.ColNames(2:end);
				obj.xValues=(1:tbl.NrOfCols-1)';
				obj.yValues=cell2mat(tbl.Data(1:end-1,:))';
			end
			obj.xLabel='Processes';
			obj.yLabel=['Exergy ',tbl.Unit];
			obj.Legend=tbl.RowNames(1:end-1);
			obj.BaseLine=0.0;
		end

		function setGraphSummaryParameters(obj,tbl,idx)
		% Set the properties of graph Summary
            if nargin<3
                obj.messageLog(cType.ERROR,'Parameters Missing');
                return
            end
            if ~isnumeric(idx)
                obj.messageLog(cType.ERROR,'Invalid Parameter');
                return
            end
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
		% Set the properties of graph recycling
            if nargin==2
                label=tbl.ColNames{end};
            end
			obj.Name='Recycling Cost Analysis';
			obj.Title=[tbl.Description ' [',tbl.State,'/',label,']'];
			obj.Categories={};
			obj.xValues=(0:10:100);
			obj.yValues=cell2mat(tbl.Data);
			obj.xLabel='Recycling (%)';
			obj.yLabel=['Unit Cost ',tbl.Unit];
			obj.Legend=tbl.ColNames(2:end);
			if tbl.isGeneralCostTable
				obj.BaseLine=0.0;
			else
				obj.BaseLine=1.0;
			end
		end

        function setGraphWasteAllocationParameters(obj,tbl,wf)
		% Set the parameters of Waste Allocation pie chart
			switch nargin
			case 2
				idx=1;
                wf=tbl.ColNames{idx+1};
			case 3
				cols=tbl.ColNames(2:end);
				idx=find(strcmp(cols,wf),1);
				if isempty(idx)
					obj.messageLog(cType.ERROR,'Parameters missing');
					return
				end
			otherwise
				obj.messageLog(cType.ERROR,'Parameters missing');
				return
			end
			obj.Name='Waste Allocation Analysis';
			obj.Title=[tbl.Description ' [',tbl.State,'/',wf,']'];
			x=cell2mat(tbl.Data(:,idx));
			jdx=find(x>1.0);
			obj.xValues=x(jdx);
            obj.Legend=tbl.RowNames(jdx);
			obj.yValues=[];
			obj.xLabel='';
			obj.yLabel='';
			obj.BaseLine=0.0;
            obj.Categories={};
        end

        function setProcessDiagramParameters(obj,tbl)
        % Set the Diagram FP paramaters
            obj.Name=tbl.Description;
			obj.Title=[tbl.Description ' [',tbl.State,']'];
            obj.xValues=getDigraphFP(tbl);
            obj.isColorbar=true;
            obj.Legend={};
			obj.yValues=[];
			obj.xLabel=['Exergy ' tbl.Unit];
			obj.yLabel='';
			obj.BaseLine=0.0;
            obj.Categories={};
        end

		function setDigraphParameters(obj,tbl)
		% Set the parameters of a digraph
			obj.Name=tbl.Description;
			obj.Title=[tbl.Description ' [',tbl.State,']'];
			source=tbl.Data(:,1);
			target=tbl.Data(:,2);
			obj.xValues=digraph(source,target,"omitselfloops");
            obj.Legend={};
			obj.yValues=[];
			obj.xLabel=['Exergy ' tbl.Unit{end}];
			obj.yLabel='';
			obj.BaseLine=0.0;
            obj.Categories={};
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
			f = figure('numbertitle','off','Name',obj.Name,...
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
			set(ax,'XTick',obj.xValues,'XTickLabel',obj.Categories,'FontSize',11);
			title(ax,obj.Title,'FontSize',14);
			xlabel(ax,obj.xLabel,'fontsize',11);
			ylabel(ax,obj.yLabel,'fontsize',11);
			box(ax,'on');
			set(ax,'ygrid','on','xgrid','off')
			hold(ax,'off');
			hl=legend(ax,obj.Legend,'FontSize',10);
			set(hl,'location','northeastoutside','orientation','vertical');
		end
    end
end