function res = log2str(val)
%log2str - Convert logical values into strings
%
%   Syntax
%     str = log2str(x)
%
%   Input Argument
%     val - logical variable or array
%
%   Output Argument
%     str - true or false string or cell array
%
    if ~isnumeric(val)
        res='false';
        return
    end
    if length(val)>1
        res=arrayfun(@(x) log2str(x),val,'UniformOutput',false);
    elseif val
        res='true';
    else
        res='false';
    end
end