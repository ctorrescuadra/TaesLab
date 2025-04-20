function B = similarResourceOperator(A, x)
%similarOperator - Compute the resource-driven operator from the demmand drive operator
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
    % Check Mattrix
    [n,m] = size(A);
    if m ~= n
        error('ERROR: similarOperator. Matrix must be square');
    end
    if length(x) ~= m
        error('ERROR: similarOperator. Tranformation vector must be compatible with operator matrix');
    end
    % Find null elements and compute 1/x
    if iscolumn(x), x = x'; end 
    ind=find(~x',1);
    y=1./x; y(ind)=0;
    % Compute Similar Operator
    B = (y' * x) .* A;
    % Restore diagonal of null elements
    if ~isempty(ind)
        idx=sub2ind(size(A),ind,ind);
        B(idx)=A(idx);
    end 
end
