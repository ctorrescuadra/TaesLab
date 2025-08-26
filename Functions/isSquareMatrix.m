function res = isSquareMatrix(A)
%isSquareMatrix - Checks if input A is a numeric square matrix.
%
%   Syntax
%     res = isSquareMatrix(A)
%
%   Input Argument:
%     A - Matrix to check
%
%   Output Argument
%     res - true/false
%
%   Example
%     A = [1 2; 3 4];   % returns true
%     B = [1 2 3; 4 5 6]; % returns false
%
%   See also ismatrix, isnumeric
%
    res = (isnumeric(A) || islogical(A)) && ismatrix(A) && (size(A,1) == size(A,2));
end