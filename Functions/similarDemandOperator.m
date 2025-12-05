function B = similarDemandOperator(A, x)
%similarDemandOperator - Convert resource-driven operator to demand-driven operator.
%   Computes the demand-driven operator from the resource-driven operator
%   using a similarity transformation with vector x. The transformation
%   preserves the diagonal elements of A.
%
%   Mathematical formula:
%     B(i,j) = x(i) * A(i,j) / x(j)  for i ≠ j
%     B(i,i) = A(i,i)                for diagonal elements
%
%   Matrix form:
%       B = D(x) * A * D(1/x)
%       where D(x) is a diagonal matrix with vector x on the diagonal
%
%   Special Cases:
%     - Zero elements in x: diagonal preserved (B(i,i) = A(i,i))
%     - Identity operator: transforms based on x ratios
%     - All zero x: returns original matrix A
%
%   Syntax:
%     B = similarDemandOperator(A, x)
%
%   Input Arguments:
%     A - Resource-driven operator (n x n square non-negative matrix)
%     x - Transformation vector (n x 1 or 1 x n, positive values)
%
%   Output Arguments:
%     B - Demand-driven operator (n x n square non-negative matrix)
%
%   Examples:
%     % Example 1: Basic transformation
%     A = [1, 1, 0; 0, 1, 1; 0, 0, 1];
%     x = [1; 2; 3];
%     B = similarDemandOperator(A, x);
%     % Returns: B = [1, 0.5, 0; 0, 1, 0.6667; 0, 0, 1]
%     % Note: Diagonal [1, 1, 1] is preserved
%
%     % Example 2: Verify diagonal preservation
%     A = eye(3) + [0 0.2 0.1; 0.3 0 0.2; 0.1 0.3 0];
%     x = [2; 3; 5];
%     B = similarDemandOperator(A, x);
%     diag(A)  % Original diagonal
%     diag(B)  % Same diagonal in B
%
%     % Example 3: Row vector input
%     A = [1, 0.5; 0.3, 1];
%     x = [2, 4];  % Row vector
%     B = similarDemandOperator(A, x);
%     % Returns: B = [1, 0.25; 0.6, 1]
%
%     % Example 4: Handle zero elements
%     A = [1, 0.2; 0, 1];
%     x = [0; 2];  % First element is zero
%     B = similarDemandOperator(A, x);
%     % Returns: B = [1, 0; 0, 1]
%     % Diagonal element B(1,1) = A(1,1) = 1 is preserved
%
%     % Example 5: Productive structure operator
%     % Resource-driven: columns sum to produce each process
%     % Demand-driven: rows sum to satisfy each demand
%     A = [0.5, 0.3, 0; 0.2, 0.4, 0.5; 0, 0.2, 0.3];
%     x = [1; 1.5; 2];
%     B = similarDemandOperator(A, x);
%
%   See also: similarResourceOperator, similarDemandMatrix, zerotol, isNonNegative
%

    % Validate input argument count
    if nargin ~= 2
        msg = buildMessage(mfilename, cMessages.NarginError, cMessages.ShowHelp);
        error(msg);
    end    
    % Validate A is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        msg = buildMessage(mfilename, cMessages.NonNegativeMatrixError);
        error(msg);
    end    
    n = size(A, 1); % Get matrix dimension
    % Validate transformation vector x
    if ~isnumeric(x) || ~isvector(x) || length(x) ~= n
        msg = buildMessage(mfilename, sprintf(cMessages.VectorLengthError, n));
        error(msg);
    end   
    % Convert to column vector if needed
    if isrow(x), x = x'; end   
    % Apply zero-tolerance filter to x and identify non-zero elements
    x = zerotol(x);
    ind = find(x); 
    % Compute reciprocal vector: y = 1./x for non-zero elements
    y = x;
    y(ind) = 1.0 ./ x(ind);   
    % Apply similarity transformation: B = (1/x * x) .* A
    % Broadcasting creates the transformation matrix y' * x (column × row)
    B = (x * y') .* A;   
    % Restore diagonal elements where x = 0 to preserve A(i,i)
    % This ensures diagonal invariance even when transformation is undefined
    if length(ind) < n      
        jnd = find(~x);                   % Find indices of zero elements       
        idx = sub2ind(size(A), jnd, jnd); % Convert to linear indices for diagonal elements        
        B(idx) = A(idx);                  % Restore original diagonal values
    end   
end
