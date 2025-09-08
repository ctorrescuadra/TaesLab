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
        Names        % Process Names
        kNames       % Kernel Process Names
        EdgesFP      % Edges struct of the exergy FP adjacency table
        EdgesCFP     % Edges struct of the exergy cost FP adjacency table
        EdgesKFP     % Edges struct of the exergy FP kernel table
        EdgesKCFP    % Edges struct of the exergy cost FP kernel table
        NodesFP      % Nodes struct Table FP
        NodesKFP     % Nodes struct Kernel Table FP
        TableFP      % Table FP
        TableCFP     % Cost Table FP
        TableKFP     % Kernel Table FP
        TableKCFP    % Kernel Cost Table FP
        GroupsTable  % Graph Components table
    end

    methods
        function obj = cDiagramFP(exc)
        %cDiagramFP - Construct an instance of this class
        %   Syntax:
        %     obj = cDiagramFP(mfp)
        %   Input Argument:
        %     exc - cExergyCost object
        %   Output Argument
        %     obj - cDigramFP object
        %
            if ~isObject(exc,'cExergyCost')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exc));
                return
            end
            % Create the Table FP properties
            obj.Names=exc.ps.ProcessKeys;
            obj.TableFP=exc.TableFP;
            eda = cDigraphAnalysis(exc.TableFP,obj.Names);
            obj.EdgesFP=eda.GraphEdges;
            obj.EdgesKFP=eda.KernelEdges;
            [obj.TableKFP,obj.kNames]=getKernelInfo(eda);
            % Create the Cost Table FP properties
            obj.TableCFP=exc.getCostTableFP;
            cda = cDigraphAnalysis(obj.TableCFP,obj.Names);
            obj.EdgesCFP=cda.GraphEdges;
            obj.EdgesKCFP=cda.KernelEdges;
            obj.TableKCFP=getKernelInfo(cda);
            % Create the graph nodes properties and group tables
            obj.NodesFP=eda.GraphNodes;
            obj.NodesKFP=eda.KernelNodes;
            obj.GroupsTable=eda.getGroupsInfo;
            % cResultId properties
            obj.ResultId=cType.ResultId.DIAGRAM_FP;
            obj.DefaultGraph=cType.Tables.DIGRAPH_FP;
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

        function res = getNodesTable(obj,name)
        %getNodesTable - Get the nodes  of a  diagram
        %   Syntax:
        %     res = obj.getNodeTable(name)
        %   Input Parameter:
        %     name - Name of the diagram
        %   Output Parameter:
        %     res - structure with the properties of nodes of the diagram
        %      The struct has the following fields:
        %        Name  - name of the node
        %        Group - group of the node (colouring)
        %
            res=[];
            switch name
                case cType.Tables.DIGRAPH_FP
                    res=obj.NodesFP;
                case cType.Tables.KDIGRAPH_FP
                    res=obj.NodesKFP;
                case cType.Tables.DIGRAPH_COST_FP
                    res=obj.NodesFP;
                case cType.Tables.KDIGRAPH_COST_FP
                    res=obj.NodesKFP;
            end 
        end
    end
end