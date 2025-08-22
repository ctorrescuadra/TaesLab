function res=transitiveClosure(A)
%transitiveClosure - Compute the transitive closure of a digraph.
%   Use the Floyd - Warshall's Algorithm
%
%   Syntax
%     res = transitiveClosure(A)
% 
%   Input Arguments
%     A - Adjacency matrix of the digraph
%
%   Output Arguments
%     res - Connectivity matrix
%           res(i,j) = 1 if there is a path from node i to node j
%
%   Example
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     res = transitiveClosure(A); %res = [1, 1, 1; 0, 1, 1; 0, 0, 1]
%
%   See also isSquareMatrix, logicalMatrix
%
%   References
%     - https://www.geeksforgeeks.org/dsa/transitive-closure-of-a-graph/
%
    % Check Input
    if nargin ~= 1
        error('ERROR: transitiveClosure. Requires one input argument');
    end
    if ~isSquareMatrix
        error('ERROR: transitiveClosure. Input must be a square matrix');
    end
    if issparse(A)
        res=full(A);
    else
        res=A;
    end
    if ~islogical(res), res=logicalMatrix(res); end
    % Floyd - Warshall's Algorithm
    for k = 1:size(A,1)
        res = res | (res(:, k) * res(k, :));
    end
    res = eye(size(A)) | res;
end