function SaveResults(res,filename)
% SaveResults saves a cResultInfo into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   It calls cResultInfo method saveResults
%   USAGE:
%       SaveResults(res,filename)
%   INPUT:
%       res - cResultInfo or cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cModelResults
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~ischar(filename) || ~isa(res,'cResultInfo')
        log.printError('Usage: SaveResults(res,filename)');
        return
    end
    % Save the results
    log=saveResults(res,filename);
    printLogger(log);
end