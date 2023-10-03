function SaveModelResults(model,filename)
% SaveResultModel saves the model results into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveModelResults(model,filename)
%   INPUT:
%       model -  cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cThermoeconomicModel
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin<2) || ~ischar(filename) ||  ~isa(model,'cThermoeconomicModel')
        log.printError('Usage: SaveModelResults(results,filename)');
        return
    end
    % Save the results
    log=saveResultsModel(model,filename);
    printLogger(log);
end