classdef (Sealed) cDiagramFP < cResultId
%cDiagramFP - Build the Diagram FP adjacency tables.
%
%   cDiagramFP constructor:
%     obj = cDiagramFP(exc)
%
%   cDiagramFP properties
%     EdgesFP  - Edges struct of the exergy adjacency table FP
%     EdgesCFP - Edges struct of the exergy cost adjacency table FP
%     EdgesKFP - Edges struct of the exergy kernel table FP
%     EdgesKCFP- Edges struct of the exergy cost kernel table FP
%     NodesFP  - Nodes struct Table FP
%     NodesKFP - Nodes struct Kernel Table FP
%     GroupsTable - Group table struct
%
%   cDiagramFP methods:
%     buildResultInfo - Build the cResultInfo object of the diagram FP
%     getNodeInfo     - get the adjacency table
%
%   See also cExergyCost, cResultId
%
    properties (GetAccess=public,SetAccess=private)
        EdgesFP      % Edges struct of the exergy FP adjacency table
        EdgesCFP     % Edges struct of the exergy cost FP adjacency table
        EdgesKFP     % Edges struct of the exergy FP kernel table
        EdgesKCFP    % Edges struct of the exergy cost FP kernel table
        NodesFP      % Nodes struct Table FP
        NodesKFP     % Nodes struct Kernel Table FP
        GroupsTable  % Group table struct
    end

    properties (Access=private)
        tfpda
        cfpda
    end

    methods
        function obj = cDiagramFP(exc)
        %cDiagramFP - Construct an instance of this class
        %   Syntax:
        %     obj = cDiagramFP(mfp)
        %   Input Argument:
        %     exc - cExergyCost object
        %
            if ~isObject(exc,'cExergyCost')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exc));
                return
            end
            % Create the graph edges of the TableFP
            da = cDigraphAnalysis(exc.TableFP,exc.ps.ProcessKeys);
            obj.EdgesFP=da.GraphEdges;
            obj.EdgesKFP=da.KernelEdges;
            obj.tfpda=da;
            % Create the graph edges of the Cost Table FP
            da = cDigraphAnalysis(exc.getCostTableFP,exc.ps.ProcessKeys);
            obj.EdgesCFP=da.GraphEdges;
            obj.EdgesKCFP=da.KernelEdges;
            obj.cfpda=da;
            % Create the graph nodes properties and group tables
            obj.NodesFP=da.GraphNodes;
            obj.NodesKFP=da.KernelNodes;
            obj.GroupsTable=da.getGroupsTable;
            % cResultId properties
            obj.ResultId=cType.ResultId.DIAGRAM_FP;
            obj.DefaultGraph=cType.Tables.DIAGRAM_FP;
            obj.ModelName=exc.ModelName;
            obj.State=exc.State;
        end

        function res=buildResultInfo(obj,fmt)
        %buildResultInfo - Get cResultInfo object of the DiagramFP
        %   Syntax:
        %     res = obj.buildResultInfo(fmt)
        %   Input Argument:
        %     fmt - cFormatData object
        %   Output Argument:
        %     res - cResultInfo object
            res=fmt.getDiagramFP(obj);
        end

        function res=getNodeInfo(obj,gtype)
        %getNodeInfo - Get the node tables depending of the graph type
        %   Syntax:
        %     res = obj.getNodeInfo(gtype)
        %   Input Argument:
        %     gtype - boolean, true for kernel graph, false for full graph
        %   Output Argument:
        %     res - struct array with the node information
            if gtype
                res=obj.NodesKFP;
            else
                res=obj.NodesFP;
            end
        end

        function res=getDigraphAnalysis(obj,tableName)
            res=cMessageLogger();
            switch tableName
                case cType.Tables.TABLE_FP
                    res=obj.tfpda;
                case cType.Tables.COST_TABLE_FP
                    res=obj.cfpda;
                otherwise
                    res.messageLog(cType.ERROR,cMessages.TableNotAvailable,tableName)
            end
        end
    end
end