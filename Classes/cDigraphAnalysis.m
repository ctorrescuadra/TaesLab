classdef cDigraphAnalysis < cMessageLogger
%cDigraphAnalysys - Analize the connectivity of a SSR Graph
%   Calculate the transitive closure of the digraph,
%   their strong conmponents and the Kernel DAG.
%   The graph is represented by its adjacency matrix,
%   and must have a single source node (IN) and a single output node (OUT).
%
%   cGraphAnalysis constructor:
%     obj = cDigraphAnalysis(A,names)
%
%   cGraphAnalysis properties:
%     NrOfNodes          - Number of nodes in the graph
%     NrOfComponents     - Number of components
%     Components         - Array indicating the component each node in the graph belongs to
%     TransitiveClosure  - Transitive closure of graph
%     GraphEdges         - Edges of the full graph
%     GraphNodes         - Nodes of the full graph
%     KernelNodes        - Nodes of the kernel DAG
%     KernelEdges        - Edges of the kernel DAG
%     isDAG              - Indicate if the graph is a DAG
%   
%   cGraphAnalysis methods:
%     isProductive        - check if the SSR graph is productive
%     isReachable         - check if two nodes are reacheable
%     isStrongConnected   - chek if two nodes belong to the same component
%     getGroupsTable      - get the node groups table
%     getKernelTable      - get Kernel DAG taable and node names
%     showGroupsTable     - show the components of the graph
%     showKernelTable     - show the Kernel DAG table in IO-Table format
%     plotGraph           - plot the digraph (colouring node groups)
%     plotKernelGraph     - plot the kernel DAG
%
    properties(GetAccess=public,SetAccess=private)
      NrOfNodes          % Number of nodes in the graph
      NrOfComponents     % Number of components
      Components         % Array indicating the component each node in the graph belongs to
      TransitiveClosure  % Transitive closure of graph
      GraphEdges         % Edges of the graph
      GraphNodes         % Nodes of the graph      
      KernelNodes        % Nodes of the kernel DAG
      KernelEdges        % Edges of the kernel DAG
      isDAG              % Indicate if the graph is a DAG 
    end

    properties(Access=private)
        graph          % Adjacency of the graph
        nodes          % Node Names
        knodes         % Kernel Names
        kG             % Kernel Matrix
    end

    methods
        function obj = cDigraphAnalysis(A,names)
        %cTransitiveClosure - Construct an instance of this class
        %   Usage:
        %     obj = cGraphAnalysis(G,names)
        %   Input Arguments :
        %     G - Adjacency matriz of the graph
        %     names - Name of the nodes
        %   Output Argument:
        %     obj - cGraphAnalysis object
        %
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
            % Build SSR Graph adjacency matrix
            N=size(A,1);
			G=[0 A(N,:);...
			   zeros(N-1,1) A(1:N-1,:);...
			   0 zeros(1,N)];
            % Initialize variables
            obj.graph = G;
            obj.nodes = ['IN',names(1:end-1),'OUT'];
            obj.NrOfNodes = numel(obj.nodes);
            % Calculate properties
	        obj.TransitiveClosure = transitiveClosure(G);
            obj.getStrongComponents;
            obj.GraphEdges=cDigraphAnalysis.getEdgeTable(G,obj.nodes);
            obj.GraphNodes=cDigraphAnalysis.getNodeTable(G,obj.nodes,obj.Components);
            obj.isDAG=(obj.NrOfComponents == obj.NrOfNodes);
            if obj.isDAG
                [obj.kG,obj.knodes] = deal(G,names);
                obj.KernelEdges=obj.GraphEdges;
                obj.KernelNodes=obj.GraphNodes;
            else
                obj.buildKernel;
                obj.KernelEdges=cDigraphAnalysis.getEdgeTable(obj.kG,obj.knodes);
                obj.KernelNodes=cDigraphAnalysis.getNodeTable(obj.kG,obj.knodes,1:obj.NrOfComponents);
            end
        end

        function [res,src,out]=isProductive(obj)
        %isProductive - Check if the graph is productive
        %   A graph is productive if all source nodes can reach all output nodes
        %   and all output nodes can be reached from all source nodes.
        %   Usage:
        %     [res,src,out] = obj.isProductive()
        %   Output Arguments:
        %     res - true | false
        %     src - Cell array with the non-SSR source nodes (optional)
        %     out - Cell array with the non-SSR output nodes (optional)
        %     
            % Determine if the graph is productive
            src=cType.EMPTY_CELL;
            out=cType.EMPTY_CELL;
            tc=obj.TransitiveClosure;
            s=tc(1,:);
            t=tc(:,end);            
            res=all(s) && all(t);
            % Show the non-SSR nodes
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
        %isReachable - Check if node v is reachable from node u
        %  Usage:
        %    res = obj.isReachable(u,v)
        %  Input Arguments:
        %    u - source node name
        %    v - target node name
        %  Output Argument:
        %    res - true | false
        %   
            res=false;
            [~,udx]=ismember(u,obj.nodes);
            [~,vdx]=ismember(v,obj.nodes);
            if udx && vdx
                res = obj.TransitiveClosure(vdx,udx);
            end
        end

        function res=isStrongConnected(obj,u,v)
        %isStrongConnected - Check if nodes u,v belong to the same component
        %  Usage:
        %    res = obj.isReachable(u,v)
        %  Input Arguments:
        %    u - source node
        %    v - target node
        %  Output Argument:
        %    res - true | false
            res=false;
            [~,udx]=ismember(u,obj.nodes);
            [~,vdx]=ismember(v,obj.nodes);
            if udx && vdx
                res = (obj.Components(udx) == obj.Components(vdx));
            end
        end

        function [kTable,kNodes]=getKernelTable(obj)
        %getKernelTable - Get the kernel matrix in IO-Table format
        %   Usage:
        %     tbl = obj.getKernelTable()
        %   Output Arguments:
        %     kTable - kernel table array
        %     kNodes - cell array with the name of the kernel nodes
        %
            kTable=full([obj.kG(2:end-1,2:end);...
                     obj.kG(1,2:end)]);
            kNodes=[obj.knodes(2:end-1),'ENV'];
        end

        function res=getGroupsTable(obj)
        %buildGroupsTable - Build the Node Groups table
        %   Output Argument:
        %     res - cTableData object with the node groups 
        %
            tmp=obj.GraphNodes;
            names = {tmp.Name};
            idx=[tmp.Group];
            comps=obj.knodes(idx);
            rowNames=names;
            colNames={'Name','Component'};
            values=comps';
            props=struct('Name','grps','Description','Graph Components');
            res=cTableData(values,rowNames,colNames,props);
        end

        %%%
        % Display functions
        %%%
        function plotGraph(obj)
        %plotGraph - Plot the graph
            cDigraphAnalysis.plot(obj.GraphNodes,obj.GraphEdges,false);
        end

        function plotKernelGraph(obj)
        %plotKernelGraph - Plot the kernel DAG
            cDigraphAnalysis.plot(obj.KernelNodes,obj.KernelEdges,true);
        end

    end

    methods(Access=private)
        function getStrongComponents(obj)
        %getStrongComponents - Get the strong components of the graph
        %   The components are calculated using the transitive closure
        %   The components are stored in obj.Components
            obj.Components=[];   
            n=obj.NrOfNodes;
            tc=obj.TransitiveClosure;
            res=zeros(1,n); cnt=0;
            for u=1:n
                if ~res(u)
                    cnt=cnt+1;
                    idx = tc(u,:) & tc(:,u)';  
                    res(idx)=cnt;
                end
            end
            obj.Components=res;
            obj.NrOfComponents = max(res);
        end

        function buildKernel(obj)
        %buildKernel - Get the kernel graph adjacency matrix
        %   The kernel graph is obtained by collapsing each strongly connected component
        %   into a single node. The kernel graph is a DAG.
        %   The adjacency matrix of the kernel graph is stored in obj.kG
        %   The names of the kernel nodes are stored in obj.knodes
        %   The number of kernel nodes is equal to the number of components
        %    
            grps=obj.Components;
            ng=obj.NrOfComponents;
            [snodes,tnodes,vals]=find(obj.graph);
            tmp1=grps(snodes);
            tmp2=grps(tnodes);
            sol=find(tmp2-tmp1);
            obj.kG=sparse(tmp1(sol),tmp2(sol),vals(sol),ng,ng);
            % Get the names of the kernel nodes
            [~,jdx,idx]=unique(grps);
            cnames = obj.nodes(jdx);
            nrg = accumarray(idx,1);
            tmp = find(nrg>1);
            for i=1:length(tmp)
                cnames{tmp(i)}=['SC',num2str(i)];
            end
            obj.knodes=cnames;
        end
    end
        
    methods(Static,Access=private)
        function res=getNodeTable(A,names,groups)
        %getNodeTable - Build Node Table from adjacency matrix and groups.
        %   Input Arguments:
        %     A - Adjacency Matrix  
        %     names - Names of the internal nodes
        %     groups - Array with the group of each internal node
        %   Output Argument:
        %     res - Struct with fields Name and Group, representing the node table
        %
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

        function res=getEdgeTable(A,names)
        %getEdgeTable - Build Edge Table from adjacency matrix
        %   Input Arguments:
        %     A - Adjacency Matrix
        %     names - Names of the internal nodes
        %   Output Argument:
        %     res - Struct with fields Source, Target and Value, representing the edge table
        %
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

        function plot(nodes,edges,type)
        %plot - Plot a digraph from nodes and edges
        %   Input Arguments:
        %     nodes - Struct with fields Name and Group, representing the node table
        %     edges - Struct with fields Source, Target and Value, representing the edge table
        %
            cmap = hsv(max([nodes.Group])); % Color Definition
            endNodes=[{edges.Source};{edges.Target}]';
            values=[edges.Value]';
            TableNodes=struct2table(nodes);
            TableEdges=table(endNodes,values,'VariableNames',{'EndNodes','Weight'});
            colors=cmap(TableNodes.Group,:);
            if type
                msize=cType.KMARKER_SIZE; 
            else
                msize=cType.MARKER_SIZE;
            end
            dg=digraph(TableEdges,TableNodes);
            plot(dg,'NodeColor',colors,'MarkerSize',msize);
        end
    end
end