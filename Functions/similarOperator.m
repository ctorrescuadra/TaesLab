function B = similarOperator(A, x)
%similarOperator - Compute the resource-driven operator from the demmand drive operator
%   Compute B(i,j) = (1/x(i)) * A(i,j) * x(j), making sure the diagonal of A remains invaraint.
%   Usage:
%     B = similarOperator(A,x)
%   Input Arguments:
%     A - Demand-Driven Operator
%     x - Transformation vector
%   Output Arguments:
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
    if iscolumn(x)
        x = x';  % Ensure row vector
    end
    y=zeros(1,n);
    % Find not null elements
    ind=find(x); jnd=find(~x',1); 
    % Compute Similar Operator
    y(ind) = 1 ./x(ind);
    B = (y' * x) .* A;
    % Restore diagonal of null elements
    if ~isempty(jnd)
        idx=sub2ind(size(A),jnd,jnd);
        B(idx)=A(idx);
    end 
end
