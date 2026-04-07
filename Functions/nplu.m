function [L, U] = nplu(A)
%NPLU Non-negative matrix LU factorization without pivoting.
%   [L, U] = NPLU(A) computes the LU factorization for the M-matrix M = I - A,
%   where A is a square non-negative matrix. The factorization is M = L*U,
%   where L is a lower triangular matrix with ones on its diagonal, and U is
%   an upper triangular matrix.
%
%   This function is specifically designed for non-negative matrices and does
%   not perform any pivoting, which is suitable for diagonally dominant
%   M-matrices. It is used to check the Hawkins-Simmons condition. 
%   The diagonal of the matrix U must be strictly positive.
%
%   Syntax:
%       [L, U] = nplu(A)
%
%   Input Arguments:
%       A - A square non-negative matrix. The function checks if the matrix
%           is square and contains only non-negative elements.
%
%   Output Arguments:
%       L - Lower triangular matrix with unit diagonal.
%       U - Upper triangular matrix.
%
%   Examples:
%       % Define a non-negative matrix A
%       A = [0 0.5 0; 0.2 0 0.1; 0 0.8 0];
%       % Compute the LU factorization of I - A
%       [L, U] = nplu(A);
%       % Verify the factorization. Must be the identity matrix
%       disp(L*U+A);
%
%   See also: inv, lu
%
	%% Input validation and initialization
    if nargin ~= 1
        error(buildMessage(mfilename, cMessages.NarginError, cMessages.ShowHelp));
    end
    % Check if it is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        error(buildMessage(mfilename, cMessages.NegativeMatrix));
    end
	% Initialize result matrices: L=I U=I-A
	n = size(A,1);                        
    L = eye(n);
    U = L-A;
    %% Factorize matrix I-A = L*U  
    for k = 1:n-1
        % 1. Check for numerical singularity (zero or near-zero pivot)
   	    dk = U(k,k);  % Current pivot value  	
        if abs(dk) < cType.EPS
			error(buildMessage(mfilename, cMessages.SingularMatrix));
        end      
        % 2. Compute multipliers for column k
        L(k+1:n, k) = U(k+1:n, k) / dk;       
        % 3. Update the remaining submatrix using an outer product
        % This eliminates the inner loops i and j   
        U(k+1:n, k+1:n) = U(k+1:n, k+1:n) - L(k+1:n, k) * U(k, k+1:n);       
        % 4. Clear the bottom of the current column in U
        U(k+1:n, k) = 0;
    end
end