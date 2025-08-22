function res=isIndex(index,range)
%isIndex - Check if a number belong to an index range.
%   
%   Syntax
%     res = isIndex(val)
%
%   Input Argument
%     index - value to check
%     range - index range
%
%   Output Argument
%     res - Logical check
%       true | false
%
%   Example 
%     res = isIndex(3, 1:5); %return true
%
    res=false;
    % Check Input
    if nargin~=2 || ~isnumeric(range) || ~isvector(range) || isempty(range)
        return
    end
    if ~isnumeric(index)
        return
    end
    if isscalar(index)
        res = isInteger(index) && (index>=range(1)) && (index<=range(end));
    elseif isvector(index)
        res = all(ismember(index,range));
    end
end