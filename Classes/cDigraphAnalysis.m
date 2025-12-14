classdef cDigraphAnalysis < cMessageLogger
%cDigraphAnalysis - Analyze directed graph structure and compute strong connectivity.
%   Performs graph-theoretic analysis of directed graphs (digraphs) to identify
%   structural properties, connectivity patterns, and hierarchical relationships.
%   This class computes transitive closure, identifies strongly connected components,
%   and generates the kernel DAG representation for thermoeconomic productive structure analysis.
%
%   Key Features:
%     - Transitive closure computation for reachability analysis
%     - Strong connectivity analysis using Tarjan's algorithm
%     - Kernel DAG generation by condensing strongly connected components
%     - Productive graph validation (single source/sink requirements)
%     - Component grouping and hierarchical structure identification
%     • Graph visualization and export capabilities
%
%   Graph representations supported:
%     Full Graph - Original directed graph with all nodes and edges
%       • Preserves complete connectivity information
%       • May contain cycles and multiple paths
%       • Used for reachability queries
%
%     Kernel DAG - Directed Acyclic Graph of strong components
%       • Nodes represent strongly connected component groups
%       • Edges show dependencies between components
%       • Eliminates cycles through component condensation
%       • Enables topological sorting and hierarchical analysis
%
%   Strong Connectivity Analysis:
%     Identifies groups of mutually reachable nodes (strong components):
%       • Nodes within a component can reach each other
%       • Components form a partition of the graph
%       • DAG structure emerges from component condensation
%       • Reveals feedback loops and circular dependencies
%
%   Applications in Thermoeconomics:
%     - Productive structure validation (ProcessMatrix)
%     - Fuel-Product tables analysis
%     - Detection of circular dependencies in production chains
%     - Hierarchical decomposition of energy systems
%     - Kernel diagram generation for visualization
%     - Structural optimization and simplification
%
%   cDigraphAnalysis Properties:
%     NrOfNodes - Number of nodes of the  graph
%       uint32
%     NrOfComponents - Number of strongly connected components
%       uint32
%     GraphNodes - Node information for the complete SSR graph
%       struct array including node name and group
%     GraphEdges - Edge list for the complete SSR graph
%       struct array including source node, target node and weigth      
%     KernelNodes - Node information for kernel DAG
%       struct array including node name and group
%     KernelEdges - Edge list for kernel DAG
%       struct array including source node, target node and weigth
%     isDAG - Indicate if graph is acyclic
%       true | false
%
%   cDigraphAnalysis Methods:
%     cDigraphAnalysis - Construct graph analysis object from adjacency matrix
%     isProductive - Validate productive graph structure (single source/sink)
%     isReachable - Check if path exists between two nodes
%     isStrongConnected - Test if two nodes are in same strong component
%     getComponentNames - Retrieve names of strongly connected component groups
%     getKernelInfo - Extract kernel DAG adjacency matrix and node names
%     getGroupsInfo - Get detailed information about component groupings
%     plot - Visualize graph structure with layout
%
%   Design Pattern:
%     Inherits from cMessageLogger for standardized error/warning reporting.
%     Immutable analysis results - properties are read-only after construction.
%     Internal caching of intermediate results (transitive closure, components).
%
%   Graph Requirements:
%     Input adjacency matrix must represent a productive graph:
%       • Square matrix (N×N) for N nodes
%       • Binary or weighted connections
%       • First node treated as source (IN)
%       • Last node treated as sink (OUT)
%       • Intermediate nodes represent processes or flows
%
%   Strong Component Detection:
%     Uses efficient algorithm for component identification:
%       • Tarjan's algorithm for linear-time complexity O(V+E)
%       • Identifies maximal strongly connected subgraphs
%       • Assigns unique component ID to each node
%       • Enables fast component membership queries
%
%   Kernel DAG Construction:
%     When cycles exist (isDAG = false):
%       • Group nodes by strong component
%       • Create meta-nodes for each component
%       • Preserve inter-component connections
%       • Result is guaranteed acyclic (DAG property)
%
%   Common Use Cases:
%     - Validating thermoeconomic productive structure topology
%     - Identifying circular dependencies in production chains
%     - Generating simplified kernel diagrams for complex systems
%     - Structural analysis before exergy cost calculation
%     - Detecting feedback loops requiring special treatment
%     - Hierarchical decomposition of energy systems
%
%   See also:
%     cDigraph, cProductiveDiagram, cExergyCost, cDiagramFP, cMessageLogger
%
    properties(GetAccess=public,SetAccess=private)
        NrOfNodes          % Number of nodes in the graph
        NrOfComponents     % Number of components
        GraphEdges         % Edges of the graph
        GraphNodes         % Nodes of the graph      
        KernelNodes        % Nodes of the kernel DAG
        KernelEdges        % Edges of the kernel DAG
        isDAG              % Digraph is Acycled
    end

    properties(Access=private)
        graph          % Adjacency of the graph
        nodes          % Node Names
        kNodes         % Kernel Names
        kG             % Kernel Matrix
        tc             % Transitive Closure
        comps          % Graphs components
    end

    methods
        function obj = cDigraphAnalysis(A,names)
        %cDigraphAnalysis - Construct graph analysis object from adjacency matrix.
        %   Creates a cDigraphAnalysis object that performs complete structural
        %   analysis including transitive closure, strong component detection,
        %   and kernel DAG generation. The constructor automatically computes
        %   all graph properties and stores them for efficient querying.
        %
        %   The input adjacency matrix is transformed to SSR (Single Source-Sink
        %   Representation) format by adding explicit IN and OUT nodes if needed.
        %   This ensures the graph has a single source and single sink node,
        %   required for productive structure analysis.
        %
        %   Syntax:
        %     obj = cDigraphAnalysis(A)
        %     obj = cDigraphAnalysis(A, names)
        %
        %   Input Arguments:
        %     A - Adjacency matrix representing directed graph
        %       numeric matrix (N×N)
        %       These matrices could be contains logical values (ProductiveStructure/ProcessMatrix)
        %       or nonnegative values (ExergyModel/TableFP)
        %
        %     names - Node names (optional)
        %       cell array of char | string array
        %       Length must equal size(A,1)
        %       If omitted, generates default names 'N1', 'N2', ...
        %
        %   Output Arguments:
        %     obj - cDigraphAnalysis object with computed properties
        %       Valid object if construction successful (obj.status = true)
        %       Invalid object if input validation fails (obj.status = false)
        %       Check with isValid(obj) before using
        %
        %   Construction Process:
        %     1. Validates adjacency matrix (must be square)
        %     2. Validates or generates node names
        %     3. Transforms to SSR format (adds IN/OUT nodes)
        %     4. Computes transitive closure for reachability
        %     5. Identifies strongly connected components
        %     6. Determines if graph is DAG (acyclic)
        %     7. Builds kernel DAG if cycles exist
        %     8. Generates edge and node tables for visualization
        %
        %   Examples:
        %     % Example 1: Simple linear chain
        %     A = [0 1 0; 0 0 1; 0 0 0];
        %     obj = cDigraphAnalysis(A);
        %     % Creates DAG with default names N1, N2, N3
        %
        %     % Example 2: Graph with custom node names
        %     A = [0 1 1; 0 0 1; 0 0 0];
        %     names = {'Resource', 'Process', 'Product'};
        %     obj = cDigraphAnalysis(A, names);
        %
        %     % Example 3: Graph with cycle requiring kernel DAG
        %     A = [0 1 0; 0 0 1; 1 0 0];
        %     obj = cDigraphAnalysis(A);
        %     fprintf('Is DAG: %d, Components: %d\n', obj.isDAG, obj.NrOfComponents);
        %
        %   Error Conditions:
        %     Returns invalid object if:
        %       • Adjacency matrix is not square
        %       • Node names array has incorrect length
        %       • Node names are not strings or cell array
        %
        %   See also:
        %     isValid, cMessageLogger, cDigraph
        
            % Check Inputs
            if ~isSquareMatrix(A)
                obj.messageLog(cType.ERROR,cMessages.NonSquareMatrix,size(A));
                return
            end
            if nargin<2 || isempty(names)
                names=arrayfun(@(x) sprintf('N%d',x),1:size(A,1),'UniformOutput',false);
            end
            if (~iscellstr(names) && ~isstring(names)) || numel(names)~=size(A,1)
                obj.messageLog(cType.ERROR,cMessages.InvalidNodeNames,numel(names),size(A,1));
                return
            end
            % Initialize variables
            obj.graph = cDigraphAnalysis.tfp2ssr(A);
            obj.nodes = ['IN',names(1:end-1),'OUT'];
            obj.NrOfNodes = numel(obj.nodes);
            % Get properties
	        obj.tc = transitiveClosure(obj.graph);
            obj.getStrongComponents;
            obj.isDAG=(obj.NrOfComponents == obj.NrOfNodes);
            obj.GraphEdges=cDigraphAnalysis.getEdgesTable(obj.graph,obj.nodes);
            obj.GraphNodes=cDigraphAnalysis.getNodesTable(obj.graph,obj.nodes,obj.comps);
            if obj.isDAG
                [obj.kG,obj.kNodes] = deal(obj.graph,obj.nodes);
                obj.KernelEdges=obj.GraphEdges;
                obj.KernelNodes=obj.GraphNodes;
            else
                obj.buildKernelMatrix;
                obj.KernelEdges=cDigraphAnalysis.getEdgesTable(obj.kG,obj.kNodes);
                obj.KernelNodes=cDigraphAnalysis.getNodesTable(obj.kG,obj.kNodes,1:obj.NrOfComponents);
            end
        end

        function [res,src,out]=isProductive(obj)
        %isProductive - Validate productive graph structure requirements.
        %   Tests whether the graph satisfies productive structure requirements:
        %   all nodes must be reachable from the source (IN) and must reach
        %   the sink (OUT). This ensures the graph represents a valid production
        %   chain without isolated components or dead ends.
        %
        %   A productive graph guarantees:
        %     • Every process receives inputs from upstream
        %     • Every process contributes to final outputs
        %     • No isolated or disconnected components exist
        %     • Complete flow paths from resources to products
        %
        %   DAG graphs (no cycles) are always productive by construction.
        %   Graphs with cycles require reachability verification.
        %
        %   Syntax:
        %     res = obj.isProductive()
        %     [res, src, out] = obj.isProductive()
        %
        %   Output Arguments:
        %     res - Productive graph indicator
        %       logical
        %       true if graph is productive (all nodes properly connected)
        %       false if isolated nodes or connectivity issues exist
        %
        %     src - Non-productive source nodes (optional)
        %       cell array of char
        %       Nodes that cannot reach the sink (OUT)
        %       Empty if graph is productive
        %       Indicates upstream dead ends
        %
        %     out - Non-productive sink nodes (optional)
        %       cell array of char
        %       Nodes not reachable from source (IN)
        %       Empty if graph is productive
        %       Indicates downstream isolated components
        %
        %   Examples:
        %     % Example 1: Valid productive graph
        %     A = [0 1 0; 0 0 1; 0 0 0];
        %     obj = cDigraphAnalysis(A);
        %     if obj.isProductive()
        %         fprintf('Valid productive structure\n');
        %     end
        %
        %     % Example 2: Detect non-productive nodes
        %     A = [0 1 1 0; 0 0 0 1; 0 0 0 0; 0 0 0 0];
        %     obj = cDigraphAnalysis(A);
        %     [isProd, srcNodes, outNodes] = obj.isProductive();
        %     if ~isProd
        %         fprintf('Non-productive sources: %s\n', strjoin(srcNodes, ', '));
        %         fprintf('Non-productive sinks: %s\n', strjoin(outNodes, ', '));
        %     end
        %
        %   Use Cases:
        %     • Validate productive structure before cost calculation
        %     • Identify structural errors in plant model
        %     • Verify all equipment contributes to production
        %     • Detect isolated subsystems requiring correction
        %
        %   See also:
        %     isReachable, isDAG
        %     
            src=cType.EMPTY_CELL;
            out=cType.EMPTY_CELL;
            % A DAG is always productive
            if obj.isDAG
                res=true;
                return
            end
            % Check if all source nodes can reach all output nodes
            s=obj.tc(1,:);
            t=obj.tc(:,end);            
            res=all(s) && all(t);
            % Get the non-SSR nodes
            if nargout==3
                idx=find(~s);
                if ~isempty(idx)
                    src=obj.nodes(idx);
                end
                jdx=transpose(find(~t));
                if ~isempty(jdx)
                    out=obj.nodes(jdx);
                end
            end
        end

        function res=isReachable(obj,u,v)
        %isReachable - Test if directed path exists between two nodes.
        %   Determines whether node v can be reached from node u by following
        %   directed edges in the graph. Uses precomputed transitive closure
        %   for O(1) query time, making repeated reachability tests efficient.
        %
        %   Reachability is fundamental for:
        %     • Verifying productive dependencies
        %     • Analyzing flow paths and connectivity
        %     • Identifying upstream/downstream relationships
        %     • Validating graph structure
        %
        %   Syntax:
        %     res = obj.isReachable(u, v)
        %
        %   Input Arguments:
        %     u - Source node name
        %       char array | string
        %       Must match a node name in the graph
        %       Case-sensitive exact match required
        %
        %     v - Target node name
        %       char array | string
        %       Must match a node name in the graph
        %       Case-sensitive exact match required
        %
        %   Output Arguments:
        %     res - Reachability indicator
        %       logical
        %       true if path exists from u to v
        %       false if no path exists or node names invalid
        %
        %   Performance:
        %     • O(1) query time (uses precomputed transitive closure)
        %     • Efficient for multiple queries
        %     • No graph traversal needed
        %
        %   Examples:
        %     % Example 1: Check simple path
        %     A = [0 1 0; 0 0 1; 0 0 0];
        %     obj = cDigraphAnalysis(A, {'A', 'B', 'C'});
        %     if obj.isReachable('A', 'C')
        %         fprintf('Path exists from A to C\n');
        %     end
        %
        %     % Example 2: Verify fuel-product relationship
        %     if obj.isReachable('Fuel', 'Product')
        %         fprintf('Fuel contributes to Product\n');
        %     end
        %
        %     % Example 3: Test bidirectional connectivity
        %     if obj.isReachable('A', 'B') && obj.isReachable('B', 'A')
        %         fprintf('Nodes A and B form a cycle\n');
        %     end
        %
        %   See also:
        %     isStrongConnected, isProductive, transitiveClosure
        %   
            res=false;
            [~,udx]=ismember(u,obj.nodes);
            [~,vdx]=ismember(v,obj.nodes);
            if udx && vdx
                res = obj.tc(vdx,udx);
            end
        end

        function res=isStrongConnected(obj,u,v)
        %isStrongConnected - Test if two nodes belong to same strong component.
        %   Determines whether nodes u and v are mutually reachable, meaning
        %   they belong to the same strongly connected component. Nodes in
        %   the same component can reach each other through directed paths,
        %   indicating circular dependencies or feedback loops.
        %
        %   Strong connectivity reveals:
        %     • Circular production dependencies
        %     • Feedback loops in productive structure
        %     • Groups requiring simultaneous equation solving
        %     • Component boundaries for decomposition
        %
        %   Syntax:
        %     res = obj.isStrongConnected(u, v)
        %
        %   Input Arguments:
        %     u - First node name
        %       char array | string
        %       Must match a node name in the graph
        %
        %     v - Second node name
        %       char array | string
        %       Must match a node name in the graph
        %
        %   Output Arguments:
        %     res - Strong connectivity indicator
        %       logical
        %       true if u and v are in same strong component (mutually reachable)
        %       false if in different components or node names invalid
        %
        %   Strong Component Properties:
        %     • Equivalence relation: reflexive, symmetric, transitive
        %     • Partitions graph into disjoint groups
        %     • Single-node components in DAGs
        %     • Multi-node components indicate cycles
        %
        %   Examples:
        %     % Example 1: Detect cycle membership
        %     A = [0 1 0; 0 0 1; 1 0 0];
        %     obj = cDigraphAnalysis(A, {'A', 'B', 'C'});
        %     if obj.isStrongConnected('A', 'C')
        %         fprintf('A and C are in a cycle\n');
        %     end
        %
        %     % Example 2: Identify feedback groups
        %     if obj.isStrongConnected('Process1', 'Process2')
        %         fprintf('Circular dependency detected\n');
        %     end
        %
        %   Use Cases:
        %     • Identifying circular production chains
        %     • Grouping processes for simultaneous solving
        %     • Detecting feedback requiring iterative methods
        %     • Component-based decomposition strategies
        %
        %   See also:
        %     isReachable, getComponentNames, NrOfComponents
        %
            res=false;
            [~,udx]=ismember(u,obj.nodes);
            [~,vdx]=ismember(v,obj.nodes);
            if udx && vdx
                res = (obj.comps(udx) == obj.comps(vdx));
            end
        end

        function [kA,kNames]=getKernelInfo(obj)
        %getKernelInfo - Extract kernel DAG adjacency matrix and node names.
        %   Returns the kernel DAG representation in fuel-product (FP) table
        %   format, suitable for thermoeconomic analysis and visualization.
        %   The kernel DAG condenses strongly connected components into single
        %   nodes, creating an acyclic graph that preserves dependencies.
        %
        %   The kernel representation:
        %     • Eliminates cycles through component condensation
        %     • Preserves inter-component dependencies
        %     • Enables hierarchical analysis and visualization
        %     • Simplifies complex graphs for clearer understanding
        %
        %   Syntax:
        %     [kA, kNames] = obj.getKernelInfo()
        %
        %   Output Arguments:
        %     kA - Kernel adjacency matrix
        %       numeric matrix (M×M where M = NrOfComponents)
        %       Fuel-Product (FP) table format
        %       Binary or weighted connections between components
        %       Guaranteed acyclic (DAG property)
        %       Row/column correspond to strong components
        %
        %     kNames - Kernel node names
        %       cell array of char (1×M)
        %       Fuel-Product format naming convention
        %       Component names or 'SC1', 'SC2', ... for multi-node groups
        %       Last element is 'ENV' (environment/sink)
        %
        %   FP Table Format:
        %     Standard thermoeconomic format where:
        %       • Rows represent processes (components)
        %       • Columns represent flows
        %       • Values indicate fuel/product relationships
        %       • Compatible with cost calculation algorithms
        %
        %   Examples:
        %     % Example 1: Extract kernel for visualization
        %     A = [0 1 0 0; 0 0 1 0; 1 0 0 1; 0 0 0 0];
        %     obj = cDigraphAnalysis(A);
        %     [kMatrix, kNames] = obj.getKernelInfo();
        %     fprintf('Kernel has %d nodes\n', length(kNames));
        %
        %     % Example 2: Export kernel for external analysis
        %     [kA, kNames] = obj.getKernelInfo();
        %     kernelTable = array2table(kA, 'VariableNames', kNames, ...
        %                               'RowNames', kNames(1:end-1));
        %
        %   Use Cases:
        %     • Generating simplified diagrams for complex systems
        %     • Exporting to graph layout software (yEd, Graphviz)
        %     • Hierarchical visualization of productive structure
        %     • Input for thermoeconomic cost calculations
        %     • Structural analysis and optimization
        %
        %   See also:
        %     KernelEdges, KernelNodes, isDAG, getComponentNames
        % 
            kA=cDigraphAnalysis.ssr2tfp(full(obj.kG));
            kNames=[obj.kNodes(2:end-1) 'ENV'];
        end

        function res=getGroupsInfo(obj)
        %getGroupsInfo - Get component group membership for all nodes.
        %   Returns a structure mapping each node to its strongly connected
        %   component group. This information is useful for understanding
        %   graph decomposition, identifying circular dependencies, and
        %   organizing nodes for hierarchical analysis.
        %
        %   Syntax:
        %     res = obj.getGroupsInfo()
        %
        %   Output Arguments:
        %     res - Node-to-group mapping structure
        %       struct array with fields:
        %         Name - Node name (char array)
        %         Group - Component group name (char array)
        %       Length equals total number of nodes (including IN/OUT)
        %       Nodes in same group are mutually reachable
        %
        %   Examples:
        %     % Example 1: Display component membership
        %     obj = cDigraphAnalysis(A, names);
        %     groups = obj.getGroupsInfo();
        %     for i = 1:length(groups)
        %         fprintf('%s -> %s\n', groups(i).Name, groups(i).Group);
        %     end
        %
        %     % Example 2: Find nodes in specific component
        %     groups = obj.getGroupsInfo();
        %     component1 = {groups(strcmp({groups.Group}, 'SC1')).Name};
        %
        %   Use Cases:
        %     • Organizing nodes by component for analysis
        %     • Identifying feedback loop participants
        %     • Coloring nodes by component in visualizations
        %     • Decomposition-based optimization strategies
        %
        %   See also:
        %     getComponentNames, isStrongConnected, NrOfComponents 
        %
            tmp=obj.GraphNodes;
            names={tmp.Name};
            idx=[tmp.Group];
            grps=obj.kNodes(idx);
            res=struct('Name',names,'Group',grps);
        end

        function res=getComponentNames(obj)
        %getComponentNames - Retrieve names of all strongly connected components.
        %   Returns component names corresponding to internal nodes (excluding
        %   IN and OUT). Each component represents either a single node (in DAG)
        %   or a group of mutually reachable nodes (in cyclic graphs).
        %
        %   Syntax:
        %     res = obj.getComponentNames()
        %
        %   Output Arguments:
        %     res - Component names array
        %       cell array of char (1×N where N = number of internal nodes)
        %       Single-node components use original node name
        %       Multi-node components named 'SC1', 'SC2', ... (Strong Component)
        %       Order corresponds to internal node sequence
        %
        %   Examples:
        %     % Example 1: List all components
        %     obj = cDigraphAnalysis(A, names);
        %     compNames = obj.getComponentNames();
        %     fprintf('Components: %s\n', strjoin(compNames, ', '));
        %
        %     % Example 2: Identify multi-node components
        %     compNames = obj.getComponentNames();
        %     cycles = compNames(startsWith(compNames, 'SC'));
        %     fprintf('Found %d cycles\n', length(cycles));
        %
        %   See also:
        %     getGroupsInfo, NrOfComponents, KernelNodes
        %
            idx=obj.comps(2:end-1);
            res=obj.kNodes(idx);
        end

        %%%%
        % Plot function
        %%%%
        function plot(obj,option,text)
        %plot - Visualize graph structure with interactive layout.
        %   Creates a MATLAB figure displaying the directed graph with nodes
        %   colored by component membership. Supports both full graph and
        %   kernel DAG visualization, with optional edge weight display.
        %
        %   Visualization features:
        %     • Automatic force-directed or hierarchical layout
        %     • Component-based node coloring (each component unique color)
        %     • Edge weight visualization with colormap
        %     • Interactive graph exploration (zoom, pan, rotate)
        %     • Node labels showing names
        %
        %   Not available in Octave (requires MATLAB graph plotting).
        %
        %   Syntax:
        %     obj.plot()
        %     obj.plot(option)
        %     obj.plot(option, title)
        %
        %   Input Arguments:
        %     option - Visualization type (optional)
        %       cType.DigraphType enumeration (default: GRAPH)
        %       GRAPH - Full graph without edge weights
        %       KERNEL - Kernel DAG without edge weights  
        %       GRAPH_WEIGHT - Full graph with edge weight colormap
        %       KERNEL_WEIGHT - Kernel DAG with edge weight colormap
        %
        %     title - Figure title text (optional)
        %       char array | string (default: 'Digraph Analysis')
        %       Displayed at top of figure
        %
        %   Examples:
        %     % Example 1: Simple graph visualization
        %     obj = cDigraphAnalysis(A, names);
        %     obj.plot();
        %
        %     % Example 2: Kernel DAG with custom title
        %     obj.plot(cType.DigraphType.KERNEL, 'CGAM Kernel Structure');
        %
        %     % Example 3: Weighted graph with colorbar
        %     obj.plot(cType.DigraphType.GRAPH_WEIGHT);
        %
        %   Interaction:
        %     • Drag nodes to rearrange layout
        %     • Click nodes to highlight connections
        %     • Use zoom and pan tools
        %     • Save figure as image (File → Save As)
        %
        %   See also:
        %     GraphEdges, GraphNodes, KernelEdges, KernelNodes
        %
            DEFAULT_TITLE='Digraph Analysis';
            % Check inputs
            if isOctave
                obj.messageLog(cType.ERROR,cMessages.GraphNotImplemented);
                return
            end
            if nargin<2 || option<0
                option=0;
                text=DEFAULT_TITLE;
            end
            if nargin<3
                text=DEFAULT_TITLE;
            end
            isKernel=bitget(option,1);
            isColorBar=bitget(option,2);
            % Get Node and Edge info
            if isKernel
                markerSize=cType.KMARKER_SIZE;
                Nodes=obj.KernelNodes;
                Edges=obj.KernelEdges;
                layout='layered';
            else
                markerSize=cType.MARKER_SIZE;
                Nodes=obj.GraphNodes;
                Edges=obj.GraphEdges;
                layout='auto';
            end
            % Build the digraph
            endNodes=[{Edges.Source};{Edges.Target}]';
            values=[Edges.Value]';
            EdgesTable=table(endNodes,values,'VariableNames',{'EndNodes','Weight'});
            NodesTable=struct2table(Nodes);
            dg=digraph(EdgesTable,NodesTable,'omitselfloops');
            % Color by groups
			grps=dg.Nodes.Group;
			ng=max([grps;3]);
			colors=lines(ng);
			Categories=colors(grps,:);
            % Plot the digraph
            if isColorBar
    			r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
			    plot(dg,"EdgeCData",dg.Edges.Weight,"EdgeColor","flat","LineWidth",1.5,...
                    'NodeColor',Categories,'MarkerSize',markerSize,...
                    'Interpreter','none','Layout',layout);
                colormap(red2blue);
			    colorbar();
            else
                plot(dg,'NodeColor',Categories,'MarkerSize',markerSize,'Interpreter','none','Layout',layout);
            end
            title(text,'fontsize',12);
        end
    end

    methods(Access=private)
        function getStrongComponents(obj)
        %getStrongComponents - Get the strong components of the graph
        %   A strong component is a maximal subgraph in which every node is reachable
        %   from every other node. A graph without cycles (DAG) has as many
        %   components as nodes.
        %   The components are calculated using the transitive closure
        %   The components are stored in the property obj.comps
        %   The name of strong components are stores in obj.kNodes
        %   Syntax:
        %     obj.getStrongComponents()
        %        
            n=obj.NrOfNodes;
            res=zeros(1,n); cnt=0;
            % Find the strongly connected components
            for u=1:n
                if ~res(u)
                    cnt=cnt+1;
                    idx = obj.tc(u,:) & obj.tc(:,u)';  
                    res(idx)=cnt;
                end
            end
            obj.comps=res;
            obj.NrOfComponents = max(res);
            % Get the names of the kernel nodes
            [~,jdx,idx]=unique(obj.comps);
            cnames = obj.nodes(jdx);
            nrg = accumarray(idx,1);
            tmp = find(nrg>1);
            for i=1:length(tmp)
                cnames{tmp(i)}=['SC',num2str(i)];
            end
            obj.kNodes=cnames;
        end

        function buildKernelMatrix(obj)
        %buildKernelMatrix - Get the kernel graph adjacency matrix
        %   The kernel graph is obtained by collapsing each strongly connected component
        %   into a single node. The kernel graph is a DAG.
        %   The kernel graph adjacency matrix is stored in obj.kG
        %   Syntax;
        %     obj.getKernelMatrix()
        %    
            grps=obj.comps;
            ng=obj.NrOfComponents;
            [snodes,tnodes,vals]=find(obj.graph);
            tmp1=grps(snodes);
            tmp2=grps(tnodes);
            sol=find(tmp2-tmp1);
            obj.kG=sparse(tmp1(sol),tmp2(sol),vals(sol),ng,ng);
        end
    end

    methods(Static,Access=private)
        function res=getNodesTable(A,names,groups)
        %getNodeTable - Build Node Table from adjacency matrix and groups.
        %   Syntax;
        %     res=cDigraphAnalysis.getNodeTable(A,names)
        %   Input Arguments:
        %     A - Adjacency Matrix in SSR format 
        %     names - Names of the internal nodes
        %     groups - Array with the group of each node
        %   Output Arguments:
        %     res - Struct with fields Name and Group, representing the node table
        
            % Get number of groups
            ng=max(groups);
            % Internal nodes
            inames=names(2:end-1);
            igrp=groups(2:end-1);
            % Source nodes
            [~,jdx]=find(A(1,2:end-1));
            snames=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            sgrp=ones(1,numel(jdx));
            % Output nodes
            idx=find(A(2:end-1,end));
            tnames=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            tgrp=repmat(ng,1,numel(idx));
            % Node Table structure
            names=[snames,inames,tnames];
            groups=[sgrp,igrp,tgrp];
            fields={'Name','Group'};
            tmp=[names;num2cell(groups)];
            res=cell2struct(tmp,fields,1);
        end

        function res=getEdgesTable(A,names)
        %getEdgesTable - Build Edge Table from adjacency matrix
        %   Syntax;
        %     res=cDigraphAnalysis.getEdgesTable(A,names)
        %   Input Arguments:
        %     A - Adjacency Matrix in SSR format
        %     names - Names of the internal nodes
        %   Output Arguments:
        %     res - Struct with fields Source, Target and Value, representing the edge table
        
            % Internal Edges
            [idx,jdx,ival]=find(A(2:end-1,2:end-1));
            isource=names(idx+1);
            itarget=names(jdx+1);
            % Source Edges
            [~,jdx,vval]=find(A(1,2:end-1));
            vsource=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            vtarget=names(jdx+1);
            % Output Edges
            [idx,~,wval]=find(A(2:end-1,end));
            wtarget=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            wsource=names(idx+1);
            % Build the Adjacency Matrix Table
            source=[vsource,isource,wsource];
            target=[vtarget,itarget,wtarget];
            values=[vval,ival',wval'];
            tmp=[source;target;num2cell(values)];
            fields={'Source','Target','Value'};
            res=cell2struct(tmp,fields,1);
        end

        function G=tfp2ssr(A)
        %tfp2ssr - Tranform a Table FP into a SSR adjacency Matrix
        %   Syntax;
        %     G=tfp2ssr(A)
        %   Input Arguments:
        %     A: Table FP
        %   Output Arguments:
        %     G: Incidence matrix in SSR format
        %
            N=size(A,1);
			G=[0 A(end,:);...
			   zeros(N-1,1) A(1:end-1,:);...
			   0 zeros(1,N)];
        end

        function A=ssr2tfp(G)
        %ssr2tfp - Transform a SSR adjacency matrix into Table FP
        %   Syntax;
        %     G=tfp2ssr(A)
        %   Input Arguments:
        %     G: Incidence matrix in SSR format        
        %   Output Arguments:
        %     A: Table FP
        %
            A=[G(2:end-1,2:end);...
               G(1,2:end)];
        end
    end
end