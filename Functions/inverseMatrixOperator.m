function [res, log, rcond] = inverseMatrixOperator(A,tol)
%inverseMatrixOperator - Calculate the inverse of the M-Matrix (I-A).
%   Computes the inverse of the matrix (I-A) where I is the identity matrix
%   and A is a non-negative square matrix using Singular Value Decomposition.
%   If (I-A) is singular or ill-conditioned, returns an empty array and logs 
%   an error message.
%
%   Syntax:
%     [res, log, rcond] = inverseMatrixOperator(A)
%     [res, log, rcond] = inverseMatrixOperator(A, tol)
%
%   Input Arguments:
%     A     - Square non-negative matrix (n x n)
%     tol   - Tolerance for condition number check. Default: cType.EPS
%             If rcond > tol, matrix is considered invertible
%
%   Output Arguments:
%     res   - Inverse of matrix (I-A), or empty array if singular
%     log   - cMessageLogger with calculation status and error messages
%             log.status = true  : Success, (I-A) is invertible
%             log.status = false : Failure, (I-A) is singular or invalid input
%     rcond - Reciprocal condition number (ratio of smallest to largest singular value)
%
%   Examples:
%     % Example 1: Non-singular case (valid structure)
%     A = [0 0.2; 0.1 0];
%     [res, log, rcond] = inverseMatrixOperator(A);
%     % Returns:
%     %   res = [1.0204 0.2041; 0.1020 1.0204]
%     %   rcond ≈ 0.8889
%     %   log.status = true
%
%     % Example 2: Singular case (ill-conditioned)
%     A = [0 1; 1 0];
%     [res, log, rcond] = inverseMatrixOperator(A);
%     % Returns:
%     %   res = []
%     %   rcond ≈ 0
%     %   log.status = false
%     printLogger(log);  % Display: ERROR: Matrix is singular to working precision
%
%     % Example 3: Invalid input (negative elements)
%     A = [-0.1 0.2; 0.1 0.3];
%     [res, log, rcond] = inverseMatrixOperator(A);
%     % Returns:
%     %   res = []
%     %   rcond = 0
%     %   log.status = false
%     printLogger(log);  % Display: ERROR: Input matrix must be square and non-negative
%
%   Algorithm:
%     1. Validate input argument count and set default tolerance
%     2. Validate A is a square non-negative matrix
%     3. Compute SVD of (I-A): [U, S, V] = svd(I-A)
%     4. Extract singular values and compute reciprocal condition number
%     5. Check if rcond > tol (well-conditioned)
%     6. If invertible: compute inverse as V*diag(1/S)*U' and apply zero tolerance
%     7. Return results with condition number and log status
%
%   See also: isNonNegativeMatrix, zerotol, cMessageLogger
%
    % Initialize message logger and outputs
    log = cMessageLogger();
    res = cType.EMPTY;
    rcond = 0;
    % Validate input argument count
    if nargin < 1
        log.messageLog(cType.ERROR, cMessages.NarginError);
        return;
    end  
    if nargin == 1
        tol=cType.EPS;
    end  
    % Validate that A is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        log.messageLog(cType.ERROR, cMessages.NonNegativeMatrixError);
        return;
    end  
    % Calculate SVD of the matrix I-A
    [U,S,V]=svd(eye(size(A,1))-A);
    sd=diag(S);
    %Compute and check the reciprocal condition number.
    rcond=sd(end)/sd(1);
    if rcond > tol % Compute the inverse
        SS=diag(1.0./sd);
        res=V*SS*U';
        log.messageLog(cType.INFO, cMessages.InverseCalculated,rcond);
    else % Log error for singular or ill-conditioned matrix
        log.messageLog(cType.ERROR,cMessages.SingularMatrix);
        return
    end
end
