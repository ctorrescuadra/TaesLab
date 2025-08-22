function res=isInteger(val)
%isInteger - Check if the value is an integer number.
%   
%   Syntax
%     res = isInteger(val)
%
%   Input Argument
%     val - value to check
%
%   Output Argument
%     res - Logical check
%       true | false
% 
%   Example
%     res = isInteger(5); %return true
%
%   See also isscalar, isnumeric
%    
    res=false;
    if nargin~=1
        return
    end
    res=isscalar(val) && isnumeric(val) && (mod(val,1)==0);
end