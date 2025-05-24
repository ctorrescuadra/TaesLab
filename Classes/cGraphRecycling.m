classdef cGraphRecycling < cGraphResults
%cGraphCost - Plot Waste Recycling cost
%
%   cGraphRecycling Constructor
%     obj=cGraphRecycling(tbl)
%
%   cGraphRecycling Methods
%     showGraph   - show the graph in a window 
%     showGraphUI - show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults
    methods
        function obj = cGraphRecycling(tbl)
		%cGraphRecycling - Build an instance of the object
        %   Syntax:
        %     obj = cGraphRecycling(tbl)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %
			obj.Name='Recycling Cost Analysis';
			obj.Title=[tbl.Description ' [',tbl.State,'/',tbl.ColNames{end},']'];
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
 		%showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraphUI(app)
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
        %showGraphUI - show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Parameter:
		%	  app - GUI app reference object
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