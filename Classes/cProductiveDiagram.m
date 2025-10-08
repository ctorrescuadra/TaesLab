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
%     EdgesSFAT  - Productive table edges
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
        %cProductiveStructure - Construct an instance of this class
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
            % Get Process Diagram
            da=ps.ProcessDigraph;
            if ~isValid(da)
                obj.messageLog(cType.ERROR,cMessages.InvalidDigraph);
                return
            end
            obj.EdgesPAT=da.GraphEdges;
            obj.NodesPAT=da.GraphNodes;
            obj.EdgesKPAT=da.KernelEdges;
            obj.NodesKPAT=da.KernelNodes;
            % Set ResultId properties
            obj.ResultId=cType.ResultId.PRODUCTIVE_DIAGRAM;
            obj.DefaultGraph=cType.Tables.FLOW_DIAGRAM;
            obj.ModelName=ps.ModelName;
            obj.State=ps.State;
        end

        function res = getNodesTable(obj,name)
        %getNodesTable - Get the nodes  of a  diagram
        %   Syntax:
        %     res = obj.getNodeTable(name)
        %   Input Arguments:
        %     name - Name of the diagram
        %   Output Arguments:
        %     res - structure with the properties of nodes of the diagram
        %      The struct has the following fields:
        %        Name  - name of the node
        %        Group - group of the node (colouring)
        %
            res=cType.EMPTY;
            % Check input parameters
            if nargin<2 || ~ischar(name)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Select the nodes table
            switch name
                case cType.Tables.FLOW_DIAGRAM
                    res=obj.NodesFAT;
                case cType.Tables.FLOW_PROCESS_DIAGRAM
                    res=obj.NodesFPAT;
                case cType.Tables.PRODUCTIVE_DIAGRAM
                    res=obj.NodesSFPAT;
                case cType.Tables.PROCESS_DIAGRAM
                    res=obj.NodesPAT;
                case cType.Tables.KPROCESS_DIAGRAM
                    res=obj.NodesKPAT;
            end 
        end

        function res = getEdgesTable(obj,name)
        %getEdgesTable - Get the edges info of a diagram
        %   Syntax:
        %     res = obj.getEdgesTable(name)
        %   Input Parameter:
        %     name - Name of the diagram
        %   Output Parameter:
        %     res - structure of the diagram edges
        %      The struct has the following fields:
        %        source - source node of the edge
        %        target - target node of the edge
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
            fields={'source','target'};
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
    end
end