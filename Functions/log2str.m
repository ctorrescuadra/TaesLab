function str = log2str(x)
% LOG2STR converts logical values into strings
    if x
        str='true';
    else
        str='false';
    end
end