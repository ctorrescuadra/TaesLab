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
			if ~isObject(tbl,'cTableCell') || ~isObject(info,'cProductiveDiagram')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(tbl));
				return
			end
			% Get the nodes table and build the digraph
			nodes=info.getNodeTable(tbl.Name);
			obj.Name=tbl.Description;
			obj.Title=tbl.Description;
			tnodes=struct2table(nodes);
			edges=table(tbl.Data,'VariableNames',{'EndNodes'});
			obj.xValues=digraph(edges,tnodes,"omitselfloops");
			% Color by groups
			grps=obj.xValues.Nodes.Group;
			ng=max([grps;3]);
			colors=hsv(ng);
			obj.Categories=colors(grps,:);
			if strcmp(tbl.Name,cType.Tables.KPROCESS_DIAGRAM)
				obj.yValues=7;
			else
				obj.yValues=5;
			end
			% Unused properties
			obj.Legend=cType.EMPTY_CELL;
			obj.xLabel=cType.EMPTY_CHAR;
			obj.yLabel=cType.EMPTY_CHAR;
			obj.BaseLine=0.0;
        end

        function showGraph(obj)
		%showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraph
		%
 			f=figure('name',obj.Name,...
				'numbertitle','off', ...
				'units','normalized',...
				'position',[0.1 0.1 0.45 0.6],...
				'color',[1 1 1]); 
			ax=axes(f);    
			% Plot the digraph
            plot(ax,obj.xValues,'Layout','auto','NodeColor',obj.Categories,'MarkerSize',obj.yValues,'Interpreter','none');
            title(obj.Title,'fontsize',14);
        end

		function showGraphUI(obj,app)
		%showGraph - show the graph in a GUI app
        %   Syntax:
        %     obj.showGraphUI(app)
		%	Input Parameter:
		%	  app - GUI app reference object
		%
			if app.isColorbar
				delete(app.Colorbar);
			end
			% Plot the digraph
			plot(app.UIAxes,obj.xValues,'Layout','auto','NodeColor',obj.Categories,'Interpreter','none');         
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