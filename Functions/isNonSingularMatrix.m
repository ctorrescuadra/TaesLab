function res=isNonSingularMatrix(A)
%isNonSingularMatrix - Check if the matrix I-A is non-singular.
%   Use the recipocal condition number to determine if the matrix is non-singular.
%   The matrix is non-singular if the reciprocal condition number is greater than cType.EPS.  
%   Syntax
%     res = isNonSingularMatrix
%
%   Input Argument:
%     A - Square non-negative matrix
%   Output Argument:
%     res - true/false
%
%   Example
%     A = [0.5 0.2; 0.3 0.4];
%     res = isNonSingularMatrix(A) % returns true
%     B = [1 2; 3 4];
%     res = isNonSingularMatrix(B) % returns false
%
    %Check input arguments
    res=false;
    if nargin~=1 || ~isNonNegativeMatrix(A)
        return
    end
    %Check if I-A is non-singular
    rcond=1./condest(eye(size(A))-A);
    res=(rcond>cType.EPS);
end