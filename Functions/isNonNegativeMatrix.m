function res=isNonNegativeMatrix(A,tol)
%isNonNegativeMatrix - Check if the matrix is square and non-negative.
%   Check if all elements of the matriz are non-negative with a tolerance of cType.EPS
%
%   Syntax:
%     res = isNonNegativeMatrix(A)
%   Input Arguments:
%     A - Matrix to check
%     tolerance - (optional) tolerance for non-negativity check. 
%       Default value is cType.EPS
%      
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
    try narginchk(1,2); catch, return; end
    if nargin == 1 || ~isnumeric(tol) || ~isscalar(tol) || tol<0
        tol = cType.EPS; % Default tolerance
    end
    reltol=tolerance(A,tol);
    res=isSquareMatrix(A) && all(A(:))>=-reltol;
end