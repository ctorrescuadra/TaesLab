function res=dfs(G,s)
%DFS - Depth-First Search traversal of a digraph
%   Performs a depth-first search traversal of a graph represented by an
%   adjacency matrix, starting from a specified node.
%
%   Usage:
%       res = dfs(G,s)
%
%   Input Arguments:
%       G - Square adjacency matrix (numeric or logical)
%           Represents the graph where G(i,j) = 1 indicates an edge from 
%           node i to node j. Must be a square matrix of size N×N where N 
%           is the number of nodes.
%
%       s - Starting node index (integer, optional)
%           Must be in range [1, N] where N is the number of nodes.
%           Default: 1 if not specified.
%
%   Output Arguments:
%       res - Logical array of size 1×N
%             RES(i) = true if node i was visited during the traversal,
%             false otherwise. Returns cType.EMPTY if input validation fails.
%
%   Algorithm:
%       Uses an iterative stack-based implementation of depth-first search
%       The algorithm:
%       1. Initializes a stack with the starting node
%       2. Marks the starting node as visited
%       3. While stack is not empty:
%          - Pops a node from the stack
%          - For each unvisited neighbor, pushes it to stack and marks visited
%
%   Examples:
%       % Simple 4-node graph: 1->2, 2->3, 1->4
%       G = [0 1 0 1; 0 0 1 0; 0 0 0 0; 0 0 0 0];
%       visited = dfs(G, 1);  % Returns [true true true true]
%
%       % Disconnected graph
%       G = [0 1 0 0; 0 0 0 0; 0 0 0 1; 0 0 0 0];
%       visited = dfs(G, 1);  % Returns [true true false false]
%       visited = dfs(G, 3);  % Returns [false false true true]
%
%       % Invalid input
%       visited = dfs([1 2; 3], 1);  % Returns cType.EMPTY (not square)
%       visited = dfs(eye(3), 5);    % Returns [false false false] (invalid start)
%
%   See Also:
%       isSquareMatrix, transitiveClosure
%
%   Notes:
%       - Self-loops (diagonal elements) are allowed but don't affect traversal
%       - Time complexity: O(V + E) where V = nodes, E = edges
%       - Space complexity: O(V) for the stack and visited array
%
%   Dependencies:
%       Requires isSquareMatrix function for input validation
%       Requires cType class for empty return value

    %% Input Validation
    try
        narginchk(1, 2);
    catch ME
        error(buildMessage(mfilename, ME.message, cMessages.ShowHelp));
    end
    % Check if it is a square non-negative matrix
    if ~isNonNegativeMatrix(G)
        error(buildMessage(mfilename, cMessages.NegativeMatrix));
    end
    % Get number of nodes in the graph 
    N = size(G, 1); 
    % Convert to logical matrix (handles zero tolerance)
    if ~islogical(G)
    G = logicalMatrix(G);
    end
    % Initialize result array: false means unvisited, true means visited
    res = false(1, N);   
    %% Parameter Processing
    % Use node 1 as default starting point if not specified
    if nargin == 1
        s = 1;
    end    
    % Validate starting node is within valid range [1, N]
    if ~ismember(s, 1:N)
        return;  % Return all false if starting node is invalid
    end    
    %% Algorithm Initialization
    % Create stack using int16 for memory efficiency with large graphs
    stack = int16(N);   % Pre-allocate stack with maximum possible size
    cnt = 1;            % Stack counter (top of stack index)
    stack(cnt) = s;     % Push starting node onto stack
    res(s) = true;      % Mark starting node as visited   
    %% Depth-First Search Main Loop
    while cnt > 0
        % Pop node from stack
        v = stack(cnt); 
        cnt = cnt - 1;    
        % Find all neighbors of current node v
        [~, idx] = find(G(v, :));  % Get column indices where G(v,j) is non-zero      
        % Process each neighbor
        for w = idx
            % Only visit unvisited nodes to avoid cycles
            if ~res(w)
                % Push unvisited neighbor onto stack
                cnt = cnt + 1;
                stack(cnt) = w;            
                % Mark neighbor as visited immediately when pushed
                % This prevents duplicate entries in the stack
                res(w) = true;
            end
        end
    end
end