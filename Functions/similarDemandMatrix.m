function B = similarDemandMatrix(A, x, y)
%similarDemandMatrix - Compute the demand-driven adjacency matrix from the resource-driven matrix.
%   Compute B(i,j) = x(i) * A(i,j) * (1./y(j)) for sparse matrices
%
%   Syntax:
%     B = similarDemandMatrix(A,x,y)
%
%   Input Arguments:
%     A - Resource-Driven matrix
%     x - Left transformation vector
%     y - Right transformation vector
%
%   Output Arguments:
%     B - Demand-Driven Operator
%
%   Example:
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     x = [1; 2; 3];
%     y = [1; 3; 2];
%     B = similarDemandMatrix(A, x, y); %B = [0, 0.333, 0; 0, 0, 1.0; 0, 0, 0]
%
%   See also similarDemandOperator, similarResourceMatrix

    % Check Arguments:
    try 
        narginchk(2,3) 
    catch ME
        msg=buildMessage(mfilename, ME.message);
        error(msg);
    end
    if ~isnumeric(A) || ~ismatrix(A)
        msg=buildMessage(mfilename, cMessages.NonNumericalMatrixError);
        error(msg);
    end
    [n,m] = size(A);
    if (nargin==2)
            y=x;
    end
    if ~isnumeric(x) || ~isvector(x) || length(x) ~= n
        msg=buildMessage(mfilename, cMessages.VectorLengthError);
        error(msg);
    end
    if ~isnumeric(y) || ~isvector(y) || length(y) ~= m
        msg=buildMessage(mfilename, cMessages.VectorLengthError);
        error(msg);
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
