function B = scaleRow(A, x)
%scaleRow - Multiply each row of matrix A by corresponding element of vector x.
%   Performs row-wise multiplication of matrix A by vector x. Each row i
%   of matrix A is multiplied by the corresponding element x(i).
%   The function supports both dense and sparse matrices, using optimized
%   algorithms for each case:
%   - Sparse matrices: Uses spdiags for efficient diagonal matrix multiplication
%   - Dense matrices: Uses element-wise broadcasting for performance
%   Accepts both numeric and logical matrices for flexibility.
%
%   Syntax:
%     B = scaleRow(A, x)
%
%   Input Arguments:
%     A - Matrix to be scaled (m x n), can be sparse
%     x - Scale vector (m x 1 or 1 x m)
%
%   Output Arguments:
%     B - Scaled matrix (m x n)
%         B(i,j) = x(i) * A(i,j) for each element
%
%   Examples:
%     % Example 1: Basic row scaling
%     A = [1 2; 3 4];
%     x = [0.5; 2];
%     B = scaleRow(A, x);     % Returns [0.5 1; 6 8]
%
%     % Example 2: Row vector input
%     A = [1 2 3; 4 5 6];
%     x = [2, 0.5];
%     B = scaleRow(A, x);     % Returns [2 4 6; 2 2.5 3]
%
%     % Example 3: Sparse matrix scaling
%     A = sparse([1 0; 0 2; 3 0]);
%     x = [10; 100; 1000];
%     B = scaleRow(A, x);     % Returns sparse [10 0; 0 200; 3000 0]
%
%     % Example 4: Zero scaling (row elimination)
%     A = [1 2 3; 4 5 6];
%     x = [1; 0];
%     B = scaleRow(A, x);     % Returns [1 2 3; 0 0 0]
%
%     % Example 5: Logical matrix
%     A = logical([1 0; 0 1]);
%     x = [2; 3];
%     B = scaleRow(A, x);     % Returns [2 0; 0 3]
%
%   See also: scaleCol, divideRow, divideCol, spdiags
%
    % Validate input argument count and matrix type
    if nargin < 2 || ~ismatrix(A) || ~(isnumeric(A) || islogical(A))
        msg = buildMessage(mfilename, cMessages.InvalidArgument, cMessages.ShowHelp);
        error(msg);
    end   
    % Get number of rows
    [nRows, ~] = size(A);    
    % Validate scale vector dimensions
    if ~(isnumeric(x) || islogical(x)) || ~isvector(x) || (nRows ~= length(x))
        msg = buildMessage(mfilename, cMessages.ScaleRowsError);
        error(msg);
    end   
    % Scale the matrix using optimized method based on sparsity
    if issparse(A)
        % For sparse matrices: diag(x) * A is more efficient
        % spdiags creates a sparse diagonal matrix from vector x
        B = spdiags(x(:), 0, nRows, nRows) * A;
    else
        % For dense matrices: use broadcasting (element-wise multiplication)
        % Ensure x is a column vector for correct broadcasting
        if isrow(x), x = x'; end
        % Broadcast multiplication: each row multiplied by corresponding x element
        B = x .* A;
    end   
end