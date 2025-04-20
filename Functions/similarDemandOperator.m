function B = similarDemandOperator(A, x)
%similarOperator - Compute the demand-driven operator from the resource-drive operator
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
    % Check Arguments
    [n,m] = size(A);
    if m ~= n
        error('ERROR: similarOperator. Matrix must be square');
    end
    if length(x) ~= m
        error('ERROR: similarOperator. Tranformation vector must be compatible with operator matrix');
    end
    % Find null elements and compute 1/x
    if isrow(x), x = x'; end
    ind=find(~x,1);
    y=1./x; y(ind)=0;
    % Compute Similar Operator
    B = (x * y') .* A;
    % Restore diagonal of null elements
    if ~isempty(ind)
        idx=sub2ind(size(A),ind,ind);
        B(idx)=A(idx);
    end 
end
