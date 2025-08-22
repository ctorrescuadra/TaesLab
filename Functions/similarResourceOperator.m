function B = similarResourceOperator(A, x)
%similarOperator - Compute the resource-driven operator from the demmand drive operator.
%   Compute B(i,j) = (1/x(i)) * A(i,j) * x(j), making sure the diagonal of A remains invariant.
%
%   Syntqx
%     B = similarResourceOperator(A,x)
%
%   Input Arguments
%     A - Demand-Driven Operator
%     x - Transformation vector
%
%   Output Arguments
%     B - Resource-Driven Operator

%   Example
%     A = [1, 0.5, 0; 0, 1, 0.6667; 0, 0, 1];
%     x = [1; 2; 3];
%     B = similarResourceOperator(A, x); %B = [1, 1, 0; 0, 1, 1; 0, 0, 1]
%
%   See also similarDemandOperator, similarResourceMatrix
%
    % Check Input Arguments
    if nargin < 2 || nargin > 2
        error('ERROR: similarOperator. Requires two input arguments');
    end
    if ~isNonNegativeMatrix(A)
        error('ERROR: similarOperator. First argument must be a non-negative square matrix');
    end
    m = size(A,2);
  
    if ~isvector(x) || length(x) ~= m
        error('ERROR: similarOperator. Tranformation vector must be compatible with operator matrix');
    end
    % Find null elements and compute 1/x
    if iscolumn(x), x = x'; end
    x=zerotol(x);
    ind=find(x);
    y=x; y(ind)=1./y(ind);
    % Compute Similar Operator
    B = (y' * x) .* A;
    % Restore diagonal of null elements
    if length(ind) < m
        jnd=find(~x);
        idx=sub2ind(size(A),jnd,jnd);
        B(idx)=A(idx);
    end 
end
