classdef cDigraph < cGraphResults
%cDigraph - Plot the productive structure digraphs.
%
%   cDigraph Constructor
%     obj=cDigraph(tbl,info)
%
%   cDigraph Methods
%     showGraph   - show the graph in a window 
%     showGraphUI - show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults
%
    properties(Access=private)
        MarkerSize = cType.MARKER_SIZE;
		isDiagramFP
    end

    methods
        function obj = cDigraph(tbl,info)
		%cDigraph - Build an instance of the object
        %   Syntax:
        %     obj = cDigraph(tbl,info)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cProductiveDiagram object with additional info
        %
			if isOctave
				obj.messageLog(cType.ERROR,cMessages.GraphNotImplemented);
				return
			end
			if ~isObject(tbl,'cTableCell')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(tbl));
				return
			end
			if isObject(info,'cDiagramFP')
				obj.isDiagramFP=true;
                edges=table(tbl.Data(:,1:2),cell2mat(tbl.Data(:,3)),'VariableNames',{'EndNodes','Weight'});
			elseif isObject(info,'cProductiveDiagram')
				obj.isDiagramFP=false;
                edges=table(tbl.Data(:,1:2),'VariableNames',{'EndNodes'});
			else
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(info));
				return
			end
			% Get the nodes table and build the digraph
			nodes=info.getNodesTable(tbl.Name);
			obj.Name=tbl.Description;
			obj.Title=tbl.Description;
			tnodes=struct2table(nodes);
			obj.xValues=digraph(edges,tnodes,'omitselfloops');
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
		%showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraph()
		%
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
		%showGraph - show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Parameter:
		%	  app - GUI app reference object
		%
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