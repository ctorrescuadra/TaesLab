classdef cGraphWaste < cGraphResults
%cGraphWaste - Plot the Waste Allocation Graph.
%   There is two graph methods to show the waste allocation
%   - PieChart - active waste allocation is shown in a PieChart
%   - BarGraph - all the waste flows allocation is show in a bar chart
%   If graph is launched in a app BarPlot is always use
%
%   cGraphWaste methods:
%     cGraphWaste  - Build an instance of the class
%     showGraph    - Show the graph in a window 
%     showGraphUI  - Show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults, cWasteAnalysis
%
	properties(Access=private)
		isPieChart    %Pie Chart is used
	end
    methods
        function obj = cGraphWaste(tbl,info,option)
		%cGraphWaste - Build an instance of the object
        %   Syntax:
        %     obj = cGraphWaste(tbl,info,option)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cWasteAnalysis object with additional info
		%     option - (true/false) indicate if PieChart is used or not
		%   Output Arguments:
		%     obj - cGraphWaste object
        %
			if (nargin==2)
				option=true;
			end
			wf=info.wasteFlow;
			obj.Name='Waste Allocation';
			if option
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
		%	Input Parameter:
		%	  app - GUI app reference object
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
    	% Plot the waste allocation pie chart
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
		% Plot the waste allocation bar graph
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