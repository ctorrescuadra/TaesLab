classdef cGraphDiagramFP < cGraphResults
%cGraphDiagramFP - Plot the FP Diagram.
%   This class creates a digraph object from a cTableMatrix object
%   containing the FP adjacency table of a productive structure.
%
%   cGraphDiagramFP methods:
%     cGraphDiagramFP - Build an instance of the class
%     showGraph       - Show the graph in a window 
%     showGraphUI     - Show the graph in the graph pannel of a GUI app
%
%   See also cGraphResults, cDiagramFP
%
    properties(Access=private)
        Unit         % Unit of the values
    end

    methods
        function obj=cGraphDiagramFP(tbl)
        %cGraphDiagramFP - Build an instance of the object
        %   Syntax:
        %     obj = cGraphDiagramFP(tbl,info)
        %   Input Arguments:
        %     tbl - cTable with the data to show graphically
        %     info - cExergyCost or cDiagramObject
        %   Output Arguments:
        %     obj - cGraphDiagramFP object
        %
            if isOctave
				obj.messageLog(cType.ERROR,cMessages.GraphNotImplemented);
				return
            end
            % Check input arguments
            if  isObject(tbl,'cTableMatrix')
                mFP=cell2mat(tbl.Data(1:end-1,1:end-1));
                EdgesTable=cGraphDiagramFP.edgesTable(mFP,tbl.RowNames);
                NodesTable=cGraphDiagramFP.nodesTable(mFP,tbl.RowNames);
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Build the digraph
            obj.xValues=digraph(EdgesTable,NodesTable,'omitselfloops');
            % Set other properties
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description ' [',tbl.State,']'];
            obj.Unit=tbl.Unit;
            obj.xLabel=['Exergy ' tbl.Unit];
            % Unused properties
            obj.Categories=cType.EMPTY;
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
			plot(ax,obj.xValues,"EdgeCData",obj.xValues.Edges.Weight,...
                "EdgeColor","flat","LineWidth",1.5,...
                "NodeColor","red","MarkerSize",cType.MARKER_SIZE,"Interpreter","none");
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
            plot(app.UIAxes,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,...
                "EdgeColor","flat","LineWidth",1.5,...
                "NodeColor","red","MarkerSize",cType.MARKER_SIZE,"Interpreter","none");
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

    methods(Static)
        function res=edgesTable(mFP,nodes)
        %adjacencyTable - Get a table with the edges of the digraph
        %   Syntax:
        %     res=cDiagramFP.adjacencyTables(mFP,nodes);
        %   Input Arguments:
        %     mFP - FP matrix values
        %     nodes - Cell Array with the process node names
        %   Output Arguments:
        %     res - Matlab table containing the edges of the digraph
        %      The tablet has the following fields
        %        EndNodes - source and target nodes of the edge
        %        Weight   - weight of the edge
        %
            % Build Internal Edges
            [idx,jdx,ival]=find(mFP(1:end-1,1:end-1));
            isource=nodes(idx);
            itarget=nodes(jdx);
            % Build Resources Edges
            [~,jdx,vval]=find(mFP(end,1:end-1));
            vsource=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            vtarget=nodes(jdx);
            % Build Output edges
            [idx,~,wval]=find(mFP(1:end-1,end));
            wtarget=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            wsource=nodes(idx);
            % Build the Adjacency Matrix
            source=[vsource,isource,wsource];
            target=[vtarget,itarget,wtarget];
            values=[vval';ival;wval];
            res=table([source',target'],values,'VariableNames',{'EndNodes','Weight'});
        end

        function res=nodesTable(mFP,nodes)
        %nodesTable - Get a table with the properties of the nodes
        %   Syntax:
        %     res=cDiagramFP.nodesTable(mFP,nodes);
        %   Input Arguments:
        %     mFP - FP matrix values
        %     nodes - Cell Array with the process node names
        %   Output Arguments:
        %     res - Matlab table containing the properties of the nodes
        %      The tablet has the following fields
        %        Name  - name of the node
        %        Group - group of the node (colouring)
            % Build Resource Nodes
            [~,jdx]=find(mFP(end,1:end-1));
            vnodes=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            % Build Internal Nodes
            inodes=nodes(1:end-2);
            % Build Output Nodes
            [~,jdx]=find(mFP(1:end-1,end));
            wnodes=arrayfun(@(x) sprintf('OUT%d',x),1:numel(jdx),'UniformOutput',false);
            nodes=[vnodes, inodes, wnodes];
            groups=repmat(cType.NodeType.PROCESS,1,length(nodes));
            res=table(nodes',groups','VariableNames',{'Name','Group'});
        end
    end
end