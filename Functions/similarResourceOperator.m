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
%
    % Check Matrix
    [n,m] = size(A);
    if m ~= n
        error('ERROR: similarOperator. Matrix must be square');
    end
    if length(x) ~= m
        error('ERROR: similarOperator. Tranformation vector must be compatible with operator matrix');
    end
    % Find null elements and compute 1/x
    if iscolumn(x), x = x'; end 
    ind=find(x);
    y=x; y(ind)=1./y(ind);
    % Compute Similar Operator
    B = (y' * x) .* A;
    % Restore diagonal of null elements
    if length(ind) < n
        jnd=find(~x);
        idx=sub2ind(size(A),jnd,jnd);
        B(idx)=A(idx);
    end 
end
