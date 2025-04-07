function B = similarResourceMatrix(A, x, y)
%similarMatrix - Compute the resource-driven sparse adjacency matrix from the demand-driven matrix
%   Compute B(i,j) = (1/x(i)) * A(i,j) * y(j) for sparse matrices
%   Usage:
%     B = similarResourceMatrix(A,x,y)
%   Input Arguments:
%     A - Demand-Driven matrix
%     x - Left transformation vector
%     y - Right transformation vector
%   Output Arguments:
%     B - Resource-Driven Operator
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
    ind=find(x);
    x(ind) = 1 ./ x(ind);
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
