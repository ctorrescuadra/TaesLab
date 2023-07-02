function SaveSummaryResults(model,filename)
% SaveSummaryResults saves the summary cost tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveSummaryResults(model,filename)
%   INPUT:
%       model - cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveSummaryResults(res,filename)');
        return
    end
    if isa(model,'cThermoeconomicModel')
        log=saveSummary(model,filename);
        printLogger(log);
    else
        log.printError('Invalid result. It sould be a cThermoeconomicModel object');
    end
end