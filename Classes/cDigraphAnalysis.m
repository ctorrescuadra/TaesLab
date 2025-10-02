classdef cDigraphAnalysis < cMessageLogger
%cDigraphAnalysis - Analyze a directed graph (digraph).
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
%     getComponentNames   - get the processes groups names 
%     getKernelInfo       - get Kernel DAG matrix and node names
%     getGroupsInfo       - get the groups info structure
%     plot                - plot the digraph info
%
    properties(GetAccess=public,SetAccess=private)
      NrOfNodes          % Number of nodes in the graph
      NrOfComponents     % Number of components
      GraphEdges         % Edges of the graph
      GraphNodes         % Nodes of the graph      
      KernelNodes        % Nodes of the kernel DAG
      KernelEdges        % Edges of the kernel DAG
      isDAG              % Indicate if the graph is a DAG 
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
        %cDigraphAnalysis - Construct an instance of this class
        %   Usage:
        %     obj = cGraphAnalysis(G,names)
        %   Input Arguments :
        %     G - Adjacency matriz of the graph
        %     names - Name of the nodes
        %   Output Argument:
        %     obj - cDigraphAnalysis object
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

            % Initialize variables
            obj.graph = cDigraphAnalysis.tfp2ssr(A);
            obj.nodes = ['IN',names(1:end-1),'OUT'];
            obj.NrOfNodes = numel(obj.nodes);
            % Calculate properties
	        obj.tc = transitiveClosure(obj.graph);
            obj.getStrongComponents;
            obj.GraphEdges=cDigraphAnalysis.getEdgesTable(obj.graph,obj.nodes);
            obj.GraphNodes=cDigraphAnalysis.getNodesTable(obj.graph,obj.nodes,obj.comps);
            obj.isDAG=(obj.NrOfComponents == obj.NrOfNodes);
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
            s=obj.tc(1,:);
            t=obj.tc(:,end);            
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
                res = obj.tc(vdx,udx);
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
                res = (obj.comps(udx) == obj.comps(vdx));
            end
        end

        function [kA,kNames]=getKernelInfo(obj)
        %getKernelInfo - Get the Kernel Table information
        %   Syntax:
        %     [kA,kNames] = obj.getKernelInfo()
        %   Output Parameters:
        %     kA - Kernel Table (FP Table format)
        %     kNames - Kernel Names (FP table format)
        % 
            kA=cDigraphAnalysis.ssr2tfp(full(obj.kG));
            kNames=[obj.kNodes(2:end-1) 'ENV'];
        end

        function res=getGroupsInfo(obj)
        %getComponets - Build the Node Groups table
        %   Output Argument:
        %     res - Node Name/Group strcture 
        %
            tmp=obj.GraphNodes;
            names={tmp.Name};
            idx=[tmp.Group];
            grps=obj.kNodes(idx);
            res=struct('Name',names,'Group',grps);
        end

        function res=getComponentNames(obj)
        %getComponentNames
            idx=obj.comps(2:end-1);
            res=obj.kNodes(idx);
        end

        %%%%
        % Plot function
        %%%%
        function plot(obj,option,text)
        % plot - plot the digraph
        %   Usage:
        %     obj.plot(option,title)
        %   Input Parameters
        %     option - type of digraph
        %      cType.DigraphType.GRAPH (Full graph without weigth)
        %      cType.DigraphType.KERNEL (Kernel graph without weigth)
        %      cType.DigraphType.GRAPH_WEIGHT (Full graph with weigth)
        %      cType.DigraphType.KERNEL_WEIGHT (Kernel graph with weigth)
        %     text - char array with the title of the digraph
        %
            % Initialize variables
            DEFAULT_TITLE='Digraph Analysis';
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
            else
                markerSize=cType.MARKER_SIZE;
                Nodes=obj.GraphNodes;
                Edges=obj.GraphEdges;
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
                    'NodeColor',Categories,'MarkerSize',markerSize,'Interpreter','none');
                colormap(red2blue);
			    colorbar();
            else
                plot(dg,'NodeColor',Categories,'MarkerSize',markerSize,'Interpreter','none');
            end
            title(text,'fontsize',12);
        end
    end

    methods(Access=private)
        function getStrongComponents(obj)
        %getStrongComponents - Get the strong components of the graph
        %   The components are calculated using the transitive closure
        %   The components are stored in obj.comps
        %   The name of strong components are stores in kNodes
        %
            % Calculate Strong Components
            n=obj.NrOfNodes;
            res=zeros(1,n); cnt=0;
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
        %   The output parameters are optional, if provided, Kernel matrix and nodes 
        %   are obtained in FP Table format
        %   Usage:
        %     obj.getKernelTable()
        %     [kA,kNames]=obj.getKernelTable
        %   Output Arguments:
        %     kA: Kernel Matrix in FP Table format
        %     kNames: Names of the kernel processes (FP Table format)
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
        %   Usage:
        %     res=cDigraphAnalysis.getNodeTable(A,names)
        %   Input Arguments:
        %     A - Adjacency Matrix in SSR format 
        %     names - Names of the internal nodes
        %     groups - Array with the group of each node
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

        function res=getEdgesTable(A,names)
        %getEdgesTable - Build Edge Table from adjacency matrix
        %   Usage:
        %     res=cDigraphAnalysis.getEdgesTable(A,names)
        %   Input Arguments:
        %     A - Adjacency Matrix in SSR format
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

        function G=tfp2ssr(A)
        % Tranform a Table FP into a SSR adjacency Matrix
        %   Usage:
        %     G=tfp2ssr(A)
        %   Input Argument:
        %     A: Table FP
        %   Output Argument
        %     G: Incidence matrix in SSR format
        %
            N=size(A,1);
			G=[0 A(end,:);...
			   zeros(N-1,1) A(1:end-1,:);...
			   0 zeros(1,N)];
        end

        function A=ssr2tfp(G)
        % Transform a SSR adjacency matrix into Table FP
        %   Usage:
        %     G=tfp2ssr(A)
        %   Input Argument:
        %     G: Incidence matrix in SSR format        
        %   Output Argument
        %     A: Table FP
        %
            A=[G(2:end-1,2:end);...
               G(1,2:end)];
        end
    end
end