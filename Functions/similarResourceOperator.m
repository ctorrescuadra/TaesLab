function B = similarResourceOperator(A, x)
%similarResourceOperator - Compute resource-driven operator from demand-driven operator.
%   Computes the demand-driven operator from the resource-driven operator
%   using a similarity transformation with vector x. The transformation
%   preserves the diagonal elements of A.
%
%   Mathematical formula:
%     B(i,j) = x(j) * A(i,j) / x(i)  for i ≠ j
%     B(i,i) = A(i,i)                for diagonal elements
%
%   Matrix form:
%       B = D(1/x) * A * D(x)
%       where D(x) is a diagonal matrix with vector x on the diagonal
%
%   Special Cases:
%     - Zero elements in x: diagonal preserved (B(i,i) = A(i,i))
%     - Identity operator: transforms based on x ratios
%     - All zero x: returns original matrix A
%
%   Syntax:
%     B = similarResourceOperator(A, x)
%
%   Input Arguments:
%     A - Demand-driven operator (n x n square non-negative matrix)
%     x - Transformation vector (n x 1 or 1 x n, positive values)
%
%   Output Arguments:
%     B - resource-driven operator (n x n square non-negative matrix)
%
%   Examples:
%     % Example 1: Basic operator transformation
%     A = [1, 0.5, 0; 0, 1, 0.6667; 0, 0, 1];
%     x = [1; 2; 3];
%     B = similarResourceOperator(A, x);
%     % B = [1, 1, 0; 0, 1, 1; 0, 0, 1]
%     % B(1,2) = A(1,2)*x(2)/x(1) = 0.5*2/1 = 1
%     % B(2,3) = A(2,3)*x(3)/x(2) = 0.6667*3/2 = 1
%
%     % Example 2: Identity operator transformation
%     A = eye(3);
%     x = [1; 2; 4];
%     B = similarResourceOperator(A, x);
%     % B = [1, 0, 0; 0, 1, 0; 0, 0, 1]
%     % Identity diagonal preserved regardless of x
%
%     % Example 3: Zero elements in transformation vector
%     A = [1, 0.5, 0.25; 0, 1, 0.5; 0, 0, 1];
%     x = [2; 0; 4];
%     B = similarResourceOperator(A, x);
%     % B = [1, 0, 0.5; 0, 1, 0; 0, 0, 1]
%     % B(2,2) = A(2,2) = 1 (preserved due to x(2) = 0)
%     % B(1,3) = A(1,3)*x(3)/x(1) = 0.25*4/2 = 0.5
%
%     % Example 4: Upper triangular operator
%     A = [1, 2, 3; 0, 1, 4; 0, 0, 1];
%     x = [1; 2; 2];
%     B = similarResourceOperator(A, x);
%     % B = [1, 4, 6; 0, 1, 4; 0, 0, 1]
%     % Off-diagonal elements scaled by x ratios
%
%     % Example 5: Full operator matrix
%     A = [1, 0.3, 0.2; 0.1, 1, 0.4; 0.05, 0.15, 1];
%     x = [1; 3; 2];
%     B = similarResourceOperator(A, x);
%     % B = [1, 0.9, 0.4; 0.033, 1, 0.267; 0.025, 0.225, 1]
%     % Full matrix transformation with preserved diagonal
%
%     % Example 6: Row vector (automatically converted)
%     A = [1, 0.5; 0, 1];
%     x = [2, 4];        % Row vector
%     B = similarResourceOperator(A, x);
%     % B = [1, 1; 0, 1]
%     % Vector automatically oriented correctly
%
%   See also:
%     similarDemandOperator, similarResourceMatrix, zerotol, isNonNegative
%

    % Validate input arguments: exactly 2 arguments required
    try
        narginchk(2, 2);
    catch ME
        msg = buildMessage(mfilename, ME.message);
        error(msg);
    end
    
    % Validate matrix A: must be square, non-negative matrix
    if ~isNonNegativeMatrix(A)
        msg = buildMessage(mfilename, cMessages.NonNegativeMatrixError);
        error(msg);
    end
    if ~isSquareMatrix(A)
        msg = buildMessage(mfilename, cMessages.SquareMatrixError);
        error(msg);
    end
    m = size(A, 2); % Get matrix dimension
    
    % Validate transformation vector x
    if ~isnumeric(x) || ~isvector(x) || length(x) ~= m
        msg = buildMessage(mfilename, cMessages.VectorLengthError);
        error(msg);
    end
    % Convert to row vector for broadcasting
    if iscolumn(x), x = x'; end 
    % Apply zero-tolerance filter to x and identify non-zero elements
    x = zerotol(x);
    ind = find(x);  
    % Compute element-wise inverse: y(i) = 1/x(i) for non-zero elements
    y = x;
    y(ind) = 1 ./ y(ind);  
    % Apply similarity transformation: B = (1/x * x) .* A
    % Broadcasting creates the transformation matrix y' * x (column × row)
    B = (y' * x) .* A;   
    % Restore diagonal elements for zero x values to preserve structure
    % This ensures B(i,i) = A(i,i) when x(i) = 0
    if length(ind) < m
        jnd = find(~x);                    % Find indices of zero elements
        idx = sub2ind(size(A), jnd, jnd);  % Convert to linear indices
        B(idx) = A(idx);                   % Restore diagonal values
    end 
end
