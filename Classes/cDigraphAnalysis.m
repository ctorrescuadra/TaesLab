classdef cDigraphAnalysis < cMessageLogger
%cGraphAnalysys - Analize the connectivity of a SSR Graph
%   Calculate the transitive closure of the graph,
%   the strong conmponents of the graph, and the Kernel DAG.
%   
%   cGraphAnalysis methods:
%     isProductive - check if the SSR graph is productive
%     isReachable - check if two nodes are reacheable
%     isStrongConnected - chek if two nodes belong to the same component
%     showGraphComponents - show the components of the graph
%  
%
    properties(GetAccess=public,SetAccess=private)
      NrOfNodes          % Number of nodes in the graph
      NrOfComponents     % Number of components
      Components         % Array indicating the component each node in the graph belongs to
      TransitiveClosure  % Transitive closure of graph
      KernelEdges        % Eges of the kernel DAG
      GraphEdges         % Edges of the graph
      GraphNodes
      KernelNodes
      GroupsTable
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
        %   Input:
        %     G - Adjacency matriz of the graph
        %     names - Name of the nodes
        %
            % Check Inputs
            if ~isSquareMatrix(A)
                obj.printError(cType.ERROR,cMessages.NonSquareMatrix,size(A));
                return
            end
            if nargin<2 || isempty(names)
                names=arrayfun(@(x) sprintf('N%d',x),1:size(A,1),'UniformOutput',false);
            end
            if (~iscellstr(names) && ~isstring(names)) || numel(names)~=size(A,1)
                obj.printError(cMessages.InvalidNodeNames,numel(names),size(A,1));
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
            obj.Components = obj.getStrongComponents;
            obj.NrOfComponents = max(obj.Components);
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
            obj.buildGroupsTable;
        end

        function [res,src,out]=isProductive(obj)
        %isProductive - Indicates if the SSR graph is productive
        %   A graph is productive is all nodes are reachable from
        %   source and all nodes reach the sink node.
        %   
        %   Usage:
        %     [res,src,out]=obj.isProductive
        %   Output Arguments:
        %     res - true | false
        %     src - indexes of noded not reached by src
        %     out - indexes of nodes do not reach out
        %
            tc=obj.TransitiveClosure;
            idx=tc(1,:);
            jdx=tc(:,end);            
            res=all(idx) && all(jdx);
            if nargout==3
                src=find(~idx(2:end-1));
                out=find(~jdx(2:end-1));
            end
        end

        function res=isReachable(obj,u,v)
        %isReachable - Check if node u is reachable from v 
        %  Usage:
        %    res = obj.isReachable(u,v)
        %  Input Arguments:
        %    u - source node name
        %    v - target node name
        %  Output Argument:
        %    res - true | false
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
            kTable=full([obj.kG(2:end-1,2:end);...
                    obj.kG(1,2:end)]);
            kNodes=[obj.knodes(2:end-1),'ENV'];
        end

        function plotGraph(obj)
            cmap = hsv(obj.NrOfComponents); % Color Definition
            tmp=obj.GraphEdges;
            edges=[{tmp.Source};{tmp.Target}]';
            values=[tmp.Value]';
            TableEdges=table(edges,values,'VariableNames',{'EndNodes','Weight'});
            ind=[obj.GraphNodes.Group];
            colors=cmap(ind,:);
            dg=digraph(TableEdges);
            plot(dg,'NodeColor',colors);
        end

        function plotKernelGraph(obj)
            cmap = hsv(obj.NrOfComponents);
            tmp=obj.KernelEdges;
            edges=[{tmp.Source};{tmp.Target}]';
            values=[tmp.Value]';
            TableEdges=table(edges,values,'VariableNames',{'EndNodes','Weight'});
            ind=[obj.KernelNodes.Group];
            colors=cmap(ind,:);
            dg=digraph(TableEdges);
            plot(dg,'NodeColor',colors,'MarkerSize',6);
        end

        function res=showGroupsTable(obj)
            res=struct2table(obj.GroupsTable);
        end
    end

    methods(Access=private)
        function res=getStrongComponents(obj)
        %getGroups - Get the components of the graph
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
        end

        function buildKernel(obj)
        %buildKernel - Get the kernel graph adjacency matrix
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

        function buildGroupsTable(obj)
            tmp=obj.GraphNodes;
            names={tmp.Name};
            idx=[tmp.Group];
            groups=obj.knodes(idx);
            obj.GroupsTable=struct('Name',names,'Component',groups);
        end
    end
        
    methods(Static)
         function res=getNodeTable(A,names,groups)
            ng=max(groups);
            %Internal
            inames=names(2:end-1);
            igrp=groups(2:end-1);
            %Source
            [~,jdx]=find(A(1,2:end-1));
            snames=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            sgrp=ones(1,numel(jdx));
            %Output
            idx=find(A(2:end-1,end));
            tnames=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            tgrp=repmat(ng,1,numel(idx));
            %NodeTable
            names=[snames,inames,tnames];
            groups=[sgrp,igrp,tgrp];
            res=struct('Name',names,'Group',num2cell(groups));
        end

        function res=getEdgeTable(A,names)
            % Build Internal Edges
            [idx,jdx,ival]=find(A(2:end-1,2:end-1));
            isource=names(idx+1);
            itarget=names(jdx+1);
            % Build Resources Edges
            [~,jdx,vval]=find(A(1,2:end-1));
            vsource=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
            vtarget=names(jdx+1);
            % Build Output edges
            [idx,~,wval]=find(A(2:end-1,end));
            wtarget=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
            wsource=names(idx+1);
            % Build the Adjacency Matrix
            source=[vsource,isource,wsource];
            target=[vtarget,itarget,wtarget];
            values=[vval,ival',wval'];
            res=struct('Source',source,'Target',target,'Value',num2cell(values));
        end
    end
end