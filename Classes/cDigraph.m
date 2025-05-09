classdef cDigraph < cGraphResults
%cDigraph - Plot Productive Structure Digraphs
%
%   cDigraph Constructor
%     obj=cDigraph(tbl,info)
%
%   cDigraph Methods
%     showGraph   - show the graph in a window 
%     showGraphUI - show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults
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
			nodes=info.getNodeTable(tbl.Name);
			obj.Name=tbl.Description;
			obj.Title=tbl.Description;
			tnodes=struct2table(nodes);
			edges=table(tbl.Data,'VariableNames',{'EndNodes'});
			obj.xValues=digraph(edges,tnodes,"omitselfloops");
            obj.Legend=cType.EMPTY_CELL;
			obj.yValues=cType.EMPTY;
			obj.xLabel=cType.EMPTY_CHAR;
			obj.yLabel=cType.EMPTY_CHAR;
			obj.BaseLine=0.0;
            obj.Categories=cType.EMPTY_CELL;
        end

        function showGraph(obj)
		%showGraph - show the graph in a window
        %   Syntax:
        %     obj.showGraph
		%
 			f=figure('name',obj.Name,'visible','off','numbertitle','off', ...
				     'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]); 
			ax=axes(f);    
			% Plot the digraph
            colors=eye(3);
            nodetable=obj.xValues.Nodes;
            nodecolors=colors(nodetable.Type,:);
            nodenames=nodetable.Name;
            plot(ax,obj.xValues,'Layout','auto','NodeLabel',nodenames,'NodeColor',nodecolors,'Interpreter','none');
            title(obj.Title,'fontsize',14,"Interpreter","none");
			set(f,'visible','on');
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
			colors=eye(3);
			nodetable=obj.xValues.Nodes;
			nodecolors=colors(nodetable.Type,:);
			nodenames=nodetable.Name;
			plot(app.UIAxes,obj.xValues,'Layout','auto','NodeLabel',nodenames,'NodeColor',nodecolors,'Interpreter','none');         
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