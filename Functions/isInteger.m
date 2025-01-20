function res=isInteger(val)
%isInteger - Check if the value is an integer number
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
    res=isscalar(val) && isnumeric(val) && (mod(val,1)==0);
end