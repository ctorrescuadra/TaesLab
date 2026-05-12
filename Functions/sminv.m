function res=sminv(A)
%sminv - Compute inverse of M-matrix (I - A) using the Sherman-Morrison formula.
%   Calculates the inverse of the M-matrix (I - A) where A is a non-negative  
%   matrix, using the Sherman-Morrison formula with rank-1 updates. 
%   This specialized algorithm is optimized for M-matrices.
%
%   Algorithm Features:
%     • Iterative rank-1 updates based on the Sherman-Morrison identity
%     • Outer product formulation for numerical efficiency  
%     • Specialized for non-negative input matrices
%     • Handles singularity detection with appropriate error reporting
%     • Optimized for matrices in thermoeconomic analysis
%
%   Syntax:
%     res = sminv(A)
%
%   Input Arguments:
%     A - Non-negative input matrix
%       numeric matrix (N×N)
%       Must be square with non-negative elements
%       Represents flow coefficients or technical coefficients
%
%   Output Arguments:
%     res - Inverse of M-matrix (I - A)
%       numeric matrix (N×N) | empty array
%       Total requirements matrix if successful
%       Empty if matrix is singular or invalid input
%       Elements represent cumulative flow dependencies
%
%   Performance:
%     • Time complexity: O(N³) for N×N matrix
%     • Space complexity: O(N²) working space
%     • Numerically stable for well-conditioned M-matrices
%
%   Examples:
%     % Example 1: Simple 2×2 IO matrix
%     A = [0.2 0.1; 0.3 0.4];  % Technical coefficients
%     inv_matrix = sminv(A);
%     if log.status
%         fprintf('Total requirements matrix computed successfully\n');
%         disp(inv_matrix);
%     end
%
%   Error Conditions:
%     Returns empty result and logs error if:
%       • Input is not a square matrix
%       • Input matrix contains negative elements
%       • Pivot element becomes zero during elimination
%
%   See also:
%     npinv, isNonNegativeMatrix, cMessages, buildMessage

    %% Input validation and initialization
    if nargin ~= 1
        error(buildMessage(mfilename, cMessages.NarginError, cMessages.ShowHelp));
    end
    % Check if it is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        error(buildMessage(mfilename, cMessages.NegativeMatrix));
    end
	% Initialize result matrix as the identity
	% This will be transformed in-place into the inverse matrix
	N = size(A,1);                       
	res = eye(N);
	%% Sherman-Morrison rank-1 update
    % Apply the Sherman Morrison identity (A-u*v')^{1}=(Lu)*(v'L)/(1-v'Lu), where L=A^{-1}
    % to the iterative Decomposition of the  the matrix A = e_1' * A_1 + ... + e_n * A_n 		
	for k = 1:N           % Process each row
    	v = A(k,:) * res;     % This is A_k * L
        dk = 1 - v(k);        % This is 1 - A_K * L * e_k
        % Check for numerical singularity (zero or near-zero pivot)
        if abs(dk) < cType.EPS
			error(buildMessage(mfilename, cMessages.SingularMatrix));
        end
      	% Build 1-rank outer product update
      	u = res(:, k) / dk;           % This is (L * e_k) / dk
      	res = res + u * v;            % Rank-1 outer product update
	end    