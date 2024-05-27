function SaveResults(arg,filename)
% SaveResults saves a cResultInfo into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   It calls cResultInfo method saveResults
%   USAGE:
%       SaveResults(res,filename)
%   INPUT:
%       arg - cResultSet object
%       filename - name of the output file (with extension)
% See also cResultInfo, cThermoeconomicModel or cDataModel
%
    log=cStatus(cType.VALID);
    if ~isa(arg,'cResultSet')       
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    % Check Input parameters
    if (nargin~=2) || ~isText(filename)
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    log=saveResults(arg,filename);
    printLogger(log);
end