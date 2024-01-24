function SaveResults(res,filename)
% SaveResults saves a cResultInfo into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   It calls cResultInfo method saveResults
%   USAGE:
%       SaveResults(res,filename)
%   INPUT:
%       res - cResultInfo object
%       filename - name of the output file (with extension)
% See also cModelResults
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~isText(filename)
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    if ~(isa(res,'cResultInfo') || isa(res,'cThermoeconomicModel')) ||  ~isValid(res)
        log.printError('Invalid result object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Save the results
    log=saveResults(res,filename);
    printLogger(log);
end