function B = scaleCol(A, x)
%scaleCol - Multiply each column of matrix A by corresponding element of vector x.
%   Performs column-wise multiplication of matrix A by vector x. Each column j
%   of matrix A is multiplied by the corresponding element x(j).
%   The function supports both dense and sparse matrices, using optimized algorithms for each case:
%     - Sparse matrices: Uses spdiags for efficient diagonal matrix multiplication
%     - Dense matrices: Uses element-wise broadcasting for performance
%   Accepts both numeric and logical matrices for flexibility.
%
%   Syntax:
%     B = scaleCol(A, x)
%
%   Input Arguments:
%     A - Matrix to be scaled (m x n), can be sparse
%     x - Scale vector (1 x n or n x 1)
%
%   Output Arguments:
%     B - Scaled matrix (m x n)
%         B(i,j) = A(i,j) * x(j) for each element
%
%   Examples:
%     % Example 1: Basic column scaling
%     A = [1 2; 3 4];
%     x = [0.5, 2];
%     B = scaleCol(A, x);     % Returns [0.5 4; 1.5 8]
%
%     % Example 2: Column vector input
%     A = [1 2 3; 4 5 6];
%     x = [2; 0.5; 3];
%     B = scaleCol(A, x);     % Returns [2 1 9; 8 2.5 18]
%
%     % Example 3: Sparse matrix scaling
%     A = sparse([1 0; 0 2; 3 0]);
%     x = [10, 100];
%     B = scaleCol(A, x);     % Returns sparse [10 0; 0 200; 30 0]
%
%     % Example 4: Zero scaling (column elimination)
%     A = [1 2 3; 4 5 6];
%     x = [1 0 1];
%     B = scaleCol(A, x);     % Returns [1 0 3; 4 0 6]
%
%     % Example 5: Logical matrix
%     A = logical([1 0; 0 1]);
%     x = [2, 3];
%     B = scaleCol(A, x);     % Returns [2 0; 0 3]
%
%   See also: scaleRow, divideCol, divideRow, spdiags
%
    % Validate input argument count and matrix type
    if nargin < 2 || ~ismatrix(A) || ~(isnumeric(A) || islogical(A))
        msg = buildMessage(mfilename, cMessages.InvalidArgument, cMessages.ShowHelp);
        error(msg);
    end    
    % Get number of columns
    [~, nCols] = size(A);   
    % Validate scale vector dimensions
    if ~isnumeric(x) || ~isvector(x) || ~islogical(x) || (nCols ~= length(x))
        msg = buildMessage(mfilename, cMessages.ScaleColsError);
        error(msg);
    end
    % Scale the matrix using optimized method based on sparsity
    if issparse(A)
        % For sparse matrices: A * diag(x) is more efficient
        % spdiags creates a sparse diagonal matrix from vector x
        B = A * spdiags(x(:), 0, nCols, nCols);
    else
        % For dense matrices: use broadcasting (element-wise multiplication)
        % Ensure x is a row vector for correct broadcasting
        if iscolumn(x), x = x'; end
        % Broadcast multiplication: each column multiplied by corresponding x element
        B = x .* A;
    end  
end