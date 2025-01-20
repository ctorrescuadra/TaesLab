function res=isIndex(index,range)
%isIndex - Check if a number belong to an index range
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
    res=false;
    if ~isnumeric(index)
        return
    end
    if isscalar(index)
        res = isInteger(index) && (index>=range(1)) && (index<=range(end));
    else
        res = all(ismember(index,range));
    end
end