classdef cGraphSummary < cGraphResults
%cGraphSummary - Plot the summary graphs for selecting flows or processes.
%   There is two graph methods to show the summary results
%   - BarGraph: Values are show in bar graphs grouped by STATE or SAMPLE 
%   - PlotGraph: Values are show in plot graphs
%
%   cGraphSummary methods:
%     cGraphSummary  - Build an instance of the class
%     showGraph      - show the graph in a window 
%     showGraphUI    - show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults, cSummaryResults
%
	properties(Access=private)
		isBarGraph
	end

    methods
        function obj = cGraphSummary(tbl,info,options)
		%cGraphWaste - Build an instance of the object
        % 	Syntax:
        %     obj = cGraphSummary(tbl,info,option)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cSummaryResults object with additional info
		%     options - struct containing the option values
        %       Variables: cell array with the variables to show
		%       BarGraph: true | false indicates if bar graph is used
		%   Output Arguments:
		%     obj - cGraphSummary object
		%
			if nargin < 2 || ~isObject(info,'cSummaryResults')
				obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
				return
			end
			if ~tbl.isSummaryTable
				obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
				return
			end
		%
			if nargin < 3
				options.Variables=cType.EMPTY_CELL;
                options.BarGraph=true;
			end
			if ~isfield(options,'Variables')
                options.Variables=cType.EMPTY_CELL;
			end
            if ~isfield(options,'BarGraph') || ~islogical(options.BarGraph)
				options.BarGraph=false;
            end
            if isempty(options.Variables)
				if tbl.isFlowsTable
					var=info.getDefaultFlowVariables;
				else
					var=info.getDefaultProcessVariables;
				end
            else
                var=options.Variables;
            end
			if ~iscell(var)
                obj.messageLog(cType.ERROR,cMessages.InvalidParameter);
                return
			end
            idx=find(ismember(tbl.RowNames,var));
			if isempty(idx)
				obj.messageLog(cType.ERROR,cMessages.InvalidParameter);
				return
			end
			obj.Name='Cost Summary';
			obj.Categories=tbl.RowNames(idx);
			obj.xValues=(1:length(idx))';
			obj.yValues=cell2mat(tbl.Data(idx,:));
			obj.Title=tbl.Description;
			obj.isBarGraph=options.BarGraph;
			switch tbl.SummaryType
				case cType.STATES
					obj.xLabel='States';
					if tbl.Resources
						obj.Title=horzcat(obj.Title,' - [',tbl.Sample,']');
					end
				case cType.RESOURCES
					obj.xLabel='Samples';
					obj.Title=horzcat(obj.Title,' - [',tbl.State,']');
				otherwise
					obj.xLabel='';
			end
			obj.yLabel=['Unit Cost ',tbl.Unit];
			obj.Legend=tbl.ColNames(2:end);
			if tbl.isGeneralCostTable
				obj.BaseLine=0.0;
			else
				obj.BaseLine=1.0;
			end
        end

        function showGraph(obj)
		%showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraph
		%
			set(groot,'defaultTextInterpreter','none');
			f=figure('name',obj.Name,...
			         'numbertitle','off',...
                     'colormap',turbo,...
			         'units','normalized',...
                     'position',[0.1 0.1 0.45 0.6],...
                     'color',[1 1 1]);
			ax=axes(f);
			if obj.isBarGraph
				bar(obj.xValues,obj.yValues,...
                    'edgecolor','none',...
                    'barwidth',0.8,...
                    'parent',ax);
				tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);		
			else
				plot(obj.xValues,obj.yValues,...
                    'Marker','diamond',...
                    'LineWidth',1);
			end
			obj.setGraphParameters(ax);
        end

		function showGraphUI(obj,app)
		%showGraphUI - show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Parameter:
		%	  app - GUI app reference object
		%
			if app.isColorbar
				delete(app.Colorbar);
			end
			if obj.isBarGraph
				bar(obj.xValues, obj.yValues,...
					'EdgeColor','none','BarWidth',0.5,...
					'BaseValue',obj.BaseLine,...
					'FaceColor','flat',...
					'Interpreter','none',...
					'Parent',app.UIAxes);
			else
				plot(obj.xValues,obj.yValues,'Marker','diamond','LineWidth',1);
			end
			setGraphParametersUI(obj,app);
			app.UIAxes.Visible='on';
		end
    end
end