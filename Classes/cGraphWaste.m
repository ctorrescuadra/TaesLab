classdef cGraphWaste < cGraphResults
%cGraphWaste - Plot the waste allocation pie chart or horizontal bar graph.
%   Two rendering modes are available, selected by the option argument:
%     PIE - Pie chart showing the allocation fractions of the currently
%           active waste flow (slices below 1 % are hidden).
%     BAR - Horizontal stacked bar chart showing the allocation of all waste
%           flows simultaneously.
%   When displayed inside an App Designer app the BAR layout is always used.
%
%   cGraphWaste Methods:
%     cGraphWaste  - Construct a cGraphWaste from a waste allocation table
%     showGraph    - Display the graph in a standalone figure window
%     showGraphUI  - Display the horizontal bar graph in an App Designer graph panel
%
%   See also cGraphResults, cWasteAnalysis
%
	properties(Access=private)
		isPieChart = false  % True when the constructor selected pie-chart rendering
	end
    methods
        function obj = cGraphWaste(tbl,info,option)
        %cGraphWaste - Construct a cGraphWaste from a waste allocation table
        %
        %   Syntax:
        %     obj = cGraphWaste(tbl, info)
        %     obj = cGraphWaste(tbl, info, option)
        %   Input Arguments:
        %     tbl    - cTable containing the waste allocation percentage data
        %     info   - cWasteAnalysis object providing the active waste flow name
        %     option - Graph style selector (optional, default: cType.DEFAULT_GRAPHSTYLE):
        %                cType.GraphStyles.PIE → pie chart for the active waste flow
        %                any other style        → horizontal stacked bar for all waste flows
        %   Output Arguments:
        %     obj - cGraphWaste object (check obj.status before use)
        %
			% Validate input arguments
			if nargin < 2 || ~isObject(info,'cWasteAnalysis')
				obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
				return
			end
			if nargin == 2
				option=cType.DEFAULT_GRAPHSTYLE;
			end
			wf=info.wasteFlow;
			obj.Name='Waste Allocation';
			style=cType.getGraphStyle(option);
			if style==cType.GraphStyles.PIE % Use pie chart to show active waste flow
				cols=tbl.ColNames(2:end);
				idx=find(strcmp(cols,wf),1);
				if isempty(idx)
					obj.messageLog(cType.ERROR,cMessages.InvalidParameter);
					return
				end
				x=cell2mat(tbl.Data(:,idx));
				jdx=find(x>1.0);
				obj.isPieChart=true;
				obj.Title=[tbl.Description ' [',tbl.State,'/',wf,']'];
				obj.xValues=x(jdx);
				obj.Legend=tbl.RowNames(jdx);
				obj.yValues=cType.EMPTY;
				obj.xLabel=cType.EMPTY_CHAR;
				obj.yLabel=cType.EMPTY_CHAR;
				obj.BaseLine=0.0;
				obj.Categories=cType.EMPTY_CELL;
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

        function showGraph(obj)
        %showGraph - Display the waste allocation graph in a standalone figure window
        %   Renders a pie chart or a horizontal stacked bar graph depending
        %   on the style selected during construction.
        %
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
        %showGraphUI - Display the waste allocation horizontal bar graph in an App Designer graph panel
        %   Always uses the BAR layout regardless of the style passed to the constructor.
        %
        %   Syntax:
        %     obj.showGraphUI(app)
        %   Input Arguments:
        %     app - matlab.apps.AppBase object whose UIAxes hosts the graph
        %
            if app.isColorbar
                delete(app.Colorbar);
            end
            bar(obj.xValues,obj.yValues',...
                'EdgeColor','none',...
                'BarLayout','stacked',...
                'Horizontal','on',...
                'Parent',app.UIAxes);
            title(app.UIAxes,obj.Title,'FontSize',14);
            xlabel(app.UIAxes,obj.xLabel,'FontSize',12);
            ylabel(app.UIAxes,obj.yLabel,'FontSize',12);
            legend(app.UIAxes,obj.Categories,'FontSize',8);
            app.UIAxes.Legend.Location='bestoutside';
            app.UIAxes.Legend.Orientation='horizontal';
            xtick=(0:10:100);
            app.UIAxes.XTick = xtick;
            app.UIAxes.XTickLabel=arrayfun(@(x) sprintf('%3d',x),xtick,'UniformOutput',false);
            app.UIAxes.XLimMode="auto";
            app.UIAxes.XGrid = 'on';
            app.UIAxes.YGrid = 'off';
            % Show the figure after all components are created
            app.UIAxes.Visible = 'on';
		end
    end

    methods(Access=private)
        function showPieChart(obj)
        %showPieChart - Render the active waste flow allocation as a pie chart
        %   Slices with a contribution below 1 % are filtered out.
        %   Uses percentage labels on MATLAB; plain pie on Octave.
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
        
        function showBarGraph(obj)
        %showBarGraph - Render all waste flows as a horizontal stacked bar graph
        %   Each bar represents one waste flow; segments show allocation fractions.
        %
        %   Syntax:
        %     obj.showBarGraph
        %
			set(groot,'defaultTextInterpreter','none');
        	f=figure('name',obj.Name,...
				'numbertitle','off',...
				'colormap',turbo,...
				'units','normalized',...
				'position',[0.1 0.1 0.45 0.6],...
				'color',[1 1 1]);
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
    end
end