classdef cGraphDiagramFP < cGraphResults
%cGraphDiagramFP - Plot the FP Diagram.
%
%   cGraphDiagramFP Constructor
%     obj=cGraphDiagramFP(tbl,info)
%
%   cGraphDiagramFP Methods
%     showGraph   - show the graph in a window 
%     showGraphUI - show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults
%
    properties(Access=private)
        Unit         % Unit of the values
        MarkerSize   % Node Marker size
    end

    methods
        function obj=cGraphDiagramFP(tbl,info)
        %cGraphDiagramFP - Build an instance of the object
        %   Syntax:
        %     obj = cGraphDiagramFP(tbl,info)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cExergyCost or cDiagramObject
        %
            if isOctave
				obj.messageLog(cType.ERROR,cMessages.GraphNotImplemented);
				return
            end
            % Check input arguments
            if  ~isObject(tbl,'cTableMatrix') || ~isObject(info,'cExergyModel')
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            dg=info.ProcessDigraph;
            if tbl.GraphOptions
                edges=dg.KernelEdges;
                nodes=dg.KernelNodes;
                obj.MarkerSize=cType.KMARKER_SIZE;
            else
                edges=dg.GraphEdges;
                nodes=dg.GraphNodes;
                obj.MarkerSize=cType.MARKER_SIZE;            
            end
            % Build the digraph
            endNodes=[{edges.Source};{edges.Target}]';
            values=[edges.Value]';
            EdgesTable=table(endNodes,values,'VariableNames',{'EndNodes','Weight'});
            NodesTable=struct2table(nodes);
            obj.xValues=digraph(EdgesTable,NodesTable,'omitselfloops');
            % Set other properties
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description ' [',tbl.State,']'];
            obj.Unit=tbl.Unit;
            obj.xLabel=['Exergy ' tbl.Unit];
			% Color by groups
			grps=obj.xValues.Nodes.Group;
			ng=max([grps;3]);
			colors=lines(ng);
			obj.Categories=colors(grps,:);
            % Unused properties
            obj.Legend=cType.EMPTY_CELL;
			obj.yLabel=cType.EMPTY_CHAR;
			obj.BaseLine=0.0;
        end
        
        function showGraph(obj)
        %showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraph
		%
            f=figure('name',obj.Name,...
                'numbertitle','off',...
				'units','normalized',...
                'position',[0.1 0.1 0.45 0.6],...
                'color',[1 1 1]); 
			ax=axes(f);
			r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
			colormap(red2blue);
			plot(ax,obj.xValues,"EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat","LineWidth",1.5,...
            'NodeColor',obj.Categories,'MarkerSize',obj.MarkerSize,'Interpreter','none');
			c=colorbar(ax);
			c.Label.String=obj.xLabel;
			c.Label.FontSize=12;
			title(ax,obj.Title,'fontsize',14);
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
            plot(app.UIAxes,obj.xValues,"EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat","LineWidth",1.5,...
                'NodeColor',obj.Categories,'MarkerSize',obj.MarkerSize);
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