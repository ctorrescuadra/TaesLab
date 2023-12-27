classdef cProductiveDiagram < cResultId
% cProductiveDiagram build the productive diagram info
    properties(GetAccess=public,SetAccess=private)
        FlowMatrix          % Flow adjacency matrix
        FlowProcessMatrix   % Flow-Process adjacency matrix
        ProductiveMatrix    % Productive adjacency matrix
        FlowNodes           % Flow nodes properties
        FlowProcessNodes    % Flow-Process nodes properties
        ProductiveNodes     % Productive nodes properties
    end

    methods
        function obj = cProductiveDiagram(ps)
        % Construct an instance of this class
        %  Input:
        %   ps - cProductiveStructure
        %
            % Get Adjacency Matrix
            obj=obj@cResultId(cType.ResultId.PRODUCTIVE_DIAGRAM);
            obj.FlowMatrix=ps.StructuralMatrix;
            obj.FlowProcessMatrix=ps.FlowProcessMatrix;
            obj.ProductiveMatrix=ps.ProductiveMatrix;
            % Get Flows node names   
            nodenames=[ps.FlowKeys];
            nodetypes=repmat(cType.NodeType.FLOW,1,ps.NrOfFlows);
            obj.FlowNodes=table(nodenames',nodetypes','VariableNames',{'Name','Type'}); 
            % Get Flow-Process node names
            nodenames=[ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            nodetypes=[repmat(cType.NodeType.FLOW,1,ps.NrOfFlows),...
                   repmat(cType.NodeType.PROCESS,1,ps.NrOfProcesses)];
            obj.FlowProcessNodes=table(nodenames',nodetypes','VariableNames',{'Name','Type'}); 
            % Get Productive (PST) node names
            nodenames=[ps.StreamKeys,ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            nodetypes=[repmat(cType.NodeType.STREAM,1,ps.NrOfStreams),...
                   repmat(cType.NodeType.FLOW,1,ps.NrOfFlows),...
                   repmat(cType.NodeType.PROCESS,1,ps.NrOfProcesses)];
            obj.ProductiveNodes=table(nodenames',nodetypes','VariableNames',{'Name','Type'});
            obj.status=cType.VALID;
        end

        function res = getNodeTable(obj,tbl)
        % Get the nodes info of a table
            switch tbl
                case cType.Tables.FLOWS_DIAGRAM
                    res=obj.FlowNodes;
                case cType.Tables.FLOW_PROCESS_DIAGRAM
                    res=obj.FlowProcessNodes;
                case cType.Tables.PRODUCTIVE_DIAGRAM
                    res=obj.ProductiveNodes;
            end 
        end

        function res = getResultInfo(obj,fmt)
        % Get cResultInfo object
            res=fmt.getProductiveDiagram(obj);
        end


    end
end