function SaveResultsModel(results,filename)
% SaveResultModel saves the model results into a file
%   The type of file depends on the file extension
%   *.csv, *.xlsx and *.mat are allowed
%   It calls cResultsModel method saveResults
%   INPUT:
%       results - cModelResults or cThermoeconomicModel object
%       filename - name of the output file (with extension)
% See also cModelResults
%
    log=cStatus();
    % Check Input parameters
    if (nargin~=2) || ~ischar(filename)
        log.printError('Usage: SaveResultsModel(results,filename)');
        return
    end
    if ~(isa(results,'cResultInfo') || isa(results,'cThermoeconomicModel'))
        log.printError('Invalid model. It sould be a cResultInfo or cThermoeconomicModel object');
        return
    end
    % Save the results
    log=saveResults(results,filename);
    printLogger(log);
end