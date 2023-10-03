function SaveSummaryResults(model,filename)
% SaveSummaryResults saves the summary cost tables into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveSummaryResults(arg,filename)
%   INPUT:
%       model - cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~ischar(filename) || ~isa(model,'cThermoeconomicModel') 
        log.printError('Usage: SaveSummaryResults(arg,filename)');
        return
    end
    log=saveSummary(model,filename);
    log.printLogger;
end