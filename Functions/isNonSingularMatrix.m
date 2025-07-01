function res=isNonSingularMatrix(A)
%isNonSingularMatrix - Check if the matrix I-A is non-singular.
%
%   Syntax:
%     res = isNonSingularMatrix
%
%   Input Argument:
%     A - Square non-negative matrix
%   Output Argument:
%     res - true/false
%
    res=false;
    [N,M]=size(A);
    if N~=M, return;end
    if ~isNonNegativeMatrix(A), return; end
    rcond=1./condest(eye(N)-A);
    res=(rcond>cType.EPS);
end