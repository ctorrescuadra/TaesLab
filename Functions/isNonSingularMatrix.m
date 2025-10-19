function res=isNonSingularMatrix(A)
%isNonSingularMatrix - Check if the matrix I-A is non-singular.
%   Use the recipocal condition number to determine if the matrix is non-singular.
%   The matrix is non-singular if the reciprocal condition number is greater than cType.EPS. 
%   The matrix A must be a non-negative matrix.
% 
%   Syntax:
%     res = isNonSingularMatrix(A)
%
%   Input Arguments:
%     A - Square non-negative matrix
%   Output Arguments:
%     res - true | false
%
%   Examples:
%     A = [0.5 0.2; 0.3 0.4];
%     res = isNonSingularMatrix(A) % returns true
%     B = [1 2; 3 4];
%     res = isNonSingularMatrix(B) % returns false
%
%   See also isNonNegativeMatrix, condest
%
    res=false;
    % Check Input
    if nargin~=1 || ~isNonNegativeMatrix(A)
        return
    end
    %Check if I-A is non-singular
    rcond=1./condest(eye(size(A))-A);
    res=(rcond>cType.EPS);
end