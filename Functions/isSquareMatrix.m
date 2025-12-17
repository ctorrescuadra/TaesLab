function res = isSquareMatrix(A)
%isSquareMatrix - Check if input is a numeric or logical square matrix.
%   Validates if the input is a two-dimensional square matrix (equal number of
%   rows and columns). Accepts numeric and logical matrices. Returns false for
%   scalars, vectors, empty matrices, non-numeric arrays, or higher-dimensional arrays.
%
%   Syntax:
%     res = isSquareMatrix(A)
%
%   Input Arguments:
%     A - Array to check
%
%   Output Arguments:
%     res - Logical result
%       true  - A is a numeric or logical square matrix (n x n)
%       false - A is not a square matrix (non-matrix, non-numeric, or rectangular)
%
%   Examples:
%     res = isSquareMatrix([1 2; 3 4]);           % Returns true (2x2)
%     res = isSquareMatrix(eye(5));               % Returns true (5x5 identity)
%     res = isSquareMatrix([1]);                  % Returns true (1x1)
%     res = isSquareMatrix([true false; false true]); % Returns true (logical 2x2)
%     res = isSquareMatrix([1 2 3; 4 5 6]);       % Returns false (2x3 rectangular)
%     res = isSquareMatrix([1 2 3]);              % Returns false (1x3 vector)
%     res = isSquareMatrix([1; 2; 3]);            % Returns false (3x1 vector)
%     res = isSquareMatrix([]);                   % Returns false (empty)
%     res = isSquareMatrix('matrix');             % Returns false (non-numeric)
%     res = isSquareMatrix(rand(2,2,2));          % Returns false (3D array)
%
%   See also: ismatrix, isnumeric, islogical, size
%
    res = false;
    % Validate input arguments count
    if nargin ~= 1
        return;
    end   
    % Check if input is numeric or logical matrix with equal dimensions
    if (isnumeric(A) || islogical(A)) && ismatrix(A)
        [nRows, nCols] = size(A);
        res = (nRows == nCols) && (nRows > 0);
    end  
end