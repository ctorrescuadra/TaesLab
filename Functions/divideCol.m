function B = divideCol(A, x)
%divideCol - Divide each column of matrix A by corresponding element of vector x.
%	Performs column-wise division of matrix A by vector x. Each column j of
%   matrix A is divided by the corresponding element x(j).
%   If x is not provided, each column is normalized by dividing by its column
%   sum, resulting in columns that sum to 1.
%	The function handles division by zero by setting those elements to zero,
%   using zerotol() to convert near-zero values to exact zeros before division.
%
%   Syntax:
%     B = divideCol(A)
%     B = divideCol(A, x)
%
%   Input Arguments:
%     A - Matrix to be scaled (m x n)
%     x - Scale vector (1 x n or n x 1), optional
%         If not provided, columns are divided by their sum
%
%   Output Arguments:
%     B - Scaled matrix (m x n)
%         B(i,j) = A(i,j) / x(j) for each element
%
%   Examples:
%     % Example 1: Divide by specific vector
%     A = [1 2; 3 4];
%     x = [1; 2];
%     B = divideCol(A, x);    % Returns [1 1; 3 2]
%
%     % Example 2: Normalize columns (divide by column sums)
%     A = [1 2; 3 4];
%     B = divideCol(A);       % Returns [0.25 0.3333; 0.75 0.6667]
%                             % Columns sum to 1
%     % Example 3: Handle zero division
%     A = [1 2; 3 4];
%     x = [0; 2];
%     B = divideCol(A, x);    % Returns [0 1; 0 2] (first column becomes zero)
%
%     % Example 4: Matrix normalization
%     A = [10 20 30; 15 25 35; 25 30 35];
%     B = divideCol(A);       % Normalize each column to sum to 1
%     sum(B, 1)               % Returns [1 1 1]
%
%   See also: scaleCol, divideRow, scaleRow, zerotol
%

    % Validate input argument count
    try
        narginchk(1, 2);
    catch ME
        error(buildMessage(mfilename, ME.message));
    end 
    % Validate matrix input
    if ~ismatrix(A) || ~isnumeric(A)
        error(buildMessage(mfilename, cMessages.InvalidArgument));
    end  
    % If x not provided, use column sums (normalize columns)
    if nargin == 1
        x = sum(A, 1);  % Sum along rows to get column sums
    end   
    % Get number of columns
    [~, nCols] = size(A);  
    % Validate scale vector
    if ~isnumeric(x) || ~isvector(x) || (nCols ~= length(x))
        error(buildMessage(mfilename, cMessages.ScaleColsError));
    end   
    % Convert near-zero values to exact zeros to avoid division by zero
    x = zerotol(x); 
    % Find non-zero elements
    nonZeroIdx = find(x);   
    % Compute reciprocal for non-zero elements (inverse operation)
    x(nonZeroIdx) = 1.0 ./ x(nonZeroIdx); 
    % Scale the matrix by multiplied by reciprocal (equivalent to division)
    % For zero elements, x remains 0, so those columns become zero
    B = scaleCol(A, x);   
end