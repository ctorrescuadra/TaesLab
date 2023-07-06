function SaveResults(res,filename)
% SaveResults saves a cResultInfo into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   It calls cResultInfo method saveResults
%   USAGE:
%       SaveResults(res,filename)
%   INPUT:
%       results - cResultInfo or cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cModelResults
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    % Save the results
    if isa(res,'cResultInfo')
        log=saveResults(res,filename);
        printLogger(log);
    else
        log.printError('Invalid input. It must be a cResultInfo object');
    end
end