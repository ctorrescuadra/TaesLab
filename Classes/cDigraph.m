classdef cDigraph < cGraphResults
%cDigraph - Plot the productive structure as a directed graph.
%   Builds a MATLAB digraph from a cTableCell adjacency table and either a
%   cProductiveDiagram or a cDiagramFP object that supplies node properties.
%   When the source is a cDiagramFP the edges are coloured by exergy weight
%   using a red-to-blue colormap; otherwise a plain layout is used.
%   Not available under Octave.
%
%   cDigraph Methods:
%     cDigraph    - Construct a cDigraph from an adjacency table and node info
%     showGraph   - Display the directed graph in a standalone figure window
%     showGraphUI - Display the directed graph in an App Designer graph panel
%
%   See also cGraphResults, cProductiveDiagram, cDiagramFP
%
    properties(Access=private)
        MarkerSize = cType.MARKER_SIZE;
		isDiagramFP
    end

    methods
        function obj = cDigraph(tbl,info)
        %cDigraph - Construct a directed-graph object from an adjacency table
        %   The info argument determines whether an FP-diagram layout (edge
        %   colouring by exergy weight) or a plain productive-structure layout
        %   is used.  Logs an error and returns an invalid object on Octave.
        %
        %   Syntax:
        %     obj = cDigraph(tbl, info)
        %   Input Arguments:
        %     tbl  - cTableCell containing the adjacency data (rows = sources, cols = targets)
        %     info - cProductiveDiagram or cDiagramFP supplying node group assignments
        %   Output Arguments:
        %     obj - cDigraph object (check obj.status before use)
        %
			% Check input arguments
			if isOctave
				obj.printError(cMessages.GraphNotImplemented);
				return
			end
			if ~isObject(tbl,'cTableCell')
				obj.printError(cMessages.InvalidObject,class(tbl));
				return
			end
			% Build edges table
			if isObject(info,'cDiagramFP')
				obj.isDiagramFP=true;
				obj.Title=[tbl.Description,' [',tbl.State,']'];
			elseif isObject(info,'cProductiveDiagram')
				obj.isDiagramFP=false;
				obj.Title=tbl.Description;
			else
				obj.printError(cMessages.InvalidObject,class(info));
				return
			end
			% Get the nodes table and build the digraph
			obj.Name=tbl.Description;
			obj.Style=cType.GraphStyles.DIGRAPH;
			obj.xValues=info.getDigraph(tbl.Name);
			% Color by groups
			grps=obj.xValues.Nodes.Group;
			ng=max([grps;3]);
			colors=hsv(ng);
			obj.Categories=colors(grps,:);
			% Select Node marker size
			if tbl.NodeType
				obj.MarkerSize=cType.KMARKER_SIZE;
			else
				obj.MarkerSize=cType.MARKER_SIZE;
			end
			% Unused properties
			obj.Legend=cType.EMPTY_CELL;
			obj.xLabel=cType.EMPTY_CHAR;
			obj.yLabel=cType.EMPTY_CHAR;
			obj.yValues=cType.EMPTY;
			obj.BaseLine=0.0;
        end

        function showGraph(obj)
        %showGraph - Display the directed graph in a standalone figure window
        %   Nodes are coloured by group using the HSV colormap.
        %   FP-diagram graphs add an exergy-weight colorbar with a red-to-blue colormap.
        %
        %   Syntax:
        %     obj.showGraph
		
			% Initilize figure/axes
 			f=figure('name',obj.Name,...
				'numbertitle','off', ...
				'units','normalized',...
				'position',[0.1 0.1 0.45 0.6],...
				'color',[1 1 1]); 
			ax=axes(f);    
			% Plot the digraph
            if obj.isDiagramFP
    			r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
				colormap(red2blue);
			    plot(ax,obj.xValues,"EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat","LineWidth",1.5,...
                    'NodeColor',obj.Categories,'MarkerSize',obj.MarkerSize,'Interpreter','none');
                colormap(red2blue);
			    c=colorbar(ax);
				c.Label.String=obj.xLabel;
				c.Label.FontSize=12;
            else
                plot(ax,obj.xValues,'NodeColor',obj.Categories,'MarkerSize',obj.MarkerSize,'Interpreter','none');
            end
            title(obj.Title,'fontsize',14);
        end

        function showGraphUI(obj,app)
        %showGraphUI - Display the directed graph in an App Designer graph panel
        %
        %   Syntax:
        %     obj.showGraphUI(app)
        %   Input Arguments:
        %     app - matlab.apps.AppBase object whose UIAxes hosts the graph

			% Clear previous graph
			if app.isColorbar && ~obj.DiagramFP
				delete(app.Colorbar);
			end
			app.UIAxes.YLimMode="auto";
			% Plot the digraph
			if obj.isDiagramFP
            	r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
            	app.UIAxes.Colormap=red2blue;
            	plot(app.UIAxes,obj.xValues,"EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat","LineWidth",1.5,...
                	'NodeColor',obj.Categories,'MarkerSize',obj.MarkerSize);
            	app.Colorbar=colorbar(app.UIAxes);
            	app.Colorbar.Label.String=['Exergy ', obj.Unit];
			else
				plot(app.UIAxes,obj.xValues,'Layout','auto','NodeColor',obj.Categories,'MarkerSize',obj.MarkerSize,'Interpreter','none');
			end      
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