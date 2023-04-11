function res=isNumCellArray(c)
    res=iscell(c);
    if ~res
        return
    end
    try
        cell2mat(c);
    catch
        res=false;
    end
end