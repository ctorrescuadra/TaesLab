function [visited, index] = bfs(A, src)
%BFS Breadth-first search traversal on a graph
%   Performs a breadth-first search (BFS) traversal on a graph represented
%   as an adjacency matrix A, starting from a given source node.
%   It used an algebraic approach for sparse matrices based on 
%   sparse matrix-vector multiplications
%
%   Syntax:
%     [visited, index] = bfs(A, source)
%
%   Input Arguments:
%     A       - Adjacency matrix (n x n) representing the graph
%     source  - Source node index (1 to n) from which to start the search
%
%   Output Arguments:
%     visited - Logical vector (1 x n) indicating which nodes were visited
%     index   - Number of BFS levels; Inf if not all nodes are reachable
%
%   See also: dfs
%
%   Check input parameters
    try
        narginchk(1, 2);
    catch ME
        error(buildMessage(mfilename, ME.message, cMessages.ShowHelp));
    end
    % Check if it is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        error(buildMessage(mfilename, cMessages.NegativeMatrix));
    end
    %Check source index
    n = size(A, 1);
    if ~all(ismember(src,1:n)) 
        error(buildMessage(mfilename, cMessages.InvalidTableIndex));
    end
    % Convert to logical matrix (handles zero tolerance)
    if ~islogical(A)
    A = logicalMatrix(A);
    end
    % Convert to sparse matrix
    if ~issparse(A)
        A=sparse(A);
    end
    % Initialize visited and current level nodes as logical vectors
    visited = false(1, n);
    current = false(1, n);    
    % Mark source node as visited and set as current level
    visited(src) = true;
    current(src) = true;
    index = 0;    
    % BFS loop: process each level of the graph
    while any(current)
        % Sparse matrix multiplication to find neighbors of current level nodes    
        % Filter out already visited nodes
        current = (current * A) & ~visited;       
        visited = visited | current;  % Update visited nodes with newly discovered nodes     
        index = index + 1;   % Increment BFS level counter
    end   
    % If not all nodes are visited, set index to Inf (disconnected graph)
    if nargout==2
        if all(visited), index = index-1;else, index=Inf; end
    end
end
