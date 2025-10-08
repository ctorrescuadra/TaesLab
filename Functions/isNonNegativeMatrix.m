function res=isNonNegativeMatrix(A,tolerance)
%isNonNegativeMatrix - Check if the matrix is square and non-negative.
%   Check if all elements of the matriz are non-negative with a tolerance of cType.EPS
%
%   Syntax:
%     res = isNonNegativeMatrix(A)
%   Input Arguments:
%     A - Matrix to check
%     tolerance - optional, default is cType.EPS
%       Tolerance for non-negativity check
%   Output Arguments:
%     res - true | false
%
%   Example:
%     A = [1 2; 3 4];
%     res = isNonNegativeMatrix(A) % returns true
%     B = [-1 2; 3 4];
%     res = isNonNegativeMatrix(B) % returns false
    
    %Chech input arguments
    res=false;
    if nargin < 1 || nargin >2 
        return
    end
    if nargin ~= 2 || ~isnumeric(tolerance) || ~isscalar(tolerance) || tolerance<0
        tolerance = cType.EPS; % Default tolerance
    end
    res=isSquareMatrix(A) && all(A(:))>=-tolerance;
end