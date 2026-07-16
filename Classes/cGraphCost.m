classdef cGraphCost < cGraphResults
%cGraphCost - Plot the irreversibility-cost stacked bar graph.
%   Builds a stacked bar chart where each bar represents a flow or process
%   and each coloured segment shows the contribution from one cost component
%   (environment plus upstream processes).  The base line is 0 for general
%   cost tables and 1 for unit-cost tables.
%
%   cGraphCost Methods:
%     cGraphCost  - Construct a cGraphCost from an irreversibility-cost table
%     showGraph   - Display the bar graph in a standalone figure window
%     showGraphUI - Display the bar graph in an App Designer graph panel
%
%   See also cGraphResults, cExergyCost
%
    methods
        function obj=cGraphCost(tbl)
        %cGraphCost - Construct a cGraphCost from an irreversibility-cost table
        %
        %   Syntax:
        %     obj = cGraphCost(tbl)
        %   Input Arguments:
        %     tbl - cTable containing the irreversibility-cost data to visualise
        %   Output Arguments:
        %     obj - cGraphCost object (check obj.status before use)
        %
            % Build graph data
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description,' [',tbl.State,']'];
            obj.Style = cType.GraphStyles.STACK;
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
        
        function showGraph(obj)
        %showGraph - Display the stacked bar graph in a standalone figure window
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
            %set(f,'visible','on');
        end

        function showGraphUI(obj,app)
        %showGraphUI - Display the stacked bar graph in an App Designer graph panel
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

end