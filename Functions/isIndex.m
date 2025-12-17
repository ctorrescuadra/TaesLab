function res = isIndex(index, minIdx, maxIdx)
%isIndex - Check if an integer value is within a valid index range.
%   Validates if a value is an integer within the specified range [minIdx, maxIdx].
%   All three parameters must be scalar integers. The minimum value must not exceed
%   the maximum value. Returns false if any validation fails.
%   
%   Syntax:
%     res = isIndex(index, minIdx, maxIdx)
%
%   Input Arguments:
%     index  - Value to check (must be integer)
%     minIdx - Minimum index value (must be integer)
%     maxIdx - Maximum index value (must be integer, >= minIdx)
%
%   Output Arguments:
%     res - Logical result
%       true  - index is an integer within [minIdx, maxIdx] range
%       false - index is invalid (non-integer, out of range, or invalid parameters)
%
%   Examples:
%     res = isIndex(3, 1, 5);      % Returns true (3 is in [1,5])
%     res = isIndex(1, 1, 5);      % Returns true (boundary case)
%     res = isIndex(5, 1, 5);      % Returns true (boundary case)
%     res = isIndex(3.1, 1, 5);    % Returns false (not an integer)
%     res = isIndex(6, 1, 5);      % Returns false (out of range)
%     res = isIndex(0, 1, 5);      % Returns false (below minimum)
%     res = isIndex(3, 5, 1);      % Returns false (min > max)
%     res = isIndex([1 2], 1, 5);  % Returns false (not scalar)
%
%   See also: isInteger, isscalar
%
    res = false; 
    % Validate input arguments count
    if nargin ~= 3
        return;
    end
    % Validate all parameters are integers
    if ~isInteger(index) || ~isInteger(minIdx) || ~isInteger(maxIdx)
        return;
    end
    % Validate range is valid (min <= max)
    if minIdx > maxIdx
        return;
    end  
    % Check if index is within range [minIdx, maxIdx]
    res = (index >= minIdx) && (index <= maxIdx);
    
end