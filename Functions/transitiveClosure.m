function res=transitiveClosure(A)
%transitiveClosure - Compute the transitive closure of a digraph.
%   Use the Floyd - Warshall's Algorithm
%
%   Syntax:
%     res = transitiveClosure(A)
% 
%   Input Arguments:
%     A - Adjacency matrix of the digraph
%
%   Output Arguments:
%     res - Connectivity matrix
%           res(i,j) = 1 if there is a path from node i to node j
%
%   Example:
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     res = transitiveClosure(A); %res = [1, 1, 1; 0, 1, 1; 0, 0, 1]
%
%   See also isSquareMatrix, logicalMatrix
%
%   References
%     - https://www.geeksforgeeks.org/dsa/transitive-closure-of-a-graph/

    % Check Input
    if nargin ~= 1
        msg=buildMessage(mfilename, cMessages.NarginError,cMessages.ShowHelp);
        error(msg);
    end
    if ~isSquareMatrix(A)
        msg=buildMessage(mfilename, cMessages.SquareMatrixError);
        error(msg);
    end
    if issparse(A)
        res=full(A);
    else
        res=A;
    end
    % Convert to logical matrix
    if ~islogical(res), res=logicalMatrix(res); end
    % Floyd - Warshall's Algorithm
    for k = 1:size(A,1)
        res = res | (res(:, k) * res(k, :));
    end
    res = eye(size(A)) | res;
end