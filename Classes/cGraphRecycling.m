classdef cGraphRecycling < cGraphResults
%cGraphRecycling - Plot the waste recycling cost line graph.
%   Creates a line graph with diamond markers showing how the unit cost of
%   selected flows or processes evolves as the waste recycling fraction varies
%   from 0 % to 100 %.  The base line is 0 for general cost tables and 1 for
%   unit-cost tables.
%
%   cGraphRecycling Methods:
%     cGraphRecycling - Construct a cGraphRecycling from a recycling cost table
%     showGraph       - Display the line graph in a standalone figure window
%     showGraphUI     - Display the line graph in an App Designer graph panel
%
%   See also cGraphResults, cWasteAnalysis
%
    methods
        function obj = cGraphRecycling(tbl)
        %cGraphRecycling - Construct a cGraphRecycling from a recycling cost table
        %
        %   Syntax:
        %     obj = cGraphRecycling(tbl)
        %   Input Arguments:
        %     tbl - cTable containing the recycling cost data (rows = variables, cols = recycling %)
        %   Output Arguments:
        %     obj - cGraphRecycling object (check obj.status before use)
        %
			obj.Name='Recycling Cost Analysis';
			obj.Title=[tbl.Description ' [',tbl.State,'/',tbl.ColNames{end},']'];
			obj.Style=cType.GraphStyles.PLOT;
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

        function showGraph(obj)
        %showGraph - Display the recycling cost line graph in a standalone figure window
        %   Syntax:
        %     obj.showGraph
		    set(groot,'defaultTextInterpreter','none');
			f=figure('name',obj.Name,...
                'numbertitle','off',...
                'colormap',turbo,...
				'units','normalized',...
                'position',[0.1 0.1 0.45 0.6],...
                'color',[1 1 1]);
			ax=axes(f);
			plot(obj.xValues,obj.yValues,'Marker','diamond','LineWidth',1);
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			obj.setGraphParameters(ax);
        end

        function showGraphUI(obj,app)
        %showGraphUI - Display the recycling cost line graph in an App Designer graph panel
        %
        %   Syntax:
        %     obj.showGraphUI(app)
        %   Input Arguments:
        %     app - matlab.apps.AppBase object whose UIAxes hosts the graph
        %
			if app.isColorbar
				delete(app.Colorbar);
			end
			plot(obj.xValues,obj.yValues,...
				'Marker','diamond',...
				'LineWidth',1,...
				'Parent',app.UIAxes);
			setGraphParametersUI(obj,app);
			app.UIAxes.Visible='on';
		end
    end
end