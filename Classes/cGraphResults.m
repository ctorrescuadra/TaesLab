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
		isPieChart  % Use Pie Chart
    end

    methods
        function obj = cGraphResults(tbl, varargin)
		% Constructor. Create the object with the graph properties  
            obj=obj@cStatusLogger(cType.VALID);
			if ~isa(tbl,'cTableResult')
				obj.messageLog(cType.ERROR,'Invalid graph table. It must be cTableResult');
				return
			end
			if ~isValid(tbl) || ~isGraph(tbl)
				obj.messageLog(cType.ERROR,'Invalid graph table %s',tbl.Name);
				return
			end
			obj.Type=tbl.GraphType;
            obj.isColorbar=false;
			obj.isPieChart=false;
            switch obj.Type
			case cType.GraphType.COST
				obj.setGraphCostParameters(tbl);
			case cType.GraphType.DIAGNOSIS
				obj.setGraphDiagnosisParameters(tbl,varargin{:});
			case cType.GraphType.SUMMARY
				obj.setGraphSummaryParameters(tbl,varargin{:})
			case cType.GraphType.RECYCLING
				obj.setGraphRecyclingParameters(tbl)
			case cType.GraphType.WASTE_ALLOCATION
				obj.setGraphWasteAllocationParameters(tbl,varargin{:})
            case cType.GraphType.DIGRAPH
				    obj.setProductiveDiagramParameters(tbl,varargin{:});
			case cType.GraphType.DIGRAPH_FP
					obj.setDigraphFpParameters(tbl);
            case cType.GraphType.DIAGRAM_FP
                    obj.setDiagramFpParameters(tbl);
			otherwise
				obj.messageLog(cType.ERROR,'Invalid graph type %d',obj.Type);
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
				if obj.isPieChart
					obj.pieChartWasteAllocation;
				else
					obj.graphWasteAllocation;
				end
            case cType.GraphType.DIGRAPH       
				    obj.showDigraph;
            case cType.GraphType.DIAGRAM_FP 
                    obj.showDiagramFP;
			case cType.GraphType.DIGRAPH_FP
					obj.showDiagramFP;
			otherwise
				obj.messageLog(cType.ERROR,'Invalid graph type %d',obj.Type);
				return
            end   
        end

		function graphCost(obj)
		% Plot the ICT graph cost
			M=numel(obj.Legend);
			cm=turbo(M);
			f=figure('name',obj.Name, 'numbertitle','off','colormap',turbo,...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			b=bar(obj.yValues,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);

			for i=1:M
				set(b(i),'facecolor',cm(i,:));
			end
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			obj.setGraphParameters(ax);
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
			f=figure('name',obj.Name, 'numbertitle','off', 'colormap',turbo,...
			'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			bar(obj.xValues,obj.yValues,'edgecolor','none','barwidth',0.8,'parent',ax);
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			obj.setGraphParameters(ax);
		end

		function graphRecycling(obj)
		% Plot the graph recycling
			f=figure('name',obj.Name,'numbertitle','off','colormap',turbo,...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			plot(obj.xValues,obj.yValues,'Marker','diamond','LineWidth',1);
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			obj.setGraphParameters(ax);
		end

		function pieChartWasteAllocation(obj)
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

		function graphWasteAllocation(obj)
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

		function showDigraph(obj)
		% Plot Productive Diagrams (digraph)
            
			f=figure('name',obj.Name, 'numbertitle','off', ...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]); 
			ax=axes(f);    
			% Plot the digraph
            colors=eye(3);
            nodetable=obj.xValues.Nodes;
            nodecolors=colors(nodetable.Type,:);
            nodenames=nodetable.Name;
            plot(ax,obj.xValues,"Layout","auto","NodeLabel",nodenames,"NodeColor",nodecolors,"Interpreter","none");
            title(obj.Title,'fontsize',14,"Interpreter","none");
		end

		function showDiagramFP(obj)
		% Show the Diagram FP
			f=figure('name',obj.Name, 'numbertitle','off', ...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]); 
			ax=axes(f);
			if obj.isColorbar
				r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
				colormap(red2blue);
				plot(ax,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat");
				title(ax,obj.Title,'fontsize',14);
				c=colorbar(ax);
				c.Label.String=obj.xLabel;
				c.Label.FontSize=12;
			end
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

		function setGraphDiagnosisParameters(obj,tbl,shout)
		% Set the properties of diagnosis graph
		% Input:
		%	tbl - Name of the table
		%	shout - Remove ENV info in graph
			if nargin==2
				shout=true;
			end
			obj.Name=tbl.Description;
			obj.Title=[tbl.Description,' [',tbl.State,']'];
			if shout
                obj.Categories=tbl.ColNames(2:end);
				obj.xValues=(1:tbl.NrOfCols-1)';
				obj.yValues=cell2mat(tbl.Data(1:end-1,:))';
            else % does not plot last bar
                obj.Categories=tbl.ColNames(2:end-1);
				obj.xValues=(1:tbl.NrOfCols-2)';
				obj.yValues=cell2mat(tbl.Data(1:end-1,1:end-1))';
			end
			obj.xLabel='Processes';
			obj.yLabel=['Exergy ',tbl.Unit];
			obj.Legend=tbl.RowNames(1:end-1);
			obj.BaseLine=0.0;
		end

		function setGraphSummaryParameters(obj,tbl,var)
		% Set the properties of graph Summary
            if nargin<3
                obj.messageLog(cType.ERROR,'Parameters missing');
                return
            end
            if ~iscell(var)
                obj.messageLog(cType.ERROR,'Invalid parameter');
                return
            end
            idx=find(ismember(tbl.RowNames,var));
			if isempty(idx)
				obj.messageLog(cType.ERROR,'Invalid variable names');
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
			obj.xValues=(0:10:100);
			obj.yValues=cell2mat(tbl.Data);
			obj.xLabel='Recycling (%)';
			obj.yLabel=['Unit Cost ',tbl.Unit];
			obj.Categories=tbl.RowNames;
			obj.Legend=tbl.ColNames(2:end);
			if tbl.isGeneralCostTable
				obj.BaseLine=0.0;
			else
				obj.BaseLine=1.0;
			end
		end

        function setGraphWasteAllocationParameters(obj,tbl,wf)
		% Set the parameters of Waste Allocation pie chart
			obj.Name='Waste Allocation';
			if (nargin==3) && (~isempty(wf))  % Use pie chart for the waste flow
				cols=tbl.ColNames(2:end);
				idx=find(strcmp(cols,wf),1);
				if isempty(idx)
					obj.messageLog(cType.ERROR,'Parameters missing');
					return
				end
				x=cell2mat(tbl.Data(:,idx));
				jdx=find(x>1.0);
				obj.isPieChart=true;
				obj.Title=[tbl.Description ' [',tbl.State,'/',wf,']'];
				obj.xValues=x(jdx);
				obj.Legend=tbl.RowNames(jdx);
				obj.yValues=[];
				obj.xLabel='';
				obj.yLabel='';
				obj.BaseLine=0.0;
				obj.Categories={};
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

        function setDiagramFpParameters(obj,tbl)
        % Set the Diagram FP paramaters (tfp, dcfp)
            if isOctave
				obj.messageLog(cType.ERROR,'Graph function not implemented in Octave');
				return
            end
            mFP=cell2mat(tbl.Data(1:end-1,1:end-1));
            obj.Name=tbl.Description;
			obj.Title=[tbl.Description ' [',tbl.State,']'];
            data=cDiagramFP.adjacencyTable(mFP,tbl.RowNames);
			source=data(:,1); target=data(:,2);
			values=cell2mat(data(:,3));
			obj.xValues=digraph(source,target,values,'omitselfloops');
            obj.isColorbar=true;
            obj.Legend={};
			obj.yValues=[];
			obj.xLabel=['Exergy ' tbl.Unit];
			obj.yLabel='';
			obj.BaseLine=0.0;
            obj.Categories={};
        end

		function setDigraphFpParameters(obj,tbl)
		% Set the Diagram FP parameters (atfp, atcfp)
			if isOctave
				obj.messageLog(cType.ERROR,'Graph function not implemented in Octave');
				return
			end
			obj.Name=tbl.Description;
			obj.Title=[tbl.Description ' [',tbl.State,']'];
			source=tbl.Data(:,1); target=tbl.Data(:,2);
			values=cell2mat(tbl.Data(:,3));
			obj.xValues=digraph(source,target,values,'omitselfloops');
			obj.isColorbar=true;
			obj.Legend={};
			obj.yValues=[];
			obj.xLabel=['Exergy ' tbl.Unit];
			obj.yLabel='';
			obj.BaseLine=0.0;
			obj.Categories={};
		end

		function setProductiveDiagramParameters(obj,tbl,nodes)
		% Set the parameters of a digraph
			if isOctave
				obj.messageLog(cType.ERROR,'Graph function not implemented in Octave');
				return
			end
			if (nargin<3) || ~isstruct(nodes)
				obj.messageLog(cType.ERROR,'Node information is missing');
				return
			end
			obj.Name=tbl.Description;
			obj.Title=tbl.Description;
			tnodes=struct2table(nodes);
			edges=table(tbl.Data,'VariableNames',{'EndNodes'});
			obj.xValues=digraph(edges,tnodes,"omitselfloops");
            obj.Legend={};
			obj.yValues=[];
			obj.xLabel='';
			obj.yLabel='';
			obj.BaseLine=0.0;
            obj.Categories={};
		end

		function graphDiagnosis_OC(obj)
		% Show the diagnosis graph (Octave Version)
		%
			M=numel(obj.Legend);
			cm=turbo(M);
			f=figure('name',obj.Name, 'numbertitle','off','colormap',turbo,...
				'units','normalized','position',[0.05 0.1 0.4 0.6]);
			ax=axes(f,'position', [0.1 0.1 0.75 0.8]);
			hold(ax,'on');
			zt=obj.yValues;
			zt(zt>0)=0; % Plot negative values
			b1=bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
			for i=1:M
				set(b1(i),'facecolor',cm(i,:));
			end
			zt=obj.yValues;
			zt(zt<0)=0; % Plot positive values
			b2=bar(zt,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
			for i=1:M
				set(b2(i),'facecolor',cm(i,:));
			end
			obj.setGraphParameters(ax);
		end
	
		function graphDiagnosis_ML(obj)
		% Show the diagnosis graph (Matlab version)
		%
			M=numel(obj.Legend);
			cm=turbo(M);
			f = figure('numbertitle','off','Name',obj.Name,'colormap',turbo,...
				'units','normalized','position',[0.1 0.1 0.4 0.6],'color',[1,1,1]);
			ax = axes(f,'Position',[0.1 0.1 0.85 0.8]);
			hold(ax,'on');
			b=bar(obj.yValues,...
				'EdgeColor','none','BarWidth',0.5,...
				'BarLayout','stacked',...
				'BaseValue',obj.BaseLine,...
				'Parent',ax);			
			for i=1:M
				b(i).FaceColor=cm(i,:);
			end
			bs=b.BaseLine;
			bs.BaseValue=obj.BaseLine;
			bs.LineStyle='-';
			bs.Color=[0.6,0.6,0.6];
			obj.setGraphParameters(ax);
		end

		function setGraphParameters(obj,ax)
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