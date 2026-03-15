function res=npinv(A)
%npinv - Compute inverse of M-matrix (I - A) using Gauss-Jordan elimination.
%   Calculates the inverse of the M-matrix (I - A) where A is a non-negative  
%   matrix, using the Compact Gauss-Jordan algorithm without pivoting and
%   outer product approach. This specialized algorithm is optimized for M-matrices
%
%   An M-matrix (I - A) where A is non-negative is invertible if and only if
%   the spectral radius of A is less than 1.
%
%   Algorithm Features:
%     • Compact Gauss-Jordan elimination without row/column pivoting
%     • Outer product formulation for numerical efficiency  
%     • Specialized for non-negative input matrices
%     • Handles singularity detection with appropriate error reporting
%     • Optimized matrices in thermoeconomic analysis
%
%   Syntax:
%     [res, log] = npinv(A)
%
%   Input Arguments:
%     A - Non-negative input matrix
%       numeric matrix (N×N)
%       Must be square with non-negative elements
%       Spectral radius should be < 1 for invertibility
%       Represents flow coefficients or technical coefficients
%
%   Output Arguments:
%     res - Inverse of M-matrix (I - A)
%       numeric matrix (N×N) | empty array
%       Total requirements matrix if successful
%       Empty if matrix is singular or invalid input
%       Elements represent cumulative flow dependencies
%
%     log - Calculation status logger
%       cMessageLogger object
%       Contains success/error status and detailed messages
%       Use log.status to check computation validity
%       Contains error details for debugging singular cases
%
%   Mathematical Background:
%     For economic flow analysis, the M-matrix inverse (I - A)^(-1) represents:
%       • x = (I - A)^(-1) * d  (Leontief equation solution)
%       • Total production requirements for given final demand
%       • Cumulative direct and indirect flow dependencies
%       • Multiplier effects in economic input-output systems
%
%   Performance:
%     • Time complexity: O(N³) for N×N matrix
%     • Space complexity: O(N²) working space
%     • Numerically stable for well-conditioned M-matrices
%     • No memory allocation during elimination process
%
%   Examples:
%     % Example 1: Simple 2×2 IO matrix
%     A = [0.2 0.1; 0.3 0.4];  % Technical coefficients
%     [inv_matrix, log] = npinv(A);
%     if log.status
%         fprintf('Total requirements matrix computed successfully\n');
%         disp(inv_matrix);
%     end
%
%     % Example 3: Handle singular matrix gracefully
%     A = [0.8 0.5; 0.4 0.2];  % Singular M-matrix
%     [inv_matrix, log] = npinv(A);
%     if ~log.status
%        log.printLogger
%     end
%
%   Error Conditions:
%     Returns empty result and logs error if:
%       • Input is not a square matrix
%       • Input matrix contains negative elements
%       • Pivot element becomes zero during elimination
%
%   See also:
%     isNonNegativeMatrix, cMessageLogger, cType

	%% Input validation and initialization
    if nargin ~= 1
        error(buildMessage(mfilename, cMessages.NarginError, cMessages.ShowHelp));
    end
    % Check if it is a square non-negative matrix
    if ~isNonNegativeMatrix(A)
        error(buildMessage(mfilename, cMessages.NegativeMatrix));
    end
	% Initialize result matrix as M-matrix: I - A
	% This will be transformed in-place into the inverse matrix
	N = size(A,1);                       
	res = eye(N) - A;
	%% Gauss-Jordan elimination with outer product formulation		
	for k = 1:N         % Process each row
    	dk = res(k,k);  % Current pivot value  	
        % Check for numerical singularity (zero or near-zero pivot)
        if abs(dk) < cType.EPS
			error(buildMessage(mfilename, cMessages.SingularMatrix));
        end
	    % Outer product elimination (compact Gauss-Jordan)
      	pk = 1/dk;                      % Pivot reciprocal for normalization      	
      	% Construct elimination vectors for outer product update
      	u = -pk * res(:,k);             % Column vector: current pivot column
      	u(k) = pk;                      % Set diagonal element to pivot reciprocal     	
        v = res(k,:);                   % Row vector: current pivot row
        % Matrix update via rank-1 outer product
        %   - Eliminates column k below diagonal
        %   - Eliminates row k to the right of diagonal  
        %   - Updates all other matrix elements
      	res = res + u * v;              % Rank-1 outer product update      	
        % Explicit update of pivot row and column
        res(k,:) = pk * v;              % Normalize pivot row by reciprocal
        res(:,k) = u;                   % Set elimination column explicitly
	end    
end
