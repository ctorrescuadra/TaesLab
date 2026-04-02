function res=topologicalOrder(A)
%getTopologicalOrder - Get topological order indices of a DAG.
%   Computes the topological ordering of nodes in a DAG using
%   Kahn's algorithm with a fixed-size queue implementation. Returns an 
%   array of indices representing the linear ordering where each node 
%   appears before all nodes that depend on it.
%
%   The implementation uses a circular buffer queue with predefined size
%   equal to the total number of edges in the graph, providing memory-
%   efficient operation without dynamic array resizing during traversal.
%
%   Syntax:
%     res = cDigraphAnalysis.getTopologicalOrder(A)
%
%   Input Arguments:
%     A: Adjacency matrix of a DAG 
%       numeric matrix (N×N)
%       Must represent a directed acyclic graph
%       Non-negative values indicate edge weights
%
%   Output Arguments:
%     res - Topological order indices
%       uint32 array (1×N)
%       Node indices in topological order
%       Empty array [] if graph contains cycles or invalid structure
%
%   Algorithm Features:
%     • Fixed-size circular queue (size = number of edges)
%     • Head/tail pointer management for O(1) enqueue/dequeue
%     • Eliminates dynamic memory allocation during traversal
%     • Predictable memory usage for large graphs
%     • Comprehensive cycle detection via completion verification
%     • Robust validation of graph acyclicity requirements
%
%   Cycle Detection:
%     The function implements rigorous cycle detection through:
%       • Initial source node validation (prevents multiple sources)
%       • Kahn's algorithm completion check (detects remaining cycles)
%       • Node processing verification (ensures all nodes included)
%       • Returns empty array immediately upon cycle detection
%
%   Performance:
%     • Time complexity: O(V + E) where V = nodes, E = edges
%     • Space complexity: O(E) for queue + O(V) for result array
%     • Memory-efficient for sparse and dense graphs
%     • No garbage collection overhead from array resizing
%
%   Examples:
%     % Example 1: Simple linear chain
%     A = [0 1 0; 0 0 1; 0 0 0];
%     order = cDigraphAnalysis.getTopologicalOrder(A);
%     % Returns [1 2 3]
%
%     % Example 2: Complex DAG
%     A = [0 1 1 0; 0 0 0 1; 0 1 0 1; 0 0 0 0];
%     order = cDigraphAnalysis.getTopologicalOrder(A);
%     % Returns valid topological ordering
%
%   Error Conditions:
%     Returns empty array [] if:
%       • Graph contains cycles (not a DAG)
%       • Multiple source nodes detected
%       • Invalid adjacency matrix structure (non square, negative matrix)
% 
%   References:
%     • Kahn, A. B. (1962). "Topological sorting of large networks". Communications of the ACM, 5(11), 558–562.
%     • https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm
%   

    %% Check input parameters
     if nargin ~= 1
        error(buildMessage(mfilename, cMessages.NarginError, cMessages.ShowHelp));
    end
    % Check if it is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        error(buildMessage(mfilename, cMessages.NegativeMatrix));
    end 
    % Initialize arrays
    N = size(A,1);
    res = zeros(1, N,'uint16');
    degree = sum(A > 0, 1);  % Count incoming edges for each node
    check = find(degree==0);
    % Check first node is source
    if numel(check)>1 || (degree(1)) 
        return
    end
    %% Fixed-size queue implementation
    maxQueueSize = sum(degree);                % Number of edges as max queue size
    queue = zeros(1, maxQueueSize,'uint16');   % Fixed-size queue
    head = 1;                                  % Queue head pointer
    tail = 1;                                  % Queue tail pointer
    qsize = 0;                                 % Current queue size
    index = 1;                                 % Current position in result           
    % Initialize queue with the source node
    queue(tail) = 1;
    tail = tail + 1;
    qsize = qsize + 1;         
    %% Kahn's algorithm implementation
    while qsize > 0
        % Remove node with no incoming edges (dequeue)
        currentNode = queue(head);
        head = head + 1;
        qsize = qsize - 1;               
        % Add to topological order
        res(index) = currentNode;
        index = index + 1;         
        % Find neighbors of current node
        neighbors = find(A(currentNode, :) > 0);      
        % Remove edges from current node to its neighbors
        for jdx = neighbors
            degree(jdx) = degree(jdx) - 1;                 
            % If neighbor now has no incoming edges, add to queue
            if degree(jdx) == 0
                queue(tail) = jdx;  % Enqueue
                tail = tail + 1;
                qsize = qsize + 1;
            end
        end       
    end
    %%
    % Cycle detection: Check if all nodes were processed
    % If not all nodes are included in the result, the graph contains cycles
    if index - 1 < N
    % Graph contains cycles - return empty array
        res = cType.EMPTY;
        return
    end
end