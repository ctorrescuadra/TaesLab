function res=transitiveClosure(A)
%transitiveClosure - Compute the transitive closure of a digraph
%   Use the Warshall's Algorithm
%
%   Syntax
%     res = transitiveClosure(A)
% 
%   Input Arguments
%     A - Adjacency matrix of the digraph
%
%   Output Arguments
%     res - Connectivity matrix
%
    res=A;
    for k = 1:size(A,1)
        res = res | (res(:, k) * res(k, :));
    end
    res = eye(size(A)) | res;
end