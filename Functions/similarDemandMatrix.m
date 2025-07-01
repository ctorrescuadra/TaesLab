function B = similarDemandMatrix(A, x, y)
%similarDemandMatrix - Compute the demand-driven adjacency matrix from the resource-driven matrix.
%   Compute B(i,j) = x(i) * A(i,j) * (1./y(j)) for sparse matrices
%
%   Syntax
%     B = similarDemandMatrix(A,x,y)
%
%   Input Arguments
%     A - Resource-Driven matrix
%     x - Left transformation vector
%     y - Right transformation vector
%
%   Output Arguments
%     B - Demand-Driven Operator
%
    % Check Arguments
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
    % Compute Matrix
    ind=find(y);
    y(ind) = 1 ./ y(ind);
    if issparse(A)
        if isrow(x), x = x'; end
        if isrow(y), y = y'; end
        [i,j,val]=find(A);
        tmp= x(i) .* val .* y(j);
        B = sparse(i,j,tmp,n,m);
    else
        if isrow(x), x = x'; end
        if iscolumn(y), y = y'; end
        B= (x * y) .* A;
    end
end
