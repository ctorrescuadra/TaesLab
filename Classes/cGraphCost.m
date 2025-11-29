classdef cGraphCost < cGraphResults
%cGraphCost - Plot the Irreversibility-cost graph.
%   This class creates a stacked bar graph from a cTable object
%   containing the irreversibility-cost data of a productive structure.
%
%   cGraphCost methods:
%     cGraphCost  - Build an instance of the class
%     showGraph   - Show the graph in a window 
%     showGraphUI - Show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults, cExergyCost
%
    methods
        function obj=cGraphCost(tbl)
        %cGraphCost - Build an instance of the object
        %   Syntax:
        %     obj = cGraphRecycling(tbl)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %   Output Arguments:
        %     obj - cGraphCost object
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
        %showGraph - Show the graph in a window
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
        %showGraphUI - Show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Parameter:
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

end