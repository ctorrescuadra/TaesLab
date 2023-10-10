function res=bfs(G,s)
% BFS - Bread First Search algorithm
%   Perform a BFS of the graph G starting in node s
%   USAGE:
%       res = bfs(G, s)
%   INPUT:
%       G - Adjacency matrix of the graph
%       s - starting point
%   OUTPUT:
%       res - logical vector indicating the visiting nodes starting in s
%
    log=cStatus(cType.VALID);
    res=[];
    sz=size(G);
    % Check parameters
    if sz(1)~=sz(2)
        log.printError('The imput matrix must be square');
        return
    end
    N=sz(1);
    if ~isnumeric(s) || ~isscalar(s) || (s<1) || (s>N)
        log.printError('Invalid search node');
        return
    end
    res=false(1,N);
    stack=cStack(N);
    % make bfs starting on the s nodes
    res(s)=true;
    stack.push(s);
    while ~stack.isempty
	    v=stack.pop;
	    [~,idx]=find(G(v,:));
        for w=idx
            if ~res(w) 
			    stack.push(w);
			    res(w)=true;
            end
        end
    end
end