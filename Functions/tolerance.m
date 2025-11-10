function res = tolerance(A, tol)
%TOLERANCE - Compute the relative tolerance value for a matrix.
%   Compute the relative tolerance value for a matrix A given an absolute tolerance tol.
%   If tol is missing, it is taken as cType.EPS.
%    Syntax:
%     res = tolerance(A,tol)
%   Input Arguments:
%     A   - matrix 
%     tol - absolute tolerance (optional, default is cType.EPS)
%   Output Arguments:
%     res - relative tolerance value
%   Example:
%     A = [1, 2; 3, 4];
%     tol = tolerance(A, 0.0001); % tol = 0.0004
%
    if nargin < 2 || isempty(tol) || ~isscalar(tol) || tol < 0
        tol = cType.EPS;
    end
    res = tol * max([1;abs(A(:))]);
end