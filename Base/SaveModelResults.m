function SaveModelResults(model,filename)
% SaveResultModel saves the model results into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   USAGE:
%       SaveModelResults(model,filename)
%   INPUT:
%       results - cResultInfo or cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cModelResults
%
    log=cStatus(cType.VALID);
    % Check Input parameters
    if (nargin~=2) || ~cType.checkFileWrite(filename)
        log.printError('Usage: SaveResultsModel(results,filename)');
        return
    end
    % Save the results
    if isa(model,'cThermoeconomicModel')
        log=saveResultsModel(model,filename);
        printLogger(log);
    else
        log.printError('Invalid model. It sould be a cThermoeconomicModel object');
    end
end