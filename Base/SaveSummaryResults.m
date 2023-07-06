function SaveSummaryResults(arg,filename)
% SaveSummaryResults saves the summary cost tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveSummaryResults(arg,filename)
%   INPUT:
%       arg - cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveSummaryResults(arg,filename)');
        return
    end
    if isa(arg,'cThermoeconomicModel') || isa(arg,'cResultInfo')
        log=saveSummary(arg,filename);
        printLogger(log);
    else
        log.printError('Invalid result. It sould be a cThermoeconomicModel or cResultInfo object');
    end
end