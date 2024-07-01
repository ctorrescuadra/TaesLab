function str = log2str(x)
%log2str - Convert logical values into strings
%
%   Syntax
%     str = log2str(x)
%
%   Input Argument
%     x - logical variable
%
%   Output Argument
%     str - true or false string
    if x
        str='true';
    else
        str='false';
    end
end