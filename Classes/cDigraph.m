classdef cDigraph < cBuildGraph
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    methods
        function obj = cDigraph(tbl,nodes)
			if isOctave
				obj.messageLog(cType.ERROR,cMessages.GraphNotImplemented);
				return
			end
			if (nargin<2) || ~isstruct(nodes)
				obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
				return
			end
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
 			f=figure('name',obj.Name, 'numbertitle','off', ...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]); 
			ax=axes(f);    
			% Plot the digraph
            colors=eye(3);
            nodetable=obj.xValues.Nodes;
            nodecolors=colors(nodetable.Type,:);
            nodenames=nodetable.Name;
            plot(ax,obj.xValues,"Layout","auto","NodeLabel",nodenames,"NodeColor",nodecolors,"Interpreter","none");
            title(obj.Title,'fontsize',14,"Interpreter","none");
        end
    end
end