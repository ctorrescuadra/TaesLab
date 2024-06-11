function res = checkList(list)
% CheckList checks that all the elements of the list are non-empty and unique
%  USAGE:
%   checkList(list)
%  INPUT:
%   list: cell array with the list elements
%  OUTPUT
%   res: check result (true/false)
    N=length(list);
    try
        tmp=unique(list);
    catch
        res=false;
        return
    end
    res=(length(tmp)==N);
end