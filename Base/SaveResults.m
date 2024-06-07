function SaveResults(arg,filename)
% SaveResults saves a cResultSet into a file
%   The file type depends on the file extension
%   *.csv, *.xlsx and *.mat extensions are allowed
% USAGE:
%   SaveResults(res,filename)
% INPUT:
%   arg - cResultSet object
%   filename - name of the output file (with extension)
%
% See also cResultSet
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