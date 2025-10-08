function res=isIndex(index,min,max)
%isIndex - Check if a number belong to an index range.
%   
%   Syntax:
%     res = isIndex(val)
%
%   Input Arguments:
%     index - value to check
%     min   - minimum index value
%     max   - maximum index value
%
%   Output Arguments:
%     res - Logical check
%       true | false
%
%   Example: 
%     res = isIndex(3, 1, 5); %return true
%     res = isIndex(3.1, 1, 5); %return false
%     res = isIndex(6, 1, 5); %return false
%
    res=false;
    % Check Input
    if nargin~=3 || ~isInteger(index) ||~isInteger(min) || ~isInteger(max) || (min>max)
        return
    end
    res = (index>=min) && (index<=max);
end