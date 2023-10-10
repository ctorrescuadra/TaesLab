function res=isNumCellArray(c)
% isNumCellArray checks if all the elements of a cell array are numbers
%   USAGE: 
%       res=isNumCellArray(c)
%   INPUT:
%       c - cell array
%   OUTPUT:
%     res - true/false
%   
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