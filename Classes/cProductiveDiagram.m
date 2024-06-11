classdef (Sealed) cProductiveDiagram < cResultId
% cProductiveDiagram build the productive diagram info
    properties(GetAccess=public,SetAccess=private)
        EdgesFAT          % Flow adjacency matrix
        EdgesFPAT         % Flow-Process adjacency matrix
        EdgesPAT          % Productive adjacency matrix
        NodesFAT          % Flow nodes properties
        NodesFPAT         % Flow-Process nodes properties
        NodesPAT          % Productive nodes properties
    end

    methods
        function obj = cProductiveDiagram(ps)
        % Construct an instance of this class
        %  Input:
        %   ps - cProductiveStructure
        %
            obj=obj@cResultId(cType.ResultId.PRODUCTIVE_DIAGRAM);
            % Get Flows (FAT) info  
            nodenames=[ps.FlowKeys];
            flowMatrix=ps.StructuralMatrix;
            nodetypes=repmat({cType.NodeType.FLOW},1,ps.NrOfFlows);
            obj.NodesFAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFAT=cProductiveDiagram.adjacencyTable(flowMatrix,nodenames);
            % Get Flow-Process node names
            nodenames=[ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            flowProcessMatrix=ps.FlowProcessMatrix;
            nodetypes=[repmat({cType.NodeType.FLOW},1,ps.NrOfFlows),...
                   repmat({cType.NodeType.PROCESS},1,ps.NrOfProcesses)];
            obj.NodesFPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFPAT=cProductiveDiagram.adjacencyTable(flowProcessMatrix,nodenames);
            % Get Productive (PST) node names
            nodenames=[ps.StreamKeys,ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            productiveMatrix=ps.ProductiveMatrix;
            nodetypes=[repmat({cType.NodeType.STREAM},1,ps.NrOfStreams),...
                   repmat({cType.NodeType.FLOW},1,ps.NrOfFlows),...
                   repmat({cType.NodeType.PROCESS},1,ps.NrOfProcesses)];
            obj.NodesPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesPAT=cProductiveDiagram.adjacencyTable(productiveMatrix,nodenames);
            obj.DefaultGraph=cType.Tables.FLOWS_DIAGRAM;
            obj.ModelName=ps.ModelName;
            obj.State=ps.State;
        end

        function res = getNodeTable(obj,tbl)
        % Get the nodes info of a table
            switch tbl
                case cType.Tables.FLOWS_DIAGRAM
                    res=obj.NodesFAT;
                case cType.Tables.FLOW_PROCESS_DIAGRAM
                    res=obj.NodesFPAT;
                case cType.Tables.PRODUCTIVE_DIAGRAM
                    res=obj.NodesPAT;
            end 
        end

        function res = getResultInfo(obj,fmt)
        % Get cResultInfo object
            res=fmt.getProductiveDiagram(obj);
        end
    end

    methods(Static,Access=private)
        function res=adjacencyTable(A,nodes)
            [idx,jdx,~]=find(A);
            source=nodes(idx);
            target=nodes(jdx);
            res=[source', target'];
        end

        function res=nodesTable(nodenames,nodetypes)
            fields={'Name','Type'};
            res=cell2struct([nodenames;nodetypes],fields,1);
        end
    end
end