function res = logicalMatrix(A, tol)
%logicalMatrix - Convert numeric matrix to logical with zero tolerance.
%	Converts a numeric matrix to a logical (boolean) matrix by first applying
%   zero tolerance to filter out near-zero values, then converting to logical.
%
%   Syntax:
%     B = logicalMatrix(A)
%     B = logicalMatrix(A, tol)
%
%   Input Arguments:
%     A   - Numeric matrix or array
%     tol - Absolute tolerance (scalar, non-negative), optional
%           Default: cType.EPS (1.0e-8)
%
%   Output Arguments:
%     res - Logical matrix
%           res(i,j) = true if abs(A(i,j)) > relative_tolerance
%           res(i,j) = false otherwise
%
%   Examples:
%     % Example 1: Basic conversion with tolerance
%     A = [0.1, 0.2; 0.00001, 0.3];
%     res = logicalMatrix(A, 0.0001);  % Returns [true, true; false, true]
%
%     % Example 2: Default tolerance
%     A = [1, 0; 1e-10, 2];
%     res = logicalMatrix(A);          % Returns [true, false; false, true]
%
%     % Example 3: Adjacency matrix from weights
%     W = [0, 0.5, 0; 0.3, 0, 0.8; 0, 0, 0];
%     adj = logicalMatrix(W);          % Returns [false, true, false; ...]
%
%     % Example 4: Clean correlation matrix
%     C = [1.0, 0.85, 0.001; 0.85, 1.0, 0.002; 0.001, 0.002, 1.0];
%     mask = logicalMatrix(C, 0.1);    % Returns [true, true, false; ...]
%
%     % Example 5: Negative values
%     A = [-0.5, 0.1; 0, -0.3];
%     res = logicalMatrix(A);          % Returns [true, true; false, true]
%
%     % Example 6: Large values with relative tolerance
%     A = [1000, 0.1; 2000, 3000];
%     res = logicalMatrix(A, 1e-6);    % Returns [true, false; true, true]
%                                      % 0.1 < 1e-6*3000, so false
%
%   Algorithm:
%     1. Validate input matrix and tolerance
%     2. Apply zerotol(A, tol) to clean near-zero values
%     3. Convert to logical: logical(cleaned_matrix)
%
%   See also: zerotol, tolerance, logical, transitiveClosure
%
    % Validate input matrix
    if nargin < 1 || ~ismatrix(A) || ~isnumeric(A)
        error(buildMessage(mfilename, cMessages.InvalidArgument, cMessages.ShowHelp));
    end    
    % Validate and set default tolerance
    if nargin == 1 || isempty(tol) || ~isscalar(tol) || tol < 0
        tol = cType.EPS;  % Default: 1.0e-8
    end   
    % Apply zero tolerance to clean near-zero values, then convert to logical
    % Step 1: zerotol sets small values to exact zero
    % Step 2: logical converts 0→false, non-zero→true
    res = logical(zerotol(A, tol));
    
end