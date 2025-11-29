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
		variables
		cases
	end

    methods
        function obj = cGraphSummary(tbl,info,options)
		%cGraphSummary - Build an instance of the object
        % 	Syntax:
        %     obj = cGraphSummary(tbl,info,option)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cSummaryResults object with additional info
		%     options - struct containing the option values
        %       Variables: cell array with the variables to show
		%       Cases: cell array with the cases (STATES/SAMPLES) to show
		%	    Style: graph style to use (BAR, STACK, PLOT)
		%   Output Arguments:
		%     obj - cGraphSummary object
		%
			% Check input arguments
			if nargin < 2 || ~isObject(info,'cSummaryResults')
				obj.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
				return
			end
			if ~tbl.isSummaryTable
				obj.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
				return
			end
			if nargin < 3
				options.Variables=cType.EMPTY_CELL;
                options.Style=cType.DEFAULT_GRAPHSTYLE;
			end
			if ~isfield(options,'Variables')
                options.Variables=cType.EMPTY_CELL;
			end
            if ~isfield(options,'Style') 
				options.Style=cType.DEFAULT_GRAPHSTYLE;
            end
			% Initialize private variables
			obj.variables=tbl.RowNames;
			obj.cases=tbl.ColNames(2:end);
			% Check GraphStyle option
			style=cType.getGraphStyle(options.Style);
			if  style==cType.GraphStyles.STACK && ~tbl.Resources
				style=cType.GraphStyles.BAR; % Stack not allowed for States summary
			end
			% Check Variables option
			idx=obj.checkVariables(tbl,info,options.Variables);
			if  isempty(idx)
				obj.messageLog(cType.ERROR,cMessages.InvalidParameter,'Variables');
				return
			end
			% Check Cases option
			jdx=obj.checkCases(style,options.Cases);
			if isempty(jdx)
				obj.messageLog(cType.ERROR,cMessages.InvalidParameter,'Cases');
				return
			end
			data=tbl.Data(idx,jdx);
			% Build graph data depending on the style
			style=cType.getGraphStyle(options.Style);
			if isscalar(idx) && style~=cType.GraphStyles.PLOT
				style=cType.GraphStyles.PLOT; % Single variable shown as plot graph
			end
            switch style
				case cType.GraphStyles.PLOT
					obj.Categories=obj.cases(jdx);					
					obj.xValues=(1:length(jdx))';
					obj.yValues=cell2mat(data)';
					obj.Legend=obj.variables(idx);
					if tbl.SummaryType==cType.RESOURCES
						obj.xLabel='Samples';
                        obj.Title=horzcat(obj.Title,' - [',tbl.Sample,']');
					else
						obj.xLabel='States';
                        obj.Title=horzcat(obj.Title,' - [',tbl.State,']');
					end
        		case {cType.GraphStyles.BAR,cType.GraphStyles.STACK}
					obj.Categories=obj.variables(idx);
					obj.xValues=(1:length(idx))';
					obj.yValues=cell2mat(data);
					obj.Legend=obj.cases(jdx);
					if tbl.isFlowsTable 
						obj.xLabel='Flows';
					else
						obj.xLabel='Processes';
					end
            end
			obj.yLabel=['Unit Cost ',tbl.Unit];
			if tbl.isGeneralCostTable
				obj.BaseLine=0.0;
			else
				obj.BaseLine=1.0;
			end
			obj.Name='Cost Summary';
			obj.Title=tbl.Description;
			obj.Style=style;
        end

        function showGraph(obj)
		%showGraph - Show the graph in a window
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
			% Create graph depending on the style
			switch obj.Style
				case cType.GraphStyles.BAR
					b=bar(obj.yValues,'grouped','edgecolor','none',...
                        'Interpreter','none','barwidth',0.5,'parent',ax);
					M=numel(obj.Legend);
					cm=turbo(M);
					for i=1:M, set(b(i),'facecolor',cm(i,:)); end
					tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
				case cType.GraphStyles.STACK
					b=bar(obj.yValues,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
					M=numel(obj.Legend);
					cm=turbo(M);
					for i=1:M, set(b(i),'facecolor',cm(i,:)); end
					tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
				case cType.GraphStyles.PLOT
					plot(obj.xValues,obj.yValues,...
						'Marker','diamond',...
						'LineWidth',1);
                    ylim('auto');
			end
			obj.setGraphParameters(ax);
        end

		function showGraphUI(obj,app)
		%showGraphUI - Show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Parameter:
		%	  app - GUI app reference object
		%
			if app.isColorbar
				delete(app.Colorbar);
			end
			% Create graph depending on the style
			switch obj.Style
				case cType.GraphStyles.BAR
					bar(obj.xValues, obj.yValues,...
						'EdgeColor','none','BarWidth',0.5,...
						'BaseValue',obj.BaseLine,...
						'FaceColor','flat',...
						'Interpreter','none',...
						'Parent',app.UIAxes);
				case cType.GraphStyles.STACK
					bar(obj.xValues, obj.yValues',...
						'EdgeColor','none',...
						'BarLayout','stacked',...
						'Parent',app.UIAxes);
				case cType.GraphStyles.PLOT
					plot(obj.xValues,obj.yValues,'Marker','diamond','LineWidth',1);
			end	
			setGraphParametersUI(obj,app);
			app.UIAxes.Visible='on';
		end
    end

	methods(Access=private)
		function res=checkVariables(obj,tbl,info,var)
		%checkVariables - Check Variables option
		%   Syntax:
		%     res=checkVariables(obj,tbl,info,var)
		%   Input Arguments:
		%     tbl - cTable with the data to show graphically
		%     info - cSummaryResults object with additional info
		%     var - cell array with the variables to show	
		%   Output Arguments:
		%     res - indices of the variables to show
		%
			res=cType.EMPTY;
			% If no variables are specified, get the output default variables
			if isempty(var)
				if tbl.isFlowsTable
					var=info.getDefaultFlowVariables;
				else
					var=info.getDefaultProcessVariables;
				end
			end
			% Check if the result is a cell array
			if ~iscell(var)
                return
			end
			% Get indices of the selected variables
            res=find(ismember(obj.variables,var));
		end

		function res=checkCases(obj,style,var)
		%checkCases - Check Cases option
		%   Syntax:
		%     res=checkCases(obj,style,var)
		%   Input Arguments:
		%     style - graph style
		%     var - cell array with the cases to show
		%   Output Arguments:
		%     res - indices of the cases to show
		%
			res=cType.EMPTY;
            if isempty(var)
				%Remove first case (Total) for stack graphs
				if style==cType.GraphStyles.STACK 
					var=obj.cases(2:end);
				else
					var=obj.cases;
				end
            end
			% Check if the result is a cell array
			if ~iscell(var)
                return
			end
			% Get indices of the selected cases
            res=find(ismember(obj.cases,var));
		end

	end
end