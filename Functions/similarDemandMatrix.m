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
%   Example
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     x = [1; 2; 3];
%     y = [1; 3; 2];
%     B = similarDemandMatrix(A, x, y); %B = [0, 0.333, 0; 0, 0, 1.0; 0, 0, 0]
%
%   See also similarDemandOperator, similarResourceMatrix
%
    % Check Arguments
    if nargin < 2 || nargin > 3
        error('ERROR: similarDemandMatrix. Requires two or three input arguments');
    end
    if ~isnumeric(A) || ~ismatrix(A)
        error('ERROR: similarDemandMatrix. First argument must be a numeric matrix');
    end
    [n,m] = size(A);
    if (nargin==2)
            y=x;
    end
    if ~isvector(x) || length(x) ~= n
        error('ERROR: similarMatrix. Left vector must be compatible with matrix %d',n);
    end
    if ~isvector(y) || length(y) ~= m
        error('ERROR: similarMatrix. Right vector must be compatible with matrix %d',m);
    end
    % Compute Matrix
    y=zerotol(y);
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
