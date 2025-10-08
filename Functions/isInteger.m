function res=isInteger(val)
%isInteger - Check if the value is an integer number.
%   
%   Syntax:
%     res = isInteger(val)
%
%   Input Arguments:
%     val - value to check
%
%   Output Arguments:
%     res - Logical check
%       true | false
% 
%   Example:
%     res = isInteger(5); %return true
%     res = isInteger(5.1); %return false
%     res = isInteger([1 2]); %return false
%   
    res=false;
    if nargin~=1
        return
    end
    res=isscalar(val) && isnumeric(val) && (val==floor(val));
end