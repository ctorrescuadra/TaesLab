function B = divideRow(A, x)
%divideRow - Divide each row of matrix A by corresponding element of vector x.
%   Performs row-wise division of matrix A by vector x. Each row i of
%   matrix A is divided by the corresponding element x(i).
%   If x is not provided, each row is normalized by dividing by its row
%   sum, resulting in rows that sum to 1
%   The function handles division by zero by setting those elements to zero,
%   using zerotol() to convert near-zero values to exact zeros before division.
%
%   Syntax:
%     B = divideRow(A)
%     B = divideRow(A, x)
%
%   Input Arguments:
%     A - Matrix to be scaled (m x n)
%     x - Scale vector (m x 1 or 1 x m), optional
%         If not provided, rows are divided by their sum
%
%   Output Arguments:
%     B - Scaled matrix (m x n)
%         B(i,j) = A(i,j) / x(i) for each element
%
%   Examples:
%     % Example 1: Divide by specific vector
%     A = [1 2; 3 4];
%     x = [1; 2];
%     B = divideRow(A, x);    % Returns [1 2; 1.5 2]
%
%     % Example 2: Normalize rows (divide by row sums)
%     A = [1 2; 3 4];
%     B = divideRow(A);       % Returns [0.3333 0.6667; 0.4286 0.5714]
%                             % Rows sum to 1
%
%     % Example 3: Handle zero division
%     A = [1 2; 3 4];
%     x = [1; 0];
%     B = divideRow(A, x);    % Returns [1 2; 0 0] (second row becomes zero)
%
%     % Example 4: Matrix normalization
%     A = [10 20 30; 15 25 35; 25 30 35];
%     B = divideRow(A);       % Normalize each row to sum to 1
%     sum(B, 2)               % Returns [1; 1; 1]
%
%   See also: scaleRow, divideCol, scaleCol, zerotol
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
    % If x not provided, use row sums (normalize rows)
    if nargin == 1
        x = sum(A, 2);  % Sum along columns to get row sums
    end    
    % Get number of rows
    [nRows, ~] = size(A);   
    % Validate scale vector
    if ~isnumeric(x) || ~isvector(x) || (nRows ~= length(x))
        error(buildMessage(mfilename, cMessages.ScaleRowsError));
    end   
    % Convert near-zero values to exact zeros to avoid division by zero
    x = zerotol(x);    
    % Find non-zero elements
    nonZeroIdx = find(x);    
    % Compute reciprocal for non-zero elements (inverse operation)
    x(nonZeroIdx) = 1.0 ./ x(nonZeroIdx);    
    % Scale the matrix by multiplied by reciprocal (equivalent to division)
    % For zero elements, x remains 0, so those rows become zero
    B = scaleRow(A, x);    
end