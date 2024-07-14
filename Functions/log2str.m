function res=log2str(val)
% Get the string representation of a logical value
%
%   Syntax
%     str = log2str(x)
%
%   Input Argument
%     val - logical variable or array
%
%   Output Argument
%     res - string or cell array
%
    if ~islogical(val) && ~isnumeric(val)
        res=cType.FALSE;
        return
    end
    if length(val)>1
        res=arrayfun(@(x) log2str(x),val,'UniformOutput',false);
    elseif val
        res=cType.TRUE;
    else
        res=cType.FALSE;
    end
end
