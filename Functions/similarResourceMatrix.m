function B = similarResourceMatrix(A, x, y)
%similarResourceMatrix - Compute the resource-driven adjacency matrix from the demand-driven matrix.
%   Compute B(i,j) = (1/x(i)) * A(i,j) * y(j)
%
%   Syntax:
%     B = similarResourceMatrix(A,x,y)
%
%   Input Arguments:
%     A - Demand-Driven matrix
%     x - Left transformation vector
%     y - Right transformation vector
%
%   Output Arguments:
%     B - Resource-Driven matrix
%
%   Example:
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     x = [1; 2; 3];
%     y = [1; 3; 2];
%     B = similarResourceMatrix(A, x, y); %B = [0, 3.0, 0; 0, 0, 1.0; 0, 0, 0]
%
%   See also similarDemandOperator, similarResourceOperator

    % Check Input Arguments:
    if nargin < 2 || nargin > 3
        error('ERROR: similarResourceMatrix. Requires two or three input arguments');
    end
    if ~isnumeric(A) || ~ismatrix(A)
        error('ERROR: similarResourceMatrix. First argument must be a numeric matrix');
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
    % Compute matrix
    x=zerotol(x);
    ind=find(x);
    x(ind) = 1 ./ x(ind);
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
