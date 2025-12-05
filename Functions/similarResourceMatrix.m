function B = similarResourceMatrix(A, x, y)
%similarResourceMatrix - Compute resource-driven matrix from demand-driven matrix.
%   Computes a generalized similarity transformation to convert a
%   demand-driven matrix to its resource-driven equivalent using two
%   transformation vectors (or one for square matrices).
%
%   The function handles both sparse and dense matrices efficiently, applying
%   zero-tolerance filtering to avoid division by zero. For square matrices,
%   a single vector can be provided (y defaults to x). This transformation is
%   used in thermoeconomic analysis to convert between demand-driven and
%   resource-driven perspectives of productive structures.
%
%   Syntax:
%     B = similarResourceMatrix(A, x)
%     B = similarResourceMatrix(A, x, y)
%
%   Input Arguments:
%     A - Demand-driven matrix (m x n, numeric)
%           Can be sparse or dense
%     x - Left transformation vector (m x 1 or 1 x m)
%     y - Right transformation vector (n x 1 or 1 x n), optional
%           If omitted, y = x (assumes square matrix)
%
%   Output Arguments:
%     B - Resource-driven matrix (m x n)
%           Sparsity preserved if A is sparse
%
%   Mathematical formula:
%     B(i,j) = x(i) * A(i,j) / y(j)
%
%   Matrix form:
%       B = D(x) * A * D(1/y)
%       where D(x) and D(y) are diagonal matrices
%
%   Notes:
%     - If nargin == 2: y is set to x (requires square matrix)
%     - Zero elements in x: treated as zero after zerotol() filtering
%     - Sparse matrices: preserves sparsity pattern
%     - Dense matrices: returns dense matrix
%
%   Examples:
%     % Example 1: Square matrix with single transformation vector
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     x = [1; 2; 3];
%     B = similarResourceMatrix(A, x);
%     % B = [0, 0.5, 0; 0, 0, 0.333; 0, 0, 0]
%     % Each element divided by row's x value, multiplied by column's x value
%
%     % Example 2: Square matrix with different x and y vectors
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     x = [1; 2; 3];
%     y = [1; 3; 2];
%     B = similarResourceMatrix(A, x, y);
%     % B = [0, 3, 0; 0, 0, 1; 0, 0, 0]
%     % B(1,2) = A(1,2)*y(2)/x(1) = 1*3/1 = 3
%     % B(2,3) = A(2,3)*y(3)/x(2) = 1*2/2 = 1
%
%     % Example 3: Rectangular matrix
%     A = [1, 2, 3; 4, 5, 6];
%     x = [2; 4];
%     y = [1; 2; 3];
%     B = similarResourceMatrix(A, x, y);
%     % B = [0.5, 2, 4.5; 1, 2.5, 4.5]
%     % B(1,1) = 1*1/2 = 0.5, B(1,2) = 2*2/2 = 2, B(1,3) = 3*3/2 = 4.5
%     % B(2,1) = 4*1/4 = 1, B(2,2) = 5*2/4 = 2.5, B(2,3) = 6*3/4 = 4.5
%
%     % Example 4: Sparse matrix handling
%     A = sparse([1, 0, 2; 0, 3, 0; 4, 0, 5]);
%     x = [1; 2; 4];
%     y = [2; 1; 3];
%     B = similarResourceMatrix(A, x, y);
%     % B = sparse([2, 0, 6; 0, 1.5, 0; 2, 0, 3.75])
%     % Preserves sparsity, transforms only non-zero elements
%
%     % Example 5: Handling zero elements in x
%     A = [1, 2; 3, 4; 5, 6];
%     x = [2; 0; 4];
%     y = [1; 2];
%     B = similarResourceMatrix(A, x, y);
%     % B = [0.5, 2; 0, 0; 1.25, 3]
%     % Second row becomes zero due to x(2) = 0
%
%     % Example 6: Row vectors (automatically converted)
%     A = [1, 2; 3, 4];
%     x = [2, 4];        % Row vector
%     y = [1, 3];        % Row vector
%     B = similarResourceMatrix(A, x, y);
%     % B = [0.5, 3; 0.75, 3]
%     % Vectors automatically oriented correctly
%
%   See also:
%     similarDemandMatrix, similarDemandOperator, similarResourceOperator,
%     zerotol, divideRow, divideCol, scaleRow, scaleCol
%

    % Validate input arguments count
    try 
        narginchk(2, 3) 
    catch ME
        msg = buildMessage(mfilename, ME.message);
        error(msg);
    end   
    % Validate matrix A: must be numeric matrix
    if ~isnumeric(A) || ~ismatrix(A)
        msg = buildMessage(mfilename, cMessages.NonNumericalMatrixError);
        error(msg);
    end    
    [n, m] = size(A);  % Get matrix dimensions    
    % If y not provided, assume square matrix with y = x
    if (nargin == 2)
        y = x;
    end   
    % Validate left transformation vector x (must match rows)
    if ~isnumeric(x) || ~isvector(x) || length(x) ~= n
        error(buildMessage(mfilename, cMessages.VectorLengthError));
    end   
    % Validate right transformation vector y (must match columns)
    if ~isnumeric(y) || ~isvector(y) || length(y) ~= m
        error(buildMessage(mfilename, cMessages.VectorLengthError));
    end    
    % Apply zero-tolerance filter to x and compute element-wise inverse
    % This prevents division by zero while preserving the productive structure
    x = zerotol(x);
    ind = find(x);
    x(ind) = 1 ./ x(ind);    
    % Compute transformed matrix using appropriate algorithm
    if issparse(A)
        % Sparse algorithm: transform only non-zero elements
        % Requires column vectors for indexing
        if isrow(x), x = x'; end
        if isrow(y), y = y'; end       
        % Extract non-zero elements and their positions
        [i, j, val] = find(A);       
        % Apply transformation: B(i,j) = (1/x(i)) * A(i,j) * y(j)
        tmp = x(i) .* val .* y(j);       
        % Reconstruct sparse matrix with transformed values
        B = sparse(i, j, tmp, n, m);
    else
        % Dense algorithm: use broadcasting for efficiency
        % Requires column x and row y for proper broadcasting
        if isrow(x), x = x'; end
        if iscolumn(y), y = y'; end        
        % Apply transformation: B = (x * y) .* A = D(1/x) * A * D(y)
        B = (x * y) .* A;
    end
end
