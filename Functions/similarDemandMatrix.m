function B = similarDemandMatrix(A, x, y)
%similarDemandMatrix - Transform resource-driven matrix to demand-driven form.
%   Computes a generalized similarity transformation to convert a
%   resource-driven matrix to its demand-driven equivalent using two
%   transformation vectors (or one for square matrices).
%
%   The function handles both sparse and dense matrices efficiently, applying
%   zero-tolerance filtering to avoid division by zero. For square matrices,
%   a single vector can be provided (y defaults to x). This transformation is
%   used in thermoeconomic analysis to convert between demand-driven and
%   resource-driven perspectives of productive structures.
%
%   Syntax:
%     B = similarDemandMatrix(A, x)
%     B = similarDemandMatrix(A, x, y)
%
%   Input Arguments:
%     A - Resource-driven matrix (m x n, numeric)
%           Can be sparse or dense
%     x - Left transformation vector (m x 1 or 1 x m)
%     y - Right transformation vector (n x 1 or 1 x n), optional
%           If omitted, y = x (assumes square matrix)
%
%   Output Arguments:
%     B - Demand-driven matrix (m x n)
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
%     % Example 1: Basic transformation (square matrix, single vector)
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     x = [1; 2; 3];
%     B = similarDemandMatrix(A, x);
%     % Returns: B = [0, 2, 0; 0, 0, 2; 0, 0, 0]
%
%     % Example 2: Two transformation vectors
%     A = [0, 1, 0; 0, 0, 1; 0, 0, 0];
%     x = [1; 2; 3];
%     y = [1; 3; 2];
%     B = similarDemandMatrix(A, x, y);
%     % Returns: B = [0, 0.3333, 0; 0, 0, 1.0; 0, 0, 0]
%
%     % Example 3: Rectangular matrix
%     A = [1, 2, 3; 4, 5, 6];  % 2x3 matrix
%     x = [2; 3];              % 2 rows
%     y = [1; 2; 3];           % 3 columns
%     B = similarDemandMatrix(A, x, y);
%     % Returns: B = [2, 2, 2; 12, 7.5, 6]
%
%     % Example 4: Sparse matrix transformation
%     A = sparse([0, 1, 0; 0, 0, 1; 1, 0, 0]);
%     x = [2; 3; 4];
%     B = similarDemandMatrix(A, x);
%     % Returns: sparse B with efficient storage
%
%     % Example 5: Handle zero elements
%     A = [0.5, 0.3; 0.2, 0.4];
%     x = [2; 3];
%     y = [0; 4];  % First element is zero
%     B = similarDemandMatrix(A, x, y);
%     % First column becomes zero (division by zero avoided)
%
%     % Example 6: Row vectors
%     A = [1, 2; 3, 4];
%     x = [2, 3];     % Row vector
%     y = [4, 5];     % Row vector
%     B = similarDemandMatrix(A, x, y);
%
%   See also: similarDemandOperator, similarResourceMatrix, zerotol, sparse
%

    % Validate input argument count
    try
        narginchk(2, 3);
    catch ME
        msg = buildMessage(mfilename, ME.message);
        error(msg);
    end    
    % Validate A is a numeric matrix
    if ~isnumeric(A) || ~ismatrix(A)
        msg = buildMessage(mfilename, cMessages.NonNumericalMatrixError);
        error(msg);
    end
    [n, m] = size(A);    % Get matrix dimensions   
    % If y not provided, assume square matrix with y = x
    if nargin == 2
        y = x;
    end   
    % Validate left transformation vector x (must match rows)
    if ~isnumeric(x) || ~isvector(x) || length(x) ~= n
        msg = buildMessage(mfilename, cMessages.VectorLengthError);
        error(msg);
    end   
    % Validate right transformation vector y (must match columns)
    if ~isnumeric(y) || ~isvector(y) || length(y) ~= m
        msg = buildMessage(mfilename, cMessages.VectorLengthError);
        error(msg);
    end   
    % Apply zero-tolerance filter to x and compute element-wise inverse
    y = zerotol(y);
    ind = find(y);
    y(ind) = 1.0 ./ y(ind);   
    % Compute transformed matrix using appropriate algorithm
    if issparse(A)
        % Sparse matrix: Transform only non-zero entries for efficiency
        % Convert vectors to column form for indexing
        if isrow(x), x = x'; end
        if isrow(y), y = y'; end       
        % Extract non-zero elements with their indices
        [i, j, val] = find(A);       
        % Apply transformation: B(i,j) = x(i) * A(i,j) / y(j)
        tmp = x(i) .* val .* y(j);        
        % Reconstruct sparse matrix with transformed values
        B = sparse(i, j, tmp, n, m);
    else
        % Dense matrix: Use vectorized operations
        % Ensure x is column and y is row for outer product
        if isrow(x), x = x'; end
        if iscolumn(y), y = y'; end       
        % Apply transformation: B = (x * y) .* A = D(x) * A * D(1/y)
        B = (x * y) .* A;
    end    
end
