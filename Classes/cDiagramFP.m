classdef (Sealed) cDiagramFP < cResultId
%cDiagramFP - Represents the Fuel-Product (FP) diagram of a thermoeconomic model.
%   This class constructs and encapsulates the exergy and exergy cost adjacency
%   tables (FP matrices) derived from a cExergyCost object. It provides a
%   detailed representation of the productive structure, including kernel
%   tables and node/edge lists suitable for graph visualization.
%
%   The class performs a digraph analysis to identify the topological structure,
%   including cycles and connected components, which is essential for advanced
%   thermoeconomic analyses like diagnosis and waste cost allocation.
%
%   Key functionalities:
%   - Builds exergy-based (TableFP) and cost-based (TableCFP) adjacency matrices.
%   - Computes the kernel tables (TableKFP, TableKCFP) for cyclic components.
%   - Generates node and edge lists for graph visualization (EdgesFP, NodesFP).
%   - Provides information about graph components and topological ordering.
%
% cDiagramFP Properties:
%   Names       - (cell) Names of the processes in the graph.
%   kNames      - (cell) Names of the processes in the kernel graph.
%   TableFP     - (matrix) Exergy adjacency table (Fuel-Product matrix).
%   TableCFP    - (matrix) Exergy cost adjacency table.
%   TableKFP    - (matrix) Exergy kernel table for cyclic components.
%   TableKCFP   - (matrix) Exergy cost kernel table.
%   EdgesFP     - (struct) Edge list for the exergy adjacency graph.
%   EdgesCFP    - (struct) Edge list for the cost adjacency graph.
%   EdgesKFP    - (struct) Edge list for the exergy kernel graph.
%   EdgesKCFP   - (struct) Edge list for the cost kernel graph.
%   NodesFP     - (struct) Node properties for the exergy graph.
%   NodesKFP    - (struct) Node properties for the kernel graph.
%   GroupsTable - (table) Information about connected components (groups).
%   NodeWeight  - (vector) Recirculation factors for each node.
%
% cDiagramFP Methods:
%   cDiagramFP      - Constructor to create a cDiagramFP instance from a cExergyCost object.
%   buildResultInfo - Generates a cResultInfo object for standardized reporting.
%   getNodesTable   - Retrieves node properties for a specified diagram type.
%
% See also: cResultId, cExergyCost, cResultInfo, cDigraphAnalysis
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
        NodeWeight   % Node Weight
    end

    methods
        function obj = cDiagramFP(exc)
        %cDiagramFP - Build an instance of this class
        %   Syntax:
        %     obj = cDiagramFP(exc)
        %   Input Arguments:
        %     exc - cExergyCost object
        %   Output Arguments:
        %     obj - cDigramFP object
        
            % Check input parameters
            if nargin<1 || ~isObject(exc,'cExergyCost')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exc));
                return
            end
            % Create the Table FP properties
            idx=[exc.ActiveProcesses,true];
            names=exc.ps.ProcessKeys(idx);
            tfp=exc.TableFP(idx,idx);
            eda = cDigraphAnalysis(tfp,names);
            if ~eda.status
                obj.messageLog(cType.ERROR,cMessages.InvalidTableFP);
                return
            end
            obj.TableFP=eda.GraphTable;
            obj.Names=eda.GraphNodes;
            obj.TableKFP=eda.KernelTable;
            obj.kNames=eda.KernelNodes;
            obj.EdgesFP=eda.getEdgesTable(cType.Digraph.GRAPH);
            obj.EdgesKFP=eda.getEdgesTable(cType.Digraph.KERNEL);
            % Create the Cost Table FP properties
            tcfp=exc.getCostTableFP;
            tcfp=tcfp(idx,idx);
            cda = cDigraphAnalysis(tcfp,names);
            if ~cda.status
                obj.messageLog(cType.ERROR,cMessages.InvalidCostTableFP);
                return
            end
            obj.TableCFP=cda.GraphTable;
            obj.TableKCFP=cda.KernelTable;
            obj.EdgesCFP=cda.getEdgesTable(cType.Digraph.GRAPH);
            obj.EdgesKCFP=cda.getEdgesTable(cType.Digraph.KERNEL);
            % Create the graph nodes properties and group tables
            obj.NodesFP=eda.getNodesTable(cType.Digraph.GRAPH);
            obj.NodesKFP=eda.getNodesTable(cType.Digraph.KERNEL);
            obj.GroupsTable=eda.getGroupsInfo;
            % Get Node Weights
            idx=eda.TopologicalOrder;
            obj.NodeWeight=exc.RecirculationFactor(idx);
            % cResultId properties
            obj.ResultId=cType.ResultId.DIAGRAM_FP;
            obj.DefaultGraph=cType.Tables.DIGRAPH_FP;
            obj.ModelName=exc.ModelName;
            obj.State=exc.State;
        end

        function res = getDigraph(obj,name)
        %getDigraph - Get the Matlab digraph object asociated to a diagram type
        %   Retrieves the properties of the nodes for a specific diagram type,
        %   which is required for graph visualization.
        %
        %   Syntax:
        %     res = obj.getNodeTable(name)
        %   Input Parameter:
        %     name - (cType.Tables) The identifier for the desired diagram
        %            (e.g., cType.Tables.DIGRAPH_FP).
        %   Output Parameter:
        %     res - (struct) A structure containing node properties, such as
        %           'Name' and 'Group', used for coloring and labeling in graphs.
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
                case cType.Tables.DIGRAPH_FP
                    res=cDiagramFP.buildDigraph(obj.NodesFP,obj.EdgesFP);
                case cType.Tables.KDIGRAPH_FP
                    res=cDiagramFP.buildDigraph(obj.NodesKFP,obj.EdgesKFP);
                case cType.Tables.DIGRAPH_COST_FP
                    res=cDiagramFP.buildDigraph(obj.NodesFP,obj.EdgesCFP);
                case cType.Tables.KDIGRAPH_COST_FP
                    res=cDiagramFP.buildDigraph(obj.NodesKFP,obj.EdgesKCFP);
            end 
        end

        function res=buildResultInfo(obj,fmt)
        %buildResultInfo - Get cResultInfo object of the DiagramFP
        %   This method generates a standardized cResultInfo object that
        %   contains all the tables and graphs related to the FP diagram.
        %
        %   Syntax:
        %     res = obj.buildResultInfo(fmt)
        %   Input Arguments:
        %     fmt - (cFormatData) Formatting options for the results.
        %   Output Arguments:
        %     res - (cResultInfo) Object containing the formatted results.
        %
            res=fmt.getDiagramFP(obj);
        end

    end

    methods(Static,Access=private)
        function res=buildDigraph(nodes,edges)
            tnodes=struct2table(nodes);
            EndNodes=[{edges.Source};{edges.Target}]';
            Weight=[edges.Value]';
            tedges=table(EndNodes,Weight);
            res=digraph(tedges,tnodes,"omitselfloops");
        end
    end

end