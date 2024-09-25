function res=transitiveClosure(A)
% transitiveClosure - Compute the transitive closure of a digraph
%   Use the Warshall's Algorithm
% Input Arguments
%   A - Adjacency matrix of the digraph
% Output Arguments
%   res - Connectivity matrix
%
    res=A;
    idx=1:size(A,1);
    for k = idx
        res = res | (res(:, k) * res(k, :));
    end
end