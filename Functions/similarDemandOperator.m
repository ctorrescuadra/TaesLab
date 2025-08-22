function B = similarDemandOperator(A, x)
%similarOperator - Compute the demand-driven operator from the resource-drive operator.
%   Compute B(i,j) = x(i) * A(i,j) * (1./x(j)), making sure the diagonal of A remains invariant.
%
%   Syntax
%     B = similarResourceOperator(A,x)
%
%   Input Arguments
%     A - Resource-Driven Operator
%     x - Transformation vector
%
%   Output Arguments
%     B - Demand-Driven Operator
%
%   Example
%     A = [1, 1, 0; 0, 1, 1; 0, 0, 1];
%     x = [1; 2; 3];
%     B = similarDemandOperator(A, x); %B = [1, 0.5, 0; 0, 1, 0.667; 0, 0, 1]
%
%   See also similarDemandMatrix, similarResourceOperator
%
    % Check Input Arguments
    if nargin < 2 || nargin > 2
        error('ERROR: similarOperator. Requires two input arguments');
    end
    if ~isNonNegativeMatrix(A)
        error('ERROR: similarOperator. First argument must be a square non-negative matrix');
    end
    n=size(A,1);
    if ~isvector(x) || length(x) ~= n
        error('ERROR: similarOperator. Transformation vector must be compatible with matrix %d', size(A, 1));
    end
    % Find null elements and compute 1/x
    if isrow(x), x = x'; end
    x=zerotol(x);
    ind=find(x); 
    y=x; y(ind)=1./x(ind);
    % Compute Similar Operator
    B = (x * y') .* A;
    % Restore diagonal of null elements
    if length(ind) < n
        jnd=find(~x);
        idx=sub2ind(size(A),jnd,jnd);
        B(idx)=A(idx);
    end 
end
