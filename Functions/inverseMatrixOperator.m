function [res, log] = inverseMatrixOperator(A)
%inverseMatrixOperator - Calculate the inverse of the M-Matrix (I-A).
%   Computes the inverse of the matrix (I-A) where I is the identity matrix
%   and A is a non-negative square matrix. If (I-A) is singular, returns an
%   empty array and logs an error message.
%
%
%   Syntax:
%     [res, log] = inverseMatrixOperator(A)
%
%   Input Arguments:
%     A - Square non-negative matrix (n x n)
%
%   Output Arguments:
%     res - Inverse of matrix (I-A), or empty array if singular
%     log - cMessageLogger with calculation status and error messages
%       log.status = true  : Success, (I-A) is invertible
%       log.status = false : Failure, (I-A) is singular or invalid input
%
%   Examples:
%     % Example 1: Non-singular case (valid structure)
%     A = [0 0.2; 0.1 0];
%     [res, log] = inverseMatrixOperator(A);
%     % Returns:
%     %   res = [1.0204 0.2041; 0.1020 1.0204]
%     %   log.status = true
%
%     % Example 2: Singular case (invalid structure)
%     A = [0 1; 1 0];
%     [res, log] = inverseMatrixOperator(A);
%     % Returns:
%     %   res = []
%     %   log.status = false
%     printLogger(log);  % Display: ERROR: Matrix is singular to working precision
%
%     % Example 3: Invalid input (negative elements)
%     A = [-0.1 0.2; 0.1 0.3];
%     [res, log] = inverseMatrixOperator(A);
%     % Returns:
%     %   res = []
%     %   log.status = false
%     printLogger(log);  % Display: ERROR: Input matrix must be square and non-negative
%
%   Algorithm:
%     1. Validate input argument count
%     2. Validate A is a square non-negative matrix
%     3. Suppress MATLAB singular matrix warnings
%     4. Compute inv(I-A) using right matrix division: I/(I-A)
%     5. Capture any singularity warnings via lastwarn()
%     6. Restore warning state and return results with log
%
%   See also: isNonNegativeMatrix, lastwarn
    
    % Initialize message logger
    log = cMessageLogger();
    res = cType.EMPTY;
    warning('off', 'MATLAB:singularMatrix');
    warning('off', 'MATLAB:nearlySingularMatrix');   
    % Validate input argument count
    if nargin ~= 1
        log.messageLog(cType.ERROR, cMessages.NarginError);
        warning('on', 'MATLAB:singularMatrix');
        warning('on', 'MATLAB:nearlySingularMatrix');  
        return;
    end   
    % Validate that A is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        log.messageLog(cType.ERROR, cMessages.NonNegativeMatrixError);
        warning('on', 'MATLAB:singularMatrix');
        warning('on', 'MATLAB:nearlySingularMatrix');  
        return;
    end   
    % Clear previous warnings before computation
    lastwarn(cType.EMPTY_CHAR, cType.EMPTY_CHAR);
    % Compute the inverse of (I-A) using right matrix division
    % This is equivalent to inv(I-A) but more numerically stable
    ImA = eye(size(A)) - A;
    res = eye(size(A)) / ImA;   
    % Check if any warnings were generated during computation
    [warnMessage, warnId] = lastwarn();   
    if ~isempty(warnId)
        % Singularity or numerical issue detected
        log.messageLog(cType.ERROR, warnMessage);
        res = cType.EMPTY;
    end   
    % Restore warning state
    warning('on', 'MATLAB:singularMatrix');
    warning('on', 'MATLAB:nearlySingularMatrix');   
end
