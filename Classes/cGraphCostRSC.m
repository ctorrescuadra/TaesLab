classdef cGraphCostRSC < cGraphResults
%cGraphCostRSC - Plot the cost distribution due to resources graph.
%  This class creates a stacked bar graph or a pie chart from a cTable object
%  containing the resource-specific cost data of a productive structure.
%  If a single flow or process is selected a pie chart is shown for that resource,
%  otherwise a stacked bar graph is shown for all the selected resources.
%
%   cGraphCost methods:
%     cGraphCost  - Build an instance of the class
%     showGraph   - Show the graph in a window
%     showGraphUI - Show the graph in the graph panel of a GUI app
%
%   See also cGraphResults, cExergyCost
%
    properties(Access=private)
        isPieChart    %Pie Chart is used
    end

    methods
        function obj=cGraphCostRSC(tbl,info,variables)
        %cGraphCost - Build an instance of the object
        %   Syntax:
        %     obj = cGraphRecycling(tbl)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cExergyCost object with additional information for the graph
        %     variables - Variables to consider in the graph
        %       cell array | array of chars
        %
        %   Output Arguments:
        %    obj - cGraphCost object
        %       if variables exist and is a string then a pie chart is shown for that variable
        %       if variables do not exist or is a cell array then a stacked bar graph is shown
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
        %showGraph - show the graph in a window
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
        %showGraphUI - show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Arguments:
		%	  app - GUI app reference object
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
        %showGraphBar - Show the bar graph in a window
        %   Syntax:
        %     obj.showGraph
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
    	%showPieChart - Plot the resource cost in a pie chart
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
        %getCategories - Get the categories to show in the graph
        %   Syntax:
        %     [res,idx] = cGraphCostRSC.getCategories(tbl,info)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cExergyCost object with additional information for the graph
        %   Output Arguments:
        %     res - Cell array with the categories to show
        %     idx - Indices of the categories in the table
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