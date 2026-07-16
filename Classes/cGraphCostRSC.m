classdef cGraphCostRSC < cGraphResults
%cGraphCostRSC - Plot the resource-specific cost distribution graph.
%   Creates either a stacked bar chart or a pie chart from a cTable containing
%   resource-specific cost data, depending on the variables argument supplied
%   to the constructor:
%     - Single flow/process name  → pie chart for that variable
%     - Cell array of names       → stacked bar chart for the listed variables
%     - 'ALL'                     → stacked bar chart for all variables
%     - Omitted or empty          → stacked bar chart for default system outputs
%
%   cGraphCostRSC Methods:
%     cGraphCostRSC - Construct a cGraphCostRSC from a resource-cost table
%     showGraph     - Display the graph in a standalone figure window
%     showGraphUI   - Display the stacked bar graph in an App Designer graph panel
%
%   See also cGraphResults, cExergyCost
%
    properties(Access=private)
        isPieChart = false  % True when a single variable was requested and a pie chart is rendered
    end

    methods
        function obj=cGraphCostRSC(tbl,info,variables)
        %cGraphCostRSC - Construct a cGraphCostRSC from a resource-cost table
        %
        %   Syntax:
        %     obj = cGraphCostRSC(tbl, info)
        %     obj = cGraphCostRSC(tbl, info, variables)
        %   Input Arguments:
        %     tbl       - cTable containing the resource-specific cost data
        %     info      - cExergyCost object providing productive structure metadata
        %     variables - Variable selection (optional):
        %                   omitted or empty  → default system output flows/processes
        %                   cell array        → stacked bar for the listed names
        %                   'ALL'             → stacked bar for every row in tbl
        %                   char (single name)→ pie chart for that flow or process
        %   Output Arguments:
        %     obj - cGraphCostRSC object (check obj.status before use)
        %   
            obj.Style = cType.GraphStyles.STACK;
            % Validate input arguments
            if ~isa(tbl,'cTable') || ~isa(info,'cExergyCost')
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Build graph data
            if (nargin==2) || isempty(variables) % Plot system outputs/processes (default)
                [res,idx]=cGraphCostRSC.getCategories(tbl,info);
                if isempty(res)
                    obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                    return
                end
                obj.Categories=res;
                obj.yValues=cell2mat(tbl.Data(idx,1:end-1));
            elseif iscell(variables) && length(variables)>1 % Plot selected variables
                [chk,idx]=ismember(variables,tbl.RowNames);
                if all(chk)
                    obj.Categories=variables;
                    obj.yValues=cell2mat(tbl.Data(idx,1:end-1));
                else
                    obj.messageLog(cType.ERROR,cMessages.InvalidVariableNames);
                    return
                end
            elseif ischar(variables) 
                if strcmpi(variables,'ALL') % Plot all variables
                    obj.Categories=tbl.RowNames;
                    obj.yValues=cell2mat(tbl.Data(:,1:end-1));
                else
                    obj.isPieChart=true; % Plot single variable as pie chart
                    [chk,idx]=ismember(variables,tbl.RowNames);
                    if ~chk
                        obj.messageLog(cType.ERROR,cMessages.InvalidVariableNames);
                        return
                    end
                end
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidVariableNames);
                return
            end
            % Set graph properties
            obj.Name=tbl.Description;
            obj.BaseLine=0.0;
            if obj.isPieChart % Pie chart for a single variable
                x=cell2mat(tbl.Data(idx,1:end-1));
                x=100*x/sum(x);
                jdx=find(x>1.0);
                obj.Title=[tbl.Description ' [',tbl.State,'/',variables,']',];
                obj.xValues=x(jdx);
                obj.Legend=tbl.ColNames(jdx+1);
                obj.yValues=cType.EMPTY;
                obj.xLabel=cType.EMPTY_CHAR;
                obj.yLabel=cType.EMPTY_CHAR;
                obj.Categories=cType.EMPTY_CELL;
                obj.Style=cType.GraphStyles.PIE;
            else    % Stacked bar graph for multiple variables
                obj.Title=[tbl.Description,' [',tbl.State,']'];
                obj.xValues=(1:length(obj.Categories))';
                if tbl.isFlowsTable
                    obj.xLabel='Flow';
                else
                    obj.xLabel='Process';
                end
                obj.Legend=tbl.ColNames(2:end-1);
                obj.BaseLine=0.0;
                obj.yLabel=['Unit Cost ',tbl.Unit];
            end
        end

        function showGraph(obj)
        %showGraph - Display either the stacked bar graph or the pie chart in a standalone figure
        %   The chart type is selected automatically based on the variables argument
        %   passed to the constructor (pie chart for a single variable, bar otherwise).
        %   Syntax:
        %     obj.showGraph
        %
            if obj.isPieChart
                obj.showPieChart;
            else
                obj.showBarGraph
            end
        end
        
        function showGraphUI(obj,app)
        %showGraphUI - Display the stacked bar graph in an App Designer graph panel
        %   Note: the GUI always uses the stacked bar layout regardless of the
        %   chart type selected for the standalone showGraph.
        %
        %   Syntax:
        %     obj.showGraphUI(app)
        %   Input Arguments:
        %     app - matlab.apps.AppBase object whose UIAxes hosts the graph
        %
            M=numel(obj.Legend);
            cm=turbo(M);
            if app.isColorbar
                delete(app.Colorbar);
            end
            % Plot the bar graph
            b=bar(obj.yValues,...
                'EdgeColor','none','BarWidth',0.5,...
                'BarLayout','stacked',...
                'BaseValue',obj.BaseLine,...
                'FaceColor','flat',...
                'Parent',app.UIAxes);
            for i=1:M, b(i).CData=cm(i,:); end
            setGraphParametersUI(obj,app);
            app.UIAxes.Visible='on';
        end
    end

    methods(Access=private)
        function showBarGraph(obj)
        %showBarGraph - Display the resource-cost stacked bar graph in a standalone figure
        %   Syntax:
        %     obj.showBarGraph
        %
            M=numel(obj.Legend);
            cm=turbo(M);
            set(groot,'defaultTextInterpreter','none');
            f = figure('Name', obj.Name, ...
                    'NumberTitle', 'off', ...
                    'Colormap', turbo, ...
                    'Units', 'normalized', ...
                    'Position', [0.1 0.1 0.45 0.6], ...
                    'Color', [1 1 1]);
            ax = axes(f);        
            b=bar(obj.yValues,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);
            for i=1:M, set(b(i),'facecolor',cm(i,:)); end
            tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
            obj.setGraphParameters(ax);
        end

        function showPieChart(obj)
        %showPieChart - Display the resource-cost contribution of a single variable as a pie chart
        %   Slices with a contribution below 1 % are merged into the remainder and hidden.
        %
        %   Syntax:
        %     obj.showPieChart
        %
			set(groot,'defaultTextInterpreter','none');
			f=figure('name',obj.Name,...
				'numbertitle','off',...
                'colormap',turbo,...
                'units','normalized',...
                'position',[0.1 0.1 0.45 0.6],...
                'color',[1 1 1]);
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
    end
    
    methods(Static,Access=private)
        function [res,idx]=getCategories(tbl,info)
        %getCategories - Determine the default variable categories from the productive structure
        %   Returns the system output flows when tbl is a flows table, or the
        %   output processes otherwise.
        %
        %   Syntax:
        %     [res, idx] = cGraphCostRSC.getCategories(tbl, info)
        %   Input Arguments:
        %     tbl  - cTable containing the resource-specific cost data
        %     info - cExergyCost object providing productive structure metadata
        %   Output Arguments:
        %     res - Cell array of default category name strings
        %     idx - Logical or numeric index vector into the table rows
        %
            if tbl.isFlowsTable
                idx=info.ps.SystemOutputFlows;
                res=info.ps.FlowKeys(idx);
            else
                idx=info.ps.OutputProcesses;
                res=info.ps.ProcessKeys(idx);
            end
        end
    end
end