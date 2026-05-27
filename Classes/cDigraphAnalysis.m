classdef cDigraphAnalysis < cMessageLogger
%cDigraphAnalysis - Analyze the process digraph structure.
%  This class provides a comprehensive toolkit for analyzing the structure of
%  directed graphs, with a special focus on identifying strongly connected
%  components (SCCs), determining topological order, and constructing a
%  condensed kernel representation. It is designed to work with adjacency
%  matrices and is particularly useful in the context of thermoeconomic
%  analysis for modeling productive systems.
%
%  Key Features:
%   - Strong Component Analysis: Implements the Kosaraju algorithm to
%     efficiently find all strongly connected components in the graph.
%   - Topological Sorting: Computes the topological order of the graph's
%     nodes, which is essential for processing Directed Acyclic Graphs (DAGs).
%   - Kernel Graph Construction: Creates a simplified "kernel" graph where
%     each strongly connected component is condensed into a single node,
%     revealing the overall acyclic structure of the system.
%   - DAG Verification: Includes a method to quickly check if the graph is
%     a DAG.
%   - Rich Data Representation: Stores graph information in easily accessible
%     tables for nodes and edges, for both the full graph and the kernel.
%
%  Typical Use Cases:
%   - Analyzing the structure of industrial processes to identify circular
%     dependencies (feedback loops).
%   - Pre-processing a system model before performing calculations that
%     require a specific topological order.
%   - Simplifying a complex system into its fundamental components for
%     high-level analysis.
%
%  This class is used for structural analysis within the TaesLab toolbox
%  to create the process diagram, enabling deeper insights into the
%  connectivity and hierarchy of energy systems.
%
%  See also: cProductiveStructure, cThermoeconomicModel, cDiagramFP
%
%    cDigraphAnalysis properties
%      NrOfNodes          - Number of nodes in the SSR graph
%      NrOfGroups         - Number of strongly connected components
%      TopologicalOrder   - Topological order array (excluding source and sink)
%      Groups             - Group assignment for each internal node
%      GroupSize          - Size (node count) of each strongly connected component
%      KernelTable        - Kernel graph adjacency matrix in FP table format
%      KernelNodes        - Node labels for the kernel graph (including ENV)
%
%    cDigraphAnalysis methods
%      cDigraphAnalysis     - Construct graph analysis object from adjacency matrix
%      isDAG                - Check if the graph is a Directed Acyclic Graph
%      isProductive         - Check if the kernel graph represents a productive system
%      getGroupsInfo        - Get the group assignment for each internal node
%      getGroupsIndex       - Get the starting index of each group
%      getTransitiveClosure - Compute the transitive closure of the graph
%      getNodesTable        - Get the nodes table info of the full or kernel graph
%      getEdgesTable        - Get the edges table info of the full or kernel graph
%
	properties(Access=private)
        mG          % Adjacency matrix of the graph
        gNodes      % Nodes of the graph
        kNodes      % Kernel Names
        kG          % Kernel Matrix
		groups      % Indicate the group the node belong
        order       % Order of the nodes
        nrg         % Size of each group
	end

	properties(GetAccess=public,SetAccess=private)
        NrOfGroups        % Number of Strong Connected Components
        NrOfNodes         % Number of Nodes of the SSR Graph
        TopologicalOrder  % Topological Order array
        Groups            % Groups index array
        GroupSize         % Size of each group
        GraphTable        % Graph FP Table ordered
        GraphNodes        % Graph Nodes ordered
        KernelTable       % Kernel Table
        KernelNodes       % Kernel Nodes
    end

	methods
        function obj=cDigraphAnalysis(tfp,names)
		%cDigraphAnalysis - Construct an instance of this class
        %   creates a digraph analysis object from a FP Table and corresponding names.
        %   It initializes the graph, finds strongly connected components,
        %   builds the kernel graph, and prepares node/edge tables for
        %   analysis and visualization.
        %   Syntax:
        %       obj = cDigraphAnalysis(tfp, names) 
        %
        %   Input Arguments:
        %     tfp   - A matrix representing the fuel-product table 
        %     names - A cell array of strings with the names of the processes.
        %
        %   Output Arguments:
        %     obj - An instance of the cDigraphAnalysis class, fully
        %           initialized with the structural analysis of the graph.
        %
        %   See also: getStrongComponents, buildKernelGraph, tfp2ssr

            % Check Inputs
            if ~isNonNegativeMatrix(tfp)
                obj.messageLog(cType.ERROR,cMessages.NegativeMatrix);
                return
            end
            if nargin<2 || isempty(names)
                names=arrayfun(@(x) sprintf('N%d',x),1:size(A,1),'UniformOutput',false);
            end
            if (~iscellstr(names) && ~isstring(names)) || numel(names)~=size(tfp,1)
                obj.messageLog(cType.ERROR,cMessages.InvalidNodeNames,numel(names),size(tfp,1));
                return
            end
            % Initialize variables
            obj.mG=cDigraphAnalysis.tfp2ssr(tfp);
            obj.gNodes=['IN',names(1:end-1),'OUT'];
            % Find Strong Components
            if ~obj.getStrongComponents
                return
            end
            % Build Kernel Graph
            obj.buildKernelGraph;
            % Build ordered Graph
            idx=obj.order;
            obj.GraphTable=cDigraphAnalysis.ssr2tfp(obj.mG(idx,idx));
            obj.GraphNodes=[obj.gNodes(idx(2:end-1)),'ENV'];
        end

        function res=get.TopologicalOrder(obj)
        %get.TopologicalOrder - Getter for the TopologicalOrder property.
        %   Return the topological sorted order of the graph's procecsss. 
        %   This order is computed during the strong component analysis.  
        %
        %   Output Arguments:
        %     res - A numeric array representing the topological order of
        %           the processes. Not includes source and sink nodes.
        %
            res=obj.order(2:end-1)-1;
        end

        function res=get.Groups(obj)
        %get.Groups - Getter for the Groups property.
        %   Return the group assignment for each node in the graph.
        %   Groups are identified during the strong component analysis.
        %
        %   Output Arguments:
        %     res - A numeric array representing the group assignment of
        %           each process. Not includes source and sink nodes.
        %
            res=obj.groups(obj.order(2:end))-1;
        end

        function res=get.GroupSize(obj)
        %get.GroupSize - Getter for the GroupSize property.
        %   Return the size (number of nodes) for each group in the graph.
        %   Group sizes are computed during the strong component analysis.
        %
        %   Output Arguments:
        %     res - A numeric array representing the size of each group
        %           (number of nodes per group). Not includes source and sink nodes.
        %
            res=full(obj.nrg(2:end-1))';
        end

        function res = isDAG(obj)
        %isDAG - Check if the graph is acyclic (DAG).
        %   This method returns true if the graph has no cycles (i.e., each node forms its own strong component)
        %   and the diagonal of the adjacency matrix is zero (no self-loops).
        %
        %   Syntax:
        %     res = obj.isDAG()
        %
        %   Output Arguments:
        %     res - A logical scalar (true or false).
        %
            res = (obj.NrOfGroups == obj.NrOfNodes) && all(diag(obj.mG) == 0);
        end

        function res=isProductive(obj)
        %isProductive - Check if the kernel graph represents a productive system.
        %   This method returns true if every node in the
        %   kernel graph (excluding the environment) has at least one
        %   incoming and one outgoing edge. This is a structural check to
        %   ensure that all components are integrated into the system.
        %
        %   Syntax:
        %     res = obj.isProductive()
        %
        %   Output Arguments:
        %     res - A logical scalar (true or false).
        %
            A=obj.kG(1:end-1,2:end);
			in=sum(A,1);
			out=sum(A,2);
			res=(all(in) && all(out));
		end

        function res=getGroupsInfo(obj)
        %getGroupsInfo - Get the group (component) for each internal node.
        %   This method returns a struct array that maps each
        %   internal node of the graph to its corresponding group (strongly
        %   connected component) in the kernel graph.
        %
        %   Syntax:
        %     res = obj.getGroupsInfo()
        %
        %   Output Arguments:
        %     res - A struct array with two fields:
        %           'Name'  - The name of the internal node.
        %           'Group' - The name of the kernel group it belongs to.
        %
            tmp=obj.groups(obj.order);
            group=obj.kNodes(tmp);
            res=struct('Name',obj.gNodes(2:end-1),'Group',group(2:end-1));
        end

        function res=getGroupIndex(obj)
        %getGroupIndex - Get the starting index of each group.
        %   Returns an array where each element is the starting index 
        %   of the corresponding group in the ordered node list.
        %
        %   Syntax:
        %     res = obj.getGroupIndex
        %
        %   Output Arguments:
        %     res - Array of starting indices for each group
        %
            res=[1, 1+cumsum(obj.nrg(1:end-1))];
        end

        function res=getTransitiveClosure(obj,option)
        %getTransitiveClosure - Compute the transitive closure of the graph.
        %   This method calculates the transitive closure, which reveals all reachable nodes from
        %   every other node. It can be computed for either the full graph or the kernel graph.
        %
        %   Syntax:
        %     res = obj.getTransitiveClosure(option)
        %
        %   Input Arguments:
        %     option - Specifies which graph to use (optional, default is KERNEL).
        %              cType.Digraph.GRAPH:  Compute for the full graph.
        %              cType.Digraph.KERNEL: Compute for the kernel graph.
        %
        %   Output Arguments:
        %     res - The adjacency matrix of the transitive closure.
        %
            if nargin==1
                option=cType.Digraph.KERNEL;
            end
            switch option
                case cType.Digraph.GRAPH
                    idx=obj.order;
                    res=cDigraphAnalysis.transitiveClosure(obj.mG(idx,idx));
                case cType.Digraph.KERNEL
                    res=cDigraphAnalysis.transitiveClosure(obj.kG);
            end
        end

        function res=getNodesTable(obj,option)
        %getNodesTable - Get the nodes table for the graph.
        %   This method returns a table containing all nodes in either the full graph
        %   or the kernel graph, with node names and their corresponding group assignments.
        %
        %   Syntax:
        %     res = obj.getNodesTable(option)
        %
        %   Input Arguments:
        %     option - Specifies which graph to use.
        %              cType.Digraph.GRAPH:  Get nodes table for the full graph.
        %              cType.Digraph.KERNEL: Get nodes table for the kernel graph.
        %
        %   Output Arguments:
        %     res - A struct containing the nodes information
        %
            switch option
                case cType.Digraph.GRAPH
                    res=cDigraphAnalysis.buildNodesTable(obj.GraphTable,obj.GraphNodes,obj.Groups);
                case cType.Digraph.KERNEL
                    res=cDigraphAnalysis.buildNodesTable(obj.KernelTable,obj.KernelNodes,1:obj.NrOfGroups-1);
            end
        end

        function res=getEdgesTable(obj,option)
        %getEdgesTable - Get the edges table for the graph.
        %   This method returns a table containing all edges in either the full graph
        %   or the kernel graph, with source and target node and weight information.
        %
        %   Syntax:
        %     res = obj.getEdgesTable(option)
        %
        %   Input Arguments:
        %     option - Specifies which graph to use.
        %              cType.Digraph.GRAPH:  Get edges table for the full graph.
        %              cType.Digraph.KERNEL: Get edges table for the kernel graph.
        %
        %   Output Arguments:
        %     res - An struct containing the edges info
        %
            switch option
                case cType.Digraph.GRAPH
                    res=cDigraphAnalysis.buildEdgesTable(obj.GraphTable,obj.GraphNodes);
                case cType.Digraph.KERNEL
                    res=cDigraphAnalysis.buildEdgesTable(obj.KernelTable,obj.KernelNodes);
            end
        end

    end

    methods (Access=private)
        function log=getStrongComponents(obj)
        %getStrongComponents - Finds strong components using Kosaraju's algorithm.
        %
        %   This private method implements the two-pass Kosaraju algorithm
        %   to find all strongly connected components (SCCs) in the graph.
        %   It first performs a depth-first search (DFS) on the transpose
        %   graph to determine the processing order, then a second DFS on
        %   the original graph to identify the components.
        %
        %   The results (number of groups, group membership, and topological
        %   order) are stored in the object's properties.
        %
        %   See also: dfSC
        
            %Find a postorder search of the reverse graph
            log=false;
            N=size(obj.mG,1);
            [~,porder]=cDigraphAnalysis.dfSC(obj.mG',1:N);
            if ~all(porder)
                obj.messageLog(cType.ERROR,cMessages.InvalidDigraph);
                return
            end
            %Find the strong connected groups
	        [grp,ord]=cDigraphAnalysis.dfSC(obj.mG,porder);
            if ~all(ord)
                obj.messageLog(cType.ERROR,cMessages.InvalidDigraph);
                return
            end  
            % Assign object variables
            obj.NrOfNodes=N;
            obj.NrOfGroups=max(grp);
            obj.order=ord;
            obj.groups=obj.NrOfGroups+1-grp;
            log=true;
        end

        function buildKernelGraph(obj)
        % buildKernelGraph - Constructs the kernel graph from strongly connected components.
        %
        %   This method builds the kernel (condensation) graph by condensing all
        %   nodes within each strongly connected component (SCC) into a single node.
        %   The kernel graph represents the DAG of SCCs and is used for higher-level
        %   graph analysis.
        %
        %   For DAGs (acyclic graphs):
        %     - The graph is reordered according to the topological order
        %     - Each node is preserved individually
        %     - Node groups have size 1
        %
        %   For graphs with cycles:
        %     - Creates a condensation graph where each SCC becomes a single node
        %     - Builds a sparse representation for efficiency
        %     - Assigns special names to multi-node components (e.g., 'SC1', 'SC2')
        %     - Tracks component sizes for later analysis
        %
        %   Output:
        %     Updates object properties:
        %       kG           - Kernel graph adjacency matrix
        %       kNodes       - Node labels for the kernel graph
        %       nrg          - Number of nodes in each group/component
        %       KernelTable  - Table representation of kernel graph in FP Table format
        %       KernelNodes  - Final node names including environment node
        %
        %   See also: getStrongComponents, ssr2tfp
            N=obj.NrOfNodes;
            NG=obj.NrOfGroups;
            idx=obj.order;
            if obj.isDAG %Order and copy the adjacency matrix
                obj.kG=obj.mG(idx,idx);
                obj.kNodes=obj.gNodes(ogj.order);
                obj.nrg=ones(1,obj.NrOfNodes);
            else
                % Build Kernel Matrix
                scmp=sparse(obj.groups,1:N,true(N,1),NG,N);
                obj.kG=scmp*obj.mG*scmp';
                obj.kG(1:NG+1:end)=0; % Set diagonal to 0 
                obj.nrg = sum(scmp,2);      
                % Build Kernel Nodes
                [~,jdx]=unique(obj.groups);
                obj.kNodes = obj.gNodes(jdx);  
                tmp = find(obj.nrg>1);
                for i=1:length(tmp)
                    obj.kNodes{tmp(i)}=['SC',num2str(i)];
                end
            end
            obj.KernelTable=cDigraphAnalysis.ssr2tfp(obj.kG);
            obj.KernelNodes=[obj.kNodes(2:end-1),'ENV'];
        end

    end

    methods (Static,Access=public)
        function [group,order]=dfSC(G,nodes)
		%dfSC - Performs a Depth-First Search for strong component analysis.
        %   This static helper function performs a single pass of
        %   depth-first search over the specified nodes of graph G.
        %   It is used by `getStrongComponents` as part of the Kosaraju algorithm.
        %
        %   Syntax: 
        %   [group, order] = cDigraphAnalysis.dfSC(G, nodes)      
        %
        %   Input Arguments:
        %     G     - The adjacency matrix of the graph.
        %     nodes - The order in which to visit the nodes.
        %
        %   Output Arguments:
        %     group - An array indicating the group (component) of each node.
        %     order - The post-order traversal of the nodes.
        %
            N=size(G,1);
            stack=zeros(1,N,'int16'); scnt=0; % Stack for DFS traversal
			order=zeros(1,N,'int16'); pcnt=0; % Post-order traversal result
			group=zeros(1,N); gcnt=0;         % Group assignment for each node
            
            % Iterate through nodes in the specified order (from first pass)
            for u=nodes
                % If node 'u' has not been visited yet
                if ~group(u)
			        gcnt=gcnt+1;group(u)=gcnt; % Assign a new group ID
                    scnt=scnt+1;stack(scnt)=u; % Push node to stack
                    pcnt=pcnt+1;order(pcnt)=u; % Record node in traversal order
                    
                    % Standard iterative DFS loop
                    while scnt>0
				        v=stack(scnt); scnt=scnt-1; % Pop a node
				        
                        % Find all neighbors of the current node 'v'
                        [~,idx]=find(G(v,:));
				        
                        % Visit all neighbors
                        for w=idx
                            % If neighbor 'w' has not been visited
					        if ~group(w)
			                    group(w)=gcnt; % Assign it to the current group
                                scnt=scnt+1;stack(scnt)=w; % Push neighbor to stack
                                pcnt=pcnt+1;order(pcnt)=w; % Record in traversal order
					        end
                        end
                    end
                end
            end
            order=order(N:-1:1); % Reverse to get the correct post-order
        end

        function G=tfp2ssr(A)
        %tfp2ssr - Transform a Fuel-Product (FP) table to SSR format.
        %   Converts a standard FP adjacency matrix into the Source-Sink
        %   Representation (SSR) format used internally by this class.
        %   SSR adds an explicit source node ('IN') and sink node ('OUT')
        %   to handle system boundary flows.
        %
        %   Syntax:
        %     G = cDigraphAnalysis.tfp2ssr(A)
        %
        %   Input Arguments:
        %     A - Square adjacency matrix in FP format (N x N).
        %
        %   Output Arguments:
        %     G - Adjacency matrix in SSR format ((N+1) x (N+1)).
        %
        %   See also: ssr2tfp
        %
            N=size(A,1);
			G=[0 A(end,:);...
			   zeros(N-1,1) A(1:end-1,:);...
			   zeros(1,N+1)];
        end

        function A=ssr2tfp(G)
        %ssr2tfp - Transform an SSR adjacency matrix back to FP table format.
        %   Reverses the `tfp2ssr` operation, converting an internal
        %   SSR-format matrix back into a standard Fuel-Product (FP) table.
        %
        %   Syntax:
        %     A = cDigraphAnalysis.ssr2tfp(G)
        %
        %   Input Arguments:
        %     G - Adjacency matrix in SSR format ((N+1) x (N+1)).
        %
        %   Output Arguments:
        %     A - Adjacency matrix in FP format (N x N).
        %
        %   See also: tfp2ssr
        %
            A=[G(2:end-1,2:end);...
               G(1,2:end)];
        end

        function res=buildNodesTable(A,names,groups)
        %buildEdgesTable - Build Node Table from adjacency matrix and groups.
        %
        %   Syntax:
        %     res=cDigraphAnalysis.buildNodesTable(A,names)
        %   Input Arguments:
        %     A - Adjacency Matrix in SSR format 
        %     names - Names of the internal nodes
        %     groups - Array with the group of each node
        %   Output Arguments:
        %     res - Struct with fields Name and Group, representing the node table
        %
            % Internal nodes
            ng=max(groups)+1;
            inames=names(1:end-1);
            igrp=groups(1:end-1)+1;
            % Source nodes
            [~,jdx]=find(A(end,1:end-1));
            snames=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            sgrp=ones(1,numel(jdx));
            % Output nodes
            idx=find(A(1:end-1,end));
            tnames=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            tgrp=repmat(ng,1,numel(idx));
            % Node Table structure
            names=[snames,inames,tnames];
            grp=[sgrp,igrp,tgrp];
            fields={'Name','Group'};
            tmp=[names;num2cell(grp)];
            res=cell2struct(tmp,fields,1);
        end

        function res=buildEdgesTable(A,names)
        %buildEdgesTable - Build Edge Table from adjacency matrix
        %   Syntax;
        %     res=cDigraphAnalysis.buildEdgesTable(A,names)
        %   Input Arguments:
        %     A - Adjacency Matrix in SSR format
        %     names - Names of the internal nodes
        %   Output Arguments:
        %     res - Struct with fields Source, Target and Value, representing the edge table
        
            % Internal Edges
            [idx,jdx,ival]=find(A(1:end-1,1:end-1));
            isource=names(idx);
            itarget=names(jdx);
            % Source Edges
            [~,jdx,vval]=find(A(end,1:end-1));
            vsource=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            vtarget=names(jdx);
            % Output Edges
            [idx,~,wval]=find(A(1:end-1,end));
            wtarget=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            wsource=names(idx);
            % Build the Adjacency Matrix Table
            source=[vsource,isource,wsource];
            target=[vtarget,itarget,wtarget];
            values=[vval,ival',wval'];
            tmp=[source;target;num2cell(values)];
            fields={'Source','Target','Value'};
            res=cell2struct(tmp,fields,1);
        end

        function res = transitiveClosure(A)
        %transitiveClosure - Computes transitive closure for ordered graph.
        %   This method computes the transitive closure of a Digraph
        %   more efficiently than a general-purpose algorithm like Floyd-Warshall 
        %   by leveraging the topological order of the nodes.
        %   The TC matrix is block upper triangular.
        %
        %   Syntax:
        %     res = cDigraphAnalysis.transitiveClosure(A)
        %
        %   Input Arguments:
        %     A - The adjacency matrix of the ordered SSR graph.
        %
        %   Output Arguments:
        %     res - The transitive closure matrix of the digraph.
        %
            N = size(A, 1);
            res = logical(A); % Start with the direct connections       
            % Iterate through nodes in reverse topological order
            for u = N:-1:1
                % Find all nodes reachable from u
                vfu = find(res(u, :));
                if ~isempty(vfu)
                    % Find all nodes that can reach u
                    vru = find(res(:, u));           
                    % For every pair (v, w) where v reaches u and u reaches w,
                    % add an edge from v to w.
                    for v = vru
                        res(v, vfu) = true;
                    end
                end
            end
            res = eye(N) | res;  
        end
    end
end
