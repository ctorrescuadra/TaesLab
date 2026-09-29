classdef (Sealed) cProductiveDiagram < cResultId
%cProductiveDiagram - Build adjacency tables for productive structure diagrams
%   Constructs the nodes and edges structures required for graph
%   visualisation from a cProductiveStructure object. Five diagram types
%   are produced:
%
%     FAT   - Flow Adjacency Table: flow-to-flow connections
%     PAT   - Process Adjacency Table: process-to-process connections
%     FPAT  - Flow-Process Adjacency Table: combined flow and process nodes
%     SFPAT - Stream-Flow-Process Adjacency Table (Productive Diagram)
%     KPAT  - Kernel Process Adjacency Table: condensed process graph
%
%   Each diagram type is stored as a pair of struct arrays (Nodes, Edges)
%   that can be retrieved individually or as a MATLAB digraph object.
%
%   cProductiveDiagram public properties:
%     NodesFAT   - Flow diagram nodes table
%     EdgesFAT   - Flow diagram edges table
%     NodesPAT   - Process diagram nodes table
%     EdgesPAT   - Process diagram edges table
%     NodesFPAT  - Flow-Process diagram nodes table
%     EdgesFPAT  - Flow-Process diagram edges table
%     NodesSFPAT - Productive diagram (stream-flow-process) nodes table
%     EdgesSFPAT - Productive diagram (stream-flow-process) edges table
%     NodesKPAT  - Kernel process diagram nodes table
%     EdgesKPAT  - Kernel process diagram edges table
%
%   cProductiveDiagram public methods:
%     cProductiveDiagram - Construct an instance of the class from a cProductiveStructure
%     getEdgesTable      - Return the edges struct for one supported diagram type
%     getDigraph         - Build the MATLAB digraph object for one supported diagram type
%     buildResultInfo    - Build the cResultInfo object for productive diagrams
%
%   See also cResultId, cProductiveStructure, cDigraphAnalysis, cResultInfo
%
    properties(Access=public)
        EdgesFAT          % Flow edges table
        EdgesFPAT         % Flow-Process edges table
        EdgesSFPAT        % Productive (SFP) edges table
        EdgesPAT          % Process edges table
        EdgesKPAT         % Kernel Process edges table
        NodesFAT          % Flow nodes table
        NodesFPAT         % Flow-Process nodes table
        NodesSFPAT        % Productive (SFP) table
        NodesPAT          % Process nodes table
        NodesKPAT         % Kernel Process nodes table
    end

    properties(Access=private)
        productiveTable   % Productive Table structure
    end

    methods
        function obj = cProductiveDiagram(ps)
        %cProductiveDiagram - Construct an instance of this class
        %   Builds all five diagram types (FAT, PAT, FPAT, SFPAT, KPAT) from
        %   the productive structure. The object is invalid if ps is not a
        %   valid cProductiveStructure or if the process digraph cannot be
        %   constructed.
        %
        %   Syntax:
        %     obj = cProductiveDiagram(ps)
        %
        %   Input Arguments:
        %     ps  - cProductiveStructure object with a valid productive
        %           structure (flows, processes, streams)
        %
        %   Output Arguments:
        %     obj - cProductiveDiagram object; check isValid(obj) before use
        
            % Check input parameters
            if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
            end
            % Get Flows (FAT) info  
            nodenames=[ps.FlowKeys];
            obj.productiveTable=ps.ProductiveTable;
            flowMatrix=obj.getFlowMatrix;
            nodetypes=repmat({cType.NodeType.FLOW},1,ps.NrOfFlows);
            obj.NodesFAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFAT=cProductiveDiagram.edgesTable(flowMatrix,nodenames);
            % Get Flow-Process node names
            nodenames=[ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            flowProcessMatrix=obj.getFlowProcessMatrix;
            nodetypes=[repmat({cType.NodeType.FLOW},1,ps.NrOfFlows),...
                   repmat({cType.NodeType.PROCESS},1,ps.NrOfProcesses)];
            obj.NodesFPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFPAT=cProductiveDiagram.edgesTable(flowProcessMatrix,nodenames);
            % Get Productive (PST) node names
            nodenames=[ps.StreamKeys,ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            productiveMatrix=obj.getProductiveMatrix;
            nodetypes=[repmat({cType.NodeType.STREAM},1,ps.NrOfStreams),...
                   repmat({cType.NodeType.FLOW},1,ps.NrOfFlows),...
                   repmat({cType.NodeType.PROCESS},1,ps.NrOfProcesses)];
            obj.NodesSFPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesSFPAT=cProductiveDiagram.edgesTable(productiveMatrix,nodenames);
            % Get Process Diagram (FP Table)
            tfp=ps.ProcessMatrix;
			nodes=ps.ProcessKeys;
			da=cDigraphAnalysis(tfp,nodes);
            if ~isValid(da)
                obj.messageLog(cType.ERROR,cMessages.InvalidDigraph);
                return
            end
            obj.EdgesPAT=da.getEdgesTable(cType.Digraph.GRAPH);
            obj.NodesPAT=da.getNodesTable(cType.Digraph.GRAPH);
            obj.EdgesKPAT=da.getEdgesTable(cType.Digraph.KERNEL);
            obj.NodesKPAT=da.getNodesTable(cType.Digraph.KERNEL);
            % Set ResultId properties
            obj.ResultId=cType.ResultId.PRODUCTIVE_DIAGRAM;
            obj.DefaultGraph=cType.Tables.FLOW_DIAGRAM;
            obj.ModelName=ps.ModelName;
            obj.State=ps.State;
        end

        function res = getEdgesTable(obj,name)
        %getEdgesTable - Get the edges struct for a specified diagram type
        %   Returns the edges struct array for one of the five supported
        %   diagram types. Used internally to build graph tables and plots.
        %
        %   Syntax:
        %     res = obj.getEdgesTable(name)
        %
        %   Input Arguments:
        %     name - (char) Diagram identifier; use a cType.Tables constant:
        %            FLOW_DIAGRAM, FLOW_PROCESS_DIAGRAM, PRODUCTIVE_DIAGRAM,
        %            PROCESS_DIAGRAM, or KPROCESS_DIAGRAM
        %
        %   Output Arguments:
        %     res  - (1×M struct array) Edge definitions with fields:
        %              Source - name of the source node (char)
        %              Target - name of the target node (char)
        %            Returns cType.EMPTY if name is invalid or not recognised.
        %
        %   See also getDigraph
        %
            res=cType.EMPTY;
            % Check input parameters
            if nargin<2 || ~ischar(name)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Select the edges table
            switch name
                case cType.Tables.FLOW_DIAGRAM
                    res=obj.EdgesFAT;
                case cType.Tables.FLOW_PROCESS_DIAGRAM
                    res=obj.EdgesFPAT;
                case cType.Tables.PRODUCTIVE_DIAGRAM
                    res=obj.EdgesSFPAT;
                case cType.Tables.PROCESS_DIAGRAM
                    res=obj.EdgesPAT;
                case cType.Tables.KPROCESS_DIAGRAM
                    res=obj.EdgesKPAT;
            end
        end 

        function res = getDigraph(obj,name)
        %getDigraph - Get the MATLAB digraph object for a specified diagram type
        %   Combines the nodes and edges of the requested diagram into a
        %   MATLAB digraph object suitable for plotting. Self-loops are
        %   omitted automatically. Returns cType.EMPTY when called from
        %   Octave or when name is not recognised.
        %
        %   Note: This method requires MATLAB. It returns cType.EMPTY when
        %   running under Octave.
        %
        %   Syntax:
        %     res = obj.getDigraph(name)
        %
        %   Input Arguments:
        %     name - (char) Diagram identifier; use a cType.Tables constant:
        %            FLOW_DIAGRAM, FLOW_PROCESS_DIAGRAM, PRODUCTIVE_DIAGRAM,
        %            PROCESS_DIAGRAM, or KPROCESS_DIAGRAM
        %
        %   Output Arguments:
        %     res  - (digraph) MATLAB digraph object with node Name/Group
        %            properties and directed edges; or cType.EMPTY if not
        %            available
        %
        %   See also getEdgesTable, digraph
        %
            res=cType.EMPTY;
            % Check if Matlab is running
            if ~isMatlab
                return
            end
            % Check input parameters
            if nargin<2 || ~ischar(name)
                return
            end
            % Build the digraph object depending of the diagram
            switch name
                case cType.Tables.FLOW_DIAGRAM
                    res=cProductiveDiagram.buildDigraph(obj.NodesFAT,obj.EdgesFAT);
                case cType.Tables.FLOW_PROCESS_DIAGRAM
                    res=cProductiveDiagram.buildDigraph(obj.NodesFPAT,obj.EdgesFPAT);
                case cType.Tables.PRODUCTIVE_DIAGRAM
                    res=cProductiveDiagram.buildDigraph(obj.NodesSFPAT,obj.EdgesSFPAT);
                case cType.Tables.PROCESS_DIAGRAM
                    res=cProductiveDiagram.buildDigraph(obj.NodesPAT,obj.EdgesPAT);
                case cType.Tables.KPROCESS_DIAGRAM
                    res=cProductiveDiagram.buildDigraph(obj.NodesKPAT,obj.EdgesKPAT);
            end
        end

        function res = buildResultInfo(obj,fmt)
        %buildResultInfo - Build the cResultInfo object for productive diagrams
        %   Delegates construction of the result container to the provided
        %   cResultTableBuilder, which assembles the diagram tables according
        %   to the active format configuration.
        %
        %   Syntax:
        %     res = obj.buildResultInfo(fmt)
        %
        %   Input Arguments:
        %     fmt - cResultTableBuilder object that defines the output format
        %
        %   Output Arguments:
        %     res - cResultInfo object containing the productive diagram tables
        %
        %   See also cResultTableBuilder, cResultInfo
        %
            res=fmt.getProductiveDiagram(obj);
        end
    end

    methods(Access=private)
        function [res,src,out]=getFlowMatrix(obj)
		%getFlowMatrix - Get the Structural Theory flow adjacency matrix
		%   Returns the flow-to-flow adjacency matrix of the productive structure
		%   as defined by Structural Theory of Energy Systems. Optionally returns
		%   the resource row vector and the output column vector for the
		%   environment process.
		%
		%   Syntax:
		%     res           = obj.getFlowMatrix
		%     [res,src,out] = obj.getFlowMatrix
		%
		%   Output Arguments:
		%     res - (NrOfFlows x NrOfFlows logical sparse) Flow adjacency matrix
		%     src - (1 x NrOfFlows logical sparse) Resource row (ENV inputs)
		%     out - (NrOfFlows x 1 logical sparse) Output column (ENV outputs)
		%
		%   See also getStreamMatrix, getProcessMatrix, getProductiveMatrix
		%
            x=obj.productiveTable;
			xAP=x.AP*x.AS; xAF=x.AE*x.AF;
			res=x.AE*x.AS+xAF(:,1:end-1)*xAP(1:end-1,:);
			if nargout>1
				src=xAP(end,:);
				out=xAF(:,end);
			end
        end

        function res=getProductiveMatrix(obj)
		%getProductiveMatrix - Get the combined productive adjacency matrix
		%   Returns the block adjacency matrix combining streams, flows, and
		%   processes in a single square matrix. Used to build the SFPAT
		%   productive diagram.
		%
		%   Syntax:
		%     res = obj.getProductiveMatrix
		%
		%   Output Arguments:
		%     res - ((NS+M+N) x (NS+M+N) logical sparse) Productive adjacency
		%           matrix, where NS = NrOfStreams, M = NrOfFlows, N = NrOfProcesses
		%
		%   See also getStreamMatrix, getFlowMatrix, getFlowProcessMatrix
		%
			x=obj.productiveTable;
			N=size(x.AP,1)-1;
			M=size(x.AE,1);
			NS=size(x.AS,1);
			res=[zeros(NS,NS), x.AS, x.AF(:,1:end-1);...
			     x.AE, zeros(M,M), zeros(M,N);...
				 x.AP(1:end-1,:), zeros(N,M), zeros(N,N)];
		end

		function res = getFlowProcessMatrix(obj)
		%getFlowProcessMatrix - Get the flow-process adjacency matrix
		%   Returns the block adjacency matrix combining flows and processes in a
		%   single square matrix. Used to build the FPAT flow-process diagram.
		%
		%   Syntax:
		%     res = obj.getFlowProcessMatrix
		%
		%   Output Arguments:
		%     res - ((M+N) x (M+N) logical sparse) Flow-process adjacency matrix,
		%           where M = NrOfStreams, N = NrOfProcesses
		%
		%   See also getFlowMatrix, getProductiveMatrix
		%
			x=obj.productiveTable;
			N=size(x.AP,1)-1;
			res=[x.AE*x.AS,x.AE*x.AF(:,1:end-1);...
				x.AP(1:end-1,:)*x.AS,zeros(N,N)];
        end
    end

    methods(Static,Access=private)
        function res=edgesTable(A,nodes)
        %edgesTable - Build an edges struct array from an adjacency matrix
        %
        %   Syntax:
        %     res = cProductiveDiagram.edgesTable(A, nodes)
        %
        %   Input Arguments:
        %     A     - (N×N numeric) Adjacency matrix; non-zero entry (i,j)
        %             represents a directed edge from node i to node j
        %     nodes - (1×N cell array of char) Node name for each row/column
        %
        %   Output Arguments:
        %     res   - (1×M struct array) Edge definitions with fields:
        %               Source - name of the source node (char)
        %               Target - name of the target node (char)
        %
            fields={'Source','Target'};
            [idx,jdx,~]=find(A);
            source=nodes(idx);
            target=nodes(jdx);
            tmp=[source;target];
            res=cell2struct(tmp,fields,1);
        end

        function res=nodesTable(nodenames,nodetypes)
        %nodesTable - Build a nodes struct array from name and type lists
        %
        %   Syntax:
        %     res = cProductiveDiagram.nodesTable(nodenames, nodetypes)
        %
        %   Input Arguments:
        %     nodenames - (1×N cell array of char) Name of each node
        %     nodetypes - (1×N cell array of char) Type/group of each node,
        %                 used for colour grouping (see cType.NodeType)
        %
        %   Output Arguments:
        %     res       - (1×N struct array) Node definitions with fields:
        %                   Name  - node name (char)
        %                   Group - node type used for visual grouping (char)
        %
            fields={'Name','Group'};
            res=cell2struct([nodenames;nodetypes],fields,1);
        end

        function res=buildDigraph(nodes,edges)
        %buildDigraph - Assemble a MATLAB digraph from nodes and edges structs
        %
        %   Syntax:
        %     res = cProductiveDiagram.buildDigraph(nodes, edges)
        %
        %   Input Arguments:
        %     nodes - (1×N struct array) Node definitions with Name and Group
        %             fields, as returned by nodesTable
        %     edges - (1×M struct array) Edge definitions with Source and
        %             Target fields, as returned by edgesTable
        %
        %   Output Arguments:
        %     res   - (digraph) MATLAB digraph with node properties table;
        %             self-loops are omitted
        %
        %   See also digraph
        %
            tnodes=struct2table(nodes);
            EndNodes=[{edges.Source};{edges.Target}]';
            tedges=table(EndNodes);
            res=digraph(tedges,tnodes,"omitselfloops");
        end
    end
end