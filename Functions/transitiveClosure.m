function res = transitiveClosure(A)
%transitiveClosure - Compute the transitive closure of a directed graph.
%     Computes the transitive closure of a directed graph using the Floyd-Warshall
%     algorithm. The transitive closure represents the reachability relation: 
%     res(i,j) is true if and only if there exists a directed path from vertex i 
%     to vertex j (including paths of length 0, i.e., i=j).
%     The algorithm has O(n³) time complexity and O(n²) space complexity, making
%     it efficient for small to medium-sized graphs. For large sparse graphs,
%     consider using specialized graph libraries.
%     Applications include determining connectivity, reachability, and
%   dependency analysis in networked systems.
%
%   Syntax:
%     res = transitiveClosure(A)
%
%   Input Arguments:
%     A - Adjacency matrix of the directed graph (n x n)
%         Can be numeric or logical, sparse or dense
%
%   Output Arguments:
%     res - Transitive closure (reachability) matrix (n x n logical)
%           res(i,j) = true if there exists a path from node i to node j
%           res(i,i) = true for all i (reflexive closure)
%
%   Examples:
%     % Example 1: Simple chain (A→B→C)
%     A = [0 1 0; 0 0 1; 0 0 0];
%     res = transitiveClosure(A);
%     % Returns: [1 1 1; 0 1 1; 0 0 1]
%     % Node 1 can reach all nodes, Node 2 can reach 2 and 3, Node 3 only itself
%
%     % Example 2: Cycle graph
%     A = [0 1 0; 0 0 1; 1 0 0];
%     res = transitiveClosure(A);
%     % Returns: [1 1 1; 1 1 1; 1 1 1]
%     % All nodes can reach all nodes due to cycle
%
%     % Example 3: Disconnected graph
%     A = [0 1 0 0; 0 0 0 0; 0 0 0 1; 0 0 0 0];
%     res = transitiveClosure(A);
%     % Returns: [1 1 0 0; 0 1 0 0; 0 0 1 1; 0 0 0 1]
%     % Two separate components: {1,2} and {3,4}
%
%     % Example 4: Diamond structure
%     A = [0 1 1 0; 0 0 0 1; 0 0 0 1; 0 0 0 0];
%     res = transitiveClosure(A);
%     % Returns: [1 1 1 1; 0 1 0 1; 0 0 1 1; 0 0 0 1]
%
%     % Example 5: Sparse matrix input
%     A = sparse([0 1 0; 0 0 1; 0 0 0]);
%     res = transitiveClosure(A);  % Returns dense logical matrix
%
%   Algorithm (Floyd-Warshall):
%     1. Initialize: Convert adjacency matrix to logical
%     2. For each intermediate node k:
%        - Update res(i,j) = res(i,j) OR (res(i,k) AND res(k,j))
%        - This adds all paths that go through k
%     3. Add self-loops: res(i,i) = true for all i (reflexive property)
%
%   See also: isSquareMatrix, logicalMatrix, graph, digraph
%
%   References:
%     - Floyd, R. W. (1962). "Algorithm 97: Shortest Path"
%     - Warshall, S. (1962). "A theorem on Boolean matrices"
%     - https://en.wikipedia.org/wiki/Floyd-Warshall_algorithm
%

    % Validate input argument count
    if nargin ~= 1
        msg = buildMessage(mfilename, cMessages.NarginError, cMessages.ShowHelp);
        error(msg);
    end   
    % Validate matrix is square
    if ~isSquareMatrix(A)
        msg = buildMessage(mfilename, cMessages.SquareMatrixError);
        error(msg);
    end   
    % Convert sparse to dense (required for logical operations)
    if issparse(A)
        res = full(A);
    else
        res = A;
    end   
    % Convert to logical matrix (handles zero tolerance)
    if ~islogical(res)
        res = logicalMatrix(res);
    end
    % Floyd-Warshall algorithm for transitive closure
    % For each intermediate vertex k, check if path i→k→j exists
    n = size(A, 1);
    for k = 1:n
        % Update reachability: can reach j from i if either:
        % - Direct path i→j exists, OR
        % - Path i→k exists AND path k→j exists
        res = res | (res(:, k) & res(k, :));
    end  
    % Add reflexive closure (every node can reach itself)
    res = eye(n) | res;  
end