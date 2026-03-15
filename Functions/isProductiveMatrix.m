function res = isProductiveMatrix(A,tol)
%isProductiveMatrix - Check if a matrix represents a productive matrix.
%   Validates if the matrix (I-A) is non-singular by computing the reciprocal
%   condition number. The matrix A must be a square non-negative matrix. The
%   matrix (I-A) is considered non-singular if its reciprocal condition number
%   is greater than cType.EPS (1.0e-8).
%
%   A matrix A is productive if:
%   - A is non-negative (all elements >= 0)
%   - (I-A) is non-singular (invertible)
%
%   Syntax:
%     res = isProductiveMatrix(A)
%     res = isProductiveMatrix(A, tol)
%
%   Input Arguments:
%     A - Matrix to check (must be numeric and non-negative)
%     tol - (optional) Tolerance for checking reciprocal condition number.
%       Must be a positive scalar. Default value is cType.EPS
%
%   Output Arguments:
%     res - Logical result
%       true  - A is a productive matrix
%       false - A is not productive (non-negative, non-square, or (I-A) is singular/not M-matrix)
%
%   Examples:
%     % Simple productive matrix
%     A = [0.2 0.1; 0.3 0.4];
%     res = isProductiveMatrix(A);        % Returns true
%     
%     % Non-productive matrix (singular I-A)
%     B = [0.5 0.5; 0.5 0.5];
%     res = isProductiveMatrix(B);        % Returns false
%     
%     % Matrix with negative elements
%     C = [-0.1 0.2; 0.3 0.4];
%     res = isProductiveMatrix(C);        % Returns false
%     
%     % Using custom tolerance
%     D = [0.1 0.05; 0.2 0.3];
%     res = isProductiveMatrix(D, 1e-10); % Returns true
%     
%     % Non-square matrix
%     E = [0.1 0.2 0.3; 0.4 0.5 0.6];
%     res = isProductiveMatrix(E);        % Returns false
%
%   See also: isNonNegativeMatrix, isSquareMatrix, lu, eye

    res = false;   
    % Validate input argument count (must have 1 or 2 arguments)
    if nargin < 1 || nargin > 2
        return;
    end    
    % Set default tolerance if not provided or invalid
    % Tolerance must be a positive numeric scalar
    if (nargin == 1) || (isempty(tol)) || ~isnumeric(tol) || tol <= 0
        tol = cType.EPS;
    end   
    % First condition: matrix A must be square and non-negative
    % This also implicitly checks if A is a valid numeric matrix
    if ~isNonNegativeMatrix(A)
        return;
    end
    % Compute the Leontief matrix M = (I - A)
    M = eye(size(A)) - A;  
    % Estimate condition number and compute reciprocal
    % A well-conditioned matrix has rcond close to 1
    % A singular matrix has rcond close to 0
    % Use rcond for MATLAB, condest for Octave
    if isMatlab
        sol= rcond(M);
    else
        sol = 1.0 / condest(M);
    end  
    % Check if matrix is non-singular (invertible)
    res = (sol > tol);   
end