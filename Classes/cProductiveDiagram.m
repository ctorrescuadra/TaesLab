classdef (Sealed) cProductiveDiagram < cResultId
%cProductiveDiagram - Build the productive diagrams adjacency tables
%   This class builds the adjacency tables of the productive structure of a
%   cProductiveStructure object. It creates the nodes and edges structures to be
%   used in graph plots.
%   It creates the following diagrams:
%   Flows Diagram (FAT)
%   Process Diagram (PAT)
%   Flow-Process Diagram (FPAT)
%   Productive Diagram (SFPAT)
%
%   cProductiveDiagram properties:
%     NodesFAT   - Flow nodes table
%     EdgesFAT   - Flow edges table
%     NodesPAT   - Process nodes table
%     EdgesPAT   - Process nodes table
%     NodesFPAT  - Flow-Process nodes table
%     EdgesFPAT  - Flow-Process edges table
%     NodesSFPAT - Productive table nodes
%     EdgesSFPAT - Productive table edges
%     NodesKPAT  - Kernel Process nodes table
%
%   cProductiveDiagram methods:
%     cProductiveDiagram - Create an instance of this class
%     buildResultInfo    - Build the cResultInfo for Productive Diagrams
%     getNodesTable      - Get the nodes of the diagram
%     getEdgesTable      - Get the edges of the diagram
%
%   See also cResultId, cProductiveStructure, cResultInfo
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

    methods
        function obj = cProductiveDiagram(ps)
        %cProductiveDiagram - Construct an instance of this class
        %   Syntax:
        %     obj = cProductiveDiagram(ps)
        %   Input Arguments:
        %     ps - cProductiveStructure object
        %   Output Arguments:
        %     obj - cProductiveDiagram object
        
            % Check input parameters
            if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
            end
            % Get Flows (FAT) info  
            nodenames=[ps.FlowKeys];
            flowMatrix=ps.getFlowMatrix;
            nodetypes=repmat({cType.NodeType.FLOW},1,ps.NrOfFlows);
            obj.NodesFAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFAT=cProductiveDiagram.edgesTable(flowMatrix,nodenames);
            % Get Flow-Process node names
            nodenames=[ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            flowProcessMatrix=ps.getFlowProcessMatrix;
            nodetypes=[repmat({cType.NodeType.FLOW},1,ps.NrOfFlows),...
                   repmat({cType.NodeType.PROCESS},1,ps.NrOfProcesses)];
            obj.NodesFPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFPAT=cProductiveDiagram.edgesTable(flowProcessMatrix,nodenames);
            % Get Productive (PST) node names
            nodenames=[ps.StreamKeys,ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            productiveMatrix=ps.getProductiveMatrix;
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
        %getEdgesTable - Get the edges info of a diagram
        %   Retrieve the information of the edges of a diagram, which is
        %   required to create the tables.
        %   Syntax:
        %     res = obj.getEdgesTable(name)
        %   Input Parameter:
        %     name - (array char) The identifier for the desired diagram (table)
        %            defined in cType.Tables
        %   Output Parameter:
        %     res - structure of the diagram edges
        %      The struct has the following fields:
        %        Source - source node of the edge
        %        Target - target node of the edge
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
        %getDigraph - Get the Matlab digraph object asociated to a diagram type
        %   Retrieves the properties of the nodes for a specific diagram type,
        %   which is required for graph visualization.
        %
        %   Syntax:
        %     res = obj.getNodeTable(name)
        %   Input Parameter:
        %     name - (array char) The identifier for the desired diagram (table)
        %            defined in cType.Tables
        %   Output Parameter:
        %     res - (digraph) A matlab diagraph objects with the information
        %           of nodes and edges of the diagram. Used by plotting.
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
        %buildResultInfo - Get cResultInfo object
        %   Syntax:
        %     res = obj.buildResultInfo(fmt)
        %   Input Arguments:
        %     fmt - cResultTableBuilder object
        %   Output Arguments:
        %     res - cResultInfo for ProductiveDiagram
        %
            res=fmt.getProductiveDiagram(obj);
        end
    end

    methods(Static,Access=private)
        function res=edgesTable(A,nodes)
        %edgesTable - Get the edges struct of an adjacency matrix
        %   Syntax:
        %     res=cDiagramFP.edgesTable(A,nodes);
        %   Input Arguments:
        %     A - Adjacency matrix
        %     nodes - Cell Array with the node names
        %   Output Arguments:
        %     res - Struct Array containing the edges info of the diagram
        %      The struct has the following fields
        %       source - source node of the edge
        %       target - target node of the edge
        %
            fields={'Source','Target'};
            [idx,jdx,~]=find(A);
            source=nodes(idx);
            target=nodes(jdx);
            tmp=[source;target];
            res=cell2struct(tmp,fields,1);
        end

        function res=nodesTable(nodenames,nodetypes)
        %nodesTable - Get a struct with the nodes info of a diagram
        %   Syntax:
        %     res=cDiagramFP.nodesTable(nodenames,nodetypes);
        %   Input Arguments:
        %     nodenames - Cell Array with the node names
        %     nodetypes - Cell Array with the node types
        %   Output Arguments:
        %     res - Struct Array containing the nodes info of the diagram
        %      The struct has the following fields
        %       Name  - name of the node
        %       Group - group of the node (colouring)
        %
            fields={'Name','Group'};
            res=cell2struct([nodenames;nodetypes],fields,1);
        end

        function res=buildDigraph(nodes,edges)
            tnodes=struct2table(nodes);
            EndNodes=[{edges.Source};{edges.Target}]';
            tedges=table(EndNodes);
            res=digraph(tedges,tnodes,"omitselfloops");
        end
    end

end