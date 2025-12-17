function res = isNonSingularMatrix(A)
%isNonSingularMatrix - Check if the matrix (I-A) is non-singular.
%   Validates if the matrix (I-A) is non-singular by computing the reciprocal
%   condition number. The matrix A must be a square non-negative matrix. The
%   matrix (I-A) is considered non-singular if its reciprocal condition number
%   is greater than cType.EPS (1.0e-8).
%   A non-singular matrix (I-A) ensures that the system has a unique solution
%   and is commonly used in productive structure analysis and cost allocation
%   algorithms.
% 
%   Syntax:
%     res = isNonSingularMatrix(A)
%
%   Input Arguments:
%     A - Square non-negative matrix
%
%   Output Arguments:
%     res - Logical result
%       true  - Matrix (I-A) is non-singular (invertible)
%       false - Matrix (I-A) is singular or A is invalid
%
%   Examples:
%     A = [0.5 0.2; 0.3 0.4];
%     res = isNonSingularMatrix(A);    % Returns true (I-A is invertible)
%
%     B = [1 0; 0 1];
%     res = isNonSingularMatrix(B);    % Returns false (I-A is zero matrix)
%
%     C = [0.9 0.1; 0.1 0.9];
%     res = isNonSingularMatrix(C);    % Returns true
%
%     D = [1 2; 3 4];
%     res = isNonSingularMatrix(D);    % Returns false (negative elements in I-A)
%
%   Algorithm:
%     1. Validates that A is a square non-negative matrix
%     2. Computes the matrix (I-A) where I is the identity matrix
%     3. Estimates the reciprocalcondition number of (I-A) using condest (Octave) or rcond (MATLAB)
%     4. A well-conditioned matrix has rcond close to 1, while a singular matrix has rcond close to 0
%     5. Matrix is non-singular if rcond > cType.EPS
%
%   See also: isNonNegativeMatrix, isSquareMatrix, condest, cond, rcond
%
    res = false;
    % Validate input arguments count
    if nargin ~= 1
        return;
    end
    % Validate that A is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        return;
    end
    % Compute I-A matrix
    ImA = eye(size(A)) - A;
    % Estimate condition number and compute reciprocal
    % A well-conditioned matrix has rcond close to 1
    % A singular matrix has rcond close to 0
    % Use rcond for MATLAB, condest for Octave
    if isMatlab
        sol= rcond(ImA);
    else
        sol = 1.0 / condest(ImA);
    end  
    % Check if matrix is non-singular (invertible)
    res = (sol > cType.EPS);   
end