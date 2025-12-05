function A = zerotol(A, tol)
%zerotol - Set matrix values near zero to exact zero.
%   Sets to zero all matrix elements whose absolute value is smaller than or
%   equal to a relative tolerance. The relative tolerance is computed by
%   scaling the absolute tolerance by the maximum magnitude in the matrix.
%
%   Syntax:
%     B = zerotol(A)
%     B = zerotol(A, tol)
%
%   Input Arguments:
%     A   - Numeric matrix or array
%     tol - Absolute tolerance (scalar, non-negative), optional
%           Default: cType.EPS (1.0e-8)
%
%   Output Arguments:
%     A - Modified matrix with near-zero values set to zero
%
%   Examples:
%     % Example 1: Clean floating-point errors
%     A = [0.1, 0.2; 0.00001, 0.3];
%     B = zerotol(A, 0.0001);     % Returns [0.1, 0.2; 0, 0.3]
%
%     % Example 2: Default tolerance
%     A = [1.5, 2.3; 1e-10, 4.2];
%     B = zerotol(A);             % Returns [1.5, 2.3; 0, 4.2]
%
%     % Example 3: Large values with relative tolerance
%     A = [1000, 2000; 0.01, 3000];
%     B = zerotol(A, 1e-6);       % Returns [1000, 2000; 0, 3000]
%                                 % 0.01 < 1e-6*3000 = 0.003, so set to 0
%
%     % Example 4: Preserve significant small values
%     A = [0.5, 0.3; 0.1, 0.2];
%     B = zerotol(A, 0.05);       % Returns [0.5, 0.3; 0.1, 0.2]
%                                 % All values > 0.05*0.5 = 0.025
%
%     % Example 5: Clean matrix after numerical computation
%     A = eye(3) - [1 0 0; 0 1 0; 1e-15 0 1];
%     B = zerotol(A);             % Returns [0 0 0; 0 0 0; 0 0 0]
%
%     % Example 6: Vector input
%     x = [1.5, 1e-9, -2.3, 1e-10];
%     y = zerotol(x);             % Returns [1.5, 0, -2.3, 0]
%
%   Algorithm:
%     1. Validate input matrix and tolerance parameter
%     2. Compute relative tolerance using tolerance() function
%     3. Set elements to zero where abs(A(i,j)) <= relative_tolerance
%
%   See also: tolerance, logicalMatrix, abs
%
    % Validate input matrix
    if nargin < 1 || ~ismatrix(A) || ~isnumeric(A)
        msg = buildMessage(mfilename, cMessages.InvalidArgument, cMessages.ShowHelp);
        error(msg);
    end
    % Validate and set default tolerance
    if nargin == 1 || isempty(tol) || ~isscalar(tol) || tol < 0
        tol = cType.EPS;  % Default: 1.0e-8
    end
    % Compute relative tolerance scaled by matrix magnitude
    % This adapts the threshold to the scale of the data
    reltol = tolerance(A, tol);   
    % Set to zero all elements with absolute value <= relative tolerance
    % This cleans up floating-point errors and near-zero values
    A(abs(A) <= reltol) = 0;
    
end