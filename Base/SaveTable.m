function SaveTable(table,filename)
% SaveTable saves a cTable into a file
%   The file type depends on the filename extension
%   *.csv, *.xlsx, *.json, *.xml, *.txt, *.html, *.tex and *.mat are allowed
% USAGE:
%   SaveResults(res,filename)
% INPUT:
%   table - cTable object
%   filename - name of the output file (with extension)
%
% See also cResultSet
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~isText(filename)
        log.printError('Usage: SaveTable(res,table,filename)');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    if ~isa(table,'cTable')
        log.printError('Usage: SaveTable(table,filename)');
    end
    log=saveTable(table,filename);
    printLogger(log);
end