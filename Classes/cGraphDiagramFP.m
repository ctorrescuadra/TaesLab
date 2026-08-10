classdef cGraphDiagramFP < cGraphResults
%cGraphDiagramFP - Plot the Fuel-Product (FP) diagram as a directed graph.
%   Builds a MATLAB digraph from a cTableMatrix containing the FP adjacency
%   matrix of a productive structure.  Edge weights represent exergy flows
%   and are mapped to a red-to-blue colormap.  Not available under Octave.
%
%   cGraphDiagramFP Methods:
%     cGraphDiagramFP - Construct a cGraphDiagramFP from an FP adjacency table
%     showGraph       - Display the FP diagram in a standalone figure window
%     showGraphUI     - Display the FP diagram in an App Designer graph panel
%     edgesTable      - (Static) Build the MATLAB table of digraph edges
%     nodesTable      - (Static) Build the MATLAB table of digraph nodes
%
%   See also cGraphResults, cDiagramFP
%
    properties(Access=private)
        Unit  % Physical unit string appended to the colorbar label (e.g. 'kW')
    end

    methods
        function obj=cGraphDiagramFP(tbl,info)
        %cGraphDiagramFP - Construct a cGraphDiagramFP from an FP adjacency table
        %   Logs an error and returns an invalid object on Octave.
        %
        %   Syntax:
        %     obj = cGraphDiagramFP(tbl, info)
        %   Input Arguments:
        %     tbl  - cTableMatrix containing the FP adjacency matrix
        %     info - cResultId subclass that provides the ActiveProcesses index vector
        %            (e.g. cDiagramFP or cExergyCost)
        %   Output Arguments:
        %     obj - cGraphDiagramFP object (check obj.status before use)
        %
            if isOctave
				obj.printError(cMessages.GraphNotImplemented);
				return
            end
            obj.Style=cType.GraphStyles.DIGRAPH;
            % Check input arguments
            if  isObject(tbl,'cTableMatrix')
                idx=[info.ActiveProcesses,true];
                mFP=cell2mat(tbl.Data(idx,idx));
                EdgesTable=cGraphDiagramFP.edgesTable(mFP,tbl.RowNames(idx));
                NodesTable=cGraphDiagramFP.nodesTable(mFP,tbl.RowNames(idx));
            else
                obj.printError(cMessages.InvalidArgument);
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
        %showGraph - Display the FP diagram in a standalone figure window
        %   Edge weights are mapped to a red-to-blue colormap; a colorbar is added.
        %
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
        %showGraphUI - Display the FP diagram in an App Designer graph panel
        %   Adds a colorbar labelled with the exergy unit string.
        %
        %   Syntax:
        %     obj.showGraphUI(app)
        %   Input Arguments:
        %     app - matlab.apps.AppBase object whose UIAxes hosts the graph
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
        %edgesTable - Build the MATLAB edges table for the FP digraph
        %   Constructs source/target node pairs and exergy weights for three
        %   edge classes: resource input edges (IN*→process), internal process
        %   edges, and output edges (process→OUT*).
        %
        %   Syntax:
        %     res = cGraphDiagramFP.edgesTable(mFP, nodes)
        %   Input Arguments:
        %     mFP   - (n×n) numeric FP adjacency matrix (last row = resources, last col = outputs)
        %     nodes - Cell array of process node name strings (length n-1)
        %   Output Arguments:
        %     res - MATLAB table with columns EndNodes (Nx2 cell) and Weight (Nx1 double)
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
        %nodesTable - Build the MATLAB nodes table for the FP digraph
        %   Assembles resource input nodes (IN*), internal process nodes, and
        %   output nodes (OUT*), assigning each a Group value for colouring.
        %
        %   Syntax:
        %     res = cGraphDiagramFP.nodesTable(mFP, nodes)
        %   Input Arguments:
        %     mFP   - (n×n) numeric FP adjacency matrix
        %     nodes - Cell array of process node name strings (length n-1)
        %   Output Arguments:
        %     res - MATLAB table with columns Name (cell) and Group (numeric, see cType.NodeType)
            % Build Resource Nodes
            [~,jdx]=find(mFP(end,1:end-1));
            vnodes=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            % Build Internal Nodes
            inodes=nodes(1:end-1);
            % Build Output Nodes
            [~,jdx]=find(mFP(1:end-1,end));
            wnodes=arrayfun(@(x) sprintf('OUT%d',x),1:numel(jdx),'UniformOutput',false);
            nodes=[vnodes, inodes, wnodes];
            groups=repmat(cType.NodeType.PROCESS,1,length(nodes));
            res=table(nodes',groups','VariableNames',{'Name','Group'});
        end
    end
end