function SaveTable(tbl,filename)
% SaveTable generates a filename with the cTable values information
%   The type of file depends on the filename extension
%   Valid extensions are: CSV,XLSX,JSON,XML,HTML,LaTeX and MAT
%   USAGE:
%       SaveTable(table,filename)
%   INPUT:
%       tbl - cTable object
%       filename - Name of file, including extension
    log=cStatus(cType.VALID);
    if nargin~=2
        log.printError('Invalid number of arguments');
        return
    end
    if ~isa(tbl,'cTable') || ~tbl.isValid
        log.printError('Invalid argument');
        return
    end
    log=saveTable(tbl,filename);
    log.printLogger;
end
        