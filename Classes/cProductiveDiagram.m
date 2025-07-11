classdef (Sealed) cProductiveDiagram < cResultId
%cProductiveDiagram - Build the productive diagrams adjacency tables
%   Flows Diagram (FAT)
%   Process Diagram (PAT)
%   Flow-Process Diagram (FPAT)
%   Productive Diagram (SFPAT)
%   
%   cProductiveDiagram Constructor
%     obj = cProductiveDiagram(ps)
%
%   cProductiveDiagram Properties
%     NodesFAT   - Flow nodes table
%     EdgesFAT   - Flow edges table
%     NodesPAT   - Process nodes table
%     EdgesPAT   - Process nodes table
%     NodesFPAT  - Flow-Process nodes table
%     EdgesFPAT  - Flow-Process edges table
%     NodesSFPAT - Productive table nodes
%     EdgesSFAT  - Productive table edges
%   cProductiveDiagram Methods
%     buildResultInfo - Build the cResultInfo for Productive Diagrams
%     getNodeTable    - Get the nodes of the diagram
%     getEdgeTable    - Get the edges of the diagram
%
%   See also cResultId, cProductiveStructure
%
    properties(Access=private)
        EdgesFAT          % Flow edges table
        EdgesFPAT         % Flow-Process edges table
        EdgesPAT          % Process edges table
        EdgesSFPAT        % Productive (SFP) edges table
        NodesFAT          % Flow nodes table
        NodesFPAT         % Flow-Process nodes table
        NodesPAT          % Process nodes table
        NodesSFPAT        % Productive (SFP) table
    end

    methods
        function obj = cProductiveDiagram(ps)
        %cProductiveStructure - Construct an instance of this class
        %   Syntax:
        %     obj = cProductiveDiagram(ps)
        %   Input Argument:
        %     ps - cProductiveStructure object
        %
            if ~isObject(ps,'cProductiveStructure')
				obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(ps));
                return
            end
            % Get Flows (FAT) info  
            nodenames=[ps.FlowKeys];
            flowMatrix=ps.StructuralMatrix;
            nodetypes=repmat({cType.NodeType.FLOW},1,ps.NrOfFlows);
            obj.NodesFAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFAT=cProductiveDiagram.edgesTable(flowMatrix,nodenames);
            % Get Flow-Process node names
            nodenames=[ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            flowProcessMatrix=ps.FlowProcessMatrix;
            nodetypes=[repmat({cType.NodeType.FLOW},1,ps.NrOfFlows),...
                   repmat({cType.NodeType.PROCESS},1,ps.NrOfProcesses)];
            obj.NodesFPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesFPAT=cProductiveDiagram.edgesTable(flowProcessMatrix,nodenames);
            % Get Productive (PST) node names
            nodenames=[ps.StreamKeys,ps.FlowKeys,ps.ProcessKeys(1:end-1)];
            productiveMatrix=ps.ProductiveMatrix;
            nodetypes=[repmat({cType.NodeType.STREAM},1,ps.NrOfStreams),...
                   repmat({cType.NodeType.FLOW},1,ps.NrOfFlows),...
                   repmat({cType.NodeType.PROCESS},1,ps.NrOfProcesses)];
            obj.NodesSFPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            obj.EdgesSFPAT=cProductiveDiagram.edgesTable(productiveMatrix,nodenames);
            % Get Process Diagram (FP Table)
            inodes=[ps.ProcessKeys(1:end-1)];
            processMatrix=ps.ProcessMatrix;
            [obj.EdgesPAT,nodenames]=cProductiveDiagram.edgesTableFP(processMatrix,inodes);
            nodetypes=[repmat({cType.NodeType.PROCESS},1,length(nodenames))];
            obj.NodesPAT=cProductiveDiagram.nodesTable(nodenames,nodetypes);
            % Set ResultId properties
            obj.ResultId=cType.ResultId.PRODUCTIVE_DIAGRAM;
            obj.DefaultGraph=cType.Tables.FLOW_DIAGRAM;
            obj.ModelName=ps.ModelName;
            obj.State=ps.State;
        end

        function res = getNodeTable(obj,name)
        %getNodeTable - Get the nodes table of a productive diagram
        %   Syntax:
        %     res = obj.getNodeTable(name)
        %   Input Parameter:
        %     name - Name of the diagram
        %   Output Parameter:
        %     res - Nodes table of the diagram
        %
            switch name
                case cType.Tables.FLOW_DIAGRAM
                    res=obj.NodesFAT;
                case cType.Tables.FLOW_PROCESS_DIAGRAM
                    res=obj.NodesFPAT;
                case cType.Tables.PRODUCTIVE_DIAGRAM
                    res=obj.NodesSFPAT;
                case cType.Tables.PROCESS_DIAGRAM
                    res=obj.NodesPAT;
            end 
        end

        function res = getEdgeTable(obj,name)
        %getEdgeTable - Get the edges table of a productive diagram
        %   Syntax:
        %     res = obj.getEdgeTable(name)
        %   Input Parameter:
        %     name - Name of the diagram
        %   Output Parameter:
        %     res - Edges table of the diagram
        %
            switch name
                case cType.Tables.FLOW_DIAGRAM
                    res=obj.EdgesFAT;
                case cType.Tables.PROCESS_DIAGRAM
                    res=obj.EdgesPAT;
                case cType.Tables.FLOW_PROCESS_DIAGRAM
                    res=obj.EdgesFPAT;
                case cType.Tables.PRODUCTIVE_DIAGRAM
                    res=obj.EdgesSFPAT;
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
        % Get the edges table of a matrix
            fields={'source','target'};
            [idx,jdx,~]=find(A);
            source=nodes(idx);
            target=nodes(jdx);
            tmp=[source', target'];
            res=cell2struct(tmp,fields,2);
        end

        function [edges,nodes]=edgesTableFP(A,inodes)
        % Get the edges tables of a matrix including environment
            fields={'source','target'};
            % Build Internal Edges
            [idx,jdx,~]=find(A(1:end-1,1:end-1));
            isource=inodes(idx);
            itarget=inodes(jdx);
            % Build Resources Edges
            [~,jdx]=find(A(end,1:end-1));
            vsource=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            vtarget=inodes(jdx);
            % Build Output Edges
            [idx,~]=find(A(1:end-1,end));
            wtarget=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            wsource=inodes(idx);
            % Build nodes
            nodes=[vsource,inodes,wtarget];
            % Build Edges
            source=[vsource,isource,wsource];
            target=[vtarget,itarget,wtarget];
            tmp=[source', target'];
            edges=cell2struct(tmp,fields,2);           
        end

        function res=nodesTable(nodenames,nodetypes)
            fields={'Name','Type'};
            res=cell2struct([nodenames;nodetypes],fields,1);
        end
    end
end