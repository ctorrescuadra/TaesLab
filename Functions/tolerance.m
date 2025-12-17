function res = tolerance(A, tol)
%TOLERANCE - Compute relative tolerance value for a matrix.
%   Computes a relative tolerance value scaled by the magnitude of the matrix.
%   The relative tolerance is the absolute tolerance multiplied by the maximum
%   absolute value in the matrix (or 1, whichever is larger).
%   This ensures that tolerance is adaptive to the scale of the data:
%     - For small values (max < 1): tolerance is tol * 1 = tol
%     - For large values (max > 1): tolerance scales proportionally
%   This function is commonly used in numerical comparisons where floating-point
%   precision needs to account for the magnitude of the values being compared.
%
%   Syntax:
%     res = tolerance(A)
%     res = tolerance(A, tol)
%
%   Input Arguments:
%     A   - Numeric matrix or array
%     tol - Absolute tolerance (scalar, non-negative), optional
%           Default: cType.EPS (1.0e-8)
%
%   Output Arguments:
%     res - Relative tolerance value (scalar)
%           res = tol * max(1, max(abs(A(:))))
%
%   Examples:
%     % Example 1: Small matrix values
%     A = [0.1 0.2; 0.3 0.4];
%     res = tolerance(A, 0.001);  % Returns 0.001 (max=0.4, uses 1 as max)
%
%     % Example 2: Large matrix values
%     A = [10 20; 30 40];
%     res = tolerance(A, 0.001);  % Returns 0.04 (0.001 * 40)
%
%     % Example 3: Default tolerance
%     A = [1 2; 3 4];
%     res = tolerance(A);         % Returns 4e-8 (cType.EPS * 4)
%
%     % Example 4: Very large values
%     A = [1000 2000; 3000 4000];
%     res = tolerance(A, 1e-6);   % Returns 0.004 (1e-6 * 4000)
%
%     % Example 5: Zero matrix
%     A = zeros(3, 3);
%     res = tolerance(A, 0.01);   % Returns 0.01 (uses 1 as fallback)
%
%   Algorithm:
%     1. Validate and set default tolerance if needed
%     2. Find maximum absolute value in matrix: maxVal = max(abs(A(:)))
%     3. Take maximum of 1 and maxVal to avoid underscaling
%     4. Compute relative tolerance: res = tol * max(1, maxVal)
%
%   See also: zerotol, cType, abs, max

    % Validate and set default tolerance
    if nargin < 2 || isempty(tol) || ~isscalar(tol) || tol < 0
        tol = cType.EPS;  % Default: 1.0e-8
    end    
    % Compute relative tolerance scaled by matrix magnitude
    % max([1; abs(A(:))]) ensures result is at least tol (when max value < 1)
    % This scales tolerance proportionally for large values
    res = tol * max([1; abs(A(:))]);    
end