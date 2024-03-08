function SaveTable(arg,table,filename)
% SaveResults saves a cResultSet into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   It calls cResultInfo method saveResults
%   USAGE:
%       SaveResults(res,filename)
%   INPUT:
%       arg - cResultSet object
%       table - table name
%       filename - name of the output file (with extension)
% See also cResultInfo, cThermoeconomicModel or cDataModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=3) || ~isText(filename)
        log.printError('Usage: SaveTable(res,table,filename)');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    log=saveTable(arg,table,filename);
    printLogger(log);
end