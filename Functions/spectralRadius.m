function res = spectralRadius(A)
%spectralRadius - Compute the spectral radius of a non-negative matrix
%
%   r = spectralRadius(A)
%
%   Description:
%       Computes the spectral radius of a square, non-negative matrix A,
%       defined as the maximum absolute value of the eigenvalues of A.
%
%   Input:
%       A - Square, non-negative numeric matrix.
%
%   Output:
%       r - Spectral radius of A, returned as a scalar numeric value.
%
%   Notes:
%       - The input matrix must be square and non-negative.
%       - If A is not a valid input, the function returns inf.
%
%   Example:
%       A = [1 2; 3 4];
%       r = spectralRadius(A);
%
%   See also: isNonNegativeMatrix, isSquareMatrix

    res = inf;   
    % Validate input argument count (must have 1 or 2 arguments)
    if nargin ~= 1
        return;
    end      
    % First condition: matrix A must be square and non-negative
    % This also implicitly checks if A is a valid numeric matrix
    if ~isNonNegativeMatrix(A)
        return;
    end
    % Compute the spectral radius
    % If matrix A is scalar return the value
    if size(A,1)==1
        res=A;
    else
        res=max(abs(eig(A)));
    end
end