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
    if (nargin<2) || ~isText(filename)
        log.printError('Usage: SaveSummaryResults(arg,filename)');
        return
    end
    if ~isa(model,'cThermoeconomicModel') || ~isValid(model)
        log.printError('Invalid model object');
        return
    end
    if isstring(filename)
        filename=convertStringsToChars(filename);
    end
    % Save summary results
    log=saveSummary(model,filename);
    log.printLogger;
end