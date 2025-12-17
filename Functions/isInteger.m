function res = isInteger(val)
%isInteger - Check if the value is an integer number.
%   Validates if the input is a scalar numeric value with no fractional part.
%   Returns false for arrays, non-numeric values, NaN, Inf, or fractional numbers.
%   
%   Syntax:
%     res = isInteger(val)
%
%   Input Arguments:
%     val - value to check (scalar)
%
%   Output Arguments:
%     res - Logical check
%       true  - val is a scalar numeric integer value
%       false - val is not an integer (non-scalar, non-numeric, or fractional)
%
%   Examples:
%     res = isInteger(5);      % Returns true
%     res = isInteger(5.0);    % Returns true
%     res = isInteger(5.1);    % Returns false
%     res = isInteger([1 2]);  % Returns false
%     res = isInteger('5');    % Returns false
%     res = isInteger(NaN);    % Returns false
%     res = isInteger(Inf);    % Returns false
%   
%   See also: isscalar, isnumeric, floor
%
    res = false;   
    % Validate input arguments
    if nargin ~= 1
        return;
    end   
    % Check if value is scalar, numeric, finite, and has no fractional part
    res = isscalar(val) && isnumeric(val) && isfinite(val) && (val == floor(val));    
end