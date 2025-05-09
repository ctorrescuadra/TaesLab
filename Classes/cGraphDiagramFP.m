classdef cGraphDiagramFP < cGraphResults
%cGraphDiagramFP - Plot the FP Diagram
%
%   cGraphDiagramFP Constructor
%     obj=cDiagramFP(tbl,info)
%
%   cGraphDiagramFP Methods
%     showGraph   - show the graph in a window 
%     showGraphUI - show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults

    properties(Access=private)
        Unit
    end

    methods
        function obj=cGraphDiagramFP(tbl)
        %cGraphDiagramFP - Build an instance of the object
        %   Syntax:
        %     obj = cGraphDiagramFP(tbl,info)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %
            if isOctave
				obj.messageLog(cType.ERROR,cMessages.GraphNotImplemented);
				return
            end
            if isObject(tbl,'cTableMatrix')
                mFP=cell2mat(tbl.Data(1:end-1,1:end-1));
                val=cDiagramFP.adjacencyTable(mFP,tbl.RowNames);
                data=struct2cell(val)';
                source=data(:,1); target=data(:,2);
                values=cell2mat(data(:,3));
            else
                source=tbl.Data(:,1); target=tbl.Data(:,2);
                values=cell2mat(tbl.Data(:,3));
            end
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description ' [',tbl.State,']'];
            obj.xValues=digraph(source,target,values,'omitselfloops');
			obj.Legend=cType.EMPTY_CELL;
			obj.yValues=cType.EMPTY;
			obj.xLabel=['Exergy ' tbl.Unit];
			obj.yLabel=cType.EMPTY_CHAR;
			obj.BaseLine=0.0;
			obj.Categories=cType.EMPTY_CELL;
            obj.Unit=tbl.Unit;
        end
        
        function showGraph(obj)
        %showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraph
		%
            f=figure('name',obj.Name, 'numbertitle','off', 'visible','off',...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]); 
			ax=axes(f);
			r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
			colormap(red2blue);
			plot(ax,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat","LineWidth",1.5);
			c=colorbar(ax);
			c.Label.String=obj.xLabel;
			c.Label.FontSize=12;
			title(ax,obj.Title,'fontsize',14);
            set(f,'visible','on');
        end

        function showGraphUI(obj,app)
        %showGraph - show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Parameter:
		%	  app - matlab.apps.AppBase object referencing the app
        %
            app.UIAxes.YLimMode="auto";
            r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
            app.UIAxes.Colormap=red2blue;
            plot(app.UIAxes,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat");
            app.Colorbar=colorbar(app.UIAxes);
            app.Colorbar.Label.String=['Exergy ', obj.Unit];
            app.UIAxes.Title.String=obj.Title;
            app.UIAxes.XLabel.String=cType.EMPTY_CHAR;
            app.UIAxes.YLabel.String=cType.EMPTY_CHAR;
            app.UIAxes.XTick=cType.EMPTY;
            app.UIAxes.YTick=cType.EMPTY;
            app.UIAxes.XGrid = 'off';
            app.UIAxes.YGrid = 'off';
            legend(app.UIAxes,'off');
            app.UIAxes.Visible='on';
        end
    end
end