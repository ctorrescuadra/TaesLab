function res=isNonNegativeMatrix(A)
%isNonNegativeMatrix - Check if the matrix is non-negative.
%   Check if all elements of the matriz are non-negative with a tolerance of cType.EPS
%
%   Syntax:
%     res = isNonNegativeMatrix(A)
%   Input Argument:
%     A - Matrix to check
%   Output Argument
%     res - true/false
    res=all(zerotol(A(:))>=0);
end