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
    if ~isnumeric(A) || ~ismatrix(A)
        msg=buildMessage(mfilename, cMessages.NonNumericalMatrixError);
        error(msg);
    end
    [n,m] = size(A);
    if (nargin==2)
        y=x;
    end
    if ~isnumeric(x) || ~isvector(x) || length(x) ~= n
        error(buildMessage(mfilename, cMessages.VectorLengthError));
    end
    if ~isnumeric(y) || ~isvector(y) || length(y) ~= m
        error(buildMessage(mfilename, cMessages.VectorLengthError));
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
