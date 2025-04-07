function B = similarDemandMatrix(A, x, y)
%similarMatrix - Compute the demand-driven sparse adjacency matrix from the resource-driven matrix
%   Compute B(i,j) = x(i) * A(i,j) * (1./y(j)) for sparse matrices
%   Usage:
%     B = similarDemandMatrix(A,x,y)
%   Input Arguments:
%     A - Resource-Driven matrix
%     x - Left transformation vector
%     y - Right transformation vector
%   Output Arguments:
%     B - Demand-Driven Operator
%
    % Check Matrix
    [n,m] = size(A);
    if (nargin==2)
            y=x;
    end
    if length(x) ~= n
        error('ERROR: similarMatrix. Left vector must be compatible with matrix %d',n);
    end
    if length(y) ~= m
        error('ERROR: similarMatrix. Right vector must be compatible with matrix %d',m);
    end
    ind=find(y);
    y(ind) = 1 ./ y(ind);
    if issparse(A)
        if isrow(x), x = x'; end
        if isrow(y), y = y'; end
        [i,j,val]=find(A);
        tmp= x(i) .* val .* y(j);
        B = sparse(i,j,tmp,n,m);
    else
        B=diag(x)*A*diag(y);
    end
end
